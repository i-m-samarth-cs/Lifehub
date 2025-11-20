using System;
using System.Collections.Generic;

namespace LifeHub.Core.Models;

public class EmailSummary
{
    public int UnreadCount { get; set; }
    public string Summary { get; set; } = string.Empty;
    public List<EmailItem> KeyEmails { get; set; } = new();
    public DateTime GeneratedAt { get; set; } = DateTime.Now;
}

public class EmailItem
{
    public string From { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string Snippet { get; set; } = string.Empty;
    public DateTime ReceivedAt { get; set; }
    public bool IsImportant { get; set; }
}
