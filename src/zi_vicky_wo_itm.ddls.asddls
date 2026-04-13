@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Work Order Item - Interface View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
define view entity ZI_VICKY_WO_ITM
  as select from zcitvicky_wo_itm
  association to parent ZI_VICKY_WO_HDR as _Header  -- ✅ Fixed
    on $projection.OrderId = _Header.OrderId
{
  key order_id        as OrderId,
  key item_id         as ItemId,
      equipment_id    as EquipmentId,
      task_desc       as TaskDesc,
      material        as Material,

      @Semantics.quantity.unitOfMeasure: 'Unit'
      quantity        as Quantity,

      unit            as Unit,
      last_changed_at as LastChangedAt,
      _Header
}
