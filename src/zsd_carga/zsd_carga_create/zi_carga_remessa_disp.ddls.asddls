// CDS de interface: reúne dados e seleciona remessas disponíveis para montagem.
@EndUserText.label: 'Remessas disponíveis para carga'
// Esta CDS não exige verificação de autorização por DCL.
@AccessControl.authorizationCheck: #NOT_REQUIRED
@VDM.viewType: #COMPOSITE
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_CARGA_REMESSA_DISP
  // Remessa standard é a origem principal; INNER JOIN exige peso convertido.
  as select from I_DeliveryDocument as Delivery
    inner join ZI_CARGA_PESO_KG as Weight
      on Delivery.DeliveryDocument = Weight.DeliveryDocument
    // O vínculo é opcional: sem carga, os campos de CargaItem ficam nulos.
    left outer join ZI_ZSDT_CARGA_IT as CargaItem
      on Delivery.DeliveryDocument = CargaItem.DeliveryDocument
    // Busca opcionalmente o endereço do parceiro de entrega (função WE).
    left outer join I_DeliveryDocumentAddress as Address
      on Delivery.DeliveryDocument = Address.DeliveryDocument
     and Address.PartnerFunction = 'WE'
{
  key Delivery.DeliveryDocument,
      Delivery.ShippingPoint,
      Delivery.ShipToParty,
      Delivery.PlannedGoodsIssueDate,
      @EndUserText.label: 'CEP de entrega'
      Address.PostalCode as DeliveryPostalCode,
      // Regra do aplicativo: classifica pelos dois primeiros caracteres do CEP brasileiro.
      // País diferente de BR ou CEP ausente resulta em região vazia.
      @EndUserText.label: 'Região de entrega'
      cast( case
        when Address.Country <> 'BR' or Address.PostalCode = '' or Address.PostalCode is null then ''
        when substring( Address.PostalCode, 1, 2 ) = '01' then 'Centro'
        when substring( Address.PostalCode, 1, 2 ) = '02' then 'Norte'
        when substring( Address.PostalCode, 1, 2 ) = '03' then 'Leste'
        when substring( Address.PostalCode, 1, 2 ) = '04' then 'Sul'
        when substring( Address.PostalCode, 1, 2 ) = '05' then 'Oeste'
        else 'Outras'
      end as abap.char(10) ) as DeliveryRegion,
      // Associa o peso original à sua unidade de medida.
      @Semantics.quantity.unitOfMeasure: 'HeaderWeightUnit'
      Delivery.HeaderGrossWeight,
      Delivery.HeaderWeightUnit
}
// Apenas remessas sem vínculo de carga e com destinatário informado.
// Peso original e convertido devem ser positivos; o limite é 14.000 kg.
where CargaItem.DeliveryDocument is null
  and Delivery.HeaderGrossWeight > 0
  and Weight.GrossWeightKg > 0
  and Weight.GrossWeightKg <= 14000
  and Delivery.ShipToParty <> ''
