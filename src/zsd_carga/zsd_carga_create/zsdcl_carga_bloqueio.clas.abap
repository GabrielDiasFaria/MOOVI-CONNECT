CLASS zsdcl_carga_bloqueio DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES ty_remessas TYPE SORTED TABLE OF outbound_delivery WITH UNIQUE KEY table_line.
    "! Bloqueia uma seleção não vazia de remessas na ordem das chaves.
    "! Em caso de erro, o chamador deve liberar os bloqueios já obtidos.
    METHODS bloquear IMPORTING it_remessas TYPE ty_remessas
      RAISING cx_abap_foreign_lock cx_abap_lock_failure.
    "! Libera apenas os bloqueios obtidos por esta instância.
    METHODS liberar RAISING cx_abap_lock_failure.
  PRIVATE SECTION.
    DATA mo_lock TYPE REF TO if_abap_lock_object.
    DATA mt_bloqueadas TYPE ty_remessas.
    METHODS parametros IMPORTING iv_remessa TYPE outbound_delivery
      RETURNING VALUE(rt_parametros) TYPE if_abap_lock_object=>tt_parameter.
ENDCLASS.

CLASS zsdcl_carga_bloqueio IMPLEMENTATION.
  METHOD parametros.
    DATA lr_mandt TYPE REF TO mandt.
    DATA lr_vbeln TYPE REF TO outbound_delivery.
    CREATE DATA lr_mandt.
    CREATE DATA lr_vbeln.
    lr_mandt->* = sy-mandt.
    lr_vbeln->* = iv_remessa.
    " Monta os parâmetros de chave exigidos pelo objeto de lock.
    rt_parametros = VALUE #( ( name = 'MANDT' value = lr_mandt )
                             ( name = 'VBELN' value = lr_vbeln ) ).
  ENDMETHOD.

METHOD bloquear.
  IF it_remessas IS INITIAL OR line_exists( it_remessas[ table_line = '' ] ).
    RAISE EXCEPTION TYPE cx_abap_lock_failure
      EXPORTING textid = cx_abap_lock_failure=>param_value_not_allowed
                field_name = 'VBELN'.
  ENDIF.
  " Usa o objeto de bloqueio da remessa; a tabela ordenada define a ordem das chaves.
  IF mo_lock IS INITIAL.
    mo_lock = cl_abap_lock_object_factory=>get_instance( 'EVVBLKE' ).
  ENDIF.
  LOOP AT it_remessas INTO DATA(lv_remessa).
    IF line_exists( mt_bloqueadas[ table_line = lv_remessa ] ).
      CONTINUE.
    ENDIF.
    " Solicita o lock sem espera e registra apenas os bloqueios obtidos.
    mo_lock->enqueue( it_parameter = parametros( lv_remessa )
      _scope = if_abap_lock_object=>cs_scope-no_update_program
      _wait = if_abap_lock_object=>cs_wait-no ).
    INSERT lv_remessa INTO TABLE mt_bloqueadas.
  ENDLOOP.
ENDMETHOD.

  METHOD liberar.
    " Libera os locks que esta instância conseguiu adquirir.
    LOOP AT mt_bloqueadas INTO DATA(lv_remessa).
      mo_lock->dequeue( it_parameter = parametros( lv_remessa )
        _scope = if_abap_lock_object=>cs_scope-no_update_program
        _synchronous = if_abap_lock_object=>cs_synchronous-yes ).
      DELETE TABLE mt_bloqueadas WITH TABLE KEY table_line = lv_remessa.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
