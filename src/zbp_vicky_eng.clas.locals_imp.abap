CLASS lhc_Engineer DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Engineer RESULT result.

ENDCLASS.

CLASS lhc_Engineer IMPLEMENTATION.


  METHOD get_instance_authorizations.
    " To allow all users full authorization, you must explicitly set the
    " authorization flags to 'allowed' (if_abap_behv=>auth-allowed).

    LOOP AT keys INTO DATA(ls_key).
      APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<ls_result>).
      <ls_result>-%tky = ls_key-%tky.

      " Grant update and delete permissions
      <ls_result>-%update      = if_abap_behv=>auth-allowed.
      <ls_result>-%delete      = if_abap_behv=>auth-allowed.

      " Grant draft action permissions
      <ls_result>-%action-Edit = if_abap_behv=>auth-allowed.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
