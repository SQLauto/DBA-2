C:
cd %ProgramFiles(x86)%\IIS Express
start /b IISExpress.exe /site:"CSC.Webservice.Customer"
start /b IISExpress.exe /site:"CSC.Webservice.External.Authorisation"
start /b IISExpress.exe /site:"CSC.WebService.External.Customer"
start /b IISExpress.exe /site:"CSC.Webservice.External.TokenStatus"
start /b IISExpress.exe /site:"CSC.Webservice.Lookup"
start /b IISExpress.exe /site:"CSC Web"
start /b IISExpress.exe /site:"CSC.MockServices"
