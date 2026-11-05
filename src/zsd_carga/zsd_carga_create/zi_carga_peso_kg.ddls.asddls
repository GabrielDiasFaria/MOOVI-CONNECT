// CDS auxiliar: normaliza o peso bruto da remessa para comparação em kg.
@EndUserText.label: 'Peso bruto de remessa em quilogramas'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_CARGA_PESO_KG
  as select from I_DeliveryDocument as Delivery
{
  key Delivery.DeliveryDocument,
      // Associa a quantidade convertida à unidade WeightUnitKg.
      @Semantics.quantity.unitOfMeasure: 'WeightUnitKg'
      // Converte da unidade original para KG; erros retornam NULL.
      // O CAST ajusta a precisão do valor antes da conversão.
      unit_conversion(
        quantity => cast( Delivery.HeaderGrossWeight as abap.dec(31, 9) ),
        source_unit => Delivery.HeaderWeightUnit,
        target_unit => abap.unit'KG',
        error_handling => 'SET_TO_NULL'
      ) as GrossWeightKg,
      // Unidade constante do resultado da conversão.
      abap.unit'KG' as WeightUnitKg
}
