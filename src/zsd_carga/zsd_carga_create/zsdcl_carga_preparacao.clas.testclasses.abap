CLASS ltc_preparacao DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS prepara_integral FOR TESTING RAISING cx_uuid_error.
    METHODS rejeita_invalida FOR TESTING RAISING cx_uuid_error.
    METHODS rejeita_cds_misturados FOR TESTING RAISING cx_uuid_error.
    METHODS rejeita_duplicidade FOR TESTING RAISING cx_uuid_error.
ENDCLASS.
CLASS ltc_preparacao IMPLEMENTATION.
  METHOD prepara_integral.
    NEW zsdcl_carga_preparacao( )->preparar(
      EXPORTING it_alocacoes = VALUE #(
        ( remessa = '0000000001' cd = '0001' carga = 1 )
        ( remessa = '0000000002' cd = '0001' carga = 1 )
        ( remessa = '0000000003' cd = '0002' carga = 2 ) )
      IMPORTING et_cabecalhos = DATA(lt_h) et_itens = DATA(lt_i) ev_valido = DATA(lv_ok) ).
    cl_abap_unit_assert=>assert_true( lv_ok ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_h ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( lt_i ) ).
    cl_abap_unit_assert=>assert_equals( exp = lt_i[ 1 ]-carga_id act = lt_i[ 2 ]-carga_id ).
    cl_abap_unit_assert=>assert_differs( exp = lt_i[ 1 ]-carga_id act = lt_i[ 3 ]-carga_id ).
    cl_abap_unit_assert=>assert_equals( exp = '0001' act = lt_h[ carga_id = lt_i[ 1 ]-carga_id ]-vstel ).
    cl_abap_unit_assert=>assert_equals( exp = '0002' act = lt_h[ carga_id = lt_i[ 3 ]-carga_id ]-vstel ).
    LOOP AT lt_h INTO DATA(ls_h).
      cl_abap_unit_assert=>assert_equals( exp = '01' act = ls_h-status ).
      cl_abap_unit_assert=>assert_not_initial( ls_h-carga_id ).
    ENDLOOP.
  ENDMETHOD.
  METHOD rejeita_invalida.
    NEW zsdcl_carga_preparacao( )->preparar(
      EXPORTING it_alocacoes = VALUE #( ( remessa = '0000000001' cd = '0001' carga = 0 ) )
      IMPORTING et_cabecalhos = DATA(lt_h) et_itens = DATA(lt_i) ev_valido = DATA(lv_ok) ).
    cl_abap_unit_assert=>assert_false( lv_ok ).
    cl_abap_unit_assert=>assert_initial( lt_h ).
    cl_abap_unit_assert=>assert_initial( lt_i ).
  ENDMETHOD.
  METHOD rejeita_cds_misturados.
    NEW zsdcl_carga_preparacao( )->preparar(
      EXPORTING it_alocacoes = VALUE #(
        ( remessa = '0000000001' cd = '0001' carga = 1 )
        ( remessa = '0000000002' cd = '0002' carga = 1 ) )
      IMPORTING et_cabecalhos = DATA(lt_h) et_itens = DATA(lt_i) ev_valido = DATA(lv_ok) ).
    cl_abap_unit_assert=>assert_false( lv_ok ).
    cl_abap_unit_assert=>assert_initial( lt_h ).
    cl_abap_unit_assert=>assert_initial( lt_i ).
  ENDMETHOD.
  METHOD rejeita_duplicidade.
    NEW zsdcl_carga_preparacao( )->preparar(
      EXPORTING it_alocacoes = VALUE #(
        ( remessa = '0000000001' cd = '0001' carga = 1 )
        ( remessa = '0000000001' cd = '0001' carga = 2 ) )
      IMPORTING et_cabecalhos = DATA(lt_h) et_itens = DATA(lt_i) ev_valido = DATA(lv_ok) ).
    cl_abap_unit_assert=>assert_false( lv_ok ).
    cl_abap_unit_assert=>assert_initial( lt_h ).
    cl_abap_unit_assert=>assert_initial( lt_i ).
  ENDMETHOD.
ENDCLASS.
