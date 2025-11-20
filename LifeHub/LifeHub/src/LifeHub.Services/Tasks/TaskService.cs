using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.Services.Tasks;

public class TaskService : ITaskService
{
    private readonly List<TaskItem> _tasks = new();

    public TaskService()
    {
        SeedMockData();
    }

    public Task<IList<TaskItem>> GetAllTasksAsync(CancellationToken ct = default)
    {
        return Task.FromResult<IList<TaskItem>>(_tasks.OrderBy(t => t.DueDate).ToList());
    }

    public Task<TaskItem> CreateTaskAsync(TaskItem task, CancellationToken ct = default)
    {
        _tasks.Add(task);
        return Task.FromResult(task);
    }

    public Task<TaskItem> UpdateTaskAsync(TaskItem task, CancellationToken ct = default)
    {
        var existing = _tasks.FirstOrDefault(t => t.Id == task.Id);
        if (existing != null)
        {
            _tasks.Remove(existing);
            _tasks.Add(task);
        }
        return Task.FromResult(task);
    }

    public Task DeleteTaskAsync(string taskId, CancellationToken ct = default)
    {
        var existing = _tasks.FirstOrDefault(t => t.Id == taskId);
        if (existing != null)
        {
            _tasks.Remove(existing);
        }
        return Task.CompletedTask;
    }

    public Task<TaskItem> ToggleCompleteAsync(string taskId, CancellationToken ct = default)
    {
        var task = _tasks.FirstOrDefault(t => t.Id == taskId);
        if (task != null)
        {
            task.IsCompleted = !task.IsCompleted;
            task.CompletedAt = task.IsCompleted ? DateTime.Now : null;
        }
        return Task.FromResult(task!);
    }

    private void SeedMockData()
    {
        var today = DateTime.Today;
        _tasks.AddRange(new[]
        {
            new TaskItem
            {
                Title = "Review pull request #234",
                Priority = TaskPriority.High,
                DueDate = today,
                Tags = new List<string> { "development", "urgent" }
            },
            new TaskItem
            {
                Title = "Update project documentation",
                Priority = TaskPriority.Medium,
                DueDate = today,
                Tags = new List<string> { "documentation" }
            },
            new TaskItem
            {
                Title = "Fix authentication bug",
                Description = "Users reporting login issues on mobile",
                Priority = TaskPriority.Urgent,
                DueDate = today,
                Tags = new List<string> { "bug", "urgent" }
            }
        });
    }
}
