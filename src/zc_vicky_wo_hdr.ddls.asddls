@EndUserText.label: 'Work Order Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

/* FIX: Removed __ from entity name */
define root view entity ZC_VICKY_WO_HDR 
  as projection on ZI_VICKY_WO_HDR
{
    @EndUserText.label: 'Order ID'
    key OrderId,

    @EndUserText.label: 'Current Status'
    Status,

    StatusCriticality,

    @EndUserText.label: 'Priority Level'
    Priority,

    @EndUserText.label: 'Work Description'
    Description,

    @EndUserText.label: 'Assigned Engineer'
    AssignedTo,

    @EndUserText.label: 'Created By'
    CreatedBy,

    @EndUserText.label: 'Created On'
    CreatedAt,

    /* Associations */
    _Items : redirected to composition child ZC_VICKY_WO_ITM
}
