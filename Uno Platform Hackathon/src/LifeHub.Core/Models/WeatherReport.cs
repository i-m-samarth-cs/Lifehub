using System;
using System.Collections.Generic;

namespace LifeHub.Core.Models
{
    public sealed class WeatherReport
    {
        public string Location { get; set; } = string.Empty;
        public double TemperatureC { get; set; }
        public string Condition { get; set; } = string.Empty;
        public DateTime ObservationTime { get; set; }
        public List<DailyForecast> Forecast { get; set; } = new();
    }

    public sealed class DailyForecast
    {
        public DateTime Date { get; set; }
        public double MinC { get; set; }
        public double MaxC { get; set; }
        public string Condition { get; set; } = string.Empty;
    }
}
