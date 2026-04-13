CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA:
      mt_hdr_create TYPE STANDARD TABLE OF zcitvicky_wo_hdr,
      mt_hdr_update TYPE STANDARD TABLE OF zcitvicky_wo_hdr,
      mt_hdr_delete TYPE STANDARD TABLE OF zcitvicky_wo_hdr,
      mt_itm_create TYPE STANDARD TABLE OF zcitvicky_wo_itm,
      mt_itm_update TYPE STANDARD TABLE OF zcitvicky_wo_itm,
      mt_itm_delete TYPE STANDARD TABLE OF zcitvicky_wo_itm.
ENDCLASS.

CLASS lhc_WorkOrderHeader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR WorkOrderHeader RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE WorkOrderHeader.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE WorkOrderHeader.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE WorkOrderHeader.

    METHODS read FOR READ
      IMPORTING keys FOR READ WorkOrderHeader RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK WorkOrderHeader.

    METHODS rba_Items FOR READ
      IMPORTING keys_rba FOR READ WorkOrderHeader\_Items FULL result_requested RESULT result LINK association_links.

    METHODS cba_Items FOR MODIFY
      IMPORTING entities_cba FOR CREATE WorkOrderHeader\_Items.

    METHODS setChangedFields FOR DETERMINE ON MODIFY
      IMPORTING keys FOR WorkOrderHeader~setChangedFields.

    METHODS setCreatedFields FOR DETERMINE ON MODIFY
      IMPORTING keys FOR WorkOrderHeader~setCreatedFields.

    METHODS validatePriority FOR VALIDATE ON SAVE
      IMPORTING keys FOR WorkOrderHeader~validatePriority.

    METHODS validateStatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR WorkOrderHeader~validateStatus.

    " --- Custom Actions ---
    METHODS setStarted FOR MODIFY
      IMPORTING keys FOR ACTION WorkOrderHeader~setStarted RESULT result.

    METHODS setOngoing FOR MODIFY
      IMPORTING keys FOR ACTION WorkOrderHeader~setOngoing RESULT result.

    METHODS setCompleted FOR MODIFY
      IMPORTING keys FOR ACTION WorkOrderHeader~setCompleted RESULT result.
ENDCLASS.

CLASS lhc_WorkOrderHeader IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create.
    DATA ls_db_hdr TYPE zcitvicky_wo_hdr.
    GET TIME STAMP FIELD DATA(lv_ts).

    LOOP AT entities INTO DATA(ls_entity).
      ls_db_hdr = CORRESPONDING #( ls_entity MAPPING FROM ENTITY ).

      " Populate Admin Fields manually for Unmanaged Scenario
      ls_db_hdr-created_at = lv_ts.
      ls_db_hdr-created_by = sy-uname.
      ls_db_hdr-last_changed_at = lv_ts.
      ls_db_hdr-last_changed_by = sy-uname.

      APPEND ls_db_hdr TO lcl_buffer=>mt_hdr_create.

      INSERT VALUE #( %cid     = ls_entity-%cid
                      OrderId  = ls_entity-OrderId )
             INTO TABLE mapped-workorderheader.
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
    GET TIME STAMP FIELD DATA(lv_ts).

    LOOP AT entities INTO DATA(ls_entity).
      SELECT SINGLE * FROM zcitvicky_wo_hdr
        WHERE order_id = @ls_entity-OrderId
        INTO @DATA(ls_db_hdr).

      IF sy-subrc = 0.
        " Ensure we ONLY update fields the UI specifically modified
        IF ls_entity-%control-OrderType   = if_abap_behv=>mk-on. ls_db_hdr-order_type  = ls_entity-OrderType.   ENDIF.
        IF ls_entity-%control-Status      = if_abap_behv=>mk-on. ls_db_hdr-status      = ls_entity-Status.      ENDIF.
        IF ls_entity-%control-Priority    = if_abap_behv=>mk-on. ls_db_hdr-priority    = ls_entity-Priority.    ENDIF.
        IF ls_entity-%control-Description = if_abap_behv=>mk-on. ls_db_hdr-description = ls_entity-Description. ENDIF.
        IF ls_entity-%control-AssignedTo  = if_abap_behv=>mk-on. ls_db_hdr-assigned_to = ls_entity-AssignedTo.  ENDIF.

        " Update Change Tracking
        ls_db_hdr-last_changed_at = lv_ts.
        ls_db_hdr-last_changed_by = sy-uname.

        APPEND ls_db_hdr TO lcl_buffer=>mt_hdr_update.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    DATA ls_db_hdr TYPE zcitvicky_wo_hdr.
    LOOP AT keys INTO DATA(ls_key).
      ls_db_hdr-order_id = ls_key-OrderId.
      APPEND ls_db_hdr TO lcl_buffer=>mt_hdr_delete.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    IF keys IS NOT INITIAL.
      SELECT * FROM zcitvicky_wo_hdr
        FOR ALL ENTRIES IN @keys
        WHERE order_id = @keys-OrderId
        INTO TABLE @DATA(lt_db_hdr).

      LOOP AT lt_db_hdr INTO DATA(ls_hdr).
        APPEND VALUE #(
          %tky          = VALUE #( OrderId = ls_hdr-order_id ) " Crucial for Draft copy
          OrderId       = ls_hdr-order_id
          OrderType     = ls_hdr-order_type
          Status        = ls_hdr-status
          Priority      = ls_hdr-priority
          Description   = ls_hdr-description
          AssignedTo    = ls_hdr-assigned_to
          CreatedBy     = ls_hdr-created_by
          CreatedAt     = ls_hdr-created_at
          LastChangedBy = ls_hdr-last_changed_by
          LastChangedAt = ls_hdr-last_changed_at
        ) TO result.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD rba_Items.
    IF keys_rba IS NOT INITIAL.
      SELECT * FROM zcitvicky_wo_itm
        FOR ALL ENTRIES IN @keys_rba
        WHERE order_id = @keys_rba-OrderId
        INTO TABLE @DATA(lt_db_itm).

      LOOP AT keys_rba INTO DATA(ls_key).
        LOOP AT lt_db_itm INTO DATA(ls_itm) WHERE order_id = ls_key-OrderId.
          APPEND VALUE #( source-%tky = ls_key-%tky
                          target-%tky = VALUE #( OrderId = ls_itm-order_id ItemId = ls_itm-item_id ) ) TO association_links.

          IF result_requested = abap_true.
            APPEND VALUE #(
              %tky          = VALUE #( OrderId = ls_itm-order_id ItemId = ls_itm-item_id )
              OrderId       = ls_itm-order_id
              ItemId        = ls_itm-item_id
              EquipmentId   = ls_itm-equipment_id
              TaskDesc      = ls_itm-task_desc
              Material      = ls_itm-material
              Quantity      = ls_itm-quantity
              Unit          = ls_itm-unit
              LastChangedAt = ls_itm-last_changed_at
            ) TO result.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD cba_Items.
    DATA ls_db_itm TYPE zcitvicky_wo_itm.
    DATA lv_last_item_id TYPE zcitvicky_wo_itm-item_id.

    LOOP AT entities_cba INTO DATA(ls_cba).
      SELECT MAX( item_id )
        FROM zcitvicky_wo_itm
        WHERE order_id = @ls_cba-OrderId
        INTO @lv_last_item_id.

      LOOP AT ls_cba-%target INTO DATA(ls_target).
        ls_db_itm = CORRESPONDING #( ls_target MAPPING FROM ENTITY ).
        lv_last_item_id = lv_last_item_id + 10.

        ls_db_itm-order_id = ls_cba-OrderId.
        ls_db_itm-item_id  = lv_last_item_id.

        APPEND ls_db_itm TO lcl_buffer=>mt_itm_create.

        INSERT VALUE #( %cid    = ls_target-%cid
                        OrderId = ls_cba-OrderId
                        ItemId  = ls_db_itm-item_id )
               INTO TABLE mapped-workorderitem.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD setChangedFields.
    GET TIME STAMP FIELD DATA(lv_ts).
    MODIFY ENTITIES OF ZI_VICKY_WO_HDR IN LOCAL MODE
      ENTITY WorkOrderHeader
      UPDATE FIELDS ( LastChangedBy LastChangedAt )
      WITH VALUE #( FOR key IN keys (
        %tky          = key-%tky
        LastChangedBy = sy-uname
        LastChangedAt = lv_ts
      ) ).
  ENDMETHOD.

  METHOD setCreatedFields.
    GET TIME STAMP FIELD DATA(lv_ts).
    MODIFY ENTITIES OF ZI_VICKY_WO_HDR IN LOCAL MODE
      ENTITY WorkOrderHeader
      UPDATE FIELDS ( CreatedBy CreatedAt Status )
      WITH VALUE #( FOR key IN keys (
        %tky      = key-%tky
        CreatedBy = sy-uname
        CreatedAt = lv_ts
        Status    = 'ongoing'
      ) ).
  ENDMETHOD.

  METHOD validatePriority.
    READ ENTITIES OF ZI_VICKY_WO_HDR IN LOCAL MODE
      ENTITY WorkOrderHeader
      FIELDS ( Priority ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).

    DATA lv_valid TYPE abap_bool.

    LOOP AT lt_header INTO DATA(ls_header).

      " Reset flag each loop
      lv_valid = abap_false.

      " Explicitly check ONLY these 6 exact values — nothing else passes
      IF ls_header-Priority = '1' OR
         ls_header-Priority = '2' OR
         ls_header-Priority = '3' OR
         ls_header-Priority = '4' OR
         ls_header-Priority = '5' OR
         ls_header-Priority = '6'.
        lv_valid = abap_true.
      ENDIF.

      IF lv_valid = abap_false.

        APPEND VALUE #(
          %tky = ls_header-%tky
        ) TO failed-workorderheader.

        APPEND VALUE #(
          %tky              = ls_header-%tky
          %msg              = new_message_with_text(
                                severity = if_abap_behv_message=>severity-error
                                text     = 'Invalid Priority! Enter: 1-Identify 2-Ordered 3-Manufactured 4-GoodQuality 5-OK 6-Bad' )
          %element-Priority = if_abap_behv=>mk-on
        ) TO reported-workorderheader.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateStatus.
    READ ENTITIES OF ZI_VICKY_WO_HDR IN LOCAL MODE
      ENTITY WorkOrderHeader
      FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).

    LOOP AT lt_header INTO DATA(ls_header).
      IF ls_header-Status IS INITIAL.
        APPEND VALUE #( %tky = ls_header-%tky ) TO failed-workorderheader.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  " --- Action Implementations ---
  METHOD setStarted.
    MODIFY ENTITIES OF ZI_VICKY_WO_HDR IN LOCAL MODE
      ENTITY WorkOrderHeader
         UPDATE FIELDS ( Status )
         WITH VALUE #( FOR key IN keys ( %tky   = key-%tky
                                         Status = 'started' ) ).

    READ ENTITIES OF ZI_VICKY_WO_HDR IN LOCAL MODE
      ENTITY WorkOrderHeader
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_workorders).

    result = VALUE #( FOR workorder IN lt_workorders
                        ( %tky   = workorder-%tky
                          %param = workorder ) ).
  ENDMETHOD.

  METHOD setOngoing.
    MODIFY ENTITIES OF ZI_VICKY_WO_HDR IN LOCAL MODE
      ENTITY WorkOrderHeader
         UPDATE FIELDS ( Status )
         WITH VALUE #( FOR key IN keys ( %tky   = key-%tky
                                         Status = 'ongoing' ) ).

    READ ENTITIES OF ZI_VICKY_WO_HDR IN LOCAL MODE
      ENTITY WorkOrderHeader
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_workorders).

    result = VALUE #( FOR workorder IN lt_workorders
                        ( %tky   = workorder-%tky
                          %param = workorder ) ).
  ENDMETHOD.

  METHOD setCompleted.
    MODIFY ENTITIES OF ZI_VICKY_WO_HDR IN LOCAL MODE
      ENTITY WorkOrderHeader
         UPDATE FIELDS ( Status )
         WITH VALUE #( FOR key IN keys ( %tky   = key-%tky
                                         Status = 'completed' ) ).

    READ ENTITIES OF ZI_VICKY_WO_HDR IN LOCAL MODE
      ENTITY WorkOrderHeader
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_workorders).

    result = VALUE #( FOR workorder IN lt_workorders
                        ( %tky   = workorder-%tky
                          %param = workorder ) ).
  ENDMETHOD.

ENDCLASS.

CLASS lhc_WorkOrderItem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE WorkOrderItem.
    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE WorkOrderItem.
    METHODS read FOR READ
      IMPORTING keys FOR READ WorkOrderItem RESULT result.
    METHODS rba_Header FOR READ
      IMPORTING keys_rba FOR READ WorkOrderItem\_Header FULL result_requested RESULT result LINK association_links.
    METHODS validateQuantity FOR VALIDATE ON SAVE
      IMPORTING keys FOR WorkOrderItem~validateQuantity.
ENDCLASS.

CLASS lhc_WorkOrderItem IMPLEMENTATION.
  METHOD update.
    GET TIME STAMP FIELD DATA(lv_ts).

    LOOP AT entities INTO DATA(ls_entity).
      SELECT SINGLE * FROM zcitvicky_wo_itm
        WHERE order_id = @ls_entity-OrderId AND item_id = @ls_entity-ItemId
        INTO @DATA(ls_db_itm).

      IF sy-subrc = 0.
        " Ensure we ONLY update fields the UI specifically modified
        IF ls_entity-%control-EquipmentId = if_abap_behv=>mk-on. ls_db_itm-equipment_id = ls_entity-EquipmentId. ENDIF.
        IF ls_entity-%control-TaskDesc    = if_abap_behv=>mk-on. ls_db_itm-task_desc    = ls_entity-TaskDesc.    ENDIF.
        IF ls_entity-%control-Material    = if_abap_behv=>mk-on. ls_db_itm-material     = ls_entity-Material.    ENDIF.
        IF ls_entity-%control-Quantity    = if_abap_behv=>mk-on. ls_db_itm-quantity     = ls_entity-Quantity.    ENDIF.
        IF ls_entity-%control-Unit        = if_abap_behv=>mk-on. ls_db_itm-unit         = ls_entity-Unit.        ENDIF.

        ls_db_itm-last_changed_at = lv_ts.
        APPEND ls_db_itm TO lcl_buffer=>mt_itm_update.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    DATA ls_db_itm TYPE zcitvicky_wo_itm.
    LOOP AT keys INTO DATA(ls_key).
      ls_db_itm-order_id = ls_key-OrderId.
      ls_db_itm-item_id  = ls_key-ItemId.
      APPEND ls_db_itm TO lcl_buffer=>mt_itm_delete.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    IF keys IS NOT INITIAL.
      SELECT * FROM zcitvicky_wo_itm
        FOR ALL ENTRIES IN @keys
        WHERE order_id = @keys-OrderId AND item_id = @keys-ItemId
        INTO TABLE @DATA(lt_db_itm).

      LOOP AT lt_db_itm INTO DATA(ls_itm).
        APPEND VALUE #(
          %tky          = VALUE #( OrderId = ls_itm-order_id ItemId = ls_itm-item_id )
          OrderId       = ls_itm-order_id
          ItemId        = ls_itm-item_id
          EquipmentId   = ls_itm-equipment_id
          TaskDesc      = ls_itm-task_desc
          Material      = ls_itm-material
          Quantity      = ls_itm-quantity
          Unit          = ls_itm-unit
          LastChangedAt = ls_itm-last_changed_at
        ) TO result.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD rba_Header.
    IF keys_rba IS NOT INITIAL.
      SELECT * FROM zcitvicky_wo_hdr
        FOR ALL ENTRIES IN @keys_rba
        WHERE order_id = @keys_rba-OrderId
        INTO TABLE @DATA(lt_db_hdr).

      LOOP AT keys_rba INTO DATA(ls_key).
        READ TABLE lt_db_hdr INTO DATA(ls_hdr) WITH KEY order_id = ls_key-OrderId.
        IF sy-subrc = 0.
          APPEND VALUE #( source-%tky = ls_key-%tky
                          target-%tky = VALUE #( OrderId = ls_hdr-order_id ) ) TO association_links.

          IF result_requested = abap_true.
            APPEND VALUE #(
              %tky          = VALUE #( OrderId = ls_hdr-order_id )
              OrderId       = ls_hdr-order_id
              OrderType     = ls_hdr-order_type
              Status        = ls_hdr-status
              Priority      = ls_hdr-priority
              Description   = ls_hdr-description
              AssignedTo    = ls_hdr-assigned_to
              CreatedBy     = ls_hdr-created_by
              CreatedAt     = ls_hdr-created_at
              LastChangedBy = ls_hdr-last_changed_by
              LastChangedAt = ls_hdr-last_changed_at
            ) TO result.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD validateQuantity.
    READ ENTITIES OF ZI_VICKY_WO_HDR IN LOCAL MODE
      ENTITY WorkOrderItem
      FIELDS ( Quantity ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item).

    LOOP AT lt_item INTO DATA(ls_item).
      IF ls_item-Quantity <= 0.
        APPEND VALUE #( %tky = ls_item-%tky ) TO failed-workorderitem.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_ZI_VICKY_WO_HDR DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize          REDEFINITION.
    METHODS check_before_save REDEFINITION.
    METHODS save              REDEFINITION.
    METHODS cleanup           REDEFINITION.
    METHODS cleanup_finalize  REDEFINITION.
