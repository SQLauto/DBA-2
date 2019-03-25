import-module DistributedCacheAdministration
$computer = gc env:computername
use-cachecluster
stop-cachecluster
start-cachecluster