IF NOT EXISTS( SELECT * FROM dbo.sysuser WHERE login= 'FAELAB\TFSAdmin' )
  INSERT INTO [NPL].[dbo].[sysuser]([login],[forename],[surname],[role_id],[email],[telephone_no],[position],[location],[date_from],[date_until],[disabled],[deleted])
  VALUES('FAELAB\TFSAdmin','TFS','Admin',5,'tfs@tfl.gov.uk',NULL,NULL,NULL,'2016-10-01',NULL,0,0)

IF NOT EXISTS( SELECT * FROM dbo.sysuser WHERE login= 'FAELAB\TFSBuild' )
   INSERT INTO [NPL].[dbo].[sysuser]([login],[forename],[surname],[role_id],[email],[telephone_no],[position],[location],[date_from],[date_until],[disabled],[deleted])
   VALUES('FAELAB\TFSBuild','TFS','Build',5,'tfs@tfl.gov.uk',NULL,NULL,NULL,'2016-10-01',NULL,0,0)
