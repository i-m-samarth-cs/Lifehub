using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces;

public interface ITaskService
{
    Task<IList<TaskItem>> GetAllTasksAsync(CancellationToken ct = default);
    Task<TaskItem> CreateTaskAsync(TaskItem task, CancellationToken ct = default);
    Task<TaskItem> UpdateTaskAsync(TaskItem task, CancellationToken ct = default);
    Task DeleteTaskAsync(string taskId, CancellationToken ct = default);
    Task<TaskItem> ToggleCompleteAsync(string taskId, CancellationToken ct = default);
}
