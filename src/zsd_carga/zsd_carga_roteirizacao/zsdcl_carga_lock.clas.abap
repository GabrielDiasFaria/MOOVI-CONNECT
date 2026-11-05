CLASS zsdcl_carga_lock DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    "! Bloqueia uma carga específica. O chamador deve manter a instância e liberar o lock ao final da LUW.
    METHODS bloquear IMPORTING iv_carga_id TYPE sysuuid_x16
      RAISING cx_abap_foreign_lock cx_abap_lock_failure.
    "! Libera somente o lock adquirido por esta instância, sem executar commit.
    METHODS liberar RAISING cx_abap_lock_failure.
  PRIVATE SECTION.
    DATA mo_lock TYPE REF TO if_abap_lock_object.
    DATA mv_carga_id TYPE sysuuid_x16.
    DATA mv_bloqueado TYPE abap_bool.
    METHODS parametros IMPORTING iv_carga_id TYPE sysuuid_x16
      RETURNING VALUE(rt_parametros) TYPE if_abap_lock_object=>tt_parameter.
ENDCLASS.

CLASS zsdcl_carga_lock IMPLEMENTATION.
  METHOD parametros.
    DATA(lr_client) = NEW mandt( sy-mandt ).
    DATA(lr_carga) = NEW sysuuid_x16( iv_carga_id ).
    rt_parametros = VALUE #( ( name = 'CLIENT' value = lr_client )
                             ( name = 'CARGA_ID' value = lr_carga ) ).
  ENDMETHOD.

  METHOD bloquear.
    IF iv_carga_id IS INITIAL OR mv_bloqueado = abap_true.
      RAISE EXCEPTION TYPE cx_abap_lock_failure
        EXPORTING textid = cx_abap_lock_failure=>param_value_not_allowed
                  field_name = 'CARGA_ID'.
    ENDIF.
    mo_lock = cl_abap_lock_object_factory=>get_instance( 'EZSDCARGAH' ).
    mo_lock->enqueue( it_parameter = parametros( iv_carga_id )
      _scope = if_abap_lock_object=>cs_scope-no_update_program
      _wait = if_abap_lock_object=>cs_wait-no ).
    mv_carga_id = iv_carga_id.
    mv_bloqueado = abap_true.
  ENDMETHOD.

  METHOD liberar.
    IF mv_bloqueado = abap_false.
      RETURN.
    ENDIF.
    mo_lock->dequeue( it_parameter = parametros( mv_carga_id )
      _scope = if_abap_lock_object=>cs_scope-no_update_program
      _synchronous = if_abap_lock_object=>cs_synchronous-yes ).
    CLEAR: mv_carga_id, mv_bloqueado, mo_lock.
  ENDMETHOD.
ENDCLASS.
