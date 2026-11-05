CLASS zsdcl_carga_orquestrador DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CONSTANTS: gc_ok TYPE char1 VALUE space,
               gc_invalida TYPE char1 VALUE 'I',
               gc_bloqueada TYPE char1 VALUE 'B',
               gc_tecnico TYPE char1 VALUE 'T'.
    "! Bloqueia e revalida a seleção inteira e prepara os registros sem gravar.
    "! Após sucesso ou falha, o chamador deve manter a instância até liberar os locks.
    METHODS preparar
      IMPORTING it_chaves TYPE zsdcl_carga_bloqueio=>ty_remessas
      EXPORTING et_cabecalhos TYPE zsdcl_carga_preparacao=>ty_cabecalhos
                et_itens TYPE zsdcl_carga_preparacao=>ty_itens
                ev_motivo TYPE char1.
    "! Libera os locks pertencentes à instância; a liberação não efetua commit.
    METHODS liberar RAISING cx_abap_lock_failure.
  PRIVATE SECTION.
    DATA mo_bloqueio TYPE REF TO zsdcl_carga_bloqueio.
ENDCLASS.
CLASS zsdcl_carga_orquestrador IMPLEMENTATION.
  METHOD preparar.
    CLEAR: et_cabecalhos, et_itens, ev_motivo.
    IF it_chaves IS INITIAL OR line_exists( it_chaves[ table_line = '' ] ) OR mo_bloqueio IS BOUND.
      ev_motivo = gc_invalida.
      RETURN.
    ENDIF.
    " Coordena bloqueio, revalidação, planejamento e preparação nesta ordem.
    " A instância de lock fica disponível ao chamador para liberação posterior.
    mo_bloqueio = NEW #( ).
    TRY.
        TEST-SEAM bloqueio.
          mo_bloqueio->bloquear( it_chaves ).
        END-TEST-SEAM.
        DATA lt_remessas TYPE zsdcl_carga_planejador=>ty_remessas.
        DATA lv_motivo TYPE char1.
        " Depois do bloqueio, verifica novamente a disponibilidade das remessas.
        TEST-SEAM validacao.
          NEW zsdcl_carga_validacao( )->ler_selecao(
            EXPORTING it_chaves = it_chaves
            IMPORTING et_remessas = lt_remessas ev_motivo = lv_motivo ).
        END-TEST-SEAM.
        IF lv_motivo IS NOT INITIAL OR lines( lt_remessas ) <> lines( it_chaves ).
          ev_motivo = gc_invalida.
          RETURN.
        ENDIF.
        " Planeja por CD e valida se todas as chaves participaram do resultado.
        DATA(lt_alocacoes) = NEW zsdcl_carga_planejador( )->planejar( lt_remessas ).
        IF lines( lt_alocacoes ) <> lines( it_chaves ).
          ev_motivo = gc_invalida.
          RETURN.
        ENDIF.
        " Apenas prepara registros em memória; ainda não grava no banco.
        NEW zsdcl_carga_preparacao( )->preparar(
          EXPORTING it_alocacoes = lt_alocacoes
          IMPORTING et_cabecalhos = et_cabecalhos et_itens = et_itens ev_valido = DATA(lv_valido) ).
        IF lv_valido <> abap_true OR lines( et_itens ) <> lines( it_chaves ).
          CLEAR: et_cabecalhos, et_itens.
          ev_motivo = gc_invalida.
        ENDIF.
      " Distingue conflito com outro usuário de falha técnica.
      CATCH cx_abap_foreign_lock.
        CLEAR: et_cabecalhos, et_itens.
        ev_motivo = gc_bloqueada.
      CATCH cx_abap_lock_failure cx_uuid_error cx_sy_open_sql_db.
        CLEAR: et_cabecalhos, et_itens.
        ev_motivo = gc_tecnico.
    ENDTRY.
  ENDMETHOD.
  METHOD liberar.
    " A liberação é explícita e não executa COMMIT.
    IF mo_bloqueio IS BOUND.
      mo_bloqueio->liberar( ).
      CLEAR mo_bloqueio.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
