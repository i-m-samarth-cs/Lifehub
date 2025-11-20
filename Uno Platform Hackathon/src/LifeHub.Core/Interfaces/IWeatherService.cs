using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces
{
    /// <summary>
    /// Abstraction for weather providers.
    /// </summary>
    public interface IWeatherService
    {
        Task<WeatherReport> GetCurrentAsync(string location, CancellationToken ct = default);
    }
}
