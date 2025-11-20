using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.Services.Focus;

public class FocusService : IFocusService
{
    private readonly List<FocusSession> _sessions = new();

    public Task<FocusSession> StartSessionAsync(FocusSessionType type, int durationMinutes, CancellationToken ct = default)
    {
        var session = new FocusSession
        {
            StartTime = DateTime.Now,
            DurationMinutes = durationMinutes,
            Type = type
        };
        _sessions.Add(session);
        return Task.FromResult(session);
    }

    public Task<FocusSession> EndSessionAsync(string sessionId, bool completed, CancellationToken ct = default)
    {
        var session = _sessions.FirstOrDefault(s => s.Id == sessionId);
        if (session != null)
        {
            session.EndTime = DateTime.Now;
            session.WasCompleted = completed;
        }
        return Task.FromResult(session!);
    }

    public Task<IList<FocusSession>> GetSessionsAsync(DateTime from, DateTime to, CancellationToken ct = default)
    {
        var sessions = _sessions
            .Where(s => s.StartTime >= from && s.StartTime <= to)
            .ToList();
        return Task.FromResult<IList<FocusSession>>(sessions);
    }

    public async Task<int> GetTodayFocusMinutesAsync(CancellationToken ct = default)
    {
        var today = DateTime.Today;
        var sessions = await GetSessionsAsync(today, today.AddDays(1), ct);
        return sessions
            .Where(s => s.Type == FocusSessionType.Focus && s.WasCompleted)
            .Sum(s => s.DurationMinutes);
    }
}
