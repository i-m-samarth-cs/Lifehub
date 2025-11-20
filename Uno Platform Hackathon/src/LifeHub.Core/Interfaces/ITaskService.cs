using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces
{
    /// <summary>
    /// Abstraction for task management.
    /// </summary>
    public interface ITaskService
    {
        Task<IList<TaskItem>> GetAllAsync(CancellationToken ct = default);
        Task<TaskItem> AddAsync(TaskItem item, CancellationToken ct = default);
        Task<TaskItem> UpdateAsync(TaskItem item, CancellationToken ct = default);
        Task DeleteAsync(string id, CancellationToken ct = default);
    }
}
