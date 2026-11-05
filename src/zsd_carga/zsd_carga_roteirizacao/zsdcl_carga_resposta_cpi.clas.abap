CLASS zsdcl_carga_resposta_cpi DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    "! Confere o JSON e valida a cobertura das remessas antes de disponibilizar a sequência.
    METHODS validar_json
      IMPORTING iv_json TYPE string
                iv_carga_enviada TYPE string
                it_remessas TYPE zsdcl_carga_valida_roteiro=>tt_remessas
      EXPORTING et_paradas TYPE zsdcl_carga_valida_roteiro=>tt_paradas
      RETURNING VALUE(rv_valido) TYPE abap_bool.
ENDCLASS.

CLASS zsdcl_carga_resposta_cpi IMPLEMENTATION.
  METHOD validar_json.
    CLEAR: rv_valido, et_paradas.
    DATA lv_carga TYPE string.
    DATA lv_status TYPE string.
    DATA lv_nao_atendidas TYPE abap_bool.
    DATA lt_paradas TYPE zsdcl_carga_valida_roteiro=>tt_paradas.
    DATA ls_parada TYPE zsdcl_carga_valida_roteiro=>ty_parada.
    DATA lv_nivel TYPE i.
    DATA lv_campo TYPE string.
    DATA lv_item_campo TYPE string.
    DATA lv_raiz TYPE abap_bool.
    DATA lv_carga_vista TYPE abap_bool.
    DATA lv_status_visto TYPE abap_bool.
    DATA lv_seq_vista TYPE abap_bool.
    DATA lv_nao_vista TYPE abap_bool.
    DATA lv_item_seq TYPE abap_bool.
    DATA lv_item_remessa TYPE abap_bool.
    DATA lv_valor TYPE string.
    TRY.
        DATA(lv_bytes) = cl_abap_codepage=>convert_to( iv_json ).
        DATA(lo_reader) = cl_sxml_string_reader=>create( lv_bytes ).
        DO.
          lo_reader->next_node( ).
          CASE lo_reader->node_type.
            WHEN if_sxml_node=>co_nt_element_open.
              lv_nivel = lv_nivel + 1.
              DATA(lv_tipo) = lo_reader->name.
              lo_reader->get_attribute_value( name = 'name' ).
              DATA(lv_nome) = lo_reader->value.
              IF lv_nivel = 1.
                IF lv_raiz = abap_true OR lv_tipo <> 'object'.
                  RETURN.
                ENDIF.
                lv_raiz = abap_true.
              ELSEIF lv_nivel = 2.
                lv_campo = lv_nome.
                CASE lv_campo.
                  WHEN 'cargaId'.
                    IF lv_carga_vista = abap_true OR lv_tipo <> 'str'. RETURN. ENDIF.
                    lv_carga_vista = abap_true.
                  WHEN 'status'.
                    IF lv_status_visto = abap_true OR lv_tipo <> 'str'. RETURN. ENDIF.
                    lv_status_visto = abap_true.
                  WHEN 'sequencia'.
                    IF lv_seq_vista = abap_true OR lv_tipo <> 'array'. RETURN. ENDIF.
                    lv_seq_vista = abap_true.
                  WHEN 'naoAtendidas'.
                    IF lv_nao_vista = abap_true OR lv_tipo <> 'array'. RETURN. ENDIF.
                    lv_nao_vista = abap_true.
                ENDCASE.
              ELSEIF lv_nivel = 3 AND lv_campo = 'naoAtendidas'.
                lv_nao_atendidas = abap_true.
              ELSEIF lv_nivel = 3 AND lv_campo = 'sequencia'.
                IF lv_tipo <> 'object'. RETURN. ENDIF.
                CLEAR: ls_parada, lv_item_seq, lv_item_remessa.
              ELSEIF lv_nivel = 4 AND lv_campo = 'sequencia'.
                lv_item_campo = lv_nome.
                CASE lv_item_campo.
                  WHEN 'sequencia'.
                    IF lv_item_seq = abap_true OR lv_tipo <> 'num'. RETURN. ENDIF.
                    lv_item_seq = abap_true.
                  WHEN 'remessa'.
                    IF lv_item_remessa = abap_true OR lv_tipo <> 'str'. RETURN. ENDIF.
                    lv_item_remessa = abap_true.
                ENDCASE.
              ENDIF.
            WHEN if_sxml_node=>co_nt_value.
              lv_valor = lo_reader->value.
              IF lv_nivel = 2.
                CASE lv_campo.
                  WHEN 'cargaId'. lv_carga = lv_valor.
                  WHEN 'status'. lv_status = lv_valor.
                ENDCASE.
              ELSEIF lv_nivel = 4 AND lv_campo = 'sequencia'.
                CASE lv_item_campo.
                  WHEN 'remessa'. ls_parada-remessa = lv_valor.
                  WHEN 'sequencia'.
                    IF lv_valor IS INITIAL OR lv_valor CN '0123456789'. RETURN. ENDIF.
                    ls_parada-sequencia = CONV i( lv_valor ).
                ENDCASE.
              ENDIF.
            WHEN if_sxml_node=>co_nt_element_close.
              IF lv_nivel = 3 AND lv_campo = 'sequencia'.
                IF lv_item_seq = abap_false OR lv_item_remessa = abap_false. RETURN. ENDIF.
                APPEND ls_parada TO lt_paradas.
              ENDIF.
              lv_nivel = lv_nivel - 1.
            WHEN if_sxml_node=>co_nt_final.
              EXIT.
          ENDCASE.
        ENDDO.
      CATCH cx_root.
        RETURN.
    ENDTRY.
    IF lv_nivel <> 0 OR lv_raiz = abap_false OR lv_carga_vista = abap_false
       OR lv_status_visto = abap_false OR lv_seq_vista = abap_false OR lv_nao_vista = abap_false.
      RETURN.
    ENDIF.
    DATA(lo_validador) = NEW zsdcl_carga_valida_roteiro( ).
    rv_valido = lo_validador->validar( iv_carga_enviada = iv_carga_enviada
      iv_carga_retornada = lv_carga iv_status = lv_status iv_tem_nao_atendidas = lv_nao_atendidas
      it_remessas = it_remessas it_paradas = lt_paradas ).
    IF rv_valido = abap_true.
      et_paradas = lt_paradas.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
