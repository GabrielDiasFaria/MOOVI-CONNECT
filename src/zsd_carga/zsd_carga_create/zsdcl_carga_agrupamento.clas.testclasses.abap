CLASS ltc_agrupamento DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    DATA mo_agrupador TYPE REF TO zsdcl_carga_agrupamento.
    METHODS setup.
    METHODS combina_pesos FOR TESTING.
    METHODS rejeita_invalidos FOR TESTING.
    METHODS privilegia_regiao_no_empate FOR TESTING.
    METHODS aceita_entrada_vazia FOR TESTING.
ENDCLASS.

CLASS ltc_agrupamento IMPLEMENTATION.
  METHOD setup.
    mo_agrupador = NEW #( ).
  ENDMETHOD.

  METHOD combina_pesos.
    DATA(lt_resultado) = mo_agrupador->agrupar( VALUE #(
      ( remessa = '0000000001' peso_kg = 8000 regiao = '01' )
      ( remessa = '0000000002' peso_kg = 7000 regiao = '02' )
      ( remessa = '0000000003' peso_kg = 7000 regiao = '01' )
      ( remessa = '0000000004' peso_kg = 6000 regiao = '02' ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = 4 act = lines( lt_resultado ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lt_resultado[ remessa = '0000000001' ]-carga ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lt_resultado[ remessa = '0000000004' ]-carga ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lt_resultado[ remessa = '0000000002' ]-carga ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lt_resultado[ remessa = '0000000003' ]-carga ).
  ENDMETHOD.

  METHOD rejeita_invalidos.
    DATA(lt_resultado) = mo_agrupador->agrupar( VALUE #(
      ( remessa = '0000000001' peso_kg = 14000 )
      ( remessa = '0000000002' peso_kg = '14000.001' )
      ( remessa = '0000000003' peso_kg = 0 )
      ( remessa = '0000000001' peso_kg = 1 )
      ( remessa = '' peso_kg = 2 ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = 5 act = lines( lt_resultado ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lt_resultado[ remessa = '0000000001' motivo = space ]-carga ).
    cl_abap_unit_assert=>assert_equals( exp = zsdcl_carga_agrupamento=>gc_acima_limite act = lt_resultado[ remessa = '0000000002' ]-motivo ).
    cl_abap_unit_assert=>assert_equals( exp = zsdcl_carga_agrupamento=>gc_peso_invalido act = lt_resultado[ remessa = '0000000003' ]-motivo ).
    cl_abap_unit_assert=>assert_equals( exp = 0 act = lt_resultado[ remessa = '0000000001' motivo = zsdcl_carga_agrupamento=>gc_remessa_duplicada ]-carga ).
    cl_abap_unit_assert=>assert_equals( exp = zsdcl_carga_agrupamento=>gc_remessa_invalida act = lt_resultado[ remessa = '' ]-motivo ).
  ENDMETHOD.

  METHOD privilegia_regiao_no_empate.
    DATA(lt_resultado) = mo_agrupador->agrupar( VALUE #(
      ( remessa = '0000000001' peso_kg = 8000 regiao = '01' )
      ( remessa = '0000000002' peso_kg = 8000 regiao = '02' )
      ( remessa = '0000000003' peso_kg = 6000 regiao = '02' ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lt_resultado[ remessa = '0000000003' ]-carga ).
  ENDMETHOD.

  METHOD aceita_entrada_vazia.
    DATA(lt_resultado) = mo_agrupador->agrupar( VALUE #( ) ).
    cl_abap_unit_assert=>assert_initial( act = lt_resultado ).
  ENDMETHOD.
ENDCLASS.
