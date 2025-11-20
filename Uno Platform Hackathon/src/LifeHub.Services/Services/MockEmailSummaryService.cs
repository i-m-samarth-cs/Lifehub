using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;

namespace LifeHub.Services.Services
{
    /// <summary>
    /// Mocked email summarization that delegates to IAiEngine if available. Otherwise returns a simple summary.
    /// </summary>
    public class MockEmailSummaryService : IEmailSummaryService
    {
        private readonly IAiEngine? _ai;

        public MockEmailSummaryService(IAiEngine? ai = null)
        {
            _ai = ai;
        }

        public async Task<string> SummarizeEmailsAsync(IEnumerable<string> emailSnippets, CancellationToken ct = default)
        {
            if (_ai != null)
            {
                return await _ai.SummarizeEmailsAsync(emailSnippets, ct);
            }

            var list = emailSnippets?.ToList() ?? new List<string>();
            return $"You have {list.Count} new messages. Top subjects: {string.Join(", ", list.Take(3))}";
        }
    }
}
