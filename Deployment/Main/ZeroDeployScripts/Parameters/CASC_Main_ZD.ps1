#
#Workspace Mappings
#

$workspaceMappings = @'
$/CACC/Main: \cacc\Main
$/Common/Main: \common\Main
$/CommonServices/Messaging/Core: \CommonServices\Messaging\Core
$/CommonServices/Messaging/MessageBusTracking: \CommonServices\Messaging\MessageBusTracking
$/CommonServices/Messaging/MessageCountMonitor: \CommonServices\Messaging\MessageCountMonitor
$/CommonServices/Messaging/Tests: \CommonServices\Messaging\Tests
$/Deployment/Main: \Deployment\Main
$/FAE/Stabilisation: \fae\Main
$/Integration/Stabilisation: \integration\Main
$/Notifications/Stabilisation: \Notifications\Main
$/PaRE/Stabilisation: \PARE\Main
$/SDM/Stabilisation: \sdm\Main
$/MasterData/Stabilisation: \MasterData\Main
$/OyBO/Stabilisation: \OyBO\Main
'@


#
#CI Builds
#

$componentCiBuilds = @{
	'FAE' 			= 'FAE.Stabilisation.CI';
	'PARE' 			= 'Pare.Stabilisation.CI';
	'CACC' 			= 'CACC.Main.CI';
	'Notifications'	= 'Notifications.Stabilisation.CI' ;
	'SDM'			= 'SDM.Stabilisation.CI' ;
	'MasterData' 	= 'MasterData.Stabilisation.CI';	
	'OyBO'		 	= 'OyBO.Stabilisation.CI';
}


	
	
	
	
	
	
	
	
	