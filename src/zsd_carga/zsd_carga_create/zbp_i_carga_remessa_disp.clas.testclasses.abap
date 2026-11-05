CLASS ltc_criacao DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS acumula_e_descarta_criacao FOR TESTING.
    METHODS acumula_e_descarta_simulacao FOR TESTING.
ENDCLASS.
CLASS ltc_criacao IMPLEMENTATION.
  METHOD acumula_e_descarta_criacao.
    ROLLBACK ENTITIES.
    MODIFY ENTITIES OF zi_carga_remessa_disp
      ENTITY Remessa EXECUTE criar_cargas FROM VALUE #( ( DeliveryDocument = '0000000001' ) )
      FAILED DATA(ls_failed_1).
    MODIFY ENTITIES OF zi_carga_remessa_disp
      ENTITY Remessa EXECUTE criar_cargas FROM VALUE #( ( DeliveryDocument = '0000000002' ) )
      FAILED DATA(ls_failed_2).
    DATA(lv_quantidade) = lines( lcl_criacao_buffer=>gt_remessas ).
    DATA(lv_primeira) = xsdbool( line_exists( lcl_criacao_buffer=>gt_remessas[ table_line = '0000000001' ] ) ).
    DATA(lv_segunda) = xsdbool( line_exists( lcl_criacao_buffer=>gt_remessas[ table_line = '0000000002' ] ) ).
    ROLLBACK ENTITIES.
    cl_abap_unit_assert=>assert_initial( ls_failed_1-remessa ).
    cl_abap_unit_assert=>assert_initial( ls_failed_2-remessa ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lv_quantidade ).
    cl_abap_unit_assert=>assert_true( lv_primeira ).
    cl_abap_unit_assert=>assert_true( lv_segunda ).
    cl_abap_unit_assert=>assert_initial( lcl_criacao_buffer=>gt_remessas ).
  ENDMETHOD.
  METHOD acumula_e_descarta_simulacao.
    ROLLBACK ENTITIES.
    MODIFY ENTITIES OF zi_carga_remessa_disp
      ENTITY Remessa EXECUTE testar_selecao FROM VALUE #( ( DeliveryDocument = '0000000001' ) )
      FAILED DATA(ls_failed_1).
    MODIFY ENTITIES OF zi_carga_remessa_disp
      ENTITY Remessa EXECUTE testar_selecao FROM VALUE #( ( DeliveryDocument = '0000000002' ) )
      FAILED DATA(ls_failed_2).
    DATA(lv_quantidade) = lines( lcl_simulacao_buffer=>gt_remessas ).
    DATA(lv_primeira) = xsdbool( line_exists( lcl_simulacao_buffer=>gt_remessas[ table_line = '0000000001' ] ) ).
    DATA(lv_segunda) = xsdbool( line_exists( lcl_simulacao_buffer=>gt_remessas[ table_line = '0000000002' ] ) ).
    ROLLBACK ENTITIES.
    cl_abap_unit_assert=>assert_initial( ls_failed_1-remessa ).
    cl_abap_unit_assert=>assert_initial( ls_failed_2-remessa ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lv_quantidade ).
    cl_abap_unit_assert=>assert_true( lv_primeira ).
    cl_abap_unit_assert=>assert_true( lv_segunda ).
    cl_abap_unit_assert=>assert_initial( lcl_simulacao_buffer=>gt_remessas ).
  ENDMETHOD.
ENDCLASS.
