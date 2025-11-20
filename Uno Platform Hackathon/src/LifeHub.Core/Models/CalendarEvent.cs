using System;

namespace LifeHub.Core.Models
{
    /// <summary>
    /// Simplified calendar event model.
    /// </summary>
    public sealed class CalendarEvent
    {
        public string Id { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string? Location { get; set; }
        public DateTime Start { get; set; }
        public DateTime End { get; set; }
        public string? Description { get; set; }
    }
}
