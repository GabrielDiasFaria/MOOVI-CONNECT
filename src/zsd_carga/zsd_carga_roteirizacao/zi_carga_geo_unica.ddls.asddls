@EndUserText.label: 'Coordenada válida por endereço'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_CARGA_GEO_UNICA
  as select from geoloc as Geo
{
  key Geo.addrnumber as AddressId,
      count( * ) as CoordinateCount,
      min( Geo.latitude ) as Latitude,
      min( Geo.longitude ) as Longitude
}
where Geo.addrnumber <> ''
  and Geo.deleted = 0
  and ( Geo.latitude <> 0 or Geo.longitude <> 0 )
group by Geo.addrnumber
