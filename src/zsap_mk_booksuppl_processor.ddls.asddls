@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'My Booking Supplemnet Processor Proj'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZSAP_MK_BookSuppl_Processor
  as projection on ZSAP_MK_BookSuppl
{
  key TravelId,
  key BookingId,
  key BookingSupplementId,
      @ObjectModel.text.element: [ 'Text' ]
      @Consumption.valueHelpDefinition: [{ entity.name: '/DMO/I_Supplement', entity.element: 'SupplementID' }]
      SupplementId,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      Price,
      CurrencyCode,
      @Semantics.systemDateTime.lastChangedAt: true
      LastChangedAt,
      @Semantics.text: true
      Text,
      /* Associations */
      _Booking : redirected to parent ZSAP_MK_Booking_Processor,
      _Product,
      _SupplementText,
      _Travel  : redirected to ZSAP_MK_TRavel_processor
}
