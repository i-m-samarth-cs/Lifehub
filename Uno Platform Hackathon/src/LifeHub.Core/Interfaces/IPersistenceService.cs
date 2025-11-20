using System.Threading;
using System.Threading.Tasks;

namespace LifeHub.Core.Interfaces
{
    /// <summary>
    /// Simple persistence abstraction (local-first).
    /// </summary>
    public interface IPersistenceService
    {
        Task SaveAsync(string key, string json, CancellationToken ct = default);
        Task<string?> LoadAsync(string key, CancellationToken ct = default);
    }
}
