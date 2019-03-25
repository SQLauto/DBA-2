CREATE SERVICE [http://tfl.gov.uk/Ft/Pare/Service/Pare_Notification]
      ON QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/Queue/Pare_Notification]
      (
            [http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]
      )