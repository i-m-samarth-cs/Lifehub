using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.Services.AI;

public class AiEngine : IAiEngine
{
    private readonly ITaskService _taskService;
    private readonly ICalendarService _calendarService;
    private readonly IFocusService _focusService;

    public AiEngine(ITaskService taskService, ICalendarService calendarService, IFocusService focusService)
    {
        _taskService = taskService;
        _calendarService = calendarService;
        _focusService = focusService;
    }

    public Task<string> SummarizeTextAsync(string text, CancellationToken ct = default)
    {
        return Task.FromResult("You have important updates from multiple sources including meetings and project updates.");
    }

    public async Task<AiInsight> GenerateDailySummaryAsync(CancellationToken ct = default)
    {
        var today = DateTime.Today;
        var events = await _calendarService.GetEventsAsync(today, today.AddDays(1), ct);
        var tasks = await _taskService.GetAllTasksAsync(ct);
        var todayTasks = tasks.Count(t => t.DueDate?.Date == today && !t.IsCompleted);
        var focusMinutes = await _focusService.GetTodayFocusMinutesAsync(ct);

        var summary = $"Today you have {events.Count} events and {todayTasks} tasks. ";
        summary += focusMinutes > 0 ? $"You've focused for {focusMinutes} minutes. Great work!" : "Start your first focus session!";

        return new AiInsight
        {
            Title = "Daily Summary",
            Content = summary,
            Type = InsightType.DailySummary
        };
    }

    public Task<IList<TaskItem>> ExtractTasksFromTextAsync(string text, CancellationToken ct = default)
    {
        return Task.FromResult<IList<TaskItem>>(new List<TaskItem>());
    }

    public Task<IList<Widget>> SuggestLayoutAsync(CancellationToken ct = default)
    {
        return Task.FromResult<IList<Widget>>(new List<Widget>());
    }
}
