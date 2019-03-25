-- AuthorisationErrorCode values
DECLARE @SourceAuthorisationErrorCode AS TABLE( 
	Id smallint NOT NULL,
	ErrorCode smallint NOT NULL,
	ErrorDescription varchar(100) NOT NULL,
	Retry bit NOT NULL
)

insert into @SourceAuthorisationErrorCode (Id, ErrorCode, ErrorDescription, Retry) values (1, 1000, 'Invalid Request', 0);
insert into @SourceAuthorisationErrorCode (Id, ErrorCode, ErrorDescription, Retry) values (2, 1001, 'Duplicate Request', 0);
insert into @SourceAuthorisationErrorCode (Id, ErrorCode, ErrorDescription, Retry) values (3, 1002, 'CPA Exception (Unrecoverable)', 0);
insert into @SourceAuthorisationErrorCode (Id, ErrorCode, ErrorDescription, Retry) values (4, 2000, 'Invalid Request (CPA)', 0);
insert into @SourceAuthorisationErrorCode (Id, ErrorCode, ErrorDescription, Retry) values (5, 3000, 'Invalid Request (Acquirer)', 0);
insert into @SourceAuthorisationErrorCode (Id, ErrorCode, ErrorDescription, Retry) values (6, 1100, 'CPA Exception (Recoverable)', 1);
insert into @SourceAuthorisationErrorCode (Id, ErrorCode, ErrorDescription, Retry) values (7, 1101, 'CPA Unavailable', 1);
insert into @SourceAuthorisationErrorCode (Id, ErrorCode, ErrorDescription, Retry) values (8, 1199, 'Unexpected Error', 1);
insert into @SourceAuthorisationErrorCode (Id, ErrorCode, ErrorDescription, Retry) values (9, 2100, 'Acquirer Exception', 1);
insert into @SourceAuthorisationErrorCode (Id, ErrorCode, ErrorDescription, Retry) values (10, 2101, 'Acquirer Unavailable', 1);
insert into @SourceAuthorisationErrorCode (Id, ErrorCode, ErrorDescription, Retry) values (11, 2102, 'Acquirer Timeout', 1);
insert into @SourceAuthorisationErrorCode (Id, ErrorCode, ErrorDescription, Retry) values (12, 2103, 'CPA Do-Not-Process Flag Set', 1);

MERGE INTO [dbo].[AuthorisationErrorCode] as Target
USING @SourceAuthorisationErrorCode as Source
ON Target.Id = Source.Id
WHEN MATCHED THEN 
UPDATE SET Target.ErrorCode = Source.ErrorCode,Target.ErrorDescription = Source.ErrorDescription,Target.Retry = Source.Retry
WHEN NOT MATCHED THEN 
INSERT (Id, ErrorCode, ErrorDescription, Retry) VALUES (Source.Id, Source.ErrorCode, Source.ErrorDescription,	Source.Retry)
WHEN NOT MATCHED BY SOURCE THEN
DELETE;


-- LogController values
If Not Exists(select LogEnabled from LogController)
INSERT INTO LogController(LogEnabled,SsbDequeueMonEnabled) VALUES (0,0)



