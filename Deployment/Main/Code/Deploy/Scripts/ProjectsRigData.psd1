@{
	Projects = @(
		@{
			Name = "SSO"
			Servers = @(
				@{
					Name = 'TS-CAS1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-CIS1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-DB1'
					Size = "Standard_DS2_v2"
				},
				@{
					Name = 'TS-AF1'
					Size = "Standard_DS1_v2"
				}
			)
		},
		@{
			Name = "Baseline"
			Servers = @(
				@{
					Name = 'TS-CAS1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-CIS1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-DB1'
					Size = "Standard_DS2_v2"
				}
			)
		},
		@{
			Name = "MasterData"
			Servers = @(
				@{
					Name = 'TS-CAS1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-CIS1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-DB1'
					Size = "Standard_DS2_v2"
				},
				@{
					Name = 'TS-SAS1'
					Size = "Standard_DS1_v2"
				}
			)
		},
		@{
			Name = "Pare"
			Servers = @(
				@{
					Name = 'TS-CAS1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-CIS1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-DB1'
					Size = "Standard_DS2_v2"
				},
				@{
					Name = 'TS-DB2'
					Size = "Standard_DS2_v2"
				},
				@{
					Name = 'TS-PARE1'
					Size = "Standard_DS1_v2"
				}
			)
		},
		@{
			Name = "Integration"
			Servers = @(
				@{
					Name = 'TS-CAS1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-CIS1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-DB1'
					Size = "Standard_DS2_v2"
				},
				@{
					Name = 'TS-DB2'
					Size = "Standard_DS2_v2"
				},
				@{
					Name = 'TS-PARE1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-FAE1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-FAE2'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-FAE3'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-FAE4'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-FTM1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-OYBO1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-SAS1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-SFTP1'
					Size = "Standard_DS1_v2"
				}
			)
		},
		@{
			Name = "CASC"
			Servers = @(
				@{
					Name = 'TS-CAS1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-CIS1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-DB1'
					Size = "Standard_DS2_v2"
				}
			)
		},
		@{
			Name = "OYBO"
			Servers = @(				
				@{
					Name = 'TS-CIS1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-DB1'
					Size = "Standard_DS2_v2"
				},				
				@{
					Name = 'TS-FTM1'
					Size = "Standard_DS1_v2"
				}
			)
		},
		@{
			Name = "FAE"
			Servers = @(				
				@{
					Name = 'TS-CIS1'
					Size = "Standard_DS1_v2"
				},
				@{
					Name = 'TS-DB1'
					Size = "Standard_DS2_v2"
				},				
				@{
					Name = 'TS-FAE1'
					Size = "Standard_DS1_v2"
				},				
				@{
					Name = 'TS-FAE2'
					Size = "Standard_DS1_v2"
				},				
				@{
					Name = 'TS-FAE3'
					Size = "Standard_DS1_v2"
				},				
				@{
					Name = 'TS-FAE4'
					Size = "Standard_DS1_v2"
				},				
				@{
					Name = 'TS-OYBO1'
					Size = "Standard_DS1_v2"
				}
			)
		}
	);
}