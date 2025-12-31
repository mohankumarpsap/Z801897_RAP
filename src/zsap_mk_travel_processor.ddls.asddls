@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'My Travel Root Processor Projection'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZSAP_MK_TRavel_processor
  as projection on ZSAP_MK_TRavel
{
  key TravelId,
      @ObjectModel.text.element: [ 'AgencyName' ]
      @Consumption.valueHelpDefinition: [{ entity.name: '/DMO/I_Agency', entity.element: 'AgencyID' }]
      AgencyId,
      @Semantics.text: true
      _Agency.Name        as AgencyName,
      @ObjectModel.text.element: [ 'CustomerName' ]
      @Consumption.valueHelpDefinition: [{ entity.name: '/DMO/I_Customer', entity.element: 'CustomerID'}]
      CustomerId,
      @Semantics.text: true
      _Customer.FirstName as CustomerName,
      BeginDate,
      EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,
      CurrencyCode,
      Description,
      @ObjectModel.text.element: [ 'StatusText' ]
      @Consumption.valueHelpDefinition: [{ entity.name: '/DMO/I_Overall_Status_VH', entity.element: 'OverallStatus'}]
      OverallStatus,
      @Semantics.user.createdBy: true
      CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      CreatedAt,
      @Semantics.user.lastChangedBy: true
      LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      LastChangedAt,
      /* Associations */
      @Semantics.text: true
      StatusText,
      criticality,
      _Agency,
      _Booking : redirected to composition child ZSAP_MK_Booking_Processor,
      _Currency,
      _Customer,
      _OverallStatus
}
