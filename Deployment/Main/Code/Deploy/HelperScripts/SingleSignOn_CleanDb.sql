begin transaction

declare @userIds Table (Id int)
declare @adminUserCustomerId int = 0
insert into @userIds([Id]) Select [u].[Id] from [SingleSignOn].[dbo].[Users] as u where [u].[Username] != 'cascadmin@tfl.gov.uk'

select @adminUserCustomerId = [CustomerId] from [SingleSignOn].[dbo].[Users] where [Username] = 'cascadmin@tfl.gov.uk'

-- delete Event records for all users
delete from [SingleSignOn].[dbo].[Events] --where [UserId] IN (Select Id from @userIds) --do we want to remove all events (including cascadmin's)?

-- delete ProductUserRoles
declare @deletedPUIds Table (Id int)
delete [pu] output [deleted].[Id] into @deletedPUIds from [SingleSignOn].[dbo].[ProductUsers] pu where [pu].[UserId] IN (select [Id] from @userIds)

delete from [SingleSignOn].[dbo].[ProductUserRoles] where [ProductUserId] IN (select [Id] from @deletedPUIds)
delete from [SingleSignOn].[dbo].[SecurityTokens]

-- delete the actual users
delete from [SingleSignOn].[dbo].[Users] where [Id] in (select [Id] from @userIds)

-- reset the identities of the dbo (sso) schema tables
DBCC CHECKIDENT('SingleSignOn.dbo.Events', RESEED, 0)

declare @maxUserId int
select @maxUserId = MAX([Id]) from [SingleSignOn].[dbo].[Users]

IF @maxUserId is null
BEGIN
	DBCC CHECKIDENT('SingleSignOn.dbo.Users', RESEED, 0)
END
ELSE
BEGIN
	DBCC CHECKIDENT('SingleSignOn.dbo.Users', RESEED, @maxUserId)
END

declare @maxPUId int
select @maxPUId = MAX([Id]) from [SingleSignOn].[dbo].[ProductUsers]

IF @maxPUId is null
BEGIN
	DBCC CHECKIDENT('SingleSignOn.dbo.ProductUsers', RESEED, 0)
END
ELSE
BEGIN
	DBCC CHECKIDENT('SingleSignOn.dbo.ProductUsers', RESEED, @maxPUId)
END

-- remove customer-related items
declare @customerIds Table (Id int)
declare @deletedCCTs Table (Id int)

insert into @customerIds select [c].[Id] from [SingleSignOn].[customer].[Customer] as c where [c].[Id] <> @adminUserCustomerId

delete from [SingleSignOn].[customer].[CustomerChangeTransaction]
delete from [SingleSignOn].[customer].[CustomerChangeQueue]
delete from [SingleSignOn].[customer].[NotificationQueue]
delete from [SingleSignOn].[customer].[SecurityAnswer] where [CustomerId] in (select [Id] from @customerIds)
delete from [SingleSignOn].[customer].[AssociatedSystemReference] where [RefSysCustomerId] in (select [Id] from @customerIds)

-- reset the identities of the customer schema tables
DBCC CHECKIDENT('SingleSignOn.customer.CustomerChangeQueue', RESEED, 0)
DBCC CHECKIDENT('SingleSignOn.customer.NotificationQueue', RESEED, 0)

declare @maxSecAnsId int
select @maxSecAnsId = MAX([Id]) from [SingleSignOn].[customer].[SecurityAnswer]

IF @maxSecAnsId is null
BEGIN
    DBCC CHECKIDENT('SingleSignOn.customer.SecurityAnswer', RESEED, 0)
END
ELSE
BEGIN
	DBCC CHECKIDENT('SingleSignOn.customer.SecurityAnswer', RESEED, @maxSecAnsId)
END 

declare @maxSysRefId int
select @maxSysRefId = MAX([Id]) from [SingleSignOn].[customer].[AssociatedSystemReference]

IF @maxSysRefId is null
BEGIN
	DBCC CHECKIDENT('SingleSignOn.customer.AssociatedSystemReference', RESEED, 0)
END
ELSE
BEGIN
	DBCC CHECKIDENT('SingleSignOn.customer.AssociatedSystemReference', RESEED, @maxSysRefId)
END

declare @addressIdsToDelete as Table (Id int)
insert into @addressIdsToDelete select [PrimaryAddressId] from [SingleSignOn].[customer].[Customer] where Id in (select Id from @customerIds)

delete from [SingleSignOn].[customer].[Customer] where Id in (select Id from @customerIds)
delete from [SingleSignOn].[customer].[Address] where Id in (select Id from @addressIdsToDelete)

declare @maxCustId int
select @maxCustId = MAX([Id]) from [SingleSignOn].[customer].[Customer]

IF @maxCustId IS NULL
BEGIN
	DBCC CHECKIDENT('SingleSignOn.customer.Customer', RESEED, 0)
END
ELSE
BEGIN
	DBCC CHECKIDENT('SingleSignOn.customer.Customer', RESEED, @maxCustId)
END

--todo make sure the Address is reseeded correctly based on whether or not there are other records remaining
DBCC CHECKIDENT('SingleSignOn.customer.Address', RESEED, 0)

commit transaction

print 'SSO database cleaned'