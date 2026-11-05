CLASS zsdcl_carga_preparacao DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES ty_cabecalhos TYPE STANDARD TABLE OF zsdt_carga_h WITH EMPTY KEY.
    TYPES ty_itens TYPE STANDARD TABLE OF zsdt_carga_it WITH EMPTY KEY.
    "! Monta dados de cabeçalho e itens sem persistir; rejeita qualquer alocação inválida.
    METHODS preparar
      IMPORTING it_alocacoes TYPE zsdcl_carga_planejador=>ty_alocacoes
      EXPORTING et_cabecalhos TYPE ty_cabecalhos
                et_itens TYPE ty_itens
                ev_valido TYPE abap_bool
      RAISING cx_uuid_error.
ENDCLASS.

CLASS zsdcl_carga_preparacao IMPLEMENTATION.
  METHOD preparar.
    TYPES: BEGIN OF ty_carga,
             numero TYPE i,
             cd TYPE vstel,
             uuid TYPE sysuuid_x16,
           END OF ty_carga.
    DATA lt_cargas TYPE HASHED TABLE OF ty_carga WITH UNIQUE KEY numero.
    DATA lt_ids TYPE HASHED TABLE OF outbound_delivery WITH UNIQUE KEY table_line.
    DATA lv_timestamp TYPE timestampl.
    CLEAR: et_cabecalhos, et_itens, ev_valido.
    IF it_alocacoes IS INITIAL.
      RETURN.
    ENDIF.
    " Primeiro valida todo o plano; uma alocação inválida interrompe a preparação.
    LOOP AT it_alocacoes INTO DATA(ls_alocacao).
      IF ls_alocacao-remessa IS INITIAL OR ls_alocacao-cd IS INITIAL OR
         ls_alocacao-carga <= 0 OR ls_alocacao-motivo IS NOT INITIAL.
        RETURN.
      ENDIF.
      INSERT ls_alocacao-remessa INTO TABLE lt_ids.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      READ TABLE lt_cargas ASSIGNING FIELD-SYMBOL(<carga>) WITH TABLE KEY numero = ls_alocacao-carga.
      IF sy-subrc = 0 AND <carga>-cd <> ls_alocacao-cd.
        RETURN.
      ELSEIF sy-subrc <> 0.
        INSERT VALUE #( numero = ls_alocacao-carga cd = ls_alocacao-cd ) INTO TABLE lt_cargas.
      ENDIF.
    ENDLOOP.
    " Gera um UUID por carga e monta os cabeçalhos em memória, com status 01.
    GET TIME STAMP FIELD lv_timestamp.
    LOOP AT lt_cargas ASSIGNING <carga>.
      <carga>-uuid = cl_system_uuid=>create_uuid_x16_static( ).
      APPEND VALUE #( carga_id = <carga>-uuid status = '01' vstel = <carga>-cd
        created_at = lv_timestamp last_changed_at = lv_timestamp
        total_changed_at = lv_timestamp ) TO et_cabecalhos.
    ENDLOOP.
    " Vincula cada remessa ao UUID do cabeçalho correspondente.
    LOOP AT it_alocacoes INTO ls_alocacao.
      APPEND VALUE #( vbeln = ls_alocacao-remessa
        carga_id = lt_cargas[ numero = ls_alocacao-carga ]-uuid ) TO et_itens.
    ENDLOOP.
    " Somente sinaliza sucesso depois de preparar cabeçalhos e itens.
    ev_valido = abap_true.
  ENDMETHOD.
ENDCLASS.
