CLASS ltc_validacao DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS vazia FOR TESTING.
    METHODS indisponivel FOR TESTING.
    METHODS duplicada FOR TESTING.
    METHODS cd_invalido FOR TESTING.
    METHODS valida FOR TESTING.
ENDCLASS.
CLASS ltc_validacao IMPLEMENTATION.
  METHOD vazia.
    NEW zsdcl_carga_validacao( )->ler_selecao(
      EXPORTING it_chaves = VALUE #( )
      IMPORTING et_remessas = DATA(lt_remessas) ev_motivo = DATA(lv_motivo) ).
    cl_abap_unit_assert=>assert_equals( exp = zsdcl_carga_validacao=>gc_selecao_vazia act = lv_motivo ).
    cl_abap_unit_assert=>assert_initial( lt_remessas ).
  ENDMETHOD.
  METHOD indisponivel.
    TEST-INJECTION consulta_remessas.
      lt_dados = VALUE #( ( DeliveryDocument = '0000000001' ShippingPoint = '0001' GrossWeightKg = 100 ) ).
    END-TEST-INJECTION.
    NEW zsdcl_carga_validacao( )->ler_selecao(
      EXPORTING it_chaves = VALUE #( ( '0000000001' ) ( '0000000002' ) )
      IMPORTING et_remessas = DATA(lt_remessas) ev_motivo = DATA(lv_motivo) ).
    cl_abap_unit_assert=>assert_equals( exp = zsdcl_carga_validacao=>gc_indisponivel act = lv_motivo ).
    cl_abap_unit_assert=>assert_initial( lt_remessas ).
  ENDMETHOD.
  METHOD duplicada.
    TEST-INJECTION consulta_remessas.
      lt_dados = VALUE #( ( DeliveryDocument = '0000000001' ShippingPoint = '0001' GrossWeightKg = 100 )
                          ( DeliveryDocument = '0000000001' ShippingPoint = '0001' GrossWeightKg = 100 ) ).
    END-TEST-INJECTION.
    NEW zsdcl_carga_validacao( )->ler_selecao(
      EXPORTING it_chaves = VALUE #( ( '0000000001' ) )
      IMPORTING et_remessas = DATA(lt_remessas) ev_motivo = DATA(lv_motivo) ).
    cl_abap_unit_assert=>assert_equals( exp = zsdcl_carga_validacao=>gc_duplicada act = lv_motivo ).
    cl_abap_unit_assert=>assert_initial( lt_remessas ).
  ENDMETHOD.
  METHOD cd_invalido.
    TEST-INJECTION consulta_remessas.
      lt_dados = VALUE #( ( DeliveryDocument = '0000000001' GrossWeightKg = 100 ) ).
    END-TEST-INJECTION.
    NEW zsdcl_carga_validacao( )->ler_selecao(
      EXPORTING it_chaves = VALUE #( ( '0000000001' ) )
      IMPORTING et_remessas = DATA(lt_remessas) ev_motivo = DATA(lv_motivo) ).
    cl_abap_unit_assert=>assert_equals( exp = zsdcl_carga_validacao=>gc_cd_invalido act = lv_motivo ).
    cl_abap_unit_assert=>assert_initial( lt_remessas ).
  ENDMETHOD.
  METHOD valida.
    TEST-INJECTION consulta_remessas.
      lt_dados = VALUE #( ( DeliveryDocument = '0000000001' ShippingPoint = '0001' DeliveryRegion = 'Norte' GrossWeightKg = 150 )
                          ( DeliveryDocument = '0000000002' ShippingPoint = '0002' DeliveryRegion = 'Outras' GrossWeightKg = 300 ) ).
    END-TEST-INJECTION.
    NEW zsdcl_carga_validacao( )->ler_selecao(
      EXPORTING it_chaves = VALUE #( ( '0000000001' ) ( '0000000002' ) )
      IMPORTING et_remessas = DATA(lt_remessas) ev_motivo = DATA(lv_motivo) ).
    cl_abap_unit_assert=>assert_initial( lv_motivo ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_remessas ) ).
    cl_abap_unit_assert=>assert_equals( exp = '02' act = lt_remessas[ 1 ]-regiao ).
    cl_abap_unit_assert=>assert_equals( exp = 150 act = lt_remessas[ 1 ]-peso_kg ).
    cl_abap_unit_assert=>assert_equals( exp = '99' act = lt_remessas[ 2 ]-regiao ).
  ENDMETHOD.
ENDCLASS.
