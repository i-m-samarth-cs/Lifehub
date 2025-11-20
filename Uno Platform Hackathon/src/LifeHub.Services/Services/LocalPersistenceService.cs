using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;

namespace LifeHub.Services.Services
{
    /// <summary>
    /// Very small file-backed or in-memory persistence. Replace with platform-specific storage.
    /// </summary>
    public class LocalPersistenceService : IPersistenceService
    {
        private readonly System.Collections.Concurrent.ConcurrentDictionary<string, string> _store = new();

        public Task<string?> LoadAsync(string key, CancellationToken ct = default)
        {
            _store.TryGetValue(key, out var value);
            return Task.FromResult<string?>(value);
        }

        public Task SaveAsync(string key, string json, CancellationToken ct = default)
        {
            _store[key] = json;
            return Task.CompletedTask;
        }
    }
}
