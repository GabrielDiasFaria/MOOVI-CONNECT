CLASS zsdcl_carga_reset DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PRIVATE SECTION.
    CONSTANTS gc_executar TYPE abap_bool VALUE abap_true.
    CONSTANTS gc_limpar_sem_geo TYPE abap_bool VALUE abap_true.
    METHODS limpar_sem_geo IMPORTING io_out TYPE REF TO if_oo_adt_classrun_out.
ENDCLASS.

CLASS zsdcl_carga_reset IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    IF sy-sysid <> 'S4H' OR sy-mandt <> '250'.
      out->write( text-001 ).
      RETURN.
    ENDIF.
    AUTHORITY-CHECK OBJECT 'S_TABU_NAM'
      ID 'TABLE' FIELD 'ZSDT_CARGA_H' ID 'ACTVT' FIELD '02'.
    IF sy-subrc <> 0.
      out->write( text-002 ).
      RETURN.
    ENDIF.
    AUTHORITY-CHECK OBJECT 'S_TABU_NAM'
      ID 'TABLE' FIELD 'ZSDT_CARGA_IT' ID 'ACTVT' FIELD '02'.
    IF sy-subrc <> 0.
      out->write( text-003 ).
      RETURN.
    ENDIF.

    CALL FUNCTION 'ENQUEUE_EZSDCARGAH'
      EXPORTING client = sy-mandt _scope = '1' _wait = space
      EXCEPTIONS foreign_lock = 1 system_failure = 2 OTHERS = 3.
    IF sy-subrc <> 0.
      out->write( text-004 ).
      RETURN.
    ENDIF.

    IF gc_limpar_sem_geo = abap_true.
      limpar_sem_geo( out ).
      CALL FUNCTION 'DEQUEUE_EZSDCARGAH'
        EXPORTING client = sy-mandt _scope = '1' _synchron = 'X'.
      RETURN.
    ENDIF.

    TRY.
        SELECT carga_id, status, vstel FROM zsdt_carga_h
          ORDER BY carga_id INTO TABLE @DATA(lt_cargas).
        SELECT COUNT(*) FROM zsdt_carga_it INTO @DATA(lv_itens).
        SELECT COUNT(*) FROM zsdt_carga_it WHERE seq_entrega <> 0
          INTO @DATA(lv_sequenciados).
        out->write( text-005 ).
        out->write( lt_cargas ).
        out->write( data = lines( lt_cargas ) name = CONV string( text-006 ) ).
        out->write( data = lv_itens name = CONV string( text-007 ) ).
        out->write( data = lv_sequenciados name = CONV string( text-008 ) ).

        IF gc_executar = abap_true.
          GET TIME STAMP FIELD DATA(lv_timestamp).
          UPDATE zsdt_carga_h SET status = '02',
            last_changed_at = @lv_timestamp, total_changed_at = @lv_timestamp.
          DATA(lv_cargas_atualizadas) = sy-dbcnt.
          UPDATE zsdt_carga_it SET seq_entrega = 0.
          DATA(lv_itens_atualizados) = sy-dbcnt.
          IF lv_cargas_atualizadas <> lines( lt_cargas ) OR lv_itens_atualizados <> lv_itens.
            ROLLBACK WORK.
            out->write( text-009 ).
          ELSE.
            COMMIT WORK AND WAIT.
            out->write( text-010 ).
            out->write( data = lv_cargas_atualizadas name = CONV string( text-006 ) ).
            out->write( data = lv_itens_atualizados name = CONV string( text-007 ) ).
          ENDIF.
        ELSE.
          out->write( text-011 ).
        ENDIF.
      CATCH cx_sy_open_sql_db INTO DATA(lx_sql).
        ROLLBACK WORK.
        out->write( text-012 ).
        out->write( lx_sql->get_text( ) ).
    ENDTRY.

    CALL FUNCTION 'DEQUEUE_EZSDCARGAH'
      EXPORTING client = sy-mandt _scope = '1' _synchron = 'X'.
  ENDMETHOD.

  METHOD limpar_sem_geo.
    TYPES: BEGIN OF ty_item,
             vbeln TYPE zsdt_carga_it-vbeln,
             carga_id TYPE zsdt_carga_it-carga_id,
           END OF ty_item,
           ty_itens TYPE HASHED TABLE OF ty_item WITH UNIQUE KEY vbeln.
    DATA lt_itens TYPE ty_itens.
    DATA lt_vistos TYPE ty_itens.
    DATA lr_cargas TYPE RANGE OF zsdt_carga_h-carga_id.

    TRY.
        SELECT carga_id, status, vstel FROM zsdt_carga_h
          INTO TABLE @DATA(lt_cabecalhos).
        LOOP AT lt_cabecalhos INTO DATA(ls_cabecalho).
          AUTHORITY-CHECK OBJECT 'V_LIKP_VST'
            ID 'VSTEL' FIELD ls_cabecalho-vstel ID 'ACTVT' FIELD '03'.
          IF sy-subrc <> 0 OR ls_cabecalho-vstel IS INITIAL.
            io_out->write( text-013 ).
            RETURN.
          ENDIF.
        ENDLOOP.

        SELECT vbeln, carga_id FROM zsdt_carga_it INTO TABLE @lt_itens.
        SELECT i~vbeln, i~carga_id, d~DeliveryAddressId, d~Latitude, d~Longitude,
               CASE WHEN d~DeliveryDocument IS NULL THEN 'X' ELSE ' ' END AS detalhe_ausente,
               CASE WHEN d~Latitude IS NULL OR d~Longitude IS NULL THEN 'X' ELSE ' ' END AS geo_ausente,
               g~CoordinateCount
          FROM zsdt_carga_it AS i
          LEFT OUTER JOIN zi_carga_detalhe AS d ON d~DeliveryDocument = i~vbeln
          LEFT OUTER JOIN zi_carga_geo_unica AS g ON g~AddressId = d~DeliveryAddressId
          INTO TABLE @DATA(lt_detalhes).

        LOOP AT lt_detalhes INTO DATA(ls_detalhe).
          IF NOT line_exists( lt_cabecalhos[ carga_id = ls_detalhe-carga_id ] )
             OR ls_detalhe-detalhe_ausente = 'X'.
            io_out->write( text-014 ).
            RETURN.
          ENDIF.
          INSERT VALUE #( vbeln = ls_detalhe-vbeln carga_id = ls_detalhe-carga_id ) INTO TABLE lt_vistos.
          IF sy-subrc <> 0.
            io_out->write( text-015 ).
            RETURN.
          ENDIF.
          IF ls_detalhe-CoordinateCount > 1.
            io_out->write( text-016 ).
            io_out->write( ls_detalhe ).
            RETURN.
          ENDIF.
          IF ls_detalhe-geo_ausente = 'X'.
            IF NOT line_exists( lr_cargas[ low = ls_detalhe-carga_id ] ).
              APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_detalhe-carga_id ) TO lr_cargas.
            ENDIF.
            io_out->write( ls_detalhe ).
          ENDIF.
        ENDLOOP.
        IF lines( lt_vistos ) <> lines( lt_itens ).
          io_out->write( text-014 ).
          RETURN.
        ENDIF.

        IF lr_cargas IS INITIAL.
          io_out->write( text-017 ).
          RETURN.
        ENDIF.
        DATA lv_vinculos TYPE i.
        LOOP AT lt_itens INTO DATA(ls_item).
          IF ls_item-carga_id IN lr_cargas.
            lv_vinculos += 1.
          ENDIF.
        ENDLOOP.
        io_out->write( text-018 ).
        io_out->write( lr_cargas ).
        io_out->write( data = lines( lr_cargas ) name = CONV string( text-006 ) ).
        io_out->write( data = lv_vinculos name = CONV string( text-007 ) ).
        IF gc_executar <> abap_true.
          io_out->write( text-011 ).
          RETURN.
        ENDIF.
        DELETE FROM zsdt_carga_it WHERE carga_id IN @lr_cargas.
        DATA(lv_itens_excluidos) = sy-dbcnt.
        DELETE FROM zsdt_carga_h WHERE carga_id IN @lr_cargas.
        DATA(lv_cargas_excluidas) = sy-dbcnt.
        IF lv_itens_excluidos <> lv_vinculos OR lv_cargas_excluidas <> lines( lr_cargas ).
          ROLLBACK WORK.
          io_out->write( text-009 ).
          RETURN.
        ENDIF.
        COMMIT WORK AND WAIT.
        io_out->write( text-019 ).
      CATCH cx_sy_open_sql_db INTO DATA(lx_sql).
        ROLLBACK WORK.
        io_out->write( text-012 ).
        io_out->write( lx_sql->get_text( ) ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
