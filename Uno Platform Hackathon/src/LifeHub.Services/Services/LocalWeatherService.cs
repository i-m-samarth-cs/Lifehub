using System;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.Services.Services
{
    public class LocalWeatherService : IWeatherService
    {
        public Task<WeatherReport> GetCurrentAsync(string location, CancellationToken ct = default)
        {
            // Mocked data - replace with HTTP client to public API later.
            var report = new WeatherReport
            {
                Location = location,
                TemperatureC = 18.5,
                Condition = "Partly Cloudy",
                ObservationTime = DateTime.UtcNow,
                Forecast =
                {
                    new DailyForecast { Date = DateTime.Today.AddDays(1), MinC = 12, MaxC = 20, Condition = "Sunny" },
                    new DailyForecast { Date = DateTime.Today.AddDays(2), MinC = 11, MaxC = 19, Condition = "Rain" },
                    new DailyForecast { Date = DateTime.Today.AddDays(3), MinC = 10, MaxC = 18, Condition = "Cloudy" }
                }
            };

            return Task.FromResult(report);
        }
    }
}
