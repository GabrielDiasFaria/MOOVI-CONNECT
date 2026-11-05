CLASS zsdcl_carga_confirmacao DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    "! Verifica status, existência de remessas e pesos convertidos em quilogramas.
    "! Retorna número da mensagem de erro ou inicial quando a carga pode ser confirmada.
    METHODS validar IMPORTING iv_carga_id TYPE sysuuid_x16
      RETURNING VALUE(rv_mensagem) TYPE symsgno.
ENDCLASS.

CLASS zsdcl_carga_confirmacao IMPLEMENTATION.
  METHOD validar.
    SELECT SINGLE status FROM zsdt_carga_h
      WHERE carga_id = @iv_carga_id INTO @DATA(lv_status).
    IF sy-subrc <> 0 OR lv_status <> '01'.
      rv_mensagem = '007'.
      RETURN.
    ENDIF.

    SELECT item~vbeln, coalesce( peso~GrossWeightKg, 0 ) AS peso_kg
      FROM zsdt_carga_it AS item
      LEFT OUTER JOIN zi_carga_peso_kg AS peso ON peso~DeliveryDocument = item~vbeln
      WHERE item~carga_id = @iv_carga_id
      INTO TABLE @DATA(lt_pesos).
    IF lt_pesos IS INITIAL.
      rv_mensagem = '008'.
      RETURN.
    ENDIF.
    DATA lv_total TYPE decfloat34.
    LOOP AT lt_pesos INTO DATA(ls_peso).
      IF ls_peso-peso_kg <= 0.
        rv_mensagem = '008'.
        RETURN.
      ENDIF.
      lv_total = lv_total + ls_peso-peso_kg.
    ENDLOOP.
    IF lv_total > 14000.
      rv_mensagem = '009'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