ENDCLASS.

CLASS lsc_ZI_VICKY_WO_HDR IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.

    " Validate Priority in CREATE buffer
    LOOP AT lcl_buffer=>mt_hdr_create INTO DATA(ls_create).
      IF ls_create-priority <> '1' AND
         ls_create-priority <> '2' AND
         ls_create-priority <> '3' AND
         ls_create-priority <> '4' AND
         ls_create-priority <> '5' AND
         ls_create-priority <> '6'.

        APPEND VALUE #(
          %tky = VALUE #( OrderId = ls_create-order_id )
        ) TO failed-workorderheader.

        APPEND VALUE #(
          %tky              = VALUE #( OrderId = ls_create-order_id )
          %msg              = new_message_with_text(
                                severity = if_abap_behv_message=>severity-error
                                text     = 'Priority must be 1,2,3,4,5 or 6 only' )
          %element-Priority = if_abap_behv=>mk-on
        ) TO reported-workorderheader.

      ENDIF.
    ENDLOOP.

    " Validate Priority in UPDATE buffer
    LOOP AT lcl_buffer=>mt_hdr_update INTO DATA(ls_update).
      IF ls_update-priority <> '1' AND
         ls_update-priority <> '2' AND
         ls_update-priority <> '3' AND
         ls_update-priority <> '4' AND
         ls_update-priority <> '5' AND
         ls_update-priority <> '6'.

        APPEND VALUE #(
          %tky = VALUE #( OrderId = ls_update-order_id )
        ) TO failed-workorderheader.

        APPEND VALUE #(
          %tky              = VALUE #( OrderId = ls_update-order_id )
          %msg              = new_message_with_text(
                                severity = if_abap_behv_message=>severity-error
                                text     = 'Priority must be 1,2,3,4,5 or 6 only' )
          %element-Priority = if_abap_behv=>mk-on
        ) TO reported-workorderheader.

      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD save.
    " Only reached if check_before_save passed (failed table is empty)

    IF lcl_buffer=>mt_hdr_create IS NOT INITIAL.
      INSERT zcitvicky_wo_hdr FROM TABLE @lcl_buffer=>mt_hdr_create
        ACCEPTING DUPLICATE KEYS.
    ENDIF.

    IF lcl_buffer=>mt_hdr_update IS NOT INITIAL.
      UPDATE zcitvicky_wo_hdr FROM TABLE @lcl_buffer=>mt_hdr_update.
    ENDIF.

    IF lcl_buffer=>mt_hdr_delete IS NOT INITIAL.
      DELETE zcitvicky_wo_hdr FROM TABLE @lcl_buffer=>mt_hdr_delete.
    ENDIF.

    IF lcl_buffer=>mt_itm_create IS NOT INITIAL.
      INSERT zcitvicky_wo_itm FROM TABLE @lcl_buffer=>mt_itm_create
        ACCEPTING DUPLICATE KEYS.
    ENDIF.

    IF lcl_buffer=>mt_itm_update IS NOT INITIAL.
      UPDATE zcitvicky_wo_itm FROM TABLE @lcl_buffer=>mt_itm_update.
    ENDIF.

    IF lcl_buffer=>mt_itm_delete IS NOT INITIAL.
      DELETE zcitvicky_wo_itm FROM TABLE @lcl_buffer=>mt_itm_delete.
    ENDIF.

  ENDMETHOD.

  METHOD cleanup.
    CLEAR: lcl_buffer=>mt_hdr_create,
           lcl_buffer=>mt_hdr_update,
           lcl_buffer=>mt_hdr_delete,
           lcl_buffer=>mt_itm_create,
           lcl_buffer=>mt_itm_update,
           lcl_buffer=>mt_itm_delete.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
