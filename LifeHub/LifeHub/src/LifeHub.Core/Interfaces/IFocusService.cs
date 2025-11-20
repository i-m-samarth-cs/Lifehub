using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces;

public interface IFocusService
{
    Task<FocusSession> StartSessionAsync(FocusSessionType type, int durationMinutes, CancellationToken ct = default);
    Task<FocusSession> EndSessionAsync(string sessionId, bool completed, CancellationToken ct = default);
    Task<IList<FocusSession>> GetSessionsAsync(DateTime from, DateTime to, CancellationToken ct = default);
    Task<int> GetTodayFocusMinutesAsync(CancellationToken ct = default);
}
