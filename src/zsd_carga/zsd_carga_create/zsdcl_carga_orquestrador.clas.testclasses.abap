CLASS ltc_orquestrador DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
 PUBLIC SECTION.
  CLASS-DATA gt_remessas TYPE zsdcl_carga_planejador=>ty_remessas.
  CLASS-DATA gv_motivo TYPE char1.
 PRIVATE SECTION.
  METHODS setup.
  METHODS separa_cd FOR TESTING RAISING cx_abap_lock_failure.
  METHODS invalida FOR TESTING RAISING cx_abap_lock_failure.
  METHODS acima_limite FOR TESTING RAISING cx_abap_lock_failure.
  METHODS bloqueio_concorrente FOR TESTING RAISING cx_abap_lock_failure.
  METHODS falha_tecnica_lock FOR TESTING RAISING cx_abap_lock_failure.
ENDCLASS.
CLASS ltc_orquestrador IMPLEMENTATION.
 METHOD setup.
  CLEAR: gt_remessas, gv_motivo.
  TEST-INJECTION bloqueio.
  END-TEST-INJECTION.
  TEST-INJECTION validacao.
   lt_remessas = ltc_orquestrador=>gt_remessas.
   lv_motivo = ltc_orquestrador=>gv_motivo.
  END-TEST-INJECTION.
 ENDMETHOD.
 METHOD separa_cd.
  gt_remessas = VALUE #( ( remessa = '0000000001' cd = 'CD01' peso_kg = 1000 regiao = '01' )
                         ( remessa = '0000000002' cd = 'CD02' peso_kg = 1000 regiao = '01' ) ).
  DATA(lo_orquestrador) = NEW zsdcl_carga_orquestrador( ).
  lo_orquestrador->preparar( EXPORTING it_chaves = VALUE #( ( '0000000001' ) ( '0000000002' ) )
    IMPORTING et_cabecalhos = DATA(lt_cabecalhos) et_itens = DATA(lt_itens) ev_motivo = DATA(lv_motivo) ).
  cl_abap_unit_assert=>assert_initial( lv_motivo ).
  cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_cabecalhos ) ).
  cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_itens ) ).
  cl_abap_unit_assert=>assert_differs( exp = lt_itens[ 1 ]-carga_id act = lt_itens[ 2 ]-carga_id ).
  lo_orquestrador->liberar( ).
 ENDMETHOD.
 METHOD invalida.
  gv_motivo = zsdcl_carga_validacao=>gc_indisponivel.
  DATA(lo_orquestrador) = NEW zsdcl_carga_orquestrador( ).
  lo_orquestrador->preparar( EXPORTING it_chaves = VALUE #( ( '0000000001' ) )
    IMPORTING et_cabecalhos = DATA(lt_cabecalhos) et_itens = DATA(lt_itens) ev_motivo = DATA(lv_motivo) ).
  cl_abap_unit_assert=>assert_equals( exp = zsdcl_carga_orquestrador=>gc_invalida act = lv_motivo ).
  cl_abap_unit_assert=>assert_initial( lt_cabecalhos ).
  cl_abap_unit_assert=>assert_initial( lt_itens ).
  lo_orquestrador->liberar( ).
 ENDMETHOD.
 METHOD acima_limite.
  gt_remessas = VALUE #( ( remessa = '0000000001' cd = 'CD01' peso_kg = 14001 ) ).
  DATA(lo_orquestrador) = NEW zsdcl_carga_orquestrador( ).
  lo_orquestrador->preparar( EXPORTING it_chaves = VALUE #( ( '0000000001' ) )
    IMPORTING et_cabecalhos = DATA(lt_cabecalhos) et_itens = DATA(lt_itens) ev_motivo = DATA(lv_motivo) ).
  cl_abap_unit_assert=>assert_equals( exp = zsdcl_carga_orquestrador=>gc_invalida act = lv_motivo ).
  cl_abap_unit_assert=>assert_initial( lt_cabecalhos ).
  cl_abap_unit_assert=>assert_initial( lt_itens ).
  lo_orquestrador->liberar( ).
 ENDMETHOD.
 METHOD bloqueio_concorrente.
  TEST-INJECTION bloqueio.
    RAISE EXCEPTION TYPE cx_abap_foreign_lock.
  END-TEST-INJECTION.
  DATA(lo_orquestrador) = NEW zsdcl_carga_orquestrador( ).
  lo_orquestrador->preparar( EXPORTING it_chaves = VALUE #( ( '0000000001' ) ( '0000000002' ) )
    IMPORTING et_cabecalhos = DATA(lt_cabecalhos) et_itens = DATA(lt_itens) ev_motivo = DATA(lv_motivo) ).
  lo_orquestrador->liberar( ).
  cl_abap_unit_assert=>assert_equals( exp = zsdcl_carga_orquestrador=>gc_bloqueada act = lv_motivo ).
  cl_abap_unit_assert=>assert_initial( lt_cabecalhos ).
  cl_abap_unit_assert=>assert_initial( lt_itens ).
 ENDMETHOD.
 METHOD falha_tecnica_lock.
  TEST-INJECTION bloqueio.
    RAISE EXCEPTION TYPE cx_abap_lock_failure.
  END-TEST-INJECTION.
  DATA(lo_orquestrador) = NEW zsdcl_carga_orquestrador( ).
  lo_orquestrador->preparar( EXPORTING it_chaves = VALUE #( ( '0000000001' ) ( '0000000002' ) )
    IMPORTING et_cabecalhos = DATA(lt_cabecalhos) et_itens = DATA(lt_itens) ev_motivo = DATA(lv_motivo) ).
  lo_orquestrador->liberar( ).
  cl_abap_unit_assert=>assert_equals( exp = zsdcl_carga_orquestrador=>gc_tecnico act = lv_motivo ).
  cl_abap_unit_assert=>assert_initial( lt_cabecalhos ).
  cl_abap_unit_assert=>assert_initial( lt_itens ).
 ENDMETHOD.
ENDCLASS.
