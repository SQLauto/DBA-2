$computers = @("TS-CAS1", "TS-CIS1", "TS-DB1", "TS-DB2", "TS-FAE1", "TS-FAE2", "TS-FAE3", "TS-FAE4", "TS-FTM1", "TS-PARE1", "TS-SAS1", "TS-OYBO1")

foreach ($computer in computers)
{
		&cmd gpupdate /target:$computer /force
}
