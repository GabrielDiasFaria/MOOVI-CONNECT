CLASS lcl_buffer IMPLEMENTATION.
  METHOD limpar.
    LOOP AT cargas INTO DATA(ls_carga).
      TRY.
          ls_carga-lock->liberar( ).
        CATCH cx_abap_lock_failure.
      ENDTRY.
    ENDLOOP.
    CLEAR cargas.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_carga DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS confirmar FOR MODIFY
      IMPORTING keys FOR ACTION Carga~confirmar.

    METHODS read FOR READ IMPORTING keys FOR READ carga RESULT result.
    METHODS roteirizacao FOR MODIFY IMPORTING keys FOR ACTION carga~roteirizacao.
ENDCLASS.
CLASS lhc_carga IMPLEMENTATION.
  METHOD read.
    IF keys IS INITIAL. RETURN. ENDIF.
    SELECT CargaId, Status, StatusTexto, ShippingPoint, CreatedAt, LastChangedAt,
           TotalChangedAt, TotalRemessas, PesoTotalKg, UnidadePeso, HeaderIcon, RemessasSemPeso,
           OcupacaoPercentual, OcupacaoIndisponivel, SituacaoPeso, MetaOcupacao, CriticidadeOcupacao
      FROM zi_carga_roteir FOR ALL ENTRIES IN @keys WHERE CargaId = @keys-CargaId
      INTO CORRESPONDING FIELDS OF TABLE @result.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      IF NOT line_exists( result[ KEY entity COMPONENTS CargaId = <key>-CargaId ] ).
        APPEND VALUE #( %tky = <key>-%tky %fail-cause = if_abap_behv=>cause-not_found ) TO failed-carga.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
  METHOD roteirizacao.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      DATA(lv_erro) = ``.
      DATA(lv_json) = ``.
      DATA(lv_carga) = ``.
      DATA(lv_resposta) = ``.
      DATA lv_http TYPE i.
      DATA lt_remessas TYPE zsdcl_carga_valida_roteiro=>tt_remessas.
      DATA lt_paradas TYPE zsdcl_carga_valida_roteiro=>tt_paradas.
      CLEAR: lv_http, lt_remessas, lt_paradas.
      IF line_exists( lcl_buffer=>cargas[ carga_id = <key>-CargaId ] ).
        lv_erro = 'Carga já está em processamento'.
      ELSE.
        DATA(lo_lock) = NEW zsdcl_carga_lock( ).
        TRY.
            lo_lock->bloquear( <key>-CargaId ).
          CATCH cx_abap_foreign_lock cx_abap_lock_failure.
            lv_erro = 'Carga bloqueada ou erro de bloqueio'.
        ENDTRY.
      ENDIF.
      IF lv_erro IS INITIAL.
        NEW zsdcl_carga_prepara_cpi( )->preparar( EXPORTING iv_carga_id = <key>-CargaId
          IMPORTING ev_json = lv_json ev_carga = lv_carga ev_erro = lv_erro et_remessas = lt_remessas ).
      ENDIF.
      IF lv_erro IS INITIAL.
        TRY.
            DATA(lv_request_id) = CONV string( cl_system_uuid=>if_system_uuid_static~create_uuid_c32( ) ).
            NEW zsdcl_carga_cpi( )->executar( EXPORTING iv_json = lv_json iv_request_id = lv_request_id
              IMPORTING ev_json = lv_resposta ev_http_code = lv_http ev_erro = lv_erro ).
            IF lv_erro IS NOT INITIAL AND lv_http IS NOT INITIAL.
              lv_erro = |{ lv_erro } ({ lv_http })|.
            ENDIF.
          CATCH cx_uuid_error.
            lv_erro = 'Falha ao criar identificador da requisição'.
        ENDTRY.
      ENDIF.
      IF lv_erro IS INITIAL.
        DATA(lv_valido) = NEW zsdcl_carga_resposta_cpi( )->validar_json(
          EXPORTING iv_json = lv_resposta iv_carga_enviada = lv_carga it_remessas = lt_remessas
          IMPORTING et_paradas = lt_paradas ).
        IF lv_valido = abap_false.
          lv_erro = 'Retorno CPI inválido ou incompleto'.
        ENDIF.
      ENDIF.
      IF lv_erro IS NOT INITIAL.
        IF lo_lock IS BOUND.
          TRY. lo_lock->liberar( ). CATCH cx_abap_lock_failure. ENDTRY.
        ENDIF.
        APPEND VALUE #( %tky = <key>-%tky %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-carga.
        APPEND VALUE #( %tky = <key>-%tky %msg = new_message( id = 'ZSD_CARGA_ROTEIR' number = '003'
          v1 = CONV symsgv( lv_erro ) severity = if_abap_behv_message=>severity-error ) ) TO reported-carga.
      ELSE.
        APPEND VALUE #( carga_id = <key>-CargaId lock = lo_lock paradas = lt_paradas ) TO lcl_buffer=>cargas.
        APPEND VALUE #( %tky = <key>-%tky %msg = new_message( id = 'ZSD_CARGA_ROTEIR' number = '006'
          severity = if_abap_behv_message=>severity-success ) ) TO reported-carga.
      ENDIF.
      CLEAR lo_lock.
    ENDLOOP.
  ENDMETHOD.
  METHOD confirmar.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      DATA lv_mensagem TYPE symsgno.
      DATA lo_lock TYPE REF TO zsdcl_carga_lock.
      CLEAR: lv_mensagem, lo_lock.
      IF line_exists( lcl_buffer=>cargas[ carga_id = <key>-CargaId ] ).
        lv_mensagem = '010'.
      ELSE.
        lo_lock = NEW zsdcl_carga_lock( ).
        TRY.
            lo_lock->bloquear( <key>-CargaId ).
          CATCH cx_abap_foreign_lock cx_abap_lock_failure.
            lv_mensagem = '010'.
        ENDTRY.
      ENDIF.
      IF lv_mensagem IS INITIAL.
        lv_mensagem = NEW zsdcl_carga_confirmacao( )->validar( <key>-CargaId ).
      ENDIF.
      IF lv_mensagem IS NOT INITIAL.
        IF lo_lock IS BOUND.
          TRY. lo_lock->liberar( ). CATCH cx_abap_lock_failure. ENDTRY.
        ENDIF.
        APPEND VALUE #( %tky = <key>-%tky %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-carga.
        APPEND VALUE #( %tky = <key>-%tky %msg = new_message( id = 'ZSD_CARGA_ROTEIR' number = lv_mensagem
          severity = if_abap_behv_message=>severity-error ) ) TO reported-carga.
      ELSE.
        APPEND VALUE #( carga_id = <key>-CargaId lock = lo_lock confirmar = abap_true ) TO lcl_buffer=>cargas.
        APPEND VALUE #( %tky = <key>-%tky %msg = new_message( id = 'ZSD_CARGA_ROTEIR' number = '011'
          severity = if_abap_behv_message=>severity-success ) ) TO reported-carga.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_zi_carga_roteir DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS check_before_save REDEFINITION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.
