// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

using System;
using System.Collections.Generic;

namespace Deployment.Domain.TaskScheduler
{
    [Serializable]
    public sealed class ScheduleInfo
	{
	    public ScheduleInfo()
	    {
            ScheduleType = ScheduleType.Daily;
	        Interval = 1;
            Days = new List<int>();
            Months = new List<Month>();
            DaysOfWeek = new List<DayOfWeek>();
	        StartDate = DateTime.UtcNow.Date;
            StartTime = DateTime.UtcNow.TimeOfDay;
            EndDate = DateTime.MaxValue;
	    }

        public ScheduleInfo(int lastResult, TimeSpan stopTaskIfRunsXHoursAndXMinutes, ScheduleType scheduleType, string modifier, int interval,
			TimeSpan startTime, DateTime startDate, TimeSpan endTime, DateTime endDate, DayOfWeek[] daysOfWeek, int[] days, Month[] months, TimeSpan repeatEvery,
			string repeatUntilTime, TimeSpan repeatDuration, TimeSpan repeatStopIfStillRunning, bool stopAtEnd, TimeSpan delay, int idleTime, string eventChannelName)
        {
            Days = days != null ? new List<int>(days) : new List<int>();
            Months = months != null ? new List<Month>(months) : new List<Month>();
            DaysOfWeek = daysOfWeek != null ? new List<DayOfWeek>(daysOfWeek) : new List<DayOfWeek>();
            LastResult = lastResult;
			StopTaskIfRunsXHoursandXMins = stopTaskIfRunsXHoursAndXMinutes;
			ScheduleType = scheduleType;
			Modifier = modifier;
			Interval = interval;
			StartTime = startTime;
			StartDate = startDate;
			EndTime = endTime;
			EndDate = endDate;
			RepeatEvery = repeatEvery;
			RepeatUntilTime = repeatUntilTime;
			RepeatDuration = repeatDuration;
			RepeatStopIfStillRunning = repeatStopIfStillRunning;
			StopAtEnd = stopAtEnd;
			Delay = delay;
			IdleTime = idleTime;
			EventChannelName = eventChannelName;
		}

		public IList<int> Days { get; }
		public IList<DayOfWeek> DaysOfWeek { get; set; }
		public TimeSpan Delay { get; }
		public DateTime EndDate { get; set; }
		public TimeSpan EndTime { get; set; }
		public string EventChannelName { get; }
		public int IdleTime { get; }
		public int Interval { get; set; }
		public int LastResult { get; }
		public string Modifier { get; }
		public IList<Month> Months { get; }
		public TimeSpan RepeatEvery { get; set;  }
        public TimeSpan RepeatDuration { get; set; }
        public TimeSpan RepeatStopIfStillRunning { get; }
		public string RepeatUntilTime { get; }
		public bool StopAtEnd { get; }
		public TimeSpan StopTaskIfRunsXHoursandXMins { get; }
		public ScheduleType ScheduleType { get; set; }
		public DateTime StartDate { get; set; }
		public TimeSpan StartTime { get; set; }
        public bool Disabled { get; set; }
        public DateTime StartAt => StartDate.Date.Add(StartTime);
	}
}

