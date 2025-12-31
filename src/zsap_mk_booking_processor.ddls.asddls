@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'My Booking Processor Projection'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZSAP_MK_Booking_Processor
  as projection on ZSAP_MK_Booking
{
  key TravelId,
  key BookingId,
      BookingDate,
      @ObjectModel.text.element: [ 'CustomerName' ]
      @Consumption.valueHelpDefinition: [{ entity.name: '/DMO/I_Customer', entity.element: 'CustomerID'}]
      CustomerId,
      @Semantics.text: true
      _Customer.FirstName as CustomerName,
      @ObjectModel.text.element: [ 'AirlineName']
      @Consumption.valueHelpDefinition: [{ entity.name: '/DMO/I_Carrier', entity.element: 'AirlineID'}]
      CarrierId,
      @Semantics.text: true
      _Carrier.Name       as AirlineName,
      @ObjectModel.text.element: [ 'ConnectionId']
      @Consumption.valueHelpDefinition: [
      { entity.name: '/DMO/I_Connection' ,
        entity.element:'ConnectionID',
        additionalBinding: [{ localElement: 'CarrierId' , element: 'AirlineID'}]}]
      @Semantics.text: true
      ConnectionId,
      FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      FlightPrice,
      CurrencyCode,
      @ObjectModel.text.element: [ 'BookingStatus' ]
      @Consumption.valueHelpDefinition: [{ entity.name: '/DMO/I_Booking_Status_VH', entity.element: 'BookingStatus'   }]
      BookingStatus,
//      @Semantics.systemDateTime.lastChangedAt: true
      LastChangedAt,
      /* Associations */
      _BookingStatus,
      _BookSuppl : redirected to composition child ZSAP_MK_BookSuppl_Processor,
      _Carrier,
      _Connection,
      _Customer,
      _Travel    : redirected to parent ZSAP_MK_TRavel_processor
}
