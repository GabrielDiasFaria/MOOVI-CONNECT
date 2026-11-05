CLASS zsdcl_carga_persistencia DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    "! Insere cabeçalhos e itens na LUW do chamador, sem executar COMMIT ou ROLLBACK.
    "! Os dados devem ter sido validados e os bloqueios mantidos pelo chamador.
    "! Uma exceção SQL deve abortar a LUW inteira; não pode ser ignorada.
    METHODS gravar IMPORTING it_cabecalhos TYPE zsdcl_carga_preparacao=>ty_cabecalhos
                             it_itens TYPE zsdcl_carga_preparacao=>ty_itens
                   RAISING cx_sy_open_sql_db.
ENDCLASS.
CLASS zsdcl_carga_persistencia IMPLEMENTATION.
  METHOD gravar.
    " Grava cabeçalhos e depois vínculos; a LUW é controlada pelo chamador RAP.
    " Falha no segundo INSERT exige que o chamador aborte a transação inteira.
    INSERT zsdt_carga_h FROM TABLE @it_cabecalhos.
    INSERT zsdt_carga_it FROM TABLE @it_itens.
  ENDMETHOD.
ENDCLASS.
