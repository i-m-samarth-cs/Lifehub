using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.Services.Services
{
    /// <summary>
    /// Local in-memory task store. Replace with persistent store later.
    /// </summary>
    public class LocalTaskService : ITaskService
    {
        private readonly List<TaskItem> _items = new();

        public Task<TaskItem> AddAsync(TaskItem item, CancellationToken ct = default)
        {
            _items.Add(item);
            return Task.FromResult(item);
        }

        public Task DeleteAsync(string id, CancellationToken ct = default)
        {
            var existing = _items.FirstOrDefault(x => x.Id.ToString() == id);
            if (existing != null) _items.Remove(existing);
            return Task.CompletedTask;
        }

        public Task<IList<TaskItem>> GetAllAsync(CancellationToken ct = default)
        {
            return Task.FromResult((IList<TaskItem>)_items.ToList());
        }

        public Task<TaskItem> UpdateAsync(TaskItem item, CancellationToken ct = default)
        {
            var idx = _items.FindIndex(x => x.Id == item.Id);
            if (idx >= 0) _items[idx] = item;
            return Task.FromResult(item);
        }
    }
}
