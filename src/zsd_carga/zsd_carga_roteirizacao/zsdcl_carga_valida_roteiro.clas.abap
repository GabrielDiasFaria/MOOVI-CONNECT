CLASS zsdcl_carga_valida_roteiro DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES tt_remessas TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    TYPES: BEGIN OF ty_parada,
             remessa TYPE string,
             sequencia TYPE i,
           END OF ty_parada,
           tt_paradas TYPE STANDARD TABLE OF ty_parada WITH EMPTY KEY.
    "! Valida a cobertura e a ordem antes de persistir o retorno do CPI.
    METHODS validar
      IMPORTING iv_carga_enviada TYPE string
                iv_carga_retornada TYPE string
                iv_status TYPE string
                iv_tem_nao_atendidas TYPE abap_bool
                it_remessas TYPE tt_remessas
                it_paradas TYPE tt_paradas
      RETURNING VALUE(rv_valido) TYPE abap_bool.
ENDCLASS.

CLASS zsdcl_carga_valida_roteiro IMPLEMENTATION.
  METHOD validar.
    rv_valido = abap_false.
    IF iv_carga_enviada IS INITIAL OR iv_carga_enviada <> iv_carga_retornada
       OR iv_status <> 'ROTEIRIZADA' OR iv_tem_nao_atendidas <> abap_false
       OR it_remessas IS INITIAL OR lines( it_remessas ) <> lines( it_paradas ).
      RETURN.
    ENDIF.

    DATA lt_remessas_unicas TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line.
    DATA lt_remessas_retornadas TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line.
    DATA lt_sequencias TYPE HASHED TABLE OF i WITH UNIQUE KEY table_line.
    LOOP AT it_remessas INTO DATA(lv_remessa).
      IF lv_remessa IS INITIAL.
        RETURN.
      ENDIF.
      INSERT lv_remessa INTO TABLE lt_remessas_unicas.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
    ENDLOOP.
    LOOP AT it_paradas INTO DATA(ls_parada).
      IF ls_parada-sequencia < 1 OR ls_parada-sequencia > lines( it_remessas )
         OR NOT line_exists( lt_remessas_unicas[ table_line = ls_parada-remessa ] ).
        RETURN.
      ENDIF.
      INSERT ls_parada-remessa INTO TABLE lt_remessas_retornadas.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      INSERT ls_parada-sequencia INTO TABLE lt_sequencias.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
    ENDLOOP.
    rv_valido = abap_true.
  ENDMETHOD.
ENDCLASS.
