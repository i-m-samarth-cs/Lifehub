using System;
using System.Collections.Generic;

namespace LifeHub.Core.Models;

public class WeatherInfo
{
    public string Location { get; set; } = string.Empty;
    public double Temperature { get; set; }
    public string Condition { get; set; } = string.Empty;
    public string IconCode { get; set; } = string.Empty;
    public int Humidity { get; set; }
    public double WindSpeed { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.Now;
    public List<WeatherForecast> Forecast { get; set; } = new();
}

public class WeatherForecast
{
    public DateTime Date { get; set; }
    public double TempHigh { get; set; }
    public double TempLow { get; set; }
    public string Condition { get; set; } = string.Empty;
    public string IconCode { get; set; } = string.Empty;
}
