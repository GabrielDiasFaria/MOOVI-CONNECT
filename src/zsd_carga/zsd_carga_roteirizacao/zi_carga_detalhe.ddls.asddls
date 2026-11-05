@EndUserText.label: 'Remessas da carga'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@VDM.viewType: #COMPOSITE
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_CARGA_DETALHE
  as select from ZI_ZSDT_CARGA_IT as CargaItem
    left outer join I_DeliveryDocument as Delivery
      on CargaItem.DeliveryDocument = Delivery.DeliveryDocument
    left outer join I_DeliveryDocumentAddress as Address
      on CargaItem.DeliveryDocument = Address.DeliveryDocument
     and Address.PartnerFunction = 'WE'
    left outer join I_Customer as Customer
      on Delivery.ShipToParty = Customer.Customer
    left outer join ZI_CARGA_GEO_UNICA as Geo
      on Address.AddressID = Geo.AddressId
     and Geo.CoordinateCount = 1
    left outer join ZI_CARGA_PESO_KG as Peso
      on CargaItem.DeliveryDocument = Peso.DeliveryDocument
{
      @UI.lineItem: [{ position: 10 }]
  key CargaItem.DeliveryDocument,
      CargaItem.CargaId,
      @EndUserText.label: 'Ordem de entrega'
      @UI.lineItem: [{ position: 15 }]
      CargaItem.SequenciaEntrega,
      @EndUserText.label: 'CD'
      @UI.lineItem: [{ position: 20 }]
      Delivery.ShippingPoint,
      @UI.lineItem: [{ position: 30 }]
      Delivery.ShipToParty,
      @EndUserText.label: 'Nome do cliente'
      @UI.lineItem: [{ position: 35 }]
      Customer.CustomerName,
      @UI.lineItem: [{ position: 40 }]
      Delivery.PlannedGoodsIssueDate,
      Address.AddressID as DeliveryAddressId,
      @EndUserText.label: 'Rua'
      @UI.lineItem: [{ position: 42 }]
      Address.StreetName as DeliveryStreet,
      @EndUserText.label: 'Número'
      @UI.lineItem: [{ position: 43 }]
      Address.HouseNumber as DeliveryHouseNumber,
      @EndUserText.label: 'Bairro'
      @UI.lineItem: [{ position: 44 }]
      Address.DistrictName as DeliveryDistrict,
      @EndUserText.label: 'Cidade'
      @UI.lineItem: [{ position: 45 }]
      Address.CityName as DeliveryCity,
      @EndUserText.label: 'UF'
      @UI.lineItem: [{ position: 46 }]
      Address.Region as DeliveryState,
      Address.Country as DeliveryCountry,
      @EndUserText.label: 'CEP de entrega'
      @UI.lineItem: [{ position: 50 }]
      Address.PostalCode as DeliveryPostalCode,
      @EndUserText.label: 'Região de entrega'
      @UI.lineItem: [{ position: 60 }]
      cast( case
        when Address.Country <> 'BR' or Address.PostalCode = '' or Address.PostalCode is null then ''
        when substring( Address.PostalCode, 1, 2 ) = '01' then 'Centro'
        when substring( Address.PostalCode, 1, 2 ) = '02' then 'Norte'
        when substring( Address.PostalCode, 1, 2 ) = '03' then 'Leste'
        when substring( Address.PostalCode, 1, 2 ) = '04' then 'Sul'
        when substring( Address.PostalCode, 1, 2 ) = '05' then 'Oeste'
        else 'Outras'
      end as abap.char(10) ) as DeliveryRegion,
      @UI.lineItem: [{ position: 70, label: 'Peso bruto' }]
      @Semantics.quantity.unitOfMeasure: 'HeaderWeightUnit'
      Delivery.HeaderGrossWeight,
      Delivery.HeaderWeightUnit,
      @EndUserText.label: 'Peso em kg'
      @UI.lineItem: [{ position: 75 }]
      @Semantics.quantity.unitOfMeasure: 'WeightUnitKg'
      Peso.GrossWeightKg,
      Peso.WeightUnitKg,
      @EndUserText.label: 'Quantidade de volumes'
      @UI.lineItem: [{ position: 80 }]
      Delivery.TotalNumberOfPackage,
      @EndUserText.label: 'Volume da remessa'
      @UI.lineItem: [{ position: 85 }]
      @Semantics.quantity.unitOfMeasure: 'HeaderVolumeUnit'
      Delivery.HeaderVolume,
      Delivery.HeaderVolumeUnit,
      @EndUserText.label: 'Volume em m³'
      @UI.lineItem: [{ position: 87 }]
      @Semantics.quantity.unitOfMeasure: 'VolumeUnitM3'
      unit_conversion(
        quantity => cast( Delivery.HeaderVolume as abap.dec(31, 9) ),
        source_unit => Delivery.HeaderVolumeUnit,
        target_unit => abap.unit'M3',
        error_handling => 'SET_TO_NULL'
      ) as VolumeM3,
      abap.unit'M3' as VolumeUnitM3,
      @EndUserText.label: 'Latitude'
      @UI.lineItem: [{ position: 90 }]
      Geo.Latitude,
      @EndUserText.label: 'Longitude'
      @UI.lineItem: [{ position: 95 }]
      Geo.Longitude
}
