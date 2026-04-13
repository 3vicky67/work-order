@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TO KNOW ABOUT WORK FORCE'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
define root view entity ZI_VICKY_WO_HDR
  as select from zcitvicky_wo_hdr
  composition [1..*] of ZI_VICKY_WO_ITM as _Items
{
  key order_id        as OrderId,
      order_type      as OrderType,
      status          as Status,

      /* Status Criticality Logic */
      case status
        when 'started'   then 1
        when 'ongoing'   then 2
        when 'completed' then 3
        else 0
      end as StatusCriticality,

      priority        as Priority,
      description     as Description,
      assigned_to     as AssignedTo,
      created_by      as CreatedBy,
      created_at      as CreatedAt,
      last_changed_by as LastChangedBy,
      last_changed_at as LastChangedAt,
      
      _Items
}
