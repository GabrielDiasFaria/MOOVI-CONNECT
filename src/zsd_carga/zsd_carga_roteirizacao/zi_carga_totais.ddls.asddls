@EndUserText.label: 'Totais de remessas e peso por carga'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@VDM.viewType: #COMPOSITE
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_CARGA_TOTAIS
  as select from ZI_ZSDT_CARGA_IT as Item
    left outer join ZI_CARGA_PESO_KG as Peso
      on Item.DeliveryDocument = Peso.DeliveryDocument
{
  key Item.CargaId,
      count( * ) as TotalRemessas,
      @Semantics.quantity.unitOfMeasure: 'UnidadePeso'
      sum( Peso.GrossWeightKg ) as PesoTotalKg,
      abap.unit'KG' as UnidadePeso,
      sum( case when Peso.GrossWeightKg is null then 1 else 0 end ) as RemessasSemPeso
}
group by Item.CargaId
