CLASS ltc_resposta_cpi DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS valido FOR TESTING.
    METHODS ausente_nula FOR TESTING.
    METHODS resposta_invalida FOR TESTING.
    METHODS divergencias FOR TESTING.
    METHODS exemplo_oito FOR TESTING.
    METHODS verificar IMPORTING iv_json TYPE string iv_esperado TYPE abap_bool.
ENDCLASS.
CLASS ltc_resposta_cpi IMPLEMENTATION.
  METHOD verificar.
    DATA lt_paradas TYPE zsdcl_carga_valida_roteiro=>tt_paradas.
    DATA(lv_valido) = NEW zsdcl_carga_resposta_cpi( )->validar_json(
      EXPORTING iv_json = iv_json iv_carga_enviada = 'C1'
        it_remessas = VALUE #( ( `0001` ) ( `0002` ) )
      IMPORTING et_paradas = lt_paradas ).
    cl_abap_unit_assert=>assert_equals( act = lv_valido exp = iv_esperado ).
    IF iv_esperado = abap_true.
      cl_abap_unit_assert=>assert_equals( act = lines( lt_paradas ) exp = 2 ).
    ELSE.
      cl_abap_unit_assert=>assert_initial( lt_paradas ).
    ENDIF.
  ENDMETHOD.
  METHOD valido.
    DATA(lv_json) = `{"cargaId":"C1","status":"ROTEIRIZADA",` &&
      `"sequencia":[{"sequencia":1,"remessa":"0001","nome":"Teste"},` &&
      `{"sequencia":2,"remessa":"0002"}],"naoAtendidas":[],"alertas":[]}`.
    verificar( iv_json = lv_json iv_esperado = abap_true ).
  ENDMETHOD.
  METHOD ausente_nula.
    DATA(lv_prefixo) = `{"cargaId":"C1","status":"ROTEIRIZADA",` &&
      `"sequencia":[{"sequencia":1,"remessa":"0001"},{"sequencia":2,"remessa":"0002"}]`.
    verificar( iv_json = lv_prefixo && `}` iv_esperado = abap_false ).
    verificar( iv_json = lv_prefixo && `,"naoAtendidas":null}` iv_esperado = abap_false ).
    verificar( iv_json = lv_prefixo && `,"naoAtendidas":[{"remessa":"0003"}]}` iv_esperado = abap_false ).
  ENDMETHOD.
  METHOD resposta_invalida.
    verificar( iv_json = `{"cargaId":"C1","status":"ROTEIRIZADA","sequencia":[` iv_esperado = abap_false ).
    DATA(lv_json) = `{"cargaId":"C1","status":"ROTEIRIZADA",` &&
      `"sequencia":[{"sequencia":"1","remessa":"0001"},{"sequencia":2,"remessa":"0002"}],"naoAtendidas":[]}`.
    verificar( iv_json = lv_json iv_esperado = abap_false ).
    lv_json = `{"cargaId":"C1","status":"ROTEIRIZADA",` &&
      `"sequencia":[{"sequencia":1,"remessa":"0001"},{"sequencia":2,"remessa":"0002"}],"naoAtendidas":{}}`.
    verificar( iv_json = lv_json iv_esperado = abap_false ).
  ENDMETHOD.
  METHOD divergencias.
    DATA(lv_base) = `,"status":"ROTEIRIZADA","sequencia":[` &&
      `{"sequencia":1,"remessa":"0001"},{"sequencia":2,"remessa":"0002"}],"naoAtendidas":[]}`.
    verificar( iv_json = `{"cargaId":"C2"` && lv_base iv_esperado = abap_false ).
    DATA(lv_json) = `{"cargaId":"C1","status":"ROTEIRIZADA",` &&
      `"sequencia":[{"sequencia":1,"remessa":"0001"},{"sequencia":1,"remessa":"0002"}],"naoAtendidas":[]}`.
    verificar( iv_json = lv_json iv_esperado = abap_false ).
    lv_json = `{"cargaId":"C1","status":"ROTEIRIZADA",` &&
      `"sequencia":[{"sequencia":1,"remessa":"0001"},{"sequencia":2,"remessa":"0003"}],"naoAtendidas":[]}`.
    verificar( iv_json = lv_json iv_esperado = abap_false ).
  ENDMETHOD.
  METHOD exemplo_oito.
    DATA lt_paradas TYPE zsdcl_carga_valida_roteiro=>tt_paradas.
    DATA(lv_json) = `{"cargaId":"CG-000001","dataExpedicao":"2026-10-14",` &&
      `"status":"ROTEIRIZADA","metodo":"GEOAPIFY",` &&
      `"resumo":{"paradas":8,"distanciaKm":33.7,"retornaAoCD":false},"sequencia":[` &&
      `{"sequencia":1,"remessa":"0080001001","nome":"Bar do Z\u00e9"},` &&
      `{"sequencia":2,"remessa":"0080001002"},{"sequencia":3,"remessa":"0080001003"},` &&
      `{"sequencia":4,"remessa":"0080001004"},{"sequencia":5,"remessa":"0080001005"},` &&
      `{"sequencia":6,"remessa":"0080001006"},{"sequencia":7,"remessa":"0080001007"},` &&
      `{"sequencia":8,"remessa":"0080001008"}],"naoAtendidas":[],"alertas":[]}`.
    DATA(lv_valido) = NEW zsdcl_carga_resposta_cpi( )->validar_json(
      EXPORTING iv_carga_enviada = 'CG-000001'
        it_remessas = VALUE #( ( `0080001001` ) ( `0080001002` ) ( `0080001003` ) ( `0080001004` )
                               ( `0080001005` ) ( `0080001006` ) ( `0080001007` ) ( `0080001008` ) )
        iv_json = lv_json IMPORTING et_paradas = lt_paradas ).
    cl_abap_unit_assert=>assert_true( lv_valido ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_paradas ) exp = 8 ).
  ENDMETHOD.
ENDCLASS.
