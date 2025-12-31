@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supplement As Child'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZSAP_MK_BookSuppl as select from /dmo/booksuppl_m
association to parent ZSAP_MK_Booking as _Booking on $projection.TravelId = _Booking.TravelId and
$projection.BookingId = _Booking.BookingId

association[1..1] to ZSAP_MK_TRavel as _Travel
on $projection.TravelId = _Travel.TravelId
association[1..1] to /DMO/I_Supplement as _Product 
on $projection.BookingSupplementId  = _Product.SupplementID
association[1..*] to /DMO/I_SupplementText as _SupplementText
on $projection.SupplementId = _SupplementText.SupplementID
{
    key travel_id as TravelId,
    key booking_id as BookingId,
    key booking_supplement_id as BookingSupplementId,
    supplement_id as SupplementId,
    @Semantics.amount.currencyCode: 'CurrencyCode'
    price as Price,
    currency_code as CurrencyCode,
    @Semantics.systemDateTime.lastChangedAt: true
    last_changed_at as LastChangedAt,
    _SupplementText.Description as Text,
    _Booking,
    _Travel,
    _Product,
    _SupplementText
    
}
