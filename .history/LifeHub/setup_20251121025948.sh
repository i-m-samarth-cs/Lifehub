#!/bin/bash

# LifeHub Integration Script
# Run this from the LifeHub/LifeHub directory to integrate all components

echo "🔧 Integrating LifeHub components..."

# Update the .csproj to include our custom files
cat > LifeHub.csproj << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFrameworks>net10.0-desktop;net10.0-browserwasm;net10.0-ios;net10.0-android</TargetFrameworks>
    <OutputType>Exe</OutputType>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <ApplicationManifest>app.manifest</ApplicationManifest>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Uno.WinUI" Version="5.5.8" />
    <PackageReference Include="Uno.WinUI.RemoteControl" Version="5.5.8" Condition="'$(Configuration)'=='Debug'" />
    <PackageReference Include="Uno.WinUI.DevServer" Version="5.5.8" Condition="'$(Configuration)'=='Debug'" />
    <PackageReference Include="Uno.Extensions.Configuration" Version="4.1.18" />
    <PackageReference Include="Microsoft.Extensions.Logging.Console" Version="8.0.1" />
    <PackageReference Include="Microsoft.Extensions.DependencyInjection" Version="8.0.1" />
  </ItemGroup>

  <ItemGroup>
    <Compile Include="../src/**/*.cs" />
  </ItemGroup>
</Project>
EOF

# Create a complete App.xaml.cs with DI
cat > App.xaml.cs << 'EOF'
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
EOF

# Create BaseViewModel
cat > ../src/LifeHub.UI/ViewModels/BaseViewModel.cs << 'EOF'
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Collections.Generic;

namespace LifeHub.UI.ViewModels;

public abstract class BaseViewModel : INotifyPropertyChanged
{
    public event PropertyChangedEventHandler? PropertyChanged;

    protected virtual void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }

    protected bool SetProperty<T>(ref T field, T value, [CallerMemberName] string? propertyName = null)
    {
        if (EqualityComparer<T>.Default.Equals(field, value))
            return false;

        field = value;
        OnPropertyChanged(propertyName);
        return true;
    }
}
EOF

# Create RelayCommand
cat > ../src/LifeHub.UI/Helpers/RelayCommand.cs << 'EOF'
using System;
using System.Threading.Tasks;
using System.Windows.Input;

namespace LifeHub.UI.Helpers;

public class RelayCommand : ICommand
{
    private readonly Func<Task> _execute;
    private readonly Func<bool>? _canExecute;

    public RelayCommand(Func<Task> execute, Func<bool>? canExecute = null)
    {
        _execute = execute;
        _canExecute = canExecute;
    }

    public event EventHandler? CanExecuteChanged;

    public bool CanExecute(object? parameter) => _canExecute?.Invoke() ?? true;

    public async void Execute(object? parameter) => await _execute();

    public void RaiseCanExecuteChanged() => CanExecuteChanged?.Invoke(this, EventArgs.Empty);
}
EOF

# Create DashboardViewModel
cat > ../src/LifeHub.UI/ViewModels/DashboardViewModel.cs << 'EOF'
using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Input;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;
using LifeHub.UI.Helpers;

namespace LifeHub.UI.ViewModels;

public class DashboardViewModel : BaseViewModel
{
    private readonly ICalendarService _calendarService;
    private readonly ITaskService _taskService;
    private readonly IWeatherService _weatherService;
    private readonly IEmailSummaryService _emailService;
    private readonly IAiEngine _aiEngine;
    private readonly IFocusService _focusService;

    private bool _isLoading;
    private string _greeting = string.Empty;
    private AiInsight? _dailyInsight;
    private WeatherInfo? _weather;
    private EmailSummary? _emailSummary;
    private int _todayFocusMinutes;

    public DashboardViewModel(
        ICalendarService calendarService,
        ITaskService taskService,
        IWeatherService weatherService,
        IEmailSummaryService emailService,
        IAiEngine aiEngine,
        IFocusService focusService)
    {
        _calendarService = calendarService;
        _taskService = taskService;
        _weatherService = weatherService;
        _emailService = emailService;
        _aiEngine = aiEngine;
        _focusService = focusService;

        TodayEvents = new ObservableCollection<CalendarEvent>();
        TodayTasks = new ObservableCollection<TaskItem>();

        RefreshCommand = new RelayCommand(async () => await LoadDataAsync());
    }

    public bool IsLoading
    {
        get => _isLoading;
        set => SetProperty(ref _isLoading, value);
    }

    public string Greeting
    {
        get => _greeting;
        set => SetProperty(ref _greeting, value);
    }

    public AiInsight? DailyInsight
    {
        get => _dailyInsight;
        set => SetProperty(ref _dailyInsight, value);
    }

    public WeatherInfo? Weather
    {
        get => _weather;
        set => SetProperty(ref _weather, value);
    }

    public EmailSummary? EmailSummary
    {
        get => _emailSummary;
        set => SetProperty(ref _emailSummary, value);
    }

