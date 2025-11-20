using System;
using Microsoft.Extensions.DependencyInjection;
using Windows.UI.Xaml;
using LifeHub.Core.Interfaces;
using LifeHub.Services.Services;

namespace LifeHub.UI
{
    public partial class App : Application
    {
        public static IServiceProvider Services { get; private set; } = null!;

        public App()
        {
            this.InitializeComponent();
            var services = new ServiceCollection();
            ConfigureServices(services);
            Services = services.BuildServiceProvider();

            this.Suspending += (s, e) => { /* TODO: persist state */ };
        }

        private void ConfigureServices(ServiceCollection services)
        {
            services.AddSingleton<IAiEngine, LocalAiEngine>();
            services.AddSingleton<ITaskService, LocalTaskService>();
            services.AddSingleton<ICalendarService, LocalCalendarService>();
            services.AddSingleton<IEmailSummaryService, MockEmailSummaryService>();
            services.AddSingleton<IWeatherService, LocalWeatherService>();
            services.AddSingleton<IPersistenceService, LocalPersistenceService>();
        }
    }
}
