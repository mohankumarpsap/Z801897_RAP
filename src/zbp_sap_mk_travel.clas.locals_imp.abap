CLASS lhc_ZSAP_MK_TRavel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ZSAP_MK_TRavel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ZSAP_MK_TRavel RESULT result.

    METHODS copyTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~copyTravel.

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


  METHOD earlynumbering_create.

    DATA: entity        TYPE STRUCTURE FOR CREATE zsap_mk_travel,
          lv_number_get TYPE /dmo/travel_id.

    LOOP AT entities INTO entity WHERE TravelId IS NOT INITIAL.
      APPEND CORRESPONDING #( entity ) TO mapped-travel.
    ENDLOOP.

    " Working with Data only where Travel IDs are empty, deleting once that are not empty
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
            returned_quantity = DATA(lv_returned_qty) "number of entries
        ).

      CATCH cx_number_ranges.
    ENDTRY.


    " total entries = number of range number generated
    IF  lines( entities_wo_travel_id )  = lv_returned_qty.

      lv_number_get = lv_number - lv_returned_qty.
      " 4100 = 4110 - 10
      LOOP AT entities_wo_travel_id INTO entity.

        lv_number_get += 1. "4101, 4102,4103 etc till 4110
        entity-TravelId = lv_number_get.

        APPEND VALUE #( %cid =  entity-%cid %key = entity-%key ) TO mapped-travel.

      ENDLOOP.


    ENDIF.

  ENDMETHOD.

  METHOD earlynumbering_cba_booking.

    DATA: max_booking_id TYPE /dmo/booking_id.

    "1. Get all the travel requests and their booking data

    READ ENTITIES OF ZSAP_MK_TRavel IN LOCAL MODE
    ENTITY Travel BY \_Booking
    FROM CORRESPONDING #( entities )
    LINK DATA(bookings).


    LOOP AT entities ASSIGNING FIELD-SYMBOL(<Travel_group>) GROUP BY <Travel_group>-TravelId.

      " Check in DB what is the max booking number
      max_booking_id = REDUCE #( INIT max = 0
      FOR ls IN bookings
      NEXT max = COND #( WHEN ls-target-BookingId > max_booking_id THEN ls-target-BookingId
      ELSE max_booking_id
      ) ).

      " Now compare that incoming Booking ID entered by the user greater than DB then okay to use, else less than DB value ignore
      max_booking_id =
      REDUCE #( INIT max = 0
      FOR ls_book IN <Travel_group>-%target
      NEXT max = COND #( WHEN ls_book-BookingId > max_booking_id THEN ls_book-BookingId
                         ELSE max_booking_id
       ) ).


      " At this Point we have what is max number
      " Assign new booking to the booking entity inside each travel
      LOOP AT <Travel_group>-%target ASSIGNING FIELD-SYMBOL(<booking_wo_travel>).
        APPEND CORRESPONDING #( <booking_wo_travel> ) TO mapped-booking
        ASSIGNING FIELD-SYMBOL(<mapped_booking>).

        IF  <mapped_booking>-BookingId IS INITIAL.
          max_booking_id += 10.
          <mapped_booking>-BookingId  = max_booking_id.
        ENDIF.

      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

  METHOD copyTravel.
  ENDMETHOD.

ENDCLASS.
