using System;

namespace LifeHub.Core.Models;

/// <summary>
/// Represents a calendar event from any source
/// </summary>
public class CalendarEvent
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public string Location { get; set; } = string.Empty;
    public string Source { get; set; } = "Local";
    public string Color { get; set; } = "#4A90E2";
    public bool IsAllDay { get; set; }
    public string? MeetingUrl { get; set; }
}