    public int TodayFocusMinutes
    {
        get => _todayFocusMinutes;
        set => SetProperty(ref _todayFocusMinutes, value);
    }

    public ObservableCollection<CalendarEvent> TodayEvents { get; }
    public ObservableCollection<TaskItem> TodayTasks { get; }

    public ICommand RefreshCommand { get; }

    public async Task LoadDataAsync()
    {
        IsLoading = true;

        try
        {
            var hour = DateTime.Now.Hour;
            Greeting = hour < 12 ? "Good Morning" : hour < 18 ? "Good Afternoon" : "Good Evening";

            var today = DateTime.Today;
            var events = await _calendarService.GetEventsAsync(today, today.AddDays(1));
            TodayEvents.Clear();
            foreach (var evt in events)
            {
                TodayEvents.Add(evt);
            }

            var allTasks = await _taskService.GetAllTasksAsync();
            TodayTasks.Clear();
            foreach (var task in allTasks)
            {
                if (!task.IsCompleted && task.DueDate?.Date <= today.AddDays(1))
                {
                    TodayTasks.Add(task);
                }
            }

            Weather = await _weatherService.GetWeatherAsync("San Francisco");
            EmailSummary = await _emailService.GetEmailSummaryAsync();
            DailyInsight = await _aiEngine.GenerateDailySummaryAsync();
            TodayFocusMinutes = await _focusService.GetTodayFocusMinutesAsync();
        }
        finally
        {
            IsLoading = false;
        }
    }
}
EOF

# Create a simple MainPage.xaml
cat > MainPage.xaml << 'EOF'
<Page
    x:Class="LifeHub.MainPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Background="{ThemeResource ApplicationPageBackgroundThemeBrush}">

    <Grid Padding="40">
        <ScrollViewer>
            <StackPanel Spacing="24" MaxWidth="1200">
                
                <!-- Header -->
                <StackPanel Spacing="8">
                    <TextBlock x:Name="GreetingText" 
                             Text="Good Morning"
                             FontSize="32"
                             FontWeight="Bold"/>
                    <TextBlock Text="Here's your dashboard for today"
                             FontSize="16"
                             Opacity="0.7"/>
                </StackPanel>

                <!-- AI Insight Card -->
                <Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
                       CornerRadius="8"
                       Padding="24"
                       BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                       BorderThickness="1">
                    <StackPanel Spacing="12">
                        <TextBlock Text="✨ Daily Insight" 
                                 FontSize="18"
                                 FontWeight="SemiBold"/>
                        <TextBlock x:Name="InsightText"
                                 Text="Loading your personalized insights..."
                                 TextWrapping="Wrap"
                                 Opacity="0.8"/>
                    </StackPanel>
                </Border>

                <Grid ColumnSpacing="20">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="2*"/>
                        <ColumnDefinition Width="1*"/>
                    </Grid.ColumnDefinitions>

                    <!-- Left Column -->
                    <StackPanel Grid.Column="0" Spacing="20">
                        
                        <!-- Calendar Widget -->
                        <Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
                               CornerRadius="8"
                               Padding="24"
                               BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                               BorderThickness="1">
                            <StackPanel Spacing="16">
                                <TextBlock Text="📅 Today's Events" 
                                         FontSize="18"
                                         FontWeight="SemiBold"/>
                                
                                <ItemsControl x:Name="EventsList">
                                    <ItemsControl.ItemTemplate>
                                        <DataTemplate>
                                            <Border Padding="0,12" BorderBrush="{ThemeResource DividerStrokeColorDefaultBrush}" BorderThickness="0,0,0,1">
                                                <StackPanel>
                                                    <TextBlock Text="{Binding Title}" 
                                                             FontWeight="SemiBold"
                                                             FontSize="15"/>
                                                    <TextBlock Opacity="0.7" FontSize="13">
                                                        <Run Text="🕒 "/>
                                                        <Run Text="{Binding StartTime}"/>
                                                    </TextBlock>
                                                    <TextBlock Text="{Binding Location}" 
                                                             Opacity="0.6"
                                                             FontSize="13"
                                                             Visibility="{Binding Location, Converter={StaticResource EmptyToCollapsedConverter}}"/>
                                                </StackPanel>
                                            </Border>
                                        </DataTemplate>
                                    </ItemsControl.ItemTemplate>
                                </ItemsControl>
                            </StackPanel>
                        </Border>

                        <!-- Tasks Widget -->
                        <Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
                               CornerRadius="8"
                               Padding="24"
                               BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                               BorderThickness="1">
                            <StackPanel Spacing="16">
                                <TextBlock Text="✅ Today's Tasks" 
                                         FontSize="18"
                                         FontWeight="SemiBold"/>
                                
                                <ItemsControl x:Name="TasksList">
                                    <ItemsControl.ItemTemplate>
                                        <DataTemplate>
                                            <Border Padding="0,8">
                                                <StackPanel Orientation="Horizontal" Spacing="12">
                                                    <CheckBox IsChecked="{Binding IsCompleted}" VerticalAlignment="Center"/>
                                                    <StackPanel>
                                                        <TextBlock Text="{Binding Title}" FontSize="15"/>
                                                        <TextBlock Text="{Binding Priority}" Opacity="0.6" FontSize="12"/>
                                                    </StackPanel>
                                                </StackPanel>
                                            </Border>
                                        </DataTemplate>
                                    </ItemsControl.ItemTemplate>
                                </ItemsControl>
                            </StackPanel>
                        </Border>
                    </StackPanel>

                    <!-- Right Column -->
                    <StackPanel Grid.Column="1" Spacing="20">
                        
                        <!-- Weather Widget -->
                        <Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
                               CornerRadius="8"
                               Padding="24"
                               BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                               BorderThickness="1">
                            <StackPanel Spacing="12">
                                <TextBlock Text="🌤️ Weather" 
                                         FontSize="18"
                                         FontWeight="SemiBold"/>
                                <TextBlock x:Name="Temperature"
                                         Text="72°F"
                                         FontSize="36"
                                         FontWeight="Bold"/>
                                <TextBlock x:Name="Condition"
                                         Text="Partly Cloudy"
                                         Opacity="0.7"/>
                                <TextBlock x:Name="LocationText"
                                         Text="San Francisco"
                                         FontSize="12"
                                         Opacity="0.5"/>
                            </StackPanel>
                        </Border>

                        <!-- Email Widget -->
                        <Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
                               CornerRadius="8"
                               Padding="24"
                               BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                               BorderThickness="1">
                            <StackPanel Spacing="12">
                                <TextBlock Text="📧 Email" 
                                         FontSize="18"
                                         FontWeight="SemiBold"/>
                                <TextBlock x:Name="EmailCount"
                                         Text="12 unread"
                                         FontSize="20"
                                         FontWeight="SemiBold"/>
                                <TextBlock x:Name="EmailSummaryText"
                                         Text="Loading..."
                                         TextWrapping="Wrap"
                                         FontSize="13"
                                         Opacity="0.7"/>
                            </StackPanel>
                        </Border>

                        <!-- Focus Widget -->
                        <Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
                               CornerRadius="8"
                               Padding="24"
                               BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                               BorderThickness="1">
                            <StackPanel Spacing="12">
                                <TextBlock Text="⏱️ Focus Time" 
                                         FontSize="18"
                                         FontWeight="SemiBold"/>
                                <TextBlock x:Name="FocusMinutes"
                                         Text="0 minutes today"
                                         FontSize="24"
                                         FontWeight="SemiBold"/>
                                <Button Content="Start Session"
                                       HorizontalAlignment="Stretch"/>
                            </StackPanel>
                        </Border>

                    </StackPanel>
                </Grid>

            </StackPanel>
        </ScrollViewer>
    </Grid>
