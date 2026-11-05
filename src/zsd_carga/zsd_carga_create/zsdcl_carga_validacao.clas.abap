CLASS zsdcl_carga_validacao DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CONSTANTS: gc_ok TYPE char1 VALUE space,
               gc_selecao_vazia TYPE char1 VALUE 'V',
               gc_indisponivel TYPE char1 VALUE 'I',
               gc_cd_invalido TYPE char1 VALUE 'C',
               gc_duplicada TYPE char1 VALUE 'D'.
    "! Lê a seleção atual após bloqueio, rejeitando seleção vazia, ausente ou ambígua.
    METHODS ler_selecao
      IMPORTING it_chaves TYPE zsdcl_carga_bloqueio=>ty_remessas
      EXPORTING et_remessas TYPE zsdcl_carga_planejador=>ty_remessas
                ev_motivo TYPE char1.
ENDCLASS.
CLASS zsdcl_carga_validacao IMPLEMENTATION.
METHOD ler_selecao.
  TYPES: BEGIN OF ty_dado,
           DeliveryDocument TYPE outbound_delivery,
           ShippingPoint TYPE vstel,
           DeliveryRegion TYPE char10,
           GrossWeightKg TYPE zi_carga_peso_kg-GrossWeightKg,
         END OF ty_dado.
  DATA lt_dados TYPE STANDARD TABLE OF ty_dado WITH EMPTY KEY.
  DATA lt_lidas TYPE SORTED TABLE OF outbound_delivery WITH UNIQUE KEY table_line.
  CLEAR: et_remessas, ev_motivo.
  IF it_chaves IS INITIAL OR line_exists( it_chaves[ table_line = '' ] ).
    ev_motivo = gc_selecao_vazia.
    RETURN.
  ENDIF.
  " Reconsulta as chaves na CDS de disponíveis, com peso normalizado em kg.
  " O TEST-SEAM permite substituir essa consulta nos testes unitários.
  TEST-SEAM consulta_remessas.
    SELECT rem~DeliveryDocument, rem~ShippingPoint, rem~DeliveryRegion,
           peso~GrossWeightKg
      FROM ZI_CARGA_REMESSA_DISP AS rem
      INNER JOIN ZI_CARGA_PESO_KG AS peso ON peso~DeliveryDocument = rem~DeliveryDocument
      INNER JOIN @it_chaves AS chave ON chave~table_line = rem~DeliveryDocument
      INTO TABLE @lt_dados.
  END-TEST-SEAM.
  " Rejeita resultado ambíguo ou CD vazio antes de devolver os dados ao planejador.
  LOOP AT lt_dados INTO DATA(ls_dado).
    INSERT ls_dado-DeliveryDocument INTO TABLE lt_lidas.
    IF sy-subrc <> 0.
      CLEAR et_remessas.
      ev_motivo = gc_duplicada.
      RETURN.
    ENDIF.
    IF ls_dado-ShippingPoint IS INITIAL.
      CLEAR et_remessas.
      ev_motivo = gc_cd_invalido.
      RETURN.
    ENDIF.
    " Traduz a descrição de região da CDS para o código usado no planejamento.
    APPEND VALUE #( remessa = ls_dado-DeliveryDocument cd = ls_dado-ShippingPoint
      peso_kg = ls_dado-GrossWeightKg
      regiao = SWITCH #( ls_dado-DeliveryRegion
        WHEN 'Centro' THEN '01' WHEN 'Norte' THEN '02'
        WHEN 'Leste' THEN '03' WHEN 'Sul' THEN '04'
        WHEN 'Oeste' THEN '05' WHEN 'Outras' THEN '99' ELSE space ) ) TO et_remessas.
  ENDLOOP.
  " Se alguma chave não foi encontrada, rejeita toda a seleção.
  IF lines( lt_lidas ) <> lines( it_chaves ).
    CLEAR et_remessas.
    ev_motivo = gc_indisponivel.
  ENDIF.
ENDMETHOD.
ENDCLASS.
