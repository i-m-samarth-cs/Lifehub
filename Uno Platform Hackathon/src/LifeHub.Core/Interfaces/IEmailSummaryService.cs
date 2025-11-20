using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace LifeHub.Core.Interfaces
{
    /// <summary>
    /// Abstraction for producing email summaries.
    /// </summary>
    public interface IEmailSummaryService
    {
        /// <summary>
        /// Summarize a list of email snippets into a short digest.
        /// </summary>
        Task<string> SummarizeEmailsAsync(IEnumerable<string> emailSnippets, CancellationToken ct = default);
    }
}
