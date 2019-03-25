ALTER MESSAGE TYPE [http://tfl.gov.uk/Ft/Pare/DirectPayment/Message/Confirmation/Request] 
 VALIDATION = WELL_FORMED_XML


If EXISTS(SELECT 1 FROM sys.xml_schema_collections where name = 'http://tfl.gov.uk/Ft/Pare/DirectPayment/Schema/Confirmation/Request')
BEGIN
	DROP  XML SCHEMA COLLECTION [http://tfl.gov.uk/Ft/Pare/DirectPayment/Schema/Confirmation/Request]
END


CREATE XML SCHEMA COLLECTION [http://tfl.gov.uk/Ft/Pare/DirectPayment/Schema/Confirmation/Request]
AS
N'<?xml version="1.0" encoding="utf-16"?>
<!-- edited with XMLSpy v2012 rel. 2 (http://www.altova.com) by Richard North (Transport For London) -->
<!--
 TfL Future Ticketing Platform XML Schema
 
 Name:			DirectPaymentConfirmationRequestV0.10.xsd
 Date:			10/05/2012
 Author:		Sam Pratt
 Description:	Defines the structure of messages sent from PCS to notify 
				PARE of a Direct Payment.
			
 Change History
 ==============
 Version	Date		Changed By		Comments
 0.1		10/05/12	S. Pratt		First version
 0.2		21/05/12	R.North			Changed name from DirectPayment to DirectPaymentConfirmation.  
										Changed MerchantId to max 15. Changed PaymentCardSchemeType to 
										PaymentCardType. Nested acquirer elements in the AcquirerResponse 
										complex type. Added annotations. 
 0.3		22/05/12	S. Pratt		Updated Schema name to be consistent with other schemas
 0.4		23/05/12	R.North			Reduced PanToken max length to 26. Restricted ExpiryDate, LastFourDigits, 
										BinNumber and added regex restriction on AuthorisationCode.  Restricted 
										PanToken to only allow 0-9 and A-F.
 0.5		21/06/12	R.North			Changed PaymentCardType enumeration to match that in AuthorisationRequest.
 0.6		29/06/12	R.North			Changed AcquirerResponse to be mandatory.
 0.7		27/07/12	R.North			Removed VerificationResult and replaced with AddressCheckResult and CVVCheckResult.
										Added TraceId and PaymentCardTransactionType. Added Error structure as a mutually 
										exclusive choice with AcquirerResponse.
 0.8		20/09/13	R.North			Added validation to AuthorisationTimeStamp to avoid date earlier than 01/01/1980.
 0.9		02/10/13	R.North			Modified TraceId to accept a max length of 19 characters (on request by Cubic).
 0.10		27/11/13	R.North			Removed restriction on AuthorisationCode as alpha-numeric codes are possible.
-->
<xs:schema xmlns="http://tfl.gov.uk/Ft/Pare/DirectPayment/Message/Confirmation/Request/v0.10" xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="unqualified">
  <xs:element name="DirectPaymentConfirmationRequest">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="DirectPaymentReferenceId" type="xs:long">
          <xs:annotation>
            <xs:documentation>A unique reference originally provided by PARE to CACC and then from CACC to the Secure Portal to track the Direct Payment.</xs:documentation>
          </xs:annotation>
        </xs:element>
        <xs:element name="PaymentCardTransactionType">
          <xs:annotation>
            <xs:documentation>The type of transaction.</xs:documentation>
          </xs:annotation>
          <xs:simpleType>
            <xs:restriction base="xs:string">
              <xs:enumeration value="ECommerceAuthorisation"/>
              <xs:enumeration value="ECommerceAccountValidityCheck"/>
              <xs:enumeration value="MotoAuthorisation"/>
              <xs:enumeration value="MotoAccountValidityCheck"/>
            </xs:restriction>
          </xs:simpleType>
        </xs:element>
        <xs:element name="Amount">
          <xs:annotation>
            <xs:documentation>The amount (in pence) of the payment</xs:documentation>
          </xs:annotation>
          <xs:simpleType>
            <xs:restriction base="xs:int">
              <xs:minInclusive value="0"/>
              <xs:maxInclusive value="9999999"/>
            </xs:restriction>
          </xs:simpleType>
        </xs:element>
        <xs:element name="MerchantId">
          <xs:annotation>
            <xs:documentation>The merchant ID for the organisation to which the payment is being made.</xs:documentation>
          </xs:annotation>
          <xs:simpleType>
            <xs:restriction base="xs:string">
              <xs:minLength value="1"/>
              <xs:maxLength value="15"/>
            </xs:restriction>
          </xs:simpleType>
        </xs:element>
        <xs:element name="AddressCheckRequested">
          <xs:annotation>
            <xs:documentation>Indicates whether the CACC portal requested an address check to be performed.  Can be used in conjunction with VerificationResult to establish whether an address check was successful or not.</xs:documentation>
          </xs:annotation>
          <xs:simpleType>
            <xs:restriction base="xs:boolean"/>
          </xs:simpleType>
        </xs:element>
        <xs:element name="AuthorisationTimeStamp">
          <xs:annotation>
            <xs:documentation>The time when the authorisation was performed by the Secure Portal</xs:documentation>
          </xs:annotation>
          <xs:simpleType>
            <xs:restriction base="xs:dateTime">
              <xs:minInclusive value="1980-01-01T04:30:00"/>
            </xs:restriction>
          </xs:simpleType>
        </xs:element>
        <xs:choice>
          <xs:annotation>
            <xs:documentation>Mutually exclusive "choice" of either an AcquirerResponse or an Error</xs:documentation>
          </xs:annotation>
          <xs:element name="AcquirerResponse">
            <xs:annotation>
              <xs:documentation>Contains the response from the acquirer</xs:documentation>
            </xs:annotation>
            <xs:complexType>
              <xs:sequence>
                <xs:element name="ResponseCode">
                  <xs:annotation>
                    <xs:documentation>Response code from the acquirer.  Could be either a Barclays response code or an Amex response code.  Must not be padded as the exact value from the acquirer must be preserved.  Only present if a response was received from the acquirer.</xs:documentation>
                  </xs:annotation>
                  <xs:simpleType>
                    <xs:restriction base="xs:string">
                      <xs:minLength value="1"/>
                      <xs:maxLength value="3"/>
                    </xs:restriction>
                  </xs:simpleType>
                </xs:element>
                <xs:element name="AuthorisationCode" nillable="true">
                  <xs:annotation>
                    <xs:documentation>Six character authorisation code provided from the issuer.  May be padded with spaces or zeros depending on acquirer.  Only present for an approved response.</xs:documentation>
                  </xs:annotation>
                  <xs:simpleType>
                    <xs:restriction base="xs:string">
                      <xs:length value="6"/>
                    </xs:restriction>
                  </xs:simpleType>
                </xs:element>
                <xs:element name="AddressCheckResult" nillable="true">
                  <xs:annotation>
                    <xs:documentation>If an address check was performed then this indicates whether the check was successful or not.</xs:documentation>
                  </xs:annotation>
                  <xs:simpleType>
                    <xs:restriction base="xs:string">
                      <xs:length value="1"/>
                    </xs:restriction>
                  </xs:simpleType>
                </xs:element>
                <xs:element name="CVVCheckResult" nillable="true">
                  <xs:annotation>
                    <xs:documentation>Indicates whether the security code check (CVV2 etc) was successful or not.</xs:documentation>
                  </xs:annotation>
                  <xs:simpleType>
                    <xs:restriction base="xs:string">
                      <xs:length value="1"/>
                    </xs:restriction>
                  </xs:simpleType>
                </xs:element>
                <xs:element name="ProductCode" nillable="true">
                  <xs:annotation>
                    <xs:documentation>Used for Mastercard only, this provides detailed identification of the type of card (e.g. if the card is prepaid)</xs:documentation>
                  </xs:annotation>
                  <xs:simpleType>
                    <xs:restriction base="xs:string">
                      <xs:minLength value="1"/>
                      <xs:maxLength value="3"/>
                    </xs:restriction>
                  </xs:simpleType>
                </xs:element>
                <xs:element name="TraceId" nillable="true">
                  <xs:annotation>
                    <xs:documentation>For Mastercard or Visa this will contain a scheme-generated unique ID for the authorisation.  All subsequent settlement requests that are associated with this authorisation must include the TraceId.</xs:documentation>
                  </xs:annotation>
                  <xs:simpleType>
                    <xs:restriction base="xs:string">
                      <xs:maxLength value="19"/>
                      <xs:minLength value="1"/>
                    </xs:restriction>
                  </xs:simpleType>
                </xs:element>
              </xs:sequence>
            </xs:complexType>
          </xs:element>
          <xs:element name="Error">
            <xs:annotation>
              <xs:documentation>If it was not possible to communicate with the acquirer then this element will contain the error details.</xs:documentation>
            </xs:annotation>
            <xs:complexType>
              <xs:sequence>
                <xs:element name="ErrorCode" type="xs:short">
                  <xs:annotation>
                    <xs:documentation>Code which maps to a defined list of errors provided by the payment system (e.g. tokenisation error, communications error etc)</xs:documentation>
                  </xs:annotation>
                </xs:element>
                <xs:element name="ErrorDescription">
                  <xs:annotation>
                    <xs:documentation>Dynamic error description providing more detail than the static description associated with the ErrorCode.  May include part of error message thrown within the payment system.</xs:documentation>
                  </xs:annotation>
                  <xs:simpleType>
                    <xs:restriction base="xs:string">
                      <xs:maxLength value="100"/>
                    </xs:restriction>
                  </xs:simpleType>
                </xs:element>
              </xs:sequence>
            </xs:complexType>
          </xs:element>
        </xs:choice>
        <xs:element name="CardDetail" minOccurs="0">
          <xs:annotation>
            <xs:documentation>Contains details of the card used for the payment. Must be present if the message contains an AcquirerResponse.  May or may not be present if the message contains an Error (e.g. if CACC passed card details into the Secure Portal then it should be able to return them even if a processing error occurred). </xs:documentation>
          </xs:annotation>
          <xs:complexType>
            <xs:sequence>
              <xs:element name="PaymentCardType">
                <xs:simpleType>
                  <xs:restriction base="xs:string">
                    <xs:enumeration value="Visa"/>
                    <xs:enumeration value="MasterCard"/>
                    <xs:enumeration value="Amex"/>
                    <xs:enumeration value="Maestro"/>
                  </xs:restriction>
                </xs:simpleType>
              </xs:element>
              <xs:element name="PanToken">
                <xs:simpleType>
                  <xs:restriction base="xs:string">
                    <xs:minLength value="1"/>
                    <xs:maxLength value="26"/>
                    <xs:pattern value="([0-9A-F])*"/>
                  </xs:restriction>
                </xs:simpleType>
              </xs:element>
              <xs:element name="ExpiryDate">
                <xs:simpleType>
                  <xs:restriction base="xs:string">
                    <xs:length value="4"/>
                    <xs:pattern value="([0-9])*"/>
                  </xs:restriction>
                </xs:simpleType>
              </xs:element>
              <xs:element name="LastFourDigits">
                <xs:simpleType>
                  <xs:restriction base="xs:string">
                    <xs:length value="4"/>
                    <xs:pattern value="([0-9])*"/>
                  </xs:restriction>
                </xs:simpleType>
              </xs:element>
              <xs:element name="BinNumber">
                <xs:simpleType>
                  <xs:restriction base="xs:string">
                    <xs:length value="6"/>
                    <xs:pattern value="([0-9])*"/>
                  </xs:restriction>
                </xs:simpleType>
              </xs:element>
              <xs:element name="CardState">
                <xs:annotation>
                  <xs:documentation>Indicates whether the card used for the payment is the card used for travel or a different (registered or new) card.  This is required to correctly process the payment in PARE (e.g. can only remove card from the deny list if debt payment was made with the travel card).</xs:documentation>
                </xs:annotation>
                <xs:simpleType>
                  <xs:restriction base="xs:string">
                    <xs:enumeration value="CardUsedForTravel"/>
                    <xs:enumeration value="OtherRegisteredCard"/>
                    <xs:enumeration value="NewCard"/>
                  </xs:restriction>
                </xs:simpleType>
              </xs:element>
            </xs:sequence>
          </xs:complexType>
        </xs:element>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>
'

ALTER MESSAGE TYPE [http://tfl.gov.uk/Ft/Pare/DirectPayment/Message/Confirmation/Request] 
VALIDATION = VALID_XML WITH SCHEMA COLLECTION 
[dbo].[http://tfl.gov.uk/Ft/Pare/DirectPayment/Schema/Confirmation/Request]
GO
