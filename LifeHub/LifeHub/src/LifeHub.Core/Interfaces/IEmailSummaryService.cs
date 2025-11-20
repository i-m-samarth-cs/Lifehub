using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces;

public interface IEmailSummaryService
{
    Task<EmailSummary> GetEmailSummaryAsync(CancellationToken ct = default);
}
