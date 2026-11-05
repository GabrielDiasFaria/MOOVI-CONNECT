CLASS lcl_simulacao_buffer DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA gt_remessas TYPE SORTED TABLE OF outbound_delivery WITH UNIQUE KEY table_line.
ENDCLASS.

CLASS lcl_simulacao_buffer IMPLEMENTATION.
ENDCLASS.

CLASS lcl_criacao_buffer DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA gt_remessas TYPE zsdcl_carga_bloqueio=>ty_remessas.
    CLASS-DATA gt_cabecalhos TYPE zsdcl_carga_preparacao=>ty_cabecalhos.
    CLASS-DATA gt_itens TYPE zsdcl_carga_preparacao=>ty_itens.
    CLASS-DATA go_orquestrador TYPE REF TO zsdcl_carga_orquestrador.
ENDCLASS.
CLASS lcl_criacao_buffer IMPLEMENTATION.
ENDCLASS.

CLASS lhc_remessa DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS read FOR READ
      IMPORTING keys FOR READ remessa RESULT result.
    METHODS testar_selecao FOR MODIFY
      IMPORTING keys FOR ACTION remessa~testar_selecao.
    METHODS criar_cargas FOR MODIFY
      IMPORTING keys FOR ACTION remessa~criar_cargas.
ENDCLASS.

CLASS lhc_remessa IMPLEMENTATION.
  METHOD read.
    " Protege FOR ALL ENTRIES contra leitura sem restrição quando não há chaves.
    IF keys IS INITIAL.
      RETURN.
    ENDIF.
    SELECT DeliveryDocument, ShippingPoint, ShipToParty,
           PlannedGoodsIssueDate, DeliveryPostalCode, DeliveryRegion,
           HeaderGrossWeight, HeaderWeightUnit
      FROM ZI_CARGA_REMESSA_DISP
      FOR ALL ENTRIES IN @keys
      WHERE DeliveryDocument = @keys-DeliveryDocument
      INTO CORRESPONDING FIELDS OF TABLE @result.
    " Informa ao RAP as chaves que não foram encontradas na CDS.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      IF NOT line_exists( result[ KEY entity COMPONENTS DeliveryDocument = <key>-DeliveryDocument ] ).
        APPEND VALUE #( %tky = <key>-%tky
                        %fail-cause = if_abap_behv=>cause-not_found ) TO failed-remessa.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
  METHOD testar_selecao.
    " Acumula as chaves da simulação no buffer; o planejamento ocorre em FINALIZE.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      INSERT <key>-DeliveryDocument INTO TABLE lcl_simulacao_buffer=>gt_remessas.
    ENDLOOP.
  ENDMETHOD.
  METHOD criar_cargas.
    " Reúne as chaves da criação para processamento posterior no ciclo RAP.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      INSERT <key>-DeliveryDocument INTO TABLE lcl_criacao_buffer=>gt_remessas.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zi_carga_remessa_disp DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize REDEFINITION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.

