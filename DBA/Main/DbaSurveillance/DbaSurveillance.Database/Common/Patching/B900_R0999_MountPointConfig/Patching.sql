GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO
SET NOCOUNT ON 
DECLARE  @MountPointConfig TABLE
		(
			id int NOT NULL,
			[Path] [nvarchar](100) NOT NULL,
			[Category] [nvarchar](10) NOT NULL
		)


INSERT @MountPointConfig ([id],[Path],[Category])
VALUES(1,'I:\FAE_DG01','Data'),(2,'I:\FAE_DG02','Data'),(3,'I:\FAE_DG03','Data'),(4,'I:\FAE_DG04','Data')


DELETE FROM C
from internal.MountPointConfig C
LEFT JOIN @MountPointConfig M ON  M.id=C.id AND M.[Path]=C.[Path] and M.category=C.category
WHERE M.[Path] is null

SET IDENTITY_INSERT internal.MountPointConfig ON

MERGE internal.MountPointConfig AS target
USING
(
	select id,[Path],[Category]
	FROM @MountPointConfig
) as SOURCE
ON( target.id=source.id )
WHEN NOT MATCHED
THEN INSERT([Id],[Path],[Category])
VALUES(		source.Id,	
			source.Path, 
			source.Category
			)
			WHEN MATCHED
			 THEN UPDATE SET 
			Path=source.Path, 
			Category=source.Category;
			
SET IDENTITY_INSERT internal.MountPointConfig OFF