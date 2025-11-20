using System;

namespace LifeHub.Core.Models;

public class AiInsight
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public InsightType Type { get; set; }
    public DateTime GeneratedAt { get; set; } = DateTime.Now;
    public string? ActionUrl { get; set; }
}

public enum InsightType
{
    DailySummary,
    ProductivityTip,
    FocusPattern,
    LayoutSuggestion,
    TaskSuggestion
}
