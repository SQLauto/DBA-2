USE [Autogration_FAE]
GO
execute [internal].[EmptyDB]
GO
USE [Autogration_PARE]
GO
execute EmptyDB
execute PcsMockResetMockPare
GO
USE [Autogration_CSCWebSSO]
GO
delete from PaymentCard; delete from Customer
GO
USE [Autogration_NotificationProcessorDb]
GO
delete from MasterCustomerCopy
