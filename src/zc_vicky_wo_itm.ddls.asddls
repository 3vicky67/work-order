@EndUserText.label: 'Work Order Item'  -- Changed to a cleaner end-user label
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity ZC_VICKY_WO_ITM
  as projection on ZI_VICKY_WO_ITM
{
      @EndUserText.label: 'Work Order ID'
  key OrderId,
  
      @EndUserText.label: 'Item ID'
  key ItemId,
  
      @EndUserText.label: 'Equipment'
      EquipmentId,
      
      @EndUserText.label: 'Task Description'
      TaskDesc,
      
      @EndUserText.label: 'Material'
      Material,
      
      @EndUserText.label: 'Quantity'
      Quantity,
      
     @Consumption.valueHelpDefinition: [{ entity: { name: 'I_UnitOfMeasure', element: 'UnitOfMeasure' } }]
      Unit,
      
      @EndUserText.label: 'Last Changed At'
      LastChangedAt,

      /* Associations */
      _Header : redirected to parent ZC_VICKY_WO_HDR
}
