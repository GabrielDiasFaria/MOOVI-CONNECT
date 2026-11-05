CLASS zsdcl_carga_agrupamento DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_remessa,
             remessa TYPE outbound_delivery,
             peso_kg TYPE decfloat34,
             regiao TYPE char2,
           END OF ty_remessa,
           ty_remessas TYPE STANDARD TABLE OF ty_remessa WITH EMPTY KEY,
           BEGIN OF ty_alocacao,
             remessa TYPE outbound_delivery,
             carga TYPE i,
             motivo TYPE char1,
           END OF ty_alocacao,
           ty_alocacoes TYPE STANDARD TABLE OF ty_alocacao WITH EMPTY KEY.
    CONSTANTS: gc_acima_limite TYPE char1 VALUE 'L',
               gc_peso_invalido TYPE char1 VALUE 'P',
               gc_remessa_duplicada TYPE char1 VALUE 'D',
               gc_remessa_invalida TYPE char1 VALUE 'I'.
    "! Agrupa remessas normalizadas em kg; carga zero identifica rejeição.
    "! Melhor encaixe decrescente, com preferência regional em empate.
    METHODS agrupar IMPORTING it_remessas TYPE ty_remessas
                    RETURNING VALUE(rt_alocacoes) TYPE ty_alocacoes.
  PRIVATE SECTION.
    CONSTANTS gc_capacidade_kg TYPE i VALUE 14000.
    TYPES: BEGIN OF ty_carga,
             numero TYPE i,
             peso_kg TYPE decfloat34,
           END OF ty_carga,
           ty_cargas TYPE STANDARD TABLE OF ty_carga WITH EMPTY KEY,
           BEGIN OF ty_regiao_carga,
             carga TYPE i,
             regiao TYPE char2,
           END OF ty_regiao_carga,
           ty_regioes_carga TYPE HASHED TABLE OF ty_regiao_carga WITH UNIQUE KEY carga regiao,
           ty_ids TYPE HASHED TABLE OF outbound_delivery WITH UNIQUE KEY table_line.
ENDCLASS.

CLASS zsdcl_carga_agrupamento IMPLEMENTATION.
  METHOD agrupar.
    DATA lt_ordenadas TYPE ty_remessas.
    DATA lt_cargas TYPE ty_cargas.
    DATA lt_regioes TYPE ty_regioes_carga.
    DATA lt_ids TYPE ty_ids.
    " Processa primeiro as remessas mais pesadas; as demais chaves estabilizam a ordem.
    lt_ordenadas = it_remessas.
    SORT lt_ordenadas BY peso_kg DESCENDING remessa ASCENDING regiao ASCENDING.
    LOOP AT lt_ordenadas INTO DATA(ls_remessa).
      " Identifica dados inválidos ou repetidos antes de alocar a remessa inteira.
      DATA(lv_motivo) = COND char1(
        WHEN ls_remessa-remessa IS INITIAL THEN gc_remessa_invalida
        WHEN line_exists( lt_ids[ table_line = ls_remessa-remessa ] ) THEN gc_remessa_duplicada
        WHEN ls_remessa-peso_kg <= 0 THEN gc_peso_invalido
        WHEN ls_remessa-peso_kg > gc_capacidade_kg THEN gc_acima_limite
        ELSE space ).
      IF ls_remessa-remessa IS NOT INITIAL.
        INSERT ls_remessa-remessa INTO TABLE lt_ids.
      ENDIF.
      IF lv_motivo IS NOT INITIAL.
        APPEND VALUE #( remessa = ls_remessa-remessa motivo = lv_motivo ) TO rt_alocacoes.
        CONTINUE.
      ENDIF.
      " Procura o menor espaço restante que comporte a remessa (melhor encaixe).
      DATA(lv_carga) = 0.
      DATA(lv_melhor_saldo) = CONV decfloat34( gc_capacidade_kg + 1 ).
      DATA(lv_mesma_regiao) = abap_false.
      LOOP AT lt_cargas ASSIGNING FIELD-SYMBOL(<lfs_carga>).
        DATA(lv_saldo) = gc_capacidade_kg - <lfs_carga>-peso_kg - ls_remessa-peso_kg.
        IF lv_saldo < 0.
          CONTINUE.
        ENDIF.
        DATA(lv_candidata_mesma_regiao) = xsdbool( ls_remessa-regiao IS NOT INITIAL AND
          line_exists( lt_regioes[ carga = <lfs_carga>-numero regiao = ls_remessa-regiao ] ) ).
        " A preferência pela mesma região é usada somente no empate de saldo.
        IF lv_saldo < lv_melhor_saldo OR
           ( lv_saldo = lv_melhor_saldo AND lv_candidata_mesma_regiao = abap_true AND lv_mesma_regiao = abap_false ).
          lv_carga = <lfs_carga>-numero.
          lv_melhor_saldo = lv_saldo.
          lv_mesma_regiao = lv_candidata_mesma_regiao.
        ENDIF.
      ENDLOOP.
      " Se nenhuma carga comportar a remessa, abre uma nova carga.
      IF lv_carga = 0.
        lv_carga = lines( lt_cargas ) + 1.
        APPEND VALUE #( numero = lv_carga ) TO lt_cargas.
      ENDIF.
      lt_cargas[ lv_carga ]-peso_kg = lt_cargas[ lv_carga ]-peso_kg + ls_remessa-peso_kg.
      IF ls_remessa-regiao IS NOT INITIAL.
        INSERT VALUE #( carga = lv_carga regiao = ls_remessa-regiao ) INTO TABLE lt_regioes.
      ENDIF.
      APPEND VALUE #( remessa = ls_remessa-remessa carga = lv_carga ) TO rt_alocacoes.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
