WAITFOR DELAY '00:00:15';

          IF (select count(*) from PCS.DBO.PCSMockLog WHERE Message like '%0123456789ABCDEF%') = 0
          THROW 51000, 'Message not found in PCSMockLog', 1;
          --clear down ready for next test
          delete from PCS.DBO.PCSMockLog WHERE Message like '%0123456789ABCDEF%'