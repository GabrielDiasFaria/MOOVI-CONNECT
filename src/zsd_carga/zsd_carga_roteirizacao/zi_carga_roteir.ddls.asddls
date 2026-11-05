@EndUserText.label: 'Cargas para roteirização'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@VDM.viewType: #COMPOSITE
@Metadata.ignorePropagatedAnnotations: true
@UI.headerInfo: { typeName: 'Carga', typeNamePlural: 'Cargas', title: { value: 'CargaId' }, imageUrl: 'HeaderIcon' }
define root view entity ZI_CARGA_ROTEIR
  as select from ZI_ZSDT_CARGA_H as Carga
    left outer join ZI_CARGA_TOTAIS as Totais
      on Carga.CargaId = Totais.CargaId
    left outer join ZI_CARGA_TOTAIS as PesoValido
      on Carga.CargaId = PesoValido.CargaId
     and PesoValido.RemessasSemPeso = 0
  association [0..*] to ZI_CARGA_DETALHE as _Remessas
    on $projection.CargaId = _Remessas.CargaId
{
  @UI.facet: [{ id: 'StatusHeader', purpose: #HEADER, type: #DATAPOINT_REFERENCE, position: 10, targetQualifier: 'StatusHeader' },
              { id: 'RemessasHeader', purpose: #HEADER, type: #DATAPOINT_REFERENCE, position: 20, targetQualifier: 'RemessasHeader' },
              { id: 'DadosCarga', type: #IDENTIFICATION_REFERENCE, label: 'Dados da carga', position: 10 },
              { id: 'Remessas', type: #LINEITEM_REFERENCE, label: 'Remessas', position: 20, targetElement: '_Remessas' }]
  @UI.lineItem: [{ position: 10 },
                 { type: #FOR_ACTION, dataAction: 'confirmar', label: 'Confirmar carga', position: 90 },
                 { type: #FOR_ACTION, dataAction: 'roteirizacao', label: 'Roteirização', position: 100 }]
  @UI.identification: [{ position: 10, label: 'ID da carga' },
                       { type: #FOR_ACTION, dataAction: 'confirmar', label: 'Confirmar carga', position: 90 },
                       { type: #FOR_ACTION, dataAction: 'roteirizacao', label: 'Roteirização', position: 100 }]
  @UI.selectionField: [{ position: 10 }]
  key Carga.CargaId,
      @UI.lineItem: [{ position: 20 }]
      @UI.identification: [{ position: 20, label: 'Status' }]
      @UI.selectionField: [{ position: 20 }]
      Carga.Status,
      @EndUserText.label: 'Status da carga'
      @UI.dataPoint: { qualifier: 'StatusHeader', title: 'Status da carga' }
      cast( case Carga.Status
        when '01' then 'Em montagem'
        when '02' then 'Confirmada'
        when '03' then 'Roteirizada'
        when '04' then 'Liberada'
        else Carga.Status
      end as abap.char(20) ) as StatusTexto,
      @EndUserText.label: 'CD'
      @UI.lineItem: [{ position: 30 }]
      @UI.identification: [{ position: 30 }]
      @UI.selectionField: [{ position: 30 }]
      Carga.ShippingPoint,
      @UI.lineItem: [{ position: 40 }]
      @UI.identification: [{ position: 40, label: 'Criado em' }]
      Carga.CreatedAt,
      @UI.identification: [{ position: 50, label: 'Última alteração' }]
      Carga.LastChangedAt,
      Carga.TotalChangedAt,
      @EndUserText.label: 'Número de remessas'
      @UI.dataPoint: { qualifier: 'RemessasHeader', title: 'Remessas' }
      @UI.lineItem: [{ position: 50 }]
      @UI.identification: [{ position: 60 }]
      coalesce( Totais.TotalRemessas, 0 ) as TotalRemessas,
      @EndUserText.label: 'Peso bruto total (kg)'
      @UI.lineItem: [{ position: 60 }]
      @UI.identification: [{ position: 70 }]
      @Semantics.quantity.unitOfMeasure: 'UnidadePeso'
      PesoValido.PesoTotalKg,
      PesoValido.UnidadePeso,
      @UI.hidden: true
      cast( 100 as abap.int1 ) as MetaOcupacao,
      @EndUserText.label: 'Ocupação por peso (%)'
      @UI.lineItem: [{ position: 70, type: #AS_DATAPOINT, hidden: #(OcupacaoIndisponivel) }]
      @UI.dataPoint: { visualization: #PROGRESS, targetValueElement: 'MetaOcupacao', criticality: 'CriticidadeOcupacao' }
      cast( division( cast( PesoValido.PesoTotalKg as abap.dec( 25, 3 ) ), 140, 2 ) as abap.dec( 16, 2 ) ) as OcupacaoPercentual,
      @UI.hidden: true
      cast( case
        when PesoValido.CargaId is null or PesoValido.PesoTotalKg is null then 0
        when PesoValido.PesoTotalKg > 14000 then 1
        when PesoValido.PesoTotalKg > 11200 then 3
        when PesoValido.PesoTotalKg > 7000 then 2
        else 0
      end as abap.int1 ) as CriticidadeOcupacao,
      @UI.hidden: true
      cast( case when PesoValido.CargaId is null then 'X' else ' ' end as abap_boolean ) as OcupacaoIndisponivel,
      @EndUserText.label: 'Situação do peso'
      @UI.lineItem: [{ position: 80 }]
      cast( case
        when Totais.CargaId is null then 'Sem remessas'
        when Totais.RemessasSemPeso > 0 then 'Peso indisponível'
        else 'Peso completo'
      end as abap.char( 20 ) ) as SituacaoPeso,
      @UI.hidden: true
      cast( 'sap-icon://shipping-status' as abap.char(40) ) as HeaderIcon,
      @EndUserText.label: 'Remessas sem peso em kg'
      @UI.lineItem: [{ position: 70 }]
      @UI.hidden : true
      coalesce( Totais.RemessasSemPeso, 0 ) as RemessasSemPeso,
      _Remessas
}
