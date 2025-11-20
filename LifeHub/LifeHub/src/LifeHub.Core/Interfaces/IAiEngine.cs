using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces;

public interface IAiEngine
{
    Task<string> SummarizeTextAsync(string text, CancellationToken ct = default);
    Task<AiInsight> GenerateDailySummaryAsync(CancellationToken ct = default);
    Task<IList<TaskItem>> ExtractTasksFromTextAsync(string text, CancellationToken ct = default);
    Task<IList<Widget>> SuggestLayoutAsync(CancellationToken ct = default);
}
