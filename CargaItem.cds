// CDS básica que expõe o vínculo persistido entre remessa e carga.
@EndUserText.label: 'Conecta - vínculos de remessas'
// Solicita verificação de autorização CDS; o efeito depende da DCL existente.
@AccessControl.authorizationCheck: #CHECK
@VDM.viewType: #BASIC
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_ZSDT_CARGA_IT
  as select from zsdt_carga_it
{
  // Remessa é a chave; CargaId identifica o cabeçalho da carga vinculada.
  key vbeln    as DeliveryDocument,
      carga_id as CargaId,
      seq_entrega as SequenciaEntrega
}
