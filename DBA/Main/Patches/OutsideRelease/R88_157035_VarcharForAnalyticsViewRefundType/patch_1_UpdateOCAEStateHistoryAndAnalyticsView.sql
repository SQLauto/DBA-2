/*
-- Runs for RefundManager Database.

-- Changes Refunds.Refund column "Source" datatype to varchar(10) instead of nvarchar(20)
-- Then it re-uses the alter script for View_OCAStateHistory_Analytics that will fix the datatype on the view.
*/

USE RefundManager;
GO

ALTER Table [refunds].[refund] alter column "Source" varchar(10) not null
GO

ALTER VIEW    [Refunds].[View_OCAStateHistory_Analytics] AS

SELECT osh.[RMViewID],
          osh.[PrestigeID],
          osh.[TravelDayVersion],
          osh.[RefundType],
          osh.[RefundComponentID],
          osh.[RefundTypeStatus],
          osh.[Amount],
          osh.[TravelDay],
          osh.[MediaPlatform],
          osh.[StatusTimestamp],
          osh.[RefundID]
FROM refunds.OcaStateHistory osh WITH (READUNCOMMITTED)
INNER JOIN refunds.RefundSource rs ON rs.Source = osh.RefundType AND rs.AnalyticsType IS NULL
UNION ALL
SELECT aosh.[RMViewID],
          aosh.[PrestigeID],
          aosh.[TravelDayVersion],
          aosh.[RefundType],
          aosh.[RefundComponentID],
          aosh.[RefundTypeStatus],
          aosh.[Amount],
          aosh.[TravelDay],
          aosh.[MediaPlatform],
          aosh.[StatusTimestamp],
          aosh.[RefundID]
FROM archive.OcaStateHistory aosh WITH (READUNCOMMITTED)
INNER JOIN refunds.RefundSource rs ON rs.Source = aosh.RefundType AND rs.AnalyticsType IS NULL
UNION ALL
SELECT  osh.RMViewId,
              r.[PrestigeId],
              NULL as TravelDayVersion, 
              r.[Source] as RefundType,
              r.[SourceReference] as RefundComponentId,
              osh.RefundTypeStatus,
              r.[Amount],
              ar.[TravelDay],
              'Oyster' as MediaPlatform,
              r.[Updated] as StatusTimestamp, --??
              r.[Id] as RefundId
FROM refunds.Refund r WITH (READUNCOMMITTED)
INNER JOIN refunds.OcaStateHistory osh WITH (READUNCOMMITTED) ON r.Id = osh.RefundId
INNER JOIN refunds.AnalyticsRefund ar WITH (READUNCOMMITTED) ON r.Id = ar.RefundId
INNER JOIN refunds.RefundSource rs ON rs.Source = r.Source AND rs.AnalyticsType IS NOT NULL
UNION ALL
SELECT  aosh.RMViewId,
              r.[PrestigeId],
              NULL as TravelDayVersion, 
              r.[Source] as RefundType,
              r.[SourceReference] as RefundComponentId,
              aosh.RefundTypeStatus,
              r.[Amount],
              ar.[TravelDay],
              'Oyster' as MediaPlatform,
              r.[Updated] as StatusTimestamp, --??
              r.[Id] as RefundId
FROM refunds.Refund r WITH (READUNCOMMITTED)
INNER JOIN archive.OcaStateHistory aosh WITH (READUNCOMMITTED) ON r.Id = aosh.RefundId
INNER JOIN refunds.AnalyticsRefund ar WITH (READUNCOMMITTED) ON r.Id = ar.RefundId
INNER JOIN refunds.RefundSource rs ON rs.Source = r.Source AND rs.AnalyticsType IS NOT NULL
GO