using System.Threading;
using System.Threading.Task;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces;

public interface IWeatherService
{
    Task<WeatherInfo> GetWeatherAsync(string location, CancellationToken ct = default);
}
