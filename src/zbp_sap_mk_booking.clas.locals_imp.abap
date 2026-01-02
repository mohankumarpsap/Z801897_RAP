CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS earlynumbering_cba_Booksuppl FOR NUMBERING
      IMPORTING entities FOR CREATE Booking\_Booksuppl.

ENDCLASS.

CLASS lhc_Booking IMPLEMENTATION.

  METHOD earlynumbering_cba_Booksuppl.

    DATA: max_book_supplement_id TYPE /dmo/booking_supplement_id.

    "1. Get all the travel requests and their booking data

    READ ENTITIES OF ZSAP_MK_TRavel IN LOCAL MODE
    ENTITY booking BY \_BookSuppl
    FROM CORRESPONDING #( entities )
    LINK DATA(booking_supplemnet).


    LOOP AT entities ASSIGNING FIELD-SYMBOL(<Booking_suppl_group>) GROUP BY <Booking_suppl_group>-%tky.

      " Check in DB what is the max booking number
      max_book_supplement_id = REDUCE #( INIT max = 0
      FOR ls IN booking_supplemnet
      USING KEY entity
      WHERE ( source-TravelId = <Booking_suppl_group>-TravelId AND source-BookingId = <Booking_suppl_group>-BookingId  )
      NEXT max = COND #( WHEN ls-target-BookingSupplementId > max_book_supplement_id THEN ls-target-BookingSupplementId
                         ELSE max_book_supplement_id
      ) ).

      " Now compare that incoming Booking ID entered by the user greater than DB then okay to use, else less than DB value ignore
      max_book_supplement_id = REDUCE #( INIT max = 0
      FOR ls_book IN <Booking_suppl_group>-%target
      USING KEY entity
      WHERE ( TravelId = <Booking_suppl_group>-TravelId AND BookingId = <Booking_suppl_group>-BookingId  )
      NEXT max = COND #( WHEN ls_book-BookingSupplementId > max_book_supplement_id THEN ls_book-BookingSupplementId
                         ELSE max_book_supplement_id
       ) ).


      " At this Point we have what is max number
      " Assign new booking to the booking entity inside each travel
      LOOP AT <Booking_suppl_group>-%target ASSIGNING FIELD-SYMBOL(<bookingsupp_wo_travel>).
        APPEND CORRESPONDING #( <bookingsupp_wo_travel> ) TO mapped-booksuppl
        ASSIGNING FIELD-SYMBOL(<mapped_bookingsuppl>).

        IF  <mapped_bookingsuppl>-BookingSupplementId IS INITIAL.
          max_book_supplement_id += 10.
          <mapped_bookingsuppl>-BookingSupplementId  = max_book_supplement_id.
        ENDIF.

      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
