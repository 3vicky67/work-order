@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help for Engineers'
@ObjectModel.resultSet.sizeCategory: #XS // Renders as a true dropdown list
define root view entity ZI_VICKY_ENG_VH
  as select from zcitvicky_eng
{
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Engineer Name'
  key name       as EngineerName,

      @EndUserText.label: 'Field'
      field      as Specialization,

      @EndUserText.label: 'Experience (Years)'
      experience as Experience,
      
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
     last_changed_at as LastChangedAt
}