CLASS lsc_zi_carga_remessa_disp IMPLEMENTATION.
  METHOD finalize.
    DATA lt_remessas TYPE zsdcl_carga_planejador=>ty_remessas.
    DATA lv_excluidas TYPE i.
    DATA lv_incluidas TYPE i.
    DATA lv_cargas TYPE i.
    DATA lv_peso_kg TYPE decfloat34.
    DATA lv_regiao TYPE char2.
    DATA lt_lidas TYPE SORTED TABLE OF outbound_delivery WITH UNIQUE KEY table_line.
    " Na criação, bloqueia e revalida a seleção e prepara os dados para SAVE.
    IF lcl_criacao_buffer=>gt_remessas IS NOT INITIAL.
      DATA lv_numero TYPE symsgno.
      " Não combina simulação e criação na mesma operação.
      IF lcl_simulacao_buffer=>gt_remessas IS NOT INITIAL.
        lv_numero = '007'.
      ELSE.
        lcl_criacao_buffer=>go_orquestrador = NEW #( ).
        lcl_criacao_buffer=>go_orquestrador->preparar(
          EXPORTING it_chaves = lcl_criacao_buffer=>gt_remessas
          IMPORTING et_cabecalhos = lcl_criacao_buffer=>gt_cabecalhos
                    et_itens = lcl_criacao_buffer=>gt_itens
                    ev_motivo = DATA(lv_motivo) ).
        lv_numero = SWITCH #( lv_motivo
          WHEN zsdcl_carga_orquestrador=>gc_invalida THEN '003'
          WHEN zsdcl_carga_orquestrador=>gc_bloqueada THEN '004'
          WHEN zsdcl_carga_orquestrador=>gc_tecnico THEN '005'
          ELSE space ).
      ENDIF.
      " Repassa falhas e mensagens ao consumidor RAP para toda a seleção.
      IF lv_numero IS NOT INITIAL.
        LOOP AT lcl_criacao_buffer=>gt_remessas INTO DATA(lv_remessa).
          APPEND VALUE #( DeliveryDocument = lv_remessa
                          %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-remessa.
        ENDLOOP.
        APPEND VALUE #( %msg = new_message( id = 'ZSD_CARGA_MONTAGEM' number = lv_numero
          severity = if_abap_behv_message=>severity-error ) ) TO reported-remessa.
      ENDIF.
      RETURN.
    ENDIF.
    IF lcl_simulacao_buffer=>gt_remessas IS INITIAL.
      RETURN.
    ENDIF.
    " Simulação: relê remessas disponíveis; o buffer não vazio protege FOR ALL ENTRIES.
    SELECT DeliveryDocument, ShippingPoint, HeaderGrossWeight, HeaderWeightUnit, DeliveryRegion
      FROM ZI_CARGA_REMESSA_DISP
      FOR ALL ENTRIES IN @lcl_simulacao_buffer=>gt_remessas
      WHERE DeliveryDocument = @lcl_simulacao_buffer=>gt_remessas-table_line
      INTO TABLE @DATA(lt_dados).
    LOOP AT lt_dados ASSIGNING FIELD-SYMBOL(<dado>).
      INSERT <dado>-DeliveryDocument INTO TABLE lt_lidas.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      " Converte o peso para kg ou contabiliza a remessa excluída.
      CLEAR lv_peso_kg.
      IF <dado>-HeaderWeightUnit = 'KG'.
        lv_peso_kg = <dado>-HeaderGrossWeight.
      ELSEIF <dado>-HeaderWeightUnit IS NOT INITIAL.
        CALL FUNCTION 'UNIT_CONVERSION_SIMPLE'
          EXPORTING input = <dado>-HeaderGrossWeight unit_in = <dado>-HeaderWeightUnit unit_out = 'KG'
          IMPORTING output = lv_peso_kg
          EXCEPTIONS OTHERS = 1.
        IF sy-subrc <> 0.
          lv_excluidas += 1.
          CONTINUE.
        ENDIF.
      ELSE.
        lv_excluidas += 1.
        CONTINUE.
      ENDIF.
      " Traduz a descrição de região para o código esperado pelo planejador.
      lv_regiao = SWITCH #( <dado>-DeliveryRegion
        WHEN 'Centro' THEN '01'
        WHEN 'Norte'  THEN '02'
        WHEN 'Leste'  THEN '03'
        WHEN 'Sul'    THEN '04'
        WHEN 'Oeste'  THEN '05'
        WHEN 'Outras' THEN '99'
        ELSE space ).
      APPEND VALUE #( remessa = <dado>-DeliveryDocument cd = <dado>-ShippingPoint
                      peso_kg = lv_peso_kg regiao = lv_regiao ) TO lt_remessas.
    ENDLOOP.
    " Conta remessas não encontradas e calcula o plano sem persistir.
    lv_excluidas += lines( lcl_simulacao_buffer=>gt_remessas ) - lines( lt_lidas ).
    DATA(lt_alocacoes) = NEW zsdcl_carga_planejador( )->planejar( lt_remessas ).
    LOOP AT lt_alocacoes ASSIGNING FIELD-SYMBOL(<alocacao>).
      IF <alocacao>-carga = 0.
        lv_excluidas += 1.
      ELSE.
        lv_incluidas += 1.
        IF <alocacao>-carga > lv_cargas.
          lv_cargas = <alocacao>-carga.
        ENDIF.
      ENDIF.
    ENDLOOP.
    " Retorna o resumo da simulação em mensagem informativa.
    APPEND VALUE #( %msg = new_message(
      id = 'ZSD_CARGA_MONTAGEM' number = '002'
      severity = if_abap_behv_message=>severity-information
      v1 = lv_incluidas v2 = lv_cargas v3 = |{ lv_excluidas }| ) ) TO reported-remessa.
  ENDMETHOD.
  METHOD save.
    " Grava os dados preparados na fase de salvamento do RAP, sem COMMIT explícito.
    IF lcl_criacao_buffer=>gt_remessas IS NOT INITIAL.
      NEW zsdcl_carga_persistencia( )->gravar(
        it_cabecalhos = lcl_criacao_buffer=>gt_cabecalhos
        it_itens = lcl_criacao_buffer=>gt_itens ).
    ENDIF.
  ENDMETHOD.
  METHOD cleanup.
    " Limpa buffers e a referência do orquestrador no ciclo de limpeza RAP.
    CLEAR: lcl_simulacao_buffer=>gt_remessas,
           lcl_criacao_buffer=>gt_remessas, lcl_criacao_buffer=>gt_cabecalhos,
           lcl_criacao_buffer=>gt_itens, lcl_criacao_buffer=>go_orquestrador.
  ENDMETHOD.
  METHOD cleanup_finalize.
    " Descarta o estado em memória na limpeza de finalização do RAP.
    CLEAR: lcl_simulacao_buffer=>gt_remessas,
           lcl_criacao_buffer=>gt_remessas, lcl_criacao_buffer=>gt_cabecalhos,
           lcl_criacao_buffer=>gt_itens, lcl_criacao_buffer=>go_orquestrador.
  ENDMETHOD.
ENDCLASS.
