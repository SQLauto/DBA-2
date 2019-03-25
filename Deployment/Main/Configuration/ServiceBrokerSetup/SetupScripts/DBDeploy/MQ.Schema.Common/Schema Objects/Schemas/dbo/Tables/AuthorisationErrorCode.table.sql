CREATE TABLE AuthorisationErrorCode ( 
	Id smallint NOT NULL,
	ErrorCode smallint NOT NULL,
	ErrorDescription varchar(100) NOT NULL,
	Retry bit NOT NULL,
	CONSTRAINT PK_AuthorisationErrorCodeMapping PRIMARY KEY CLUSTERED (Id)
)