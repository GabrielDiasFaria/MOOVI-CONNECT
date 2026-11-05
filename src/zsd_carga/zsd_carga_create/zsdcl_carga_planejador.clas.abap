CLASS zsdcl_carga_planejador DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_remessa,
             remessa TYPE outbound_delivery,
             cd TYPE vstel,
             peso_kg TYPE decfloat34,
             regiao TYPE char2,
           END OF ty_remessa,
           ty_remessas TYPE STANDARD TABLE OF ty_remessa WITH EMPTY KEY,
           BEGIN OF ty_alocacao,
             remessa TYPE outbound_delivery,
             cd TYPE vstel,
             carga TYPE i,
             motivo TYPE char1,
           END OF ty_alocacao,
           ty_alocacoes TYPE STANDARD TABLE OF ty_alocacao WITH EMPTY KEY.
    CONSTANTS gc_cd_invalido TYPE char1 VALUE 'C'.
    "! Planeja cargas sem persistência, separadas por CD.
    METHODS planejar IMPORTING it_remessas TYPE ty_remessas
                     RETURNING VALUE(rt_alocacoes) TYPE ty_alocacoes.
ENDCLASS.

CLASS zsdcl_carga_planejador IMPLEMENTATION.
  METHOD planejar.
    DATA lt_validas TYPE ty_remessas.
    DATA lt_ids TYPE HASHED TABLE OF outbound_delivery WITH UNIQUE KEY table_line.
    DATA lv_offset TYPE i.
    DATA(lt_ordenadas) = it_remessas.
    " Valida remessas duplicadas e CD antes de formar grupos.
    SORT lt_ordenadas BY remessa cd.
    LOOP AT lt_ordenadas INTO DATA(ls_remessa).
      IF ls_remessa-remessa IS INITIAL.
        APPEND VALUE #( remessa = ls_remessa-remessa cd = ls_remessa-cd
          motivo = zsdcl_carga_agrupamento=>gc_remessa_invalida ) TO rt_alocacoes.
        CONTINUE.
      ENDIF.
      INSERT ls_remessa-remessa INTO TABLE lt_ids.
      IF sy-subrc <> 0.
        APPEND VALUE #( remessa = ls_remessa-remessa cd = ls_remessa-cd
          motivo = zsdcl_carga_agrupamento=>gc_remessa_duplicada ) TO rt_alocacoes.
      ELSEIF ls_remessa-cd IS INITIAL.
        APPEND VALUE #( remessa = ls_remessa-remessa
          motivo = gc_cd_invalido ) TO rt_alocacoes.
      ELSE.
        APPEND ls_remessa TO lt_validas.
      ENDIF.
    ENDLOOP.
    " Cada CD é planejado separadamente, sem misturar remessas entre CDs.
    SORT lt_validas BY cd remessa.
    LOOP AT lt_validas INTO ls_remessa GROUP BY ls_remessa-cd ASSIGNING FIELD-SYMBOL(<lfs_cd>).
      DATA lt_cd TYPE zsdcl_carga_agrupamento=>ty_remessas.
      CLEAR lt_cd.
      LOOP AT GROUP <lfs_cd> INTO DATA(ls_membro).
        APPEND VALUE #( remessa = ls_membro-remessa peso_kg = ls_membro-peso_kg
                        regiao = ls_membro-regiao ) TO lt_cd.
      ENDLOOP.
      " O agrupador aplica o limite de peso ao conjunto deste CD.
      DATA(lt_resultado) = NEW zsdcl_carga_agrupamento( )->agrupar( lt_cd ).
      DATA(lv_maximo) = 0.
      LOOP AT lt_resultado INTO DATA(ls_resultado).
        IF ls_resultado-carga > lv_maximo.
          lv_maximo = ls_resultado-carga.
        ENDIF.
        APPEND VALUE #( remessa = ls_resultado-remessa cd = <lfs_cd>
          carga = COND #( WHEN ls_resultado-carga > 0 THEN ls_resultado-carga + lv_offset ELSE 0 )
          motivo = ls_resultado-motivo ) TO rt_alocacoes.
      ENDLOOP.
      " Desloca a numeração para não repetir números de carga entre CDs.
      lv_offset += lv_maximo.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
