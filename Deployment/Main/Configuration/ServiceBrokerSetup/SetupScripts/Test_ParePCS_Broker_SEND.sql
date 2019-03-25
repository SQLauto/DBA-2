DECLARE @ConversationHandle uniqueidentifier;
          DECLARE @StatusTime datetime = GETDATE();
          DECLARE @Token nvarchar(26) = '0123456789ABCDEF';
          --Send the message
          Exec [PARE].[dbo].[SendStatusListUpdateRequest]
          1,
          'Correction',
          @Token,
          '0113',
          '001',
          1,
          @StatusTime,
          2,
          @StatusTime,
          @ConversationHandle = @ConversationHandle output;