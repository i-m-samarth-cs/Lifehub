using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.Services.Weather;

public class WeatherService : IWeatherService
{
    public Task<WeatherInfo> GetWeatherAsync(string location, CancellationToken ct = default)
    {
        var weather = new WeatherInfo
        {
            Location = location,
            Temperature = 72,
            Condition = "Partly Cloudy",
            IconCode = "partly-cloudy",
            Humidity = 65,
            WindSpeed = 8.5,
            Forecast = new List<WeatherForecast>
            {
                new WeatherForecast
                {
                    Date = DateTime.Today.AddDays(1),
                    TempHigh = 75,
                    TempLow = 58,
                    Condition = "Sunny"
                }
            }
        };

        return Task.FromResult(weather);
    }
}
