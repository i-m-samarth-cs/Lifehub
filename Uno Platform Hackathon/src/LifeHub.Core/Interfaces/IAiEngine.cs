using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces
{
    /// <summary>
    /// AI engine abstraction for summarization and insights.
    /// </summary>
    public interface IAiEngine
    {
        Task<string> SummarizeEmailsAsync(IEnumerable<string> snippets, CancellationToken ct = default);
        Task<IList<TaskItem>> ExtractTasksFromTextAsync(string text, CancellationToken ct = default);
        Task<string> GenerateDailySummaryAsync(DashboardUsageProfile profile, CancellationToken ct = default);
        Task<LayoutSuggestion> GetLayoutSuggestionsAsync(DashboardUsageProfile profile, CancellationToken ct = default);
    }

    public sealed class DashboardUsageProfile
    {
        public int WidgetOpenFrequency { get; set; }
        public int FocusSessionsToday { get; set; }
        public int TasksCompletedToday { get; set; }
    }

    public sealed class LayoutSuggestion
    {
        public string SuggestedTheme { get; set; } = string.Empty;
        public IList<string> WidgetsToPromote { get; set; } = new List<string>();
        public IList<string> WidgetsToHide { get; set; } = new List<string>();
    }
}
