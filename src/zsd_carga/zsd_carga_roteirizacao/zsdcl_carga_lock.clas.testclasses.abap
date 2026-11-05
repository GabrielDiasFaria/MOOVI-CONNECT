CLASS ltc_carga_lock DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS rejeita_chave_vazia FOR TESTING.
    METHODS liberar_sem_lock FOR TESTING RAISING cx_abap_lock_failure.
ENDCLASS.
CLASS ltc_carga_lock IMPLEMENTATION.
  METHOD rejeita_chave_vazia.
    DATA(lo_lock) = NEW zsdcl_carga_lock( ).
    TRY.
        lo_lock->bloquear( CONV sysuuid_x16( '' ) ).
        cl_abap_unit_assert=>fail( msg = 'Chave vazia não deve ser bloqueada' ).
      CATCH cx_abap_lock_failure.
        RETURN.
      CATCH cx_abap_foreign_lock.
        cl_abap_unit_assert=>fail( msg = 'Erro de concorrência inesperado' ).
    ENDTRY.
  ENDMETHOD.
  METHOD liberar_sem_lock.
    NEW zsdcl_carga_lock( )->liberar( ).
  ENDMETHOD.
ENDCLASS.
