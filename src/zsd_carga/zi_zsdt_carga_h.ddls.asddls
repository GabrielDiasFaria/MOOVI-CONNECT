// CDS básica de leitura dos dados persistidos no cabeçalho da carga.
@EndUserText.label: 'Conecta - cabeçalho de carga'
// Solicita verificação de autorização CDS; o efeito depende da DCL existente.
@AccessControl.authorizationCheck: #CHECK
@VDM.viewType: #BASIC
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_ZSDT_CARGA_H
  as select from zsdt_carga_h
{
  // UUID identifica a carga; aliases facilitam o consumo dos campos.
  key carga_id   as CargaId,
      // Timestamps de criação e alteração, seguidos por status e CD.
      created_at      as CreatedAt,
      last_changed_at  as LastChangedAt,
      total_changed_at as TotalChangedAt,
      status           as Status,
      vstel            as ShippingPoint
}
