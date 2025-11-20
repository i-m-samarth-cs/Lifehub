using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;
using Models = LifeHub.Core.Models;

namespace LifeHub.Services.Services
{
    /// <summary>
    /// Simple local/pseudo AI engine: rule-based and mock responses.
    /// </summary>
    public class LocalAiEngine : IAiEngine
    {
        public Task<string> SummarizeEmailsAsync(IEnumerable<string> snippets, CancellationToken ct = default)
        {
            var list = snippets?.Take(5).ToList() ?? new List<string>();
            var summary = list.Any() ? $"Today: {list.Count} messages. Sample: {string.Join("; ", list)}" : "No recent messages.";
            return Task.FromResult(summary);
        }

        public Task<IList<Models.TaskItem>> ExtractTasksFromTextAsync(string text, CancellationToken ct = default)
        {
            // Very naive: split sentences that start with verbs to tasks (demo only)
            var tasks = text?.Split('.', '\n')
                .Select(s => s.Trim())
                .Where(s => !string.IsNullOrWhiteSpace(s) && s.Length > 5)
                .Take(5)
                .Select(s => new Models.TaskItem { Title = s })
                .ToList() ?? new List<Models.TaskItem>();

            return Task.FromResult((IList<Models.TaskItem>)tasks);
        }

        public Task<string> GenerateDailySummaryAsync(DashboardUsageProfile profile, CancellationToken ct = default)
        {
            var summary = $"You opened widgets {profile.WidgetOpenFrequency} times, completed {profile.TasksCompletedToday} tasks and had {profile.FocusSessionsToday} focus sessions.";
            return Task.FromResult(summary);
        }

        public Task<LayoutSuggestion> GetLayoutSuggestionsAsync(DashboardUsageProfile profile, CancellationToken ct = default)
        {
            var suggestion = new LayoutSuggestion();
            if (profile.FocusSessionsToday > 2)
            {
                suggestion.SuggestedTheme = "Focus";
                suggestion.WidgetsToPromote.Add("FocusTimer");
            }
            else
            {
                suggestion.SuggestedTheme = "Balanced";
                suggestion.WidgetsToPromote.Add("Calendar");
            }
            return Task.FromResult(suggestion);
        }
    }
}
