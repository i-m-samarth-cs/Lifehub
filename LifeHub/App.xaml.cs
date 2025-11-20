using Microsoft.Extensions.DependencyInjection;
using Microsoft.UI.Xaml;
using LifeHub.Core.Interfaces;
using LifeHub.Services.Calendar;
using LifeHub.Services.Tasks;
using LifeHub.Services.Weather;
using LifeHub.Services.Email;
using LifeHub.Services.AI;
using LifeHub.Services.Focus;
using LifeHub.Services.Notes;
using LifeHub.UI.ViewModels;
using System;

namespace LifeHub;

public partial class App : Application
{
    private Window? _window;
    public IServiceProvider Services { get; private set; } = null!;
    public new static App Current => (App)Application.Current;

    public App()
    {
        this.InitializeComponent();
        ConfigureServices();
    }

    private void ConfigureServices()
    {
        var services = new ServiceCollection();

        // Register services
        services.AddSingleton<ICalendarService, CalendarService>();
        services.AddSingleton<ITaskService, TaskService>();
        services.AddSingleton<IWeatherService, WeatherService>();
        services.AddSingleton<IFocusService, FocusService>();
        services.AddSingleton<INoteService, NoteService>();
        services.AddSingleton<IAiEngine, AiEngine>();
        services.AddSingleton<IEmailSummaryService, EmailSummaryService>();

        // Register ViewModels
        services.AddTransient<DashboardViewModel>();

        Services = services.BuildServiceProvider();
    }

    protected override void OnLaunched(Microsoft.UI.Xaml.LaunchActivatedEventArgs args)
    {
        _window = new Window
        {
            Title = "LifeHub - Your Smart Daily Dashboard"
        };

        _window.Content = new MainPage();
        _window.Activate();
    }
}
