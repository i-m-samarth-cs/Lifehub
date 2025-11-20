using System;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.DevHost
{
    internal class Program
    {
        static async Task<int> Main(string[] args)
        {
            var services = new ServiceCollection();
            // Register same demo services as UI
            services.AddSingleton<IAiEngine, LifeHub.Services.Services.LocalAiEngine>();
            services.AddSingleton<ITaskService, LifeHub.Services.Services.LocalTaskService>();
            services.AddSingleton<ICalendarService, LifeHub.Services.Services.LocalCalendarService>();
            services.AddSingleton<IEmailSummaryService, LifeHub.Services.Services.MockEmailSummaryService>();
            services.AddSingleton<IWeatherService, LifeHub.Services.Services.LocalWeatherService>();
            services.AddSingleton<IPersistenceService, LifeHub.Services.Services.LocalPersistenceService>();

            var provider = services.BuildServiceProvider();

            Console.WriteLine("LifeHub DevHost - Demo output\n");

            var taskService = provider.GetRequiredService<ITaskService>();
            var weather = provider.GetRequiredService<IWeatherService>();
            var email = provider.GetRequiredService<IEmailSummaryService>();

            // Add sample tasks
            var t1 = await taskService.AddAsync(new TaskItem { Title = "Write demo README", Description = "Prepare run instructions" });
            var t2 = await taskService.AddAsync(new TaskItem { Title = "Review schedule", DueDate = DateTime.Today.AddDays(1) });

            Console.WriteLine("Tasks:");
            var all = await taskService.GetAllAsync();
            foreach (var t in all)
            {
                Console.WriteLine($" - [{(t.IsCompleted ? 'x' : ' ')}] {t.Title} (Due: {t.DueDate?.ToShortDateString() ?? "n/a"})");
            }

            Console.WriteLine();

            // Weather
            var w = await weather.GetCurrentAsync("San Francisco");
            Console.WriteLine($"Weather for {w.Location}: {w.TemperatureC}°C, {w.Condition}");
            Console.WriteLine("3-day forecast:");
            foreach (var f in w.Forecast)
            {
                Console.WriteLine($" - {f.Date.ToShortDateString()}: {f.MinC}°C - {f.MaxC}°C, {f.Condition}");
            }

            Console.WriteLine();

            // Email summary
            var sampleEmails = new[] { "Team meeting tomorrow", "Invoice #12345", "Welcome to LifeHub" };
            var summary = await email.SummarizeEmailsAsync(sampleEmails);
            Console.WriteLine("Email Summary:");
            Console.WriteLine(summary);

            Console.WriteLine();
            Console.WriteLine("Demo complete.");
            return 0;
        }
    }
}
