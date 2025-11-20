using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces
{
    /// <summary>
    /// Abstraction for calendar providers.
    /// </summary>
    public interface ICalendarService
    {
        Task<IList<CalendarEvent>> GetEventsAsync(DateTime from, DateTime to, CancellationToken ct = default);
    }
}
