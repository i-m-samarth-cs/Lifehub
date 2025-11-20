using System;
using System.Collections.Generic;

namespace LifeHub.Core.Models
{
    /// <summary>
    /// Represents a task or todo item.
    /// </summary>
    public sealed class TaskItem
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime? DueDate { get; set; }
        public bool IsCompleted { get; set; }
        public List<string> Tags { get; set; } = new();
        public string? Source { get; set; }
    }
}
