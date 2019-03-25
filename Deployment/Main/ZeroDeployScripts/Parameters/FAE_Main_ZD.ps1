#
#Workspace Mappings
#

$workspaceMappings = @'
$/CACC/Stabilisation: \cacc\Main
$/Common/Stabilisation: \common\Main
$/CommonServices/Messaging/Core: \CommonServices\Messaging\Core
$/CommonServices/Messaging/MessageBusTracking: \CommonServices\Messaging\MessageBusTracking
$/CommonServices/Messaging/MessageCountMonitor: \CommonServices\Messaging\MessageCountMonitor
$/CommonServices/Messaging/Tests: \CommonServices\Messaging\Tests
$/DBA/Stabilisation: \DBA\Main
$/Deployment/Stabilisation: \Deployment\Main
$/FAE/Main: \fae\Main
$/Integration/Stabilisation: \integration\Main
$/Notifications/Stabilisation: \Notifications\Main
$/PaRE/Stabilisation: \PARE\Main
$/SDM/Stabilisation: \sdm\Main
$/MasterData/Stabilisation: \MasterData\Main
$/OyBo/Stabilisation: \OyBo\Main
'@


#
#CI Builds
#

$componentCiBuilds = @{
	'FAE' 			= 'FAE.Main.CI';
	'PARE' 			= 'Pare.Stabilisation.CI';
	'CACC' 			= 'CACC.Stabilisation.CI';
	'Notifications'	= 'Notifications.Stabilisation.CI' ;
	'SDM'			= 'SDM.Stabilisation.CI' ;
	'MasterData' 	= 'MasterData.Stabilisation.CI';
	'OyBo' 			= 'OyBo.Stabilisation.CI';
}


	
	
	
	
	
	
	
	
	