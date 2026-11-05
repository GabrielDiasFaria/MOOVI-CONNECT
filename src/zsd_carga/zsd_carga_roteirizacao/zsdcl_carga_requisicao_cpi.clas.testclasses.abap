CLASS ltc_json DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS serializacao FOR TESTING.
ENDCLASS.
CLASS ltc_json IMPLEMENTATION.
  METHOD serializacao.
    DATA lv_lat TYPE decfloat34 VALUE '-23.548'.
    DATA lv_lon TYPE decfloat34 VALUE '-46.753'.
    DATA ls_request TYPE zsdcl_carga_requisicao_cpi=>ty_requisicao.
    ls_request-carga_id = 'UUID'.
    ls_request-data_expedicao = '2026-10-14'.
    ls_request-origem = VALUE #( cd = '0001' endereco = 'CD' lat = REF #( lv_lat ) lon = REF #( lv_lon ) ).
    ls_request-veiculo = VALUE #( tipo = 'VUC' placa = 'TESTE' cap_peso_kg = '1500'
      cap_volume_m3 = '8' hora_saida = '08:00' hora_fim_turno = '18:00' ).
    ls_request-paradas = VALUE #( ( remessa = '0080001001' cliente = '1000101'
      nome = 'Bar do Zé' endereco = 'Rua A' peso_kg = '128.4' volume_m3 = '0.188' ) ).
    DATA(lv_json) = NEW zsdcl_carga_requisicao_cpi( )->serializar( ls_request ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_json exp = '*"cargaId":"UUID"*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_json exp = '*"dataExpedicao":"2026-10-14"*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_json exp = '*"lat":-23.548*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_json exp = '*"capPesoKg":1500*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_json exp = '*"capVolumeM3":8*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_json exp = '*"retornarAoCD":false*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_json exp = '*"pesoKg":128.4*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_json exp = '*"volumeM3":0.188*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_json exp = '*"janela":null*' ).
  ENDMETHOD.
ENDCLASS.
