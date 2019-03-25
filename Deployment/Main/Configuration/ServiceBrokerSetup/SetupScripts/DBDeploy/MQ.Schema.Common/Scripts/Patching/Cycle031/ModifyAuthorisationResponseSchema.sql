If EXISTS(SELECT 1 FROM sys.xml_schema_collections where name = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Schema/Authorisation/Response/v1')
BEGIN
	DROP  XML SCHEMA COLLECTION [http://tfl.gov.uk/Ft/Pare/Authorisation/Schema/Authorisation/Response/v1]
END

CREATE XML SCHEMA COLLECTION [http://tfl.gov.uk/Ft/Pare/Authorisation/Schema/Authorisation/Response/v1]
AS
N'<?xml version="1.0" encoding="utf-16"?>
<!-- edited with XMLSpy v2012 rel. 2 (http://www.altova.com) by Richard North (Transport For London) -->
<!--
 TfL Future Ticketing Platform XML Schema
 
 Name:			AuthorisationResponseV0.10.xsd
 Date:			05/01/2012
 Author:		Sam Pratt
 Description:	Defines the structure of messages sent from 
				PCS to PARE to to advise of the result of an
				authorisation.
			
 Change History
 ==============
 Version	Date		Changed By		Comments
 0.1		05/01/12	S. Pratt		First version
 0.2		26/01/12	R.North			Updated datatype for ProductCode
 0.3		26/01/12	R.North			Added new element "Token".  This is a pass-through of the Token provided in the 
										request message. It is to avoid PARE having to perform a lookup to create the 
										PaymentCardLink record when processing the response.
 0.4		11/05/12	R.North			Added ErrorDescription and made ResponseCode nillable as it will not be present if
										a response was not received from the acquirer.
 0.5		18/05/12	R.North			Result is now two state and acquirer response details are nested. Also removed "Token"
										as it is no longer required for link creation in PARE.
 0.6		23/05/12	R North			Added TransmissionCount and ErrorCode. Reduced Token max length to 26. Added regex 
										restriction on AuthorisationCode. Removed AuthorisationOriginId.  Restricted PanToken to only allow 0-9 and A-F.
 0.7		26/05/12	R North			Removed Result element.  Created a choice element containing either the AcquirerResponse 
										or a new Error element containing the ErrorCode and ErrorDescription.
 0.8		29/05/12	R North			Added TraceId (for Mastercard and Visa). 
 0.9		02/10/13	R.North			Modified TraceId to accept a max length of 19 characters (on request by Cubic).
 0.10		27/11/13	R.North			Removed restriction on AuthorisationCode as alpha-numeric codes are possible.
-->
<xs:schema xmlns="http://tfl.gov.uk/Ft/Pare/Authorisation/Message/Authorisation/Response/v0.10" xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="unqualified">
	<xs:element name="AuthorisationResponse">
		<xs:complexType>
			<xs:sequence>
				<xs:element name="AuthorisationTrackingId" type="xs:long">
					<xs:annotation>
						<xs:documentation>A unique reference provided by the consumer in the request which will be passed back in the response to allow the messages to be correlated and the authorisation result recorded.</xs:documentation>
					</xs:annotation>
				</xs:element>
				<xs:element name="TransmissionCount" type="xs:short">
					<xs:annotation>
						<xs:documentation>The number of times the same message (identified by having the same AuthorisationTrackingId) has been transmitted.  In normal operation this will be set to 1 but could increase if timeouts cause resends to occur.</xs:documentation>
					</xs:annotation>
				</xs:element>
				<xs:choice>
					<xs:annotation>
						<xs:documentation>Mutually exclusive "choice" of either an AcquirerResponse or an Error</xs:documentation>
					</xs:annotation>
					<xs:element name="AcquirerResponse">
						<xs:complexType>
							<xs:sequence>
								<xs:element name="ResponseCode">
									<xs:annotation>
										<xs:documentation>Response code from the acquirer.  Could be either a Barclays response code or an Amex response code.  Must not be padded as the exact value from the acquirer must be preserved.</xs:documentation>
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
								<xs:element name="PanToken" nillable="true">
									<xs:annotation>
										<xs:documentation>For Mastercard or Amex, this will contain a token which represents the card''s embossed PAN when it differs to the ePAN.</xs:documentation>
									</xs:annotation>
									<xs:simpleType>
										<xs:restriction base="xs:string">
											<xs:minLength value="1"/>
											<xs:maxLength value="26"/>
											<xs:pattern value="([0-9A-F])*"/>
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
			</xs:sequence>
		</xs:complexType>
	</xs:element>
</xs:schema>
'

