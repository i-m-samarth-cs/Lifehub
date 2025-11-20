using System;
using System.Collections.Generic;

namespace LifeHub.Core.Models;

public class TaskItem
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTime? DueDate { get; set; }
    public bool IsCompleted { get; set; }
    public TaskPriority Priority { get; set; } = TaskPriority.Medium;
    public List<string> Tags { get; set; } = new();
    public string Source { get; set; } = "Local";
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime? CompletedAt { get; set; }
}

public enum TaskPriority
{
    Low,
    Medium,
    High,
    Urgent
}
