using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.Services.Email;

public class EmailSummaryService : IEmailSummaryService
{
    private readonly IAiEngine _aiEngine;

    public EmailSummaryService(IAiEngine aiEngine)
    {
        _aiEngine = aiEngine;
    }

    public async Task<EmailSummary> GetEmailSummaryAsync(CancellationToken ct = default)
    {
        var emails = new List<EmailItem>
        {
            new EmailItem
            {
                From = "team@company.com",
                Subject = "Q4 Planning Meeting Scheduled",
                Snippet = "The Q4 planning meeting has been scheduled for next Tuesday...",
                ReceivedAt = DateTime.Now.AddHours(-2),
                IsImportant = true
            }
        };

        var summary = await _aiEngine.SummarizeTextAsync("emails", ct);

        return new EmailSummary
        {
            UnreadCount = 12,
            Summary = summary,
            KeyEmails = emails
        };
    }
}
