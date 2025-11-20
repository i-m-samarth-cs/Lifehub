using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.Services.Calendar;

public class CalendarService : ICalendarService
{
    private readonly List<CalendarEvent> _events = new();

    public CalendarService()
    {
        SeedMockData();
    }

    public Task<IList<CalendarEvent>> GetEventsAsync(DateTime from, DateTime to, CancellationToken ct = default)
    {
        var events = _events
            .Where(e => e.StartTime >= from && e.StartTime <= to)
            .OrderBy(e => e.StartTime)
            .ToList();
        return Task.FromResult<IList<CalendarEvent>>(events);
    }

    public Task<CalendarEvent> CreateEventAsync(CalendarEvent calendarEvent, CancellationToken ct = default)
    {
        _events.Add(calendarEvent);
        return Task.FromResult(calendarEvent);
    }

    public Task<CalendarEvent> UpdateEventAsync(CalendarEvent calendarEvent, CancellationToken ct = default)
    {
        var existing = _events.FirstOrDefault(e => e.Id == calendarEvent.Id);
        if (existing != null)
        {
            _events.Remove(existing);
            _events.Add(calendarEvent);
        }
        return Task.FromResult(calendarEvent);
    }

    public Task DeleteEventAsync(string eventId, CancellationToken ct = default)
    {
        var existing = _events.FirstOrDefault(e => e.Id == eventId);
        if (existing != null)
        {
            _events.Remove(existing);
        }
        return Task.CompletedTask;
    }

    private void SeedMockData()
    {
        var today = DateTime.Today;
        _events.AddRange(new[]
        {
            new CalendarEvent
            {
                Title = "Team Standup",
                Description = "Daily sync with the team",
                StartTime = today.AddHours(9),
                EndTime = today.AddHours(9.5),
                Color = "#4A90E2",
                MeetingUrl = "https://meet.example.com/standup"
            },
            new CalendarEvent
            {
                Title = "Client Presentation",
                Description = "Q4 results presentation",
                StartTime = today.AddHours(14),
                EndTime = today.AddHours(15),
                Color = "#E94B3C",
                Location = "Conference Room A"
            },
            new CalendarEvent
            {
                Title = "Lunch with Sarah",
                StartTime = today.AddHours(12),
                EndTime = today.AddHours(13),
                Color = "#50C878",
                Location = "Café Downtown"
            }
        });
    }
}