CLASS lsc_zi_carga_roteir IMPLEMENTATION.
  METHOD check_before_save.
    LOOP AT lcl_buffer=>cargas INTO DATA(ls_carga).
      IF ls_carga-confirmar = abap_true.
        DATA(lv_mensagem) = NEW zsdcl_carga_confirmacao( )->validar( ls_carga-carga_id ).
        IF lv_mensagem IS NOT INITIAL.
          APPEND VALUE #( CargaId = ls_carga-carga_id %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-carga.
          APPEND VALUE #( CargaId = ls_carga-carga_id %msg = new_message( id = 'ZSD_CARGA_ROTEIR'
            number = lv_mensagem severity = if_abap_behv_message=>severity-error ) ) TO reported-carga.
        ENDIF.
        CONTINUE.
      ENDIF.
      SELECT SINGLE status FROM zsdt_carga_h WHERE carga_id = @ls_carga-carga_id INTO @DATA(lv_status).
      IF sy-subrc <> 0 OR lv_status <> '02'.
        APPEND VALUE #( CargaId = ls_carga-carga_id %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-carga.
        CONTINUE.
      ENDIF.
      SELECT vbeln FROM zsdt_carga_it WHERE carga_id = @ls_carga-carga_id INTO TABLE @DATA(lt_itens).
      IF sy-subrc <> 0 OR lines( lt_itens ) <> lines( ls_carga-paradas ).
        APPEND VALUE #( CargaId = ls_carga-carga_id %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-carga.
        CONTINUE.
      ENDIF.
      LOOP AT ls_carga-paradas INTO DATA(ls_parada).
        IF NOT line_exists( lt_itens[ vbeln = ls_parada-remessa ] ).
          APPEND VALUE #( CargaId = ls_carga-carga_id %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-carga.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
  METHOD save.
    LOOP AT lcl_buffer=>cargas INTO DATA(ls_carga).
      IF ls_carga-confirmar = abap_true.
        GET TIME STAMP FIELD DATA(lv_timestamp).
        UPDATE zsdt_carga_h SET status = '02', last_changed_at = @lv_timestamp, total_changed_at = @lv_timestamp
          WHERE carga_id = @ls_carga-carga_id AND status = '01'.
        IF sy-dbcnt <> 1.
          RAISE EXCEPTION TYPE cx_abap_behv_save_failed.
        ENDIF.
        CONTINUE.
      ENDIF.
      LOOP AT ls_carga-paradas INTO DATA(ls_parada).
        DATA(lv_vbeln) = CONV zsdt_carga_it-vbeln( ls_parada-remessa ).
        UPDATE zsdt_carga_it SET seq_entrega = @ls_parada-sequencia
          WHERE carga_id = @ls_carga-carga_id AND vbeln = @lv_vbeln.
        IF sy-dbcnt <> 1.
          RAISE EXCEPTION TYPE cx_abap_behv_save_failed.
        ENDIF.
      ENDLOOP.
      GET TIME STAMP FIELD lv_timestamp.
      UPDATE zsdt_carga_h SET status = '03', last_changed_at = @lv_timestamp, total_changed_at = @lv_timestamp
        WHERE carga_id = @ls_carga-carga_id AND status = '02'.
      IF sy-dbcnt <> 1.
        RAISE EXCEPTION TYPE cx_abap_behv_save_failed.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
  METHOD cleanup.
    lcl_buffer=>limpar( ).
  ENDMETHOD.
  METHOD cleanup_finalize.
    lcl_buffer=>limpar( ).
  ENDMETHOD.
ENDCLASS.
