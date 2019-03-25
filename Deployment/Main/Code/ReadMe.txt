The responsibility of this Solution is to:
1) Import the deployment tool and its dependancies from the referenced projects (referencing Deployment.sln).
2) Create installers for all the scripts/code required to generate the CatalogTemplate setup.
3) Contain the documentation for set-up.

There are the following installers and their responsibilities:

To do a deployment:
1) Create the VAPP.
2) Copy the MSIs this project generates to the AD box.
3) Install CatalogTemplate.msi to location D:\CatalogTemplate.
4) Install powershell 5 on the AD controller using Win7AndW2K8R2-KB3134760-x64.msu which is within the CatalogTempate.msi
5) Reboot the AD controller.
6) Follow the numbered powershell scripts to build the VAPP

a) CatalogTemplate.msi
	************************************************************************************
	This MSI is responsible for deploying the scripts which will be manually run to the
	AD box which will be used to make the RIG changes
	************************************************************************************

		-	Script AD changes/enable remoting, force GPO update
		-	Install Powershell 5
		-	Reboot all the machines
		-	Pending reboot validation
		-	IIS Setup
		-	SQL login TFSBuild setup as sysadmin on each instance.
		-	Deployment scripts so MSIs can be installed.
		-	Clean up script to remove various files/registry settinsg which were created as part of setup.
		-	Event Log clean up.
		-	Post Validate setup:
				-	AD changes
				-	Remoting
				-	Service Accounts
				-	Computers in correct OU
				-	GPO Exists
				-	SBus set up
				-	Machines exist
				-	DNS Records are correct
				-	No pending reboots
				-	SQL is running under correct accounts.
				-	Service accounts have local admin and run as batch and run as service permissions.
				-   .NET framework validation
b) ServiceBusServerCertificates.msi
c) ServiceBusServerAndClientCertificates.msi
d) ServiceBus.msi ****
e) WindowsSftp.msi