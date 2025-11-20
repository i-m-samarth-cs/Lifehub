using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.Services.Services
{
    public class LocalCalendarService : ICalendarService
    {
        public Task<IList<CalendarEvent>> GetEventsAsync(DateTime from, DateTime to, CancellationToken ct = default)
        {
            // Return mocked events for demo/demo data.
            var list = new List<CalendarEvent>
            {
                new CalendarEvent { Id = "1", Title = "Morning Standup", Start = from.Date.AddHours(9), End = from.Date.AddHours(9).AddMinutes(30) },
                new CalendarEvent { Id = "2", Title = "Design Review", Start = from.Date.AddHours(11), End = from.Date.AddHours(12) }
            };
            return Task.FromResult((IList<CalendarEvent>)list);
        }
    }
}
