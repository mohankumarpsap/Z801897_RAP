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

        APPEND VALUE #(
        %cid =  entity-%cid
        %key = entity-%key
        %is_draft = entity-%is_draft
         )
        TO mapped-travel.

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
          <mapped_booking>-%is_draft = <booking_wo_travel>-%is_draft.
          <mapped_booking>-BookingId  = max_booking_id.
        ENDIF.

      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

  METHOD copyTravel.

    DATA: travels          TYPE TABLE FOR CREATE ZSAP_MK_TRavel\\Travel,
          bookings_cba     TYPE TABLE FOR CREATE ZSAP_MK_TRavel\\Travel\_Booking,
          bookingsuppl_cba TYPE TABLE FOR CREATE ZSAP_MK_TRavel\\Booking\_BookSuppl.

    "1.Remove the Travel instance with initial % CID
    READ TABLE keys WITH KEY %cid = ' ' INTO DATA(key_with_initail_cid).
    ASSERT key_with_initail_cid IS INITIAL.
    "2.Read all Travel, Booking, booking Supplement using EML

    READ ENTITIES OF ZSAP_MK_TRavel IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH
    CORRESPONDING #( keys )
    RESULT DATA(travel_read_result)
    FAILED failed.

    "3.Fill travel internal table for travel data creation - %CID - ABCD

    READ ENTITIES OF ZSAP_MK_TRavel IN LOCAL MODE
    ENTITY Travel BY \_Booking
    ALL FIELDS WITH
    CORRESPONDING #( travel_read_result )
    RESULT DATA(book_read_result)
    FAILED failed.

    "4.Fill Booking internal table for Booking data creation - &CID_REF - ABCD

    READ ENTITIES OF ZSAP_MK_TRavel
    ENTITY Booking BY \_BookSuppl
    ALL FIELDS WITH
    CORRESPONDING #( book_read_result )
    RESULT DATA(booksuppl_read_result)
    FAILED DATA(fail).

    "5.Fill Booking Supplement internal table for Booking Supplement data creation - &CID_REF - ABCD



    LOOP AT travel_read_result ASSIGNING FIELD-SYMBOL(<travel>).


      " Travel Data to be created
      APPEND VALUE #(  %cid = keys[ %tky = <travel>-%tky ]-%cid
                       %data = CORRESPONDING #( <travel> EXCEPT TravelId  ) )
                               TO travels ASSIGNING FIELD-SYMBOL(<new_travel>).


      <new_travel>-BeginDate = cl_abap_context_info=>get_system_date(  ).
      <new_travel>-EndDate = cl_abap_context_info=>get_system_date(  ) + 30.
      <new_travel>-OverallStatus = 'O'.


      APPEND VALUE #(  %cid_ref = keys[ %tky = <travel>-%tky ]-%cid )
                     TO bookings_cba ASSIGNING FIELD-SYMBOL(<bookings_cba>).


      LOOP AT book_read_result ASSIGNING FIELD-SYMBOL(<booking>) WHERE TravelId = <travel>-TravelId.

        APPEND VALUE #(  %cid = keys[ KEY entity %tky = <travel>-%tky ]-%cid && <booking>-BookingId
                      %data = CORRESPONDING #( book_read_result[ KEY entity %tky = <booking>-%tky ] EXCEPT TravelId )
                      )
                     TO <bookings_cba>-%target  ASSIGNING FIELD-SYMBOL(<new_booking>).


        <new_booking>-BookingStatus = 'N'.


        APPEND VALUE #(  %cid_ref = keys[ KEY entity %tky = <travel>-%tky ]-%cid && <booking>-BookingId )
                       TO bookingsuppl_cba ASSIGNING FIELD-SYMBOL(<bookings_suppl_cba>).

*
        LOOP AT booksuppl_read_result ASSIGNING FIELD-SYMBOL(<booking_suppl>)
        WHERE TravelId = <travel>-TravelId AND BookingId = <booking>-BookingId.

          APPEND VALUE #(  %cid = keys[ KEY entity %tky = <travel>-%tky ]-%cid
                                        && <booking>-BookingId
                                        && <booking_suppl>-BookingSupplementId
                              %data = CORRESPONDING #( booksuppl_read_result[ KEY entity %tky = <booking_suppl>-%tky ] EXCEPT TravelId bookingId )
                         )
                             TO <bookings_suppl_cba>-%target."ASSIGNING FIELD-SYMBOL(<new_booking_suppl>). Optinal as no new level

        ENDLOOP.
*

      ENDLOOP.

    ENDLOOP.

    "6.Create EML to create new BO instance using existing data

    MODIFY ENTITIES OF ZSAP_MK_TRavel IN LOCAL MODE
       ENTITY Travel
          CREATE FIELDS ( AgencyId CustomerId BeginDate EndDate BookingFee TotalPrice CurrencyCode OverallStatus )
             WITH travels
               CREATE BY \_Booking FIELDS (  BookingId BookingDate CustomerId CarrierId ConnectionId FlightDate FlightPrice BookingStatus )
                  WITH bookings_cba
                    ENTITY Booking
                      CREATE BY \_BookSuppl
                        FIELDS ( BookingSupplementId SupplementId price CurrencyCode )
                          WITH bookingsuppl_cba
                            MAPPED DATA(mapped_create).

    mapped-travel = mapped_create-travel.

