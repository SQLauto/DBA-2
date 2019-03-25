d:

REM Make SSO Mock Response files writeable
attrib -r -s "..\..\..\CACC\Main\CSC MockServices\MockResponses\*.*" /D /L /S

REM Make autogration config writeable
attrib -r -s "..\..\..\integration\main\Code\Autogration.AcceptanceTests\app.config" 

REM Make connection strings writeable
attrib -r -s "..\..\..\PARE\main\Code\Pare.TravelTokenInfoService\connectionstrings.config"

attrib -r -s "..\..\..\PARE\main\Code\Pare.TravelTokenService\connectionstrings.config"

attrib -r -s "..\..\..\PARE\main\Code\MasterDataMockWebApi\localMasterData.config"

attrib -r -s "..\..\..\PARE\main\Code\CSCSupportService\connectionstrings.config"

attrib -r -s "..\..\..\FAE\Main\Code\JourneyUsageService\connectionstrings.config"

attrib -r -s "..\..\..\FAE\Main\Code\Tfl.Ft.Fae.JourneyUsage.ApiService\web.config" 

REM MasterData - copying master data files into D:\FMJTAssets\ drive
Powershell.exe -executionpolicy Unrestricted -File CopyMasterDataAssets.ps1


REM Make web.configs writeable
cd "..\..\..\CACC\Main"
attrib -r -s "web.config" /D /L /S

REM Make applicationhost.config writeable
attrib -r -s "%userprofile%\Documents\IISExpress\config\applicationhost.config"

cd\
mkdir TapResultFile\Unprocessed
mkdir TapResultFile\Processed
mkdir TapResultFile\Loading
mkdir TapResultFile\Invalid
mkdir TapResultFile\Failed
mkdir TapFileProcessor\Unprocessed
mkdir TapFileProcessor\Processed
mkdir TapFileProcessor\Loading
mkdir TapFileProcessor\Invalid
mkdir TapFileProcessor\Failed
mkdir TFL\CACC\MockServices\MockResponses\Sso\Webservices
mkdir TFL\CACC\MockServices\MockResponses\Sso\Webservices\Validation
mkdir TFL\CACC\MockServices\MockResponses\Sso\Webservices\CustomerService\GetById
mkdir TFL\CACC\EmailQueue
mkdir RequestCardPayment
mkdir tfl\Notifications\EmailNotification\NotificationFileProcessor\Unprocessed
mkdir tfl\Notifications\EmailNotification\NotificationFileProcessor\Processed
mkdir tfl\Notifications\EmailNotification\NotificationFileProcessor\Loading
mkdir tfl\Notifications\EmailNotification\NotificationFileProcessor\Invalid
mkdir tfl\Notifications\EmailNotification\NotificationFileProcessor\Failed
mkdir TFL\Notifications\EmailDrop
mkdir AFConfigSettingsDoNotDelete
mkdir OTFPFileStore\Unprocessed
mkdir OTFPFileStore\Processed
mkdir OTFPFileStore\Loading
mkdir OTFPFileStore\Invalid
mkdir OTFPFileStore\Failed
mkdir OTFPFileStore\CubicAcknowledgements
mkdir OTFPFileStore\FAE
mkdir OTFPFileStore\OysterOnline
mkdir OTFPFileStore\OysterOnline\Sales
mkdir OTFPFileStore\OysterOnline\Autoloads
mkdir OTFPFileStore\OysterOnline\Refunds
mkdir OTFPFileStore\OysterOnline\Replacements
mkdir OTFPFileStore\Analytics
mkdir OTFPFileStore\Photocard
