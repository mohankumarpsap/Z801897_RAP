CLASS lhc_ZSAP_MK_TRavel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ZSAP_MK_TRavel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ZSAP_MK_TRavel RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Travel.

    METHODS earlynumbering_cba_Booking FOR NUMBERING
      IMPORTING entities FOR CREATE Travel\_Booking.

ENDCLASS.

CLASS lhc_ZSAP_MK_TRavel IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_cba_booking.

  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA: entity        TYPE STRUCTURE FOR CREATE zsap_mk_travel,
          lv_number_get TYPE /dmo/travel_id.

    LOOP AT entities INTO entity WHERE TravelId IS NOT INITIAL.
      APPEND CORRESPONDING #( entity ) TO mapped-travel.
    ENDLOOP.

    DATA(entities_wo_travel_id) = entities.
    DELETE entities_wo_travel_id WHERE TravelId IS NOT INITIAL.

    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING
            nr_range_nr       = '01'
            object            = CONV #( '/DMO/TRAVL' )
           quantity           = CONV #( lines( entities_wo_travel_id ) )
          IMPORTING
            number            = DATA(lv_number)
            returncode        = DATA(lv_returncode)
            returned_quantity = DATA(lv_returned_qty)
        ).

      CATCH cx_number_ranges.
    ENDTRY.


    IF  lines( entities_wo_travel_id )  = lv_returned_qty.

      lv_number_get = lv_number - lv_returned_qty.

      LOOP AT entities_wo_travel_id INTO entity.

        lv_number_get += 1.
        entity-TravelId = lv_number_get.

        APPEND VALUE #( %cid =  entity-%cid %key = entity-%key ) TO mapped-travel.

      ENDLOOP.


    ENDIF.

  ENDMETHOD.

ENDCLASS.
