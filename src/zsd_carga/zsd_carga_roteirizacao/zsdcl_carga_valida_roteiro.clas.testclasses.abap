CLASS ltc_valida_roteiro DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    DATA mo_validador TYPE REF TO zsdcl_carga_valida_roteiro.
    METHODS setup.
    METHODS retorno_valido FOR TESTING.
    METHODS sequencia_duplicada FOR TESTING.
    METHODS remessa_desconhecida FOR TESTING.
    METHODS carga_divergente FOR TESTING.
    METHODS nao_atendida FOR TESTING.
    METHODS exemplo_oito_paradas FOR TESTING.
    METHODS status_invalido FOR TESTING.
    METHODS remessa_duplicada FOR TESTING.
    METHODS sequencia_fora_limite FOR TESTING.
    METHODS sem_cobertura FOR TESTING.
    METHODS sem_remessas FOR TESTING.
ENDCLASS.

CLASS ltc_valida_roteiro IMPLEMENTATION.
  METHOD setup.
    mo_validador = NEW #( ).
  ENDMETHOD.
  METHOD retorno_valido.
    cl_abap_unit_assert=>assert_true( mo_validador->validar(
      iv_carga_enviada = 'C1' iv_carga_retornada = 'C1' iv_status = 'ROTEIRIZADA'
      iv_tem_nao_atendidas = abap_false it_remessas = VALUE #( ( `0001` ) ( `0002` ) )
      it_paradas = VALUE #( ( remessa = `0002` sequencia = 1 ) ( remessa = `0001` sequencia = 2 ) ) ) ).
  ENDMETHOD.
  METHOD sequencia_duplicada.
    cl_abap_unit_assert=>assert_false( mo_validador->validar(
      iv_carga_enviada = 'C1' iv_carga_retornada = 'C1' iv_status = 'ROTEIRIZADA'
      iv_tem_nao_atendidas = abap_false it_remessas = VALUE #( ( `0001` ) ( `0002` ) )
      it_paradas = VALUE #( ( remessa = `0001` sequencia = 1 ) ( remessa = `0002` sequencia = 1 ) ) ) ).
  ENDMETHOD.
  METHOD remessa_desconhecida.
    cl_abap_unit_assert=>assert_false( mo_validador->validar(
      iv_carga_enviada = 'C1' iv_carga_retornada = 'C1' iv_status = 'ROTEIRIZADA'
      iv_tem_nao_atendidas = abap_false it_remessas = VALUE #( ( `0001` ) )
      it_paradas = VALUE #( ( remessa = `0002` sequencia = 1 ) ) ) ).
  ENDMETHOD.
  METHOD carga_divergente.
    cl_abap_unit_assert=>assert_false( mo_validador->validar(
      iv_carga_enviada = 'C1' iv_carga_retornada = 'C2' iv_status = 'ROTEIRIZADA'
      iv_tem_nao_atendidas = abap_false it_remessas = VALUE #( ( `0001` ) )
      it_paradas = VALUE #( ( remessa = `0001` sequencia = 1 ) ) ) ).
  ENDMETHOD.
  METHOD nao_atendida.
    cl_abap_unit_assert=>assert_false( mo_validador->validar(
      iv_carga_enviada = 'C1' iv_carga_retornada = 'C1' iv_status = 'ROTEIRIZADA'
      iv_tem_nao_atendidas = abap_true it_remessas = VALUE #( ( `0001` ) )
      it_paradas = VALUE #( ( remessa = `0001` sequencia = 1 ) ) ) ).
  ENDMETHOD.
  METHOD exemplo_oito_paradas.
    cl_abap_unit_assert=>assert_true( mo_validador->validar(
      iv_carga_enviada = 'CG-000001' iv_carga_retornada = 'CG-000001' iv_status = 'ROTEIRIZADA'
      iv_tem_nao_atendidas = abap_false
      it_remessas = VALUE #( ( `0080001001` ) ( `0080001002` ) ( `0080001003` ) ( `0080001004` )
                             ( `0080001005` ) ( `0080001006` ) ( `0080001007` ) ( `0080001008` ) )
      it_paradas = VALUE #( ( remessa = `0080001001` sequencia = 1 )
                           ( remessa = `0080001002` sequencia = 2 )
                           ( remessa = `0080001003` sequencia = 3 )
                           ( remessa = `0080001004` sequencia = 4 )
                           ( remessa = `0080001005` sequencia = 5 )
                           ( remessa = `0080001006` sequencia = 6 )
                           ( remessa = `0080001007` sequencia = 7 )
                           ( remessa = `0080001008` sequencia = 8 ) ) ) ).
  ENDMETHOD.
  METHOD status_invalido.
    cl_abap_unit_assert=>assert_false( mo_validador->validar(
      iv_carga_enviada = 'C1' iv_carga_retornada = 'C1' iv_status = 'ERRO'
      iv_tem_nao_atendidas = abap_false it_remessas = VALUE #( ( `0001` ) )
      it_paradas = VALUE #( ( remessa = `0001` sequencia = 1 ) ) ) ).
  ENDMETHOD.
  METHOD remessa_duplicada.
    cl_abap_unit_assert=>assert_false( mo_validador->validar(
      iv_carga_enviada = 'C1' iv_carga_retornada = 'C1' iv_status = 'ROTEIRIZADA'
      iv_tem_nao_atendidas = abap_false it_remessas = VALUE #( ( `0001` ) ( `0002` ) )
      it_paradas = VALUE #( ( remessa = `0001` sequencia = 1 ) ( remessa = `0001` sequencia = 2 ) ) ) ).
  ENDMETHOD.
  METHOD sequencia_fora_limite.
    cl_abap_unit_assert=>assert_false( mo_validador->validar(
      iv_carga_enviada = 'C1' iv_carga_retornada = 'C1' iv_status = 'ROTEIRIZADA'
      iv_tem_nao_atendidas = abap_false it_remessas = VALUE #( ( `0001` ) ( `0002` ) )
      it_paradas = VALUE #( ( remessa = `0001` sequencia = 1 ) ( remessa = `0002` sequencia = 3 ) ) ) ).
  ENDMETHOD.
  METHOD sem_cobertura.
    cl_abap_unit_assert=>assert_false( mo_validador->validar(
      iv_carga_enviada = 'C1' iv_carga_retornada = 'C1' iv_status = 'ROTEIRIZADA'
      iv_tem_nao_atendidas = abap_false it_remessas = VALUE #( ( `0001` ) ( `0002` ) )
      it_paradas = VALUE #( ( remessa = `0001` sequencia = 1 ) ) ) ).
  ENDMETHOD.
  METHOD sem_remessas.
    cl_abap_unit_assert=>assert_false( mo_validador->validar(
      iv_carga_enviada = 'C1' iv_carga_retornada = 'C1' iv_status = 'ROTEIRIZADA'
      iv_tem_nao_atendidas = abap_false it_remessas = VALUE #( ) it_paradas = VALUE #( ) ) ).
  ENDMETHOD.
ENDCLASS.