" My Own Style
*
*    DATA: lt_travels   TYPE TABLE FOR CREATE ZSAP_MK_TRavel\\Travel,
*          lt_bookings  TYPE TABLE FOR CREATE ZSAP_MK_TRavel\\Travel\_Booking,
*          lt_booksuppl TYPE TABLE FOR CREATE ZSAP_MK_TRavel\\Booking\_BookSuppl.
*
*    "Safety check
*    READ TABLE keys WITH KEY %cid = '' TRANSPORTING NO FIELDS.
*    ASSERT sy-subrc <> 0.
*
*    "1️ Read existing data
*    READ ENTITIES OF ZSAP_MK_TRavel IN LOCAL MODE
*      ENTITY Travel ALL FIELDS WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_travel_old).
*
*    READ ENTITIES OF ZSAP_MK_TRavel IN LOCAL MODE
*      ENTITY Travel BY \_Booking ALL FIELDS WITH CORRESPONDING #( lt_travel_old )
*      RESULT DATA(lt_booking_old).
*
*    READ ENTITIES OF ZSAP_MK_TRavel IN LOCAL MODE
*      ENTITY Booking BY \_BookSuppl ALL FIELDS WITH CORRESPONDING #( lt_booking_old )
*      RESULT DATA(lt_booksuppl_old).
*
*    "2️ Build new structure
*    LOOP AT lt_travel_old INTO DATA(ls_travel_old).
*
*      " Creating empty table structure with field symbol
*      APPEND INITIAL LINE TO lt_travels ASSIGNING FIELD-SYMBOL(<new_travel>).
*      MOVE-CORRESPONDING ls_travel_old TO <new_travel>.
*
*      <new_travel>-%cid = keys[ KEY entity %tky = ls_travel_old-%tky ]-%cid.
*      <new_travel>-BeginDate = cl_abap_context_info=>get_system_date( ).
*      <new_travel>-EndDate   = <new_travel>-BeginDate + 30.
*      <new_travel>-OverallStatus = 'O'.
*
*      LOOP AT lt_booking_old INTO DATA(ls_booking_old)
*           WHERE TravelId = ls_travel_old-TravelId.
*
*        " Creating empty table structure with field symbol
*        APPEND INITIAL LINE TO lt_bookings ASSIGNING FIELD-SYMBOL(<new_booking_grp>).
*
*        " %CID_REF for the item booking table map
*        <new_booking_grp>-%cid_ref = keys[ KEY entity %tky = ls_travel_old-%tky ]-%cid.
*        APPEND INITIAL LINE TO <new_booking_grp>-%target ASSIGNING FIELD-SYMBOL(<new_booking>).
*        MOVE-CORRESPONDING ls_booking_old TO <new_booking>.
*
*        <new_booking>-BookingStatus = 'N'.
*        <new_booking>-%cid = keys[ KEY entity %tky = ls_travel_old-%tky ]-%cid
*                                   && ls_booking_old-BookingId.
*        <new_booking>-TravelId = ' '.
*
*        LOOP AT lt_booksuppl_old INTO DATA(ls_booksuppl_old)
*             WHERE TravelId = ls_travel_old-TravelId AND BookingId = ls_booking_old-BookingId.
*
*          " Creating empty table structure with field symbol
*          APPEND INITIAL LINE TO lt_booksuppl ASSIGNING FIELD-SYMBOL(<new_booksuppl_grp>).
*
*          " %CID_REF for the item booking_supplement table map
*          <new_booksuppl_grp>-%cid_ref =  keys[ KEY entity %tky = ls_travel_old-%tky ]-%cid && ls_booking_old-BookingId.
*          APPEND INITIAL LINE TO <new_booksuppl_grp>-%target ASSIGNING FIELD-SYMBOL(<new_suppl>).
*          MOVE-CORRESPONDING ls_booksuppl_old TO <new_suppl>.
*
*          <new_suppl>-%cid = keys[ KEY entity %tky = ls_travel_old-%tky ]-%cid
*                                        && ls_booking_old-BookingId
*                                        && ls_booksuppl_old-BookingSupplementId.
*          <new_suppl>-TravelId = ' '.
*          <new_suppl>-BookingId = ' '.
*
*        ENDLOOP.
*      ENDLOOP.
*    ENDLOOP.
*
*    "3️ Create new instances
*    MODIFY ENTITIES OF ZSAP_MK_TRavel IN LOCAL MODE
*ENTITY Travel
* CREATE FIELDS ( AgencyId CustomerId BeginDate EndDate BookingFee TotalPrice CurrencyCode OverallStatus )
*    WITH lt_travels
*      CREATE BY \_Booking FIELDS (  BookingId BookingDate CustomerId CarrierId ConnectionId FlightDate FlightPrice BookingStatus )
*         WITH lt_bookings
*           ENTITY Booking
*             CREATE BY \_BookSuppl
*               FIELDS ( BookingSupplementId SupplementId price CurrencyCode )
*                 WITH lt_booksuppl
*                   MAPPED DATA(mapped_create).
*
*    mapped-travel = mapped_create-travel.

  ENDMETHOD.

ENDCLASS.
