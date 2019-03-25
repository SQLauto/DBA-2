CREATE TABLE [SsbSessionConversations] (
	FromService SYSNAME NOT NULL,
	ToService SYSNAME NOT NULL,
	OnContract SYSNAME NOT NULL,
	Handle UNIQUEIDENTIFIER NOT NULL,
	Created DATETIMEOFFSET NOT NULL,
	PRIMARY KEY (FromService, ToService, OnContract),
	UNIQUE (Handle));
GO