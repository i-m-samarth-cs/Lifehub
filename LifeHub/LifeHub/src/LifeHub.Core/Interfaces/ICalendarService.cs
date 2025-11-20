using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces;

public interface ICalendarService
{
    Task<IList<CalendarEvent>> GetEventsAsync(DateTime from, DateTime to, CancellationToken ct = default);
    Task<CalendarEvent> CreateEventAsync(CalendarEvent calendarEvent, CancellationToken ct = default);
    Task<CalendarEvent> UpdateEventAsync(CalendarEvent calendarEvent, CancellationToken ct = default);
    Task DeleteEventAsync(string eventId, CancellationToken ct = default);
}
