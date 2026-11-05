CLASS ltc_planejador DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS separa_cds FOR TESTING.
    METHODS preserva_limite_e_duplicados FOR TESTING.
    METHODS rejeita_cd_vazio FOR TESTING.
    METHODS aceita_vazio FOR TESTING.
ENDCLASS.

CLASS ltc_planejador IMPLEMENTATION.
  METHOD separa_cds.
    DATA(lt_result) = NEW zsdcl_carga_planejador( )->planejar( VALUE #(
      ( remessa = '0000000001' cd = '0001' peso_kg = 8000 regiao = '01' )
      ( remessa = '0000000002' cd = '0002' peso_kg = 6000 regiao = '01' )
      ( remessa = '0000000003' cd = '0001' peso_kg = 6000 regiao = '02' ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( lt_result ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lt_result[ remessa = '0000000001' ]-carga ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lt_result[ remessa = '0000000003' ]-carga ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lt_result[ remessa = '0000000002' ]-carga ).
  ENDMETHOD.
  METHOD preserva_limite_e_duplicados.
    DATA(lt_result) = NEW zsdcl_carga_planejador( )->planejar( VALUE #(
      ( remessa = '0000000001' cd = '0001' peso_kg = 14000 )
      ( remessa = '0000000002' cd = '0001' peso_kg = '14000.001' )
      ( remessa = '0000000003' cd = '0002' peso_kg = 1 )
      ( remessa = '0000000003' cd = '0001' peso_kg = 1 ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = 4 act = lines( lt_result ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lt_result[ remessa = '0000000001' ]-carga ).
    cl_abap_unit_assert=>assert_equals( exp = zsdcl_carga_agrupamento=>gc_acima_limite
      act = lt_result[ remessa = '0000000002' ]-motivo ).
    cl_abap_unit_assert=>assert_equals( exp = 0
      act = lt_result[ remessa = '0000000003' motivo = zsdcl_carga_agrupamento=>gc_remessa_duplicada ]-carga ).
  ENDMETHOD.
  METHOD rejeita_cd_vazio.
    DATA(lt_result) = NEW zsdcl_carga_planejador( )->planejar( VALUE #(
      ( remessa = '0000000001' peso_kg = 1000 ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = zsdcl_carga_planejador=>gc_cd_invalido act = lt_result[ 1 ]-motivo ).
    cl_abap_unit_assert=>assert_initial( act = lt_result[ 1 ]-carga ).
  ENDMETHOD.
  METHOD aceita_vazio.
    DATA(lt_result) = NEW zsdcl_carga_planejador( )->planejar( VALUE #( ) ).
    cl_abap_unit_assert=>assert_initial( act = lt_result ).
  ENDMETHOD.
ENDCLASS.
