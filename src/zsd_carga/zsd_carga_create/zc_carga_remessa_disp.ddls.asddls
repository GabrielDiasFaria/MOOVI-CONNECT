// CDS de projeção: expõe dados e metadados para a interface do aplicativo.
@EndUserText.label: 'Remessas disponíveis para carga'
// Não exige verificação de autorização por DCL nesta projeção.
@AccessControl.authorizationCheck: #NOT_REQUIRED
@VDM.viewType: #CONSUMPTION
@Metadata.ignorePropagatedAnnotations: true
// Nomes de exibição e chave usada como título na interface.
@UI.headerInfo: { typeName: 'Remessa', typeNamePlural: 'Remessas', title: { value: 'DeliveryDocument' } }
// Ordem inicial da lista: CD, região, data e remessa.
@UI.presentationVariant: [{ sortOrder: [{ by: 'ShippingPoint', direction: #ASC },
                                       { by: 'DeliveryRegion', direction: #ASC },
                                       { by: 'PlannedGoodsIssueDate', direction: #ASC },
                                       { by: 'DeliveryDocument', direction: #ASC }] }]
define root view entity ZC_CARGA_REMESSA_DISP
  // Projeção transacional para uso com o behavior RAP.
  provider contract transactional_query
  as projection on ZI_CARGA_REMESSA_DISP
{
  // lineItem define a coluna e os botões; CHANGE_SET solicita agrupamento das ações.
  // O agrupamento efetivo depende do cliente OData em execução.
  @UI.lineItem: [{ position: 10 },
                 { type: #FOR_ACTION, dataAction: 'testar_selecao', label: 'Simular cargas', position: 100, invocationGrouping: #CHANGE_SET },
                 { type: #FOR_ACTION, dataAction: 'criar_cargas', label: 'Criar cargas', position: 110, invocationGrouping: #CHANGE_SET }]
  // Disponibiliza a remessa como filtro na tela.
  @UI.selectionField: [{ position: 10 }]
  key DeliveryDocument,
  // Os campos seguintes definem rótulos, colunas e filtros da lista.
  @EndUserText.label: 'CD'
  @UI.lineItem: [{ position: 20, label: 'CD' }]
  @UI.selectionField: [{ position: 20 }]
      ShippingPoint,
  @EndUserText.label: 'CEP de entrega'
  @UI.lineItem: [{ position: 25 }]
      DeliveryPostalCode,
  @EndUserText.label: 'Região de entrega'
  @UI.lineItem: [{ position: 27 }]
      DeliveryRegion,
  @UI.lineItem: [{ position: 30 }]
  @UI.selectionField: [{ position: 30 }]
      ShipToParty,
  @UI.lineItem: [{ position: 40 }]
  @UI.selectionField: [{ position: 40 }]
      PlannedGoodsIssueDate,
  @UI.lineItem: [{ position: 50, label: 'Peso bruto' }]
  // Associa o peso à unidade para os consumidores.
  @Semantics.quantity.unitOfMeasure: 'HeaderWeightUnit'
      HeaderGrossWeight,
      HeaderWeightUnit
}
