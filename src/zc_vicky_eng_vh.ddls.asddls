@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View for Engineers'
@Metadata.allowExtensions: true
@UI.headerInfo: { 
  typeName: 'Engineer', 
  typeNamePlural: 'Engineers', 
  title: { type: #STANDARD, value: 'EngineerName' } 
}
define root view entity ZC_VICKY_ENG_VH
  provider contract transactional_query
  as projection on ZI_VICKY_ENG_VH
{
  @UI.facet: [ 
    { 
      id: 'EngineerDetails', 
      purpose: #STANDARD, 
      type: #IDENTIFICATION_REFERENCE, 
      label: 'Engineer Details', 
      position: 10 
    } 
  ]

  @EndUserText.label: 'Engineer Name'
  @UI: { lineItem: [ { position: 10 } ], identification: [ { position: 10 } ], selectionField: [ { position: 10 } ] }
  key EngineerName,  // <--- Changed: Just use the exposed name directly

  @EndUserText.label: 'Specialization'
  @UI: { lineItem: [ { position: 20 } ], identification: [ { position: 20 } ] }
  Specialization,    // <--- Changed: Just use the exposed name directly

  @EndUserText.label: 'Experience (Years)'
  @UI: { lineItem: [ { position: 30 } ], identification: [ { position: 30 } ] }
  Experience
}
