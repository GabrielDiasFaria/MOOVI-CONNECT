CLASS ltc_persistencia DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    CLASS-DATA go_environment TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS grava FOR TESTING RAISING cx_sy_open_sql_db.
    METHODS duplicada_falha FOR TESTING.
ENDCLASS.
CLASS ltc_persistencia IMPLEMENTATION.
  METHOD class_setup.
    go_environment = cl_osql_test_environment=>create(
      i_dependency_list = VALUE #( ( 'ZSDT_CARGA_H' ) ( 'ZSDT_CARGA_IT' ) ) ).
  ENDMETHOD.
  METHOD class_teardown.
    go_environment->destroy( ).
  ENDMETHOD.
  METHOD setup.
    go_environment->clear_doubles( ).
  ENDMETHOD.
  METHOD grava.
    DATA lv_uuid TYPE sysuuid_x16 VALUE '00000000000000000000000000000001'.
    NEW zsdcl_carga_persistencia( )->gravar(
      it_cabecalhos = VALUE #( ( carga_id = lv_uuid status = '01' vstel = '0001' ) )
      it_itens = VALUE #( ( vbeln = '0000000001' carga_id = lv_uuid ) ) ).
    SELECT carga_id, status, vstel FROM zsdt_carga_h INTO TABLE @DATA(lt_h).
    SELECT vbeln, carga_id FROM zsdt_carga_it INTO TABLE @DATA(lt_i).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_h ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_i ) ).
    cl_abap_unit_assert=>assert_equals( exp = '01' act = lt_h[ 1 ]-status ).
    cl_abap_unit_assert=>assert_equals( exp = '0001' act = lt_h[ 1 ]-vstel ).
    cl_abap_unit_assert=>assert_equals( exp = lv_uuid act = lt_i[ 1 ]-carga_id ).
  ENDMETHOD.
  METHOD duplicada_falha.
    DATA lv_uuid TYPE sysuuid_x16 VALUE '00000000000000000000000000000001'.
    DATA lv_uuid_existente TYPE sysuuid_x16 VALUE '00000000000000000000000000000002'.
    DATA lt_existentes TYPE STANDARD TABLE OF zsdt_carga_it WITH EMPTY KEY.
    lt_existentes = VALUE #( ( vbeln = '0000000001' carga_id = lv_uuid_existente ) ).
    go_environment->insert_test_data( lt_existentes ).
    DATA lv_falhou TYPE abap_bool.
    TRY.
        NEW zsdcl_carga_persistencia( )->gravar(
          it_cabecalhos = VALUE #( ( carga_id = lv_uuid status = '01' vstel = '0001' ) )
          it_itens = VALUE #( ( vbeln = '0000000001' carga_id = lv_uuid ) ) ).
      CATCH cx_sy_open_sql_db.
        lv_falhou = abap_true.
    ENDTRY.
    SELECT carga_id, vstel FROM zsdt_carga_h WHERE carga_id = @lv_uuid INTO TABLE @DATA(lt_cabecalhos).
    SELECT vbeln, carga_id FROM zsdt_carga_it WHERE vbeln = '0000000001' INTO TABLE @DATA(lt_itens).
    cl_abap_unit_assert=>assert_true( lv_falhou ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_cabecalhos ) ).
    cl_abap_unit_assert=>assert_equals( exp = '0001' act = lt_cabecalhos[ 1 ]-vstel ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_itens ) ).
    cl_abap_unit_assert=>assert_equals( exp = lv_uuid_existente act = lt_itens[ 1 ]-carga_id ).
  ENDMETHOD.
ENDCLASS.
