using System;

namespace LifeHub.Core.Models;

public class FocusSession
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public DateTime StartTime { get; set; }
    public DateTime? EndTime { get; set; }
    public int DurationMinutes { get; set; }
    public FocusSessionType Type { get; set; }
    public bool WasCompleted { get; set; }
    public string? Note { get; set; }
}

public enum FocusSessionType
{
    Focus,
    ShortBreak,
    LongBreak
}