</Page>
EOF

# Create MainPage.xaml.cs
cat > MainPage.xaml.cs << 'EOF'
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using LifeHub.UI.ViewModels;
using System.Linq;

namespace LifeHub;

public sealed partial class MainPage : Page
{
    public DashboardViewModel ViewModel { get; }

    public MainPage()
    {
        this.InitializeComponent();
        
        ViewModel = App.Current.Services.GetService(typeof(DashboardViewModel)) as DashboardViewModel 
            ?? throw new System.InvalidOperationException("DashboardViewModel not registered");
        
        Loaded += MainPage_Loaded;
    }

    private async void MainPage_Loaded(object sender, RoutedEventArgs e)
    {
        await ViewModel.LoadDataAsync();
        UpdateUI();
        
        ViewModel.PropertyChanged += (s, e) => 
        {
            DispatcherQueue.TryEnqueue(UpdateUI);
        };
    }

    private void UpdateUI()
    {
        GreetingText.Text = ViewModel.Greeting;
        
        if (ViewModel.DailyInsight != null)
        {
            InsightText.Text = ViewModel.DailyInsight.Content;
        }
        
        if (ViewModel.Weather != null)
        {
            Temperature.Text = $"{ViewModel.Weather.Temperature}°F";
            Condition.Text = ViewModel.Weather.Condition;
            LocationText.Text = ViewModel.Weather.Location;
        }
        
        if (ViewModel.EmailSummary != null)
        {
            EmailCount.Text = $"{ViewModel.EmailSummary.UnreadCount} unread";
            EmailSummaryText.Text = ViewModel.EmailSummary.Summary;
        }
        
        FocusMinutes.Text = $"{ViewModel.TodayFocusMinutes} minutes today";
        
        EventsList.ItemsSource = ViewModel.TodayEvents.ToList();
        TasksList.ItemsSource = ViewModel.TodayTasks.ToList();
    }
}
EOF

echo "✅ Integration complete!"
echo ""
echo "🚀 Now run:"
echo "   dotnet build"
echo "   dotnet run --framework net10.0-desktop"