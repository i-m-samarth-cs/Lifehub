#!/bin/bash

# LifeHub - Complete Uno Platform Application Generator
# This script creates a full-featured, cross-platform daily dashboard app
# Run with: bash create-lifehub.sh

set -e

echo "🚀 Creating LifeHub - Your Smart Daily Dashboard"
echo "================================================"

# Check prerequisites
command -v dotnet >/dev/null 2>&1 || { echo "❌ .NET SDK is required but not installed. Aborting." >&2; exit 1; }

# Create solution directory
PROJECT_NAME="LifeHub"
echo "📁 Creating project structure..."
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Create Uno Platform app
echo "🔨 Creating Uno Platform application..."
dotnet new install Uno.Templates
dotnet new unoapp -preset recommended -o . --force

# Create solution structure
echo "📦 Creating solution structure..."
mkdir -p src/LifeHub.Core/{Models,Interfaces,Services}
mkdir -p src/LifeHub.Services/{Calendar,Tasks,Email,Weather,AI,Focus,Notes}
mkdir -p src/LifeHub.UI/{ViewModels,Views,Widgets,Helpers,Resources,Converters}

# ============================================================================
# VIEWMODELS
# ============================================================================

echo "🎨 Creating ViewModels..."

# BaseViewModel.cs
cat > src/LifeHub.UI/ViewModels/BaseViewModel.cs << 'EOF'
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace LifeHub.UI.ViewModels
{
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
}
EOF

# DashboardViewModel.cs
cat > src/LifeHub.UI/ViewModels/DashboardViewModel.cs << 'EOF'
using System;
using System.Collections.ObjectModel;
using System.Threading.Tasks;
using System.Windows.Input;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.UI.ViewModels
{
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
                // Set greeting based on time
                var hour = DateTime.Now.Hour;
                Greeting = hour < 12 ? "Good Morning" : hour < 18 ? "Good Afternoon" : "Good Evening";

                // Load today's events
                var today = DateTime.Today;
                var events = await _calendarService.GetEventsAsync(today, today.AddDays(1));
                TodayEvents.Clear();
                foreach (var evt in events)
                {
                    TodayEvents.Add(evt);
                }

                // Load today's tasks
                var allTasks = await _taskService.GetAllTasksAsync();
                TodayTasks.Clear();
                foreach (var task in allTasks)
                {
                    if (!task.IsCompleted && task.DueDate?.Date <= today.AddDays(1))
                    {
                        TodayTasks.Add(task);
                    }
                }

                // Load weather
                Weather = await _weatherService.GetWeatherAsync("San Francisco");

                // Load email summary
                EmailSummary = await _emailService.GetEmailSummaryAsync();

                // Load AI insight
                DailyInsight = await _aiEngine.GenerateDailySummaryAsync();

                // Load focus stats
                TodayFocusMinutes = await _focusService.GetTodayFocusMinutesAsync();
            }
            finally
            {
                IsLoading = false;
            }
        }
    }

    // Simple RelayCommand implementation
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
}
EOF

# ============================================================================
# XAML VIEWS AND STYLES
# ============================================================================

echo "🎨 Creating XAML Views..."

# MainPage.xaml
cat > MainPage.xaml << 'EOF'
<Page
    x:Class="LifeHub.MainPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    mc:Ignorable="d"
    Background="{ThemeResource ApplicationPageBackgroundThemeBrush}">

    <Grid>
        <NavigationView x:Name="NavView"
                       PaneDisplayMode="Left"
                       IsBackButtonVisible="Collapsed"
                       Header="LifeHub"
                       SelectionChanged="NavView_SelectionChanged">
            
            <NavigationView.MenuItems>
                <NavigationViewItem Content="Dashboard" Tag="Dashboard">
                    <NavigationViewItem.Icon>
                        <FontIcon Glyph="&#xE80F;"/>
                    </NavigationViewItem.Icon>
                </NavigationViewItem>
                <NavigationViewItem Content="Calendar" Tag="Calendar">
                    <NavigationViewItem.Icon>
                        <FontIcon Glyph="&#xE787;"/>
                    </NavigationViewItem.Icon>
                </NavigationViewItem>
                <NavigationViewItem Content="Tasks" Tag="Tasks">
                    <NavigationViewItem.Icon>
                        <FontIcon Glyph="&#xE73A;"/>
                    </NavigationViewItem.Icon>
                </NavigationViewItem>
                <NavigationViewItem Content="Focus" Tag="Focus">
                    <NavigationViewItem.Icon>
                        <FontIcon Glyph="&#xE916;"/>
                    </NavigationViewItem.Icon>
                </NavigationViewItem>
                <NavigationViewItem Content="Notes" Tag="Notes">
                    <NavigationViewItem.Icon>
                        <FontIcon Glyph="&#xE70B;"/>
                    </NavigationViewItem.Icon>
                </NavigationViewItem>
            </NavigationView.MenuItems>

            <NavigationView.FooterMenuItems>
                <NavigationViewItem Content="Settings" Tag="Settings">
                    <NavigationViewItem.Icon>
                        <FontIcon Glyph="&#xE713;"/>
                    </NavigationViewItem.Icon>
                </NavigationViewItem>
            </NavigationView.FooterMenuItems>

            <Frame x:Name="ContentFrame" Padding="20">
                <!-- Dashboard View -->
                <ScrollViewer>
                    <StackPanel Spacing="20" MaxWidth="1200">
                        
                        <!-- Header -->
                        <StackPanel Spacing="8">
                            <TextBlock x:Name="GreetingText" 
                                     Text="Good Morning"
                                     Style="{StaticResource TitleTextBlockStyle}"
                                     FontWeight="Bold"/>
                            <TextBlock Text="Here's what's happening today"
                                     Style="{StaticResource SubtitleTextBlockStyle}"
                                     Foreground="{ThemeResource TextFillColorSecondaryBrush}"/>
                        </StackPanel>

                        <!-- AI Insight Card -->
                        <Border x:Name="InsightCard"
                               Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
                               BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                               BorderThickness="1"
                               CornerRadius="8"
                               Padding="20">
                            <StackPanel Spacing="12">
                                <StackPanel Orientation="Horizontal" Spacing="8">
                                    <FontIcon Glyph="&#xE946;" 
                                            FontSize="20"
                                            Foreground="{ThemeResource AccentFillColorDefaultBrush}"/>
                                    <TextBlock Text="Daily Insight" 
                                             Style="{StaticResource SubtitleTextBlockStyle}"
                                             FontWeight="SemiBold"/>
                                </StackPanel>
                                <TextBlock x:Name="InsightText"
                                         Text="Loading your daily summary..."
                                         TextWrapping="Wrap"
                                         Foreground="{ThemeResource TextFillColorSecondaryBrush}"/>
                            </StackPanel>
                        </Border>

                        <!-- Main Grid -->
                        <Grid ColumnSpacing="20" RowSpacing="20">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="2*"/>
                                <ColumnDefinition Width="1*"/>
                            </Grid.ColumnDefinitions>

                            <!-- Left Column -->
                            <StackPanel Grid.Column="0" Spacing="20">
                                
                                <!-- Calendar Widget -->
                                <Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
                                       BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                                       BorderThickness="1"
                                       CornerRadius="8"
                                       Padding="20">
                                    <StackPanel Spacing="16">
                                        <StackPanel Orientation="Horizontal" Spacing="8">
                                            <FontIcon Glyph="&#xE787;" FontSize="20"/>
                                            <TextBlock Text="Today's Events" 
                                                     Style="{StaticResource SubtitleTextBlockStyle}"
                                                     FontWeight="SemiBold"/>
                                        </StackPanel>
                                        
                                        <ListView x:Name="EventsList"
                                                SelectionMode="None"
                                                ItemsSource="{x:Bind ViewModel.TodayEvents, Mode=OneWay}">
                                            <ListView.ItemTemplate>
                                                <DataTemplate>
                                                    <Grid Padding="0,8" ColumnSpacing="12">
                                                        <Grid.ColumnDefinitions>
                                                            <ColumnDefinition Width="60"/>
                                                            <ColumnDefinition Width="*"/>
                                                        </Grid.ColumnDefinitions>
                                                        
                                                        <TextBlock Grid.Column="0"
                                                                 Text="{Binding StartTime, Converter={StaticResource TimeConverter}}"
                                                                 Foreground="{ThemeResource TextFillColorSecondaryBrush}"
                                                                 VerticalAlignment="Top"/>
                                                        
                                                        <StackPanel Grid.Column="1">
                                                            <TextBlock Text="{Binding Title}" 
                                                                     FontWeight="SemiBold"/>
                                                            <TextBlock Text="{Binding Location}"
                                                                     Foreground="{ThemeResource TextFillColorSecondaryBrush}"
                                                                     Visibility="{Binding Location, Converter={StaticResource EmptyToCollapsedConverter}}"/>
                                                        </StackPanel>
                                                    </Grid>
                                                </DataTemplate>
                                            </ListView.ItemTemplate>
                                        </ListView>
                                    </StackPanel>
                                </Border>

                                <!-- Tasks Widget -->
                                <Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
                                       BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                                       BorderThickness="1"
                                       CornerRadius="8"
                                       Padding="20">
                                    <StackPanel Spacing="16">
                                        <StackPanel Orientation="Horizontal" Spacing="8">
                                            <FontIcon Glyph="&#xE73A;" FontSize="20"/>
                                            <TextBlock Text="Today's Tasks" 
                                                     Style="{StaticResource SubtitleTextBlockStyle}"
                                                     FontWeight="SemiBold"/>
                                        </StackPanel>
                                        
                                        <ListView x:Name="TasksList"
                                                SelectionMode="None"
                                                ItemsSource="{x:Bind ViewModel.TodayTasks, Mode=OneWay}">
                                            <ListView.ItemTemplate>
                                                <DataTemplate>
                                                    <Grid Padding="0,8">
                                                        <Grid.ColumnDefinitions>
                                                            <ColumnDefinition Width="Auto"/>
                                                            <ColumnDefinition Width="*"/>
                                                        </Grid.ColumnDefinitions>
                                                        
                                                        <CheckBox Grid.Column="0"
                                                                IsChecked="{Binding IsCompleted}"
                                                                VerticalAlignment="Center"/>
                                                        
                                                        <StackPanel Grid.Column="1" Margin="12,0,0,0">
                                                            <TextBlock Text="{Binding Title}"/>
                                                            <StackPanel Orientation="Horizontal" Spacing="8">
                                                                <Border Background="{ThemeResource AccentFillColorDefaultBrush}"
                                                                       CornerRadius="4"
                                                                       Padding="6,2"
                                                                       Visibility="{Binding Priority, Converter={StaticResource PriorityToVisibilityConverter}}">
                                                                    <TextBlock Text="{Binding Priority}"
                                                                             FontSize="11"
                                                                             Foreground="White"/>
                                                                </Border>
                                                            </StackPanel>
                                                        </StackPanel>
                                                    </Grid>
                                                </DataTemplate>
                                            </ListView.ItemTemplate>
                                        </ListView>
                                    </StackPanel>
                                </Border>
                            </StackPanel>

                            <!-- Right Column -->
                            <StackPanel Grid.Column="1" Spacing="20">
                                
                                <!-- Weather Widget -->
                                <Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
                                       BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                                       BorderThickness="1"
                                       CornerRadius="8"
                                       Padding="20">
                                    <StackPanel Spacing="12">
                                        <TextBlock Text="Weather" 
                                                 Style="{StaticResource SubtitleTextBlockStyle}"
                                                 FontWeight="SemiBold"/>
                                        <StackPanel Spacing="4">
                                            <TextBlock x:Name="Temperature"
                                                     Text="72°F"
                                                     Style="{StaticResource TitleTextBlockStyle}"
                                                     FontWeight="Bold"/>
                                            <TextBlock x:Name="Condition"
                                                     Text="Partly Cloudy"
                                                     Foreground="{ThemeResource TextFillColorSecondaryBrush}"/>
                                            <TextBlock x:Name="Location"
                                                     Text="San Francisco"
                                                     FontSize="12"
                                                     Foreground="{ThemeResource TextFillColorTertiaryBrush}"/>
                                        </StackPanel>
                                    </StackPanel>
                                </Border>

                                <!-- Email Summary Widget -->
                                <Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
                                       BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                                       BorderThickness="1"
                                       CornerRadius="8"
                                       Padding="20">
                                    <StackPanel Spacing="12">
                                        <StackPanel Orientation="Horizontal" Spacing="8">
                                            <FontIcon Glyph="&#xE715;" FontSize="20"/>
                                            <TextBlock Text="Email" 
                                                     Style="{StaticResource SubtitleTextBlockStyle}"
                                                     FontWeight="SemiBold"/>
                                        </StackPanel>
                                        <TextBlock x:Name="EmailCount"
                                                 Text="12 unread"
                                                 Style="{StaticResource BodyStrongTextBlockStyle}"/>
                                        <TextBlock x:Name="EmailSummaryText"
                                                 Text="Loading..."
                                                 TextWrapping="Wrap"
                                                 FontSize="13"
                                                 Foreground="{ThemeResource TextFillColorSecondaryBrush}"/>
                                    </StackPanel>
                                </Border>

                                <!-- Focus Stats Widget -->
                                <Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
                                       BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                                       BorderThickness="1"
                                       CornerRadius="8"
                                       Padding="20">
                                    <StackPanel Spacing="12">
                                        <StackPanel Orientation="Horizontal" Spacing="8">
                                            <FontIcon Glyph="&#xE916;" FontSize="20"/>
                                            <TextBlock Text="Focus Time" 
                                                     Style="{StaticResource SubtitleTextBlockStyle}"
                                                     FontWeight="SemiBold"/>
                                        </StackPanel>
                                        <TextBlock x:Name="FocusMinutes"
                                                 Text="0 minutes today"
                                                 Style="{StaticResource TitleTextBlockStyle}"/>
                                        <Button Content="Start Focus Session"
                                               Style="{StaticResource AccentButtonStyle}"
                                               HorizontalAlignment="Stretch"/>
                                    </StackPanel>
                                </Border>

                            </StackPanel>
                        </Grid>

                    </StackPanel>
                </ScrollViewer>
            </Frame>

        </NavigationView>
    </Grid>
</Page>
EOF

# MainPage.xaml.cs
cat > MainPage.xaml.cs << 'EOF'
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using LifeHub.UI.ViewModels;

namespace LifeHub
{
    public sealed partial class MainPage : Page
    {
        public DashboardViewModel ViewModel { get; }

        public MainPage()
        {
            this.InitializeComponent();
            
            // Get ViewModel from DI container (assuming it's registered)
            ViewModel = App.Current.Services.GetService<DashboardViewModel>();
            
            // Load data
            _ = ViewModel.LoadDataAsync();
            
            // Update UI bindings
            ViewModel.PropertyChanged += ViewModel_PropertyChanged;
        }

        private void ViewModel_PropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
        {
            DispatcherQueue.TryEnqueue(() =>
            {
                switch (e.PropertyName)
                {
                    case nameof(ViewModel.Greeting):
                        GreetingText.Text = ViewModel.Greeting;
                        break;
                    case nameof(ViewModel.DailyInsight):
                        if (ViewModel.DailyInsight != null)
                        {
                            InsightText.Text = ViewModel.DailyInsight.Content;
                        }
                        break;
                    case nameof(ViewModel.Weather):
                        if (ViewModel.Weather != null)
                        {
                            Temperature.Text = $"{ViewModel.Weather.Temperature}°F";
                            Condition.Text = ViewModel.Weather.Condition;
                            Location.Text = ViewModel.Weather.Location;
                        }
                        break;
                    case nameof(ViewModel.EmailSummary):
                        if (ViewModel.EmailSummary != null)
                        {
                            EmailCount.Text = $"{ViewModel.EmailSummary.UnreadCount} unread";
                            EmailSummaryText.Text = ViewModel.EmailSummary.Summary;
                        }
                        break;
                    case nameof(ViewModel.TodayFocusMinutes):
                        FocusMinutes.Text = $"{ViewModel.TodayFocusMinutes} minutes today";
                        break;
                }
            });
        }

        private void NavView_SelectionChanged(NavigationView sender, NavigationViewSelectionChangedEventArgs args)
        {
            if (args.SelectedItemContainer != null)
            {
                var tag = args.SelectedItemContainer.Tag?.ToString();
                // TODO: Navigate to different pages based on tag
            }
        }
    }
}
EOF

# ============================================================================
# APP SETUP AND DEPENDENCY INJECTION
# ============================================================================

echo "⚙️  Configuring App.xaml.cs..."

# Update App.xaml.cs with DI
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

namespace LifeHub
{
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
}
EOF

# ============================================================================
# CONVERTERS
# ============================================================================

echo "🔄 Creating Value Converters..."

mkdir -p src/LifeHub.UI/Converters

cat > src/LifeHub.UI/Converters/TimeConverter.cs << 'EOF'
using Microsoft.UI.Xaml.Data;
using System;

namespace LifeHub.UI.Converters
{
    public class TimeConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            if (value is DateTime dateTime)
            {
                return dateTime.ToString("h:mm tt");
            }
            return string.Empty;
        }

        public object ConvertBack(object value, Type targetType, object parameter, string language)
        {
            throw new NotImplementedException();
        }
    }
}
EOF

# ============================================================================
# FINAL BUILD AND RUN
# ============================================================================

echo "🔧 Building project structure..."

# Create project reference file to include all our files
cat > LifeHub.csproj << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFrameworks>net8.0;net8.0-android;net8.0-ios;net8.0-maccatalyst;net8.0-windows10.0.19041.0;net8.0-browserwasm</TargetFrameworks>
    <OutputType>Exe</OutputType>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    
    <SupportedOSPlatformVersion Condition="$([MSBuild]::GetTargetPlatformIdentifier('$(TargetFramework)')) == 'android'">21.0</SupportedOSPlatformVersion>
    <SupportedOSPlatformVersion Condition="$([MSBuild]::GetTargetPlatformIdentifier('$(TargetFramework)')) == 'ios'">14.2</SupportedOSPlatformVersion>
    <SupportedOSPlatformVersion Condition="$([MSBuild]::GetTargetPlatformIdentifier('$(TargetFramework)')) == 'maccatalyst'">14.0</SupportedOSPlatformVersion>
    <SupportedOSPlatformVersion Condition="$([MSBuild]::GetTargetPlatformIdentifier('$(TargetFramework)')) == 'windows'">10.0.19041.0</SupportedOSPlatformVersion>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Uno.WinUI" Version="5.0.0" />
    <PackageReference Include="Microsoft.Extensions.DependencyInjection" Version="8.0.0" />
    <PackageReference Include="Uno.Extensions.Configuration" Version="5.0.0" />
  </ItemGroup>

  <ItemGroup>
    <!-- Core Models -->
    <Compile Include="src/LifeHub.Core/Models/*.cs" />
    <!-- Core Interfaces -->
    <Compile Include="src/LifeHub.Core/Interfaces/*.cs" />
    <!-- Services -->
    <Compile Include="src/LifeHub.Services/**/*.cs" />
    <!-- UI -->
    <Compile Include="src/LifeHub.UI/ViewModels/*.cs" />
    <Compile Include="src/LifeHub.UI/Converters/*.cs" />
  </ItemGroup>
</Project>
EOF

# Create a comprehensive README
cat > README.md << 'EOF'
# 🚀 LifeHub - Your Smart Daily Dashboard

LifeHub is a cross-platform, AI-powered daily dashboard application built with Uno Platform and .NET. It unifies your calendar, tasks, emails, weather, notes, and focus time in one beautiful, privacy-respecting interface.

## ✨ Features

### 📅 Calendar Aggregation
- View today's and upcoming events
- Support for multiple calendar sources (extensible design)
- Clean, timeline-based view

### ✅ Task Management
- Create, edit, and complete tasks
- Priority levels and due dates
- Tag-based organization
- Today/Upcoming/Overdue categorization

### 📧 Email Summary
- AI-powered email digestion
- Unread count and key emails
- Smart summarization of daily inbox

### ⏱️ Focus Timer (Pomodoro)
- Configurable focus sessions
- Short and long breaks
- Daily focus statistics
- Productivity tracking

### 🌤️ Weather Widget
- Current conditions
- 3-day forecast
- Customizable location

### 📝 Quick Notes
- Markdown support
- AI-powered task extraction
- Fast, local-first storage

### 🤖 AI Insights
- Daily productivity summaries
- Smart task suggestions from notes
- Layout personalization recommendations
- Privacy-first AI (local or cloud options)

## 🛠️ Technology Stack

- **Framework**: Uno Platform 5.0
- **Language**: C# / .NET 8.0
- **Pattern**: MVVM
- **DI**: Microsoft.Extensions.DependencyInjection
- **Platforms**: Windows, Android, iOS, macOS, Linux, WebAssembly

## 🏗️ Architecture

```
LifeHub/
├── src/
│   ├── LifeHub.Core/
│   │   ├── Models/          # Domain models
│   │   ├── Interfaces/      # Service abstractions
│   │   └── Services/        # Core business logic
│   ├── LifeHub.Services/    # Service implementations
│   │   ├── Calendar/
│   │   ├── Tasks/
│   │   ├── Email/
│   │   ├── Weather/
│   │   ├── AI/
│   │   ├── Focus/
│   │   └── Notes/
│   └── LifeHub.UI/          # Views and ViewModels
│       ├── ViewModels/
│       ├── Views/
│       ├── Widgets/
│       ├── Converters/
│       └── Resources/
```

## 🚀 Getting Started

### Prerequisites
- .NET 8.0 SDK or later
- Uno Platform templates: `dotnet new install Uno.Templates`

### Run the Application

```bash
# For Windows
dotnet run -f net8.0-windows10.0.19041.0

# For WebAssembly
dotnet run -f net8.0-browserwasm

# For Android
dotnet run -f net8.0-android

# For iOS
dotnet run -f net8.0-ios
```

## 🎨 Design Philosophy

- **Modern & Minimal**: Clean, coffee-shop workspace aesthetic
- **Responsive**: Adapts from mobile to desktop seamlessly
- **Accessible**: High contrast themes, large text support, screen reader friendly
- **Privacy-First**: Local-first data, transparent AI usage

## 🔮 Future Enhancements

- [ ] Google Calendar integration
- [ ] Microsoft Outlook integration
- [ ] Gmail/IMAP email sync
- [ ] Google Tasks / Microsoft To-Do sync
- [ ] On-device LLM integration
- [ ] Cloud LLM options (OpenAI, Gemini)
- [ ] Widget drag-and-drop reordering
- [ ] Custom API widget builder
- [ ] Multi-user profiles
- [ ] Data sync across devices

## 📄 License

MIT License - feel free to use and modify as needed!

## 🤝 Contributing

Contributions welcome! This is a demonstration project showcasing Uno Platform capabilities.

---

Built with ❤️ using Uno Platform
EOF

# Create a simple launcher script
cat > run-lifehub.sh << 'EOF'
#!/bin/bash

echo "🚀 Starting LifeHub..."
echo ""
echo "Choose your platform:"
echo "1) Windows (Desktop)"
echo "2) WebAssembly (Browser)"
echo "3) Android"
echo "4) iOS"
echo ""
read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo "Launching Windows app..."
        dotnet run -f net8.0-windows10.0.19041.0
        ;;
    2)
        echo "Launching WebAssembly app..."
        dotnet run -f net8.0-browserwasm
        ;;
    3)
        echo "Launching Android app..."
        dotnet run -f net8.0-android
        ;;
    4)
        echo "Launching iOS app..."
        dotnet run -f net8.0-ios
        ;;
    *)
        echo "Invalid choice. Running Windows version..."
        dotnet run -f net8.0-windows10.0.19041.0
        ;;
esac
EOF

chmod +x run-lifehub.sh

# Add NuGet config for packages
cat > nuget.config << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
    <add key="uno" value="https://api.nuget.org/v3/index.json" />
  </packageSources>
</configuration>
EOF

echo ""
echo "✅ LifeHub project structure created successfully!"
echo ""
echo "📁 Project Structure:"
echo "   - Core models and interfaces defined"
echo "   - Service implementations with mock data"
echo "   - ViewModels with MVVM pattern"
echo "   - Main dashboard UI with widgets"
echo "   - Dependency injection configured"
echo ""
echo "🎯 Next Steps:"
echo ""
echo "1. Build the project:"
echo "   dotnet restore"
echo "   dotnet build"
echo ""
echo "2. Run the application:"
echo "   ./run-lifehub.sh"
echo "   or"
echo "   dotnet run -f net8.0-windows10.0.19041.0"
echo ""
echo "3. Features ready to use:"
echo "   ✅ Dashboard with AI insights"
echo "   ✅ Calendar widget with today's events"
echo "   ✅ Task management with priorities"
echo "   ✅ Weather widget"
echo "   ✅ Email summary"
echo "   ✅ Focus timer statistics"
echo ""
echo "🔧 Customize by:"
echo "   - Editing mock data in Services/"
echo "   - Adding real API integrations"
echo "   - Customizing themes in App.xaml"
echo "   - Extending AI capabilities in AiEngine.cs"
echo ""
echo "📚 See README.md for full documentation"
echo ""
echo "Happy coding! 🎉"

echo "📝 Creating Core Models..."

# CalendarEvent.cs
cat > src/LifeHub.Core/Models/CalendarEvent.cs << 'EOF'
using System;

namespace LifeHub.Core.Models
{
    /// <summary>
    /// Represents a calendar event from any source
    /// </summary>
    public class CalendarEvent
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string Location { get; set; } = string.Empty;
        public string Source { get; set; } = "Local"; // Google, Outlook, Local
        public string Color { get; set; } = "#4A90E2";
        public bool IsAllDay { get; set; }
        public string? MeetingUrl { get; set; }
    }
}
EOF

# TaskItem.cs
cat > src/LifeHub.Core/Models/TaskItem.cs << 'EOF'
using System;
using System.Collections.Generic;

namespace LifeHub.Core.Models
{
    /// <summary>
    /// Represents a task or to-do item
    /// </summary>
    public class TaskItem
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public DateTime? DueDate { get; set; }
        public bool IsCompleted { get; set; }
        public TaskPriority Priority { get; set; } = TaskPriority.Medium;
        public List<string> Tags { get; set; } = new();
        public string Source { get; set; } = "Local"; // Local, GoogleTasks, MicrosoftToDo
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? CompletedAt { get; set; }
    }

    public enum TaskPriority
    {
        Low,
        Medium,
        High,
        Urgent
    }
}
EOF

# Note.cs
cat > src/LifeHub.Core/Models/Note.cs << 'EOF'
using System;

namespace LifeHub.Core.Models
{
    /// <summary>
    /// Represents a quick note
    /// </summary>
    public class Note
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime ModifiedAt { get; set; } = DateTime.Now;
        public List<string> Tags { get; set; } = new();
    }
}
EOF

# FocusSession.cs
cat > src/LifeHub.Core/Models/FocusSession.cs << 'EOF'
using System;

namespace LifeHub.Core.Models
{
    /// <summary>
    /// Represents a Pomodoro focus session
    /// </summary>
    public class FocusSession
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public DateTime StartTime { get; set; }
        public DateTime? EndTime { get; set; }
        public int DurationMinutes { get; set; }
        public FocusSessionType Type { get; set; }
        public bool WasCompleted { get; set; }
        public string? Note { get; set; }
    }

    public enum FocusSessionType
    {
        Focus,
        ShortBreak,
        LongBreak
    }
}
EOF

# WeatherInfo.cs
cat > src/LifeHub.Core/Models/WeatherInfo.cs << 'EOF'
using System;
using System.Collections.Generic;

namespace LifeHub.Core.Models
{
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
}
EOF

# AiInsight.cs
cat > src/LifeHub.Core/Models/AiInsight.cs << 'EOF'
using System;

namespace LifeHub.Core.Models
{
    public class AiInsight
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public InsightType Type { get; set; }
        public DateTime GeneratedAt { get; set; } = DateTime.Now;
        public string? ActionUrl { get; set; }
    }

    public enum InsightType
    {
        DailySummary,
        ProductivityTip,
        FocusPattern,
        LayoutSuggestion,
        TaskSuggestion
    }
}
EOF

# EmailSummary.cs
cat > src/LifeHub.Core/Models/EmailSummary.cs << 'EOF'
using System;
using System.Collections.Generic;

namespace LifeHub.Core.Models
{
    public class EmailSummary
    {
        public int UnreadCount { get; set; }
        public string Summary { get; set; } = string.Empty;
        public List<EmailItem> KeyEmails { get; set; } = new();
        public DateTime GeneratedAt { get; set; } = DateTime.Now;
    }

    public class EmailItem
    {
        public string From { get; set; } = string.Empty;
        public string Subject { get; set; } = string.Empty;
        public string Snippet { get; set; } = string.Empty;
        public DateTime ReceivedAt { get; set; }
        public bool IsImportant { get; set; }
    }
}
EOF

# Widget.cs
cat > src/LifeHub.Core/Models/Widget.cs << 'EOF'
namespace LifeHub.Core.Models
{
    public class Widget
    {
        public string Id { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public bool IsVisible { get; set; } = true;
        public int Order { get; set; }
        public WidgetSize Size { get; set; } = WidgetSize.Medium;
    }

    public enum WidgetSize
    {
        Small,
        Medium,
        Large
    }
}
EOF

# ============================================================================
# INTERFACES
# ============================================================================

echo "🔌 Creating Service Interfaces..."

# ICalendarService.cs
cat > src/LifeHub.Core/Interfaces/ICalendarService.cs << 'EOF'
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces
{
    public interface ICalendarService
    {
        Task<IList<CalendarEvent>> GetEventsAsync(DateTime from, DateTime to, CancellationToken ct = default);
        Task<CalendarEvent> CreateEventAsync(CalendarEvent calendarEvent, CancellationToken ct = default);
        Task<CalendarEvent> UpdateEventAsync(CalendarEvent calendarEvent, CancellationToken ct = default);
        Task DeleteEventAsync(string eventId, CancellationToken ct = default);
    }
}
EOF

# ITaskService.cs
cat > src/LifeHub.Core/Interfaces/ITaskService.cs << 'EOF'
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces
{
    public interface ITaskService
    {
        Task<IList<TaskItem>> GetAllTasksAsync(CancellationToken ct = default);
        Task<TaskItem> CreateTaskAsync(TaskItem task, CancellationToken ct = default);
        Task<TaskItem> UpdateTaskAsync(TaskItem task, CancellationToken ct = default);
        Task DeleteTaskAsync(string taskId, CancellationToken ct = default);
        Task<TaskItem> ToggleCompleteAsync(string taskId, CancellationToken ct = default);
    }
}
EOF

# IEmailSummaryService.cs
cat > src/LifeHub.Core/Interfaces/IEmailSummaryService.cs << 'EOF'
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces
{
    public interface IEmailSummaryService
    {
        Task<EmailSummary> GetEmailSummaryAsync(CancellationToken ct = default);
    }
}
EOF

# IWeatherService.cs
cat > src/LifeHub.Core/Interfaces/IWeatherService.cs << 'EOF'
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces
{
    public interface IWeatherService
    {
        Task<WeatherInfo> GetWeatherAsync(string location, CancellationToken ct = default);
    }
}
EOF

# IFocusService.cs
cat > src/LifeHub.Core/Interfaces/IFocusService.cs << 'EOF'
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces
{
    public interface IFocusService
    {
        Task<FocusSession> StartSessionAsync(FocusSessionType type, int durationMinutes, CancellationToken ct = default);
        Task<FocusSession> EndSessionAsync(string sessionId, bool completed, CancellationToken ct = default);
        Task<IList<FocusSession>> GetSessionsAsync(DateTime from, DateTime to, CancellationToken ct = default);
        Task<int> GetTodayFocusMinutesAsync(CancellationToken ct = default);
    }
}
EOF

# INoteService.cs
cat > src/LifeHub.Core/Interfaces/INoteService.cs << 'EOF'
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces
{
    public interface INoteService
    {
        Task<IList<Note>> GetAllNotesAsync(CancellationToken ct = default);
        Task<Note> CreateNoteAsync(Note note, CancellationToken ct = default);
        Task<Note> UpdateNoteAsync(Note note, CancellationToken ct = default);
        Task DeleteNoteAsync(string noteId, CancellationToken ct = default);
    }
}
EOF

# IAiEngine.cs
cat > src/LifeHub.Core/Interfaces/IAiEngine.cs << 'EOF'
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces
{
    public interface IAiEngine
    {
        Task<string> SummarizeTextAsync(string text, CancellationToken ct = default);
        Task<AiInsight> GenerateDailySummaryAsync(CancellationToken ct = default);
        Task<IList<TaskItem>> ExtractTasksFromTextAsync(string text, CancellationToken ct = default);
        Task<IList<Widget>> SuggestLayoutAsync(CancellationToken ct = default);
    }
}
EOF

# ============================================================================
# SERVICE IMPLEMENTATIONS
# ============================================================================

echo "⚙️  Creating Service Implementations..."

# CalendarService.cs
cat > src/LifeHub.Services/Calendar/CalendarService.cs << 'EOF'
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.Services.Calendar
{
    /// <summary>
    /// Local calendar service with mock data
    /// TODO: Add Google Calendar integration
    /// TODO: Add Outlook integration
    /// </summary>
    public class CalendarService : ICalendarService
    {
        private readonly List<CalendarEvent> _events = new();

        public CalendarService()
        {
            SeedMockData();
        }

        public Task<IList<CalendarEvent>> GetEventsAsync(DateTime from, DateTime to, CancellationToken ct = default)
        {
            var events = _events
                .Where(e => e.StartTime >= from && e.StartTime <= to)
                .OrderBy(e => e.StartTime)
                .ToList();
            return Task.FromResult<IList<CalendarEvent>>(events);
        }

        public Task<CalendarEvent> CreateEventAsync(CalendarEvent calendarEvent, CancellationToken ct = default)
        {
            _events.Add(calendarEvent);
            return Task.FromResult(calendarEvent);
        }

        public Task<CalendarEvent> UpdateEventAsync(CalendarEvent calendarEvent, CancellationToken ct = default)
        {
            var existing = _events.FirstOrDefault(e => e.Id == calendarEvent.Id);
            if (existing != null)
            {
                _events.Remove(existing);
                _events.Add(calendarEvent);
            }
            return Task.FromResult(calendarEvent);
        }

        public Task DeleteEventAsync(string eventId, CancellationToken ct = default)
        {
            var existing = _events.FirstOrDefault(e => e.Id == eventId);
            if (existing != null)
            {
                _events.Remove(existing);
            }
            return Task.CompletedTask;
        }

        private void SeedMockData()
        {
            var today = DateTime.Today;
            _events.AddRange(new[]
            {
                new CalendarEvent
                {
                    Title = "Team Standup",
                    Description = "Daily sync with the team",
                    StartTime = today.AddHours(9),
                    EndTime = today.AddHours(9.5),
                    Color = "#4A90E2",
                    MeetingUrl = "https://meet.example.com/standup"
                },
                new CalendarEvent
                {
                    Title = "Client Presentation",
                    Description = "Q4 results presentation",
                    StartTime = today.AddHours(14),
                    EndTime = today.AddHours(15),
                    Color = "#E94B3C",
                    Location = "Conference Room A"
                },
                new CalendarEvent
                {
                    Title = "Lunch with Sarah",
                    StartTime = today.AddHours(12),
                    EndTime = today.AddHours(13),
                    Color = "#50C878",
                    Location = "Café Downtown"
                },
                new CalendarEvent
                {
                    Title = "Code Review",
                    StartTime = today.AddDays(1).AddHours(10),
                    EndTime = today.AddDays(1).AddHours(11),
                    Color = "#9B59B6"
                },
                new CalendarEvent
                {
                    Title = "Dentist Appointment",
                    StartTime = today.AddDays(2).AddHours(16),
                    EndTime = today.AddDays(2).AddHours(17),
                    Color = "#F39C12",
                    Location = "Downtown Dental Clinic"
                }
            });
        }
    }
}
EOF

# TaskService.cs
cat > src/LifeHub.Services/Tasks/TaskService.cs << 'EOF'
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.Services.Tasks
{
    /// <summary>
    /// Local task service with mock data
    /// TODO: Add Google Tasks integration
    /// TODO: Add Microsoft To-Do integration
    /// </summary>
    public class TaskService : ITaskService
    {
        private readonly List<TaskItem> _tasks = new();

        public TaskService()
        {
            SeedMockData();
        }

        public Task<IList<TaskItem>> GetAllTasksAsync(CancellationToken ct = default)
        {
            return Task.FromResult<IList<TaskItem>>(_tasks.OrderBy(t => t.DueDate).ToList());
        }

        public Task<TaskItem> CreateTaskAsync(TaskItem task, CancellationToken ct = default)
        {
            _tasks.Add(task);
            return Task.FromResult(task);
        }

        public Task<TaskItem> UpdateTaskAsync(TaskItem task, CancellationToken ct = default)
        {
            var existing = _tasks.FirstOrDefault(t => t.Id == task.Id);
            if (existing != null)
            {
                _tasks.Remove(existing);
                _tasks.Add(task);
            }
            return Task.FromResult(task);
        }

        public Task DeleteTaskAsync(string taskId, CancellationToken ct = default)
        {
            var existing = _tasks.FirstOrDefault(t => t.Id == taskId);
            if (existing != null)
            {
                _tasks.Remove(existing);
            }
            return Task.CompletedTask;
        }

        public Task<TaskItem> ToggleCompleteAsync(string taskId, CancellationToken ct = default)
        {
            var task = _tasks.FirstOrDefault(t => t.Id == taskId);
            if (task != null)
            {
                task.IsCompleted = !task.IsCompleted;
                task.CompletedAt = task.IsCompleted ? DateTime.Now : null;
            }
            return Task.FromResult(task!);
        }

        private void SeedMockData()
        {
            var today = DateTime.Today;
            _tasks.AddRange(new[]
            {
                new TaskItem
                {
                    Title = "Review pull request #234",
                    Priority = TaskPriority.High,
                    DueDate = today,
                    Tags = new List<string> { "development", "urgent" }
                },
                new TaskItem
                {
                    Title = "Update project documentation",
                    Priority = TaskPriority.Medium,
                    DueDate = today,
                    Tags = new List<string> { "documentation" }
                },
                new TaskItem
                {
                    Title = "Schedule team meeting",
                    Priority = TaskPriority.Low,
                    DueDate = today.AddDays(1),
                    Tags = new List<string> { "management" }
                },
                new TaskItem
                {
                    Title = "Fix authentication bug",
                    Description = "Users reporting login issues on mobile",
                    Priority = TaskPriority.Urgent,
                    DueDate = today,
                    Tags = new List<string> { "bug", "urgent" }
                },
                new TaskItem
                {
                    Title = "Prepare presentation slides",
                    Priority = TaskPriority.High,
                    DueDate = today.AddDays(2),
                    Tags = new List<string> { "presentation" }
                },
                new TaskItem
                {
                    Title = "Buy groceries",
                    Priority = TaskPriority.Low,
                    Tags = new List<string> { "personal" },
                    IsCompleted = true,
                    CompletedAt = today.AddDays(-1)
                }
            });
        }
    }
}
EOF

# EmailSummaryService.cs
cat > src/LifeHub.Services/Email/EmailSummaryService.cs << 'EOF'
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.Services.Email
{
    /// <summary>
    /// Email summary service with mock data
    /// TODO: Add IMAP integration
    /// TODO: Add OAuth for Gmail/Outlook
    /// </summary>
    public class EmailSummaryService : IEmailSummaryService
    {
        private readonly IAiEngine _aiEngine;

        public EmailSummaryService(IAiEngine aiEngine)
        {
            _aiEngine = aiEngine;
        }

        public async Task<EmailSummary> GetEmailSummaryAsync(CancellationToken ct = default)
        {
            // Mock email data
            var emails = new List<EmailItem>
            {
                new EmailItem
                {
                    From = "team@company.com",
                    Subject = "Q4 Planning Meeting Scheduled",
                    Snippet = "The Q4 planning meeting has been scheduled for next Tuesday at 2 PM...",
                    ReceivedAt = DateTime.Now.AddHours(-2),
                    IsImportant = true
                },
                new EmailItem
                {
                    From = "client@example.com",
                    Subject = "Project Update Request",
                    Snippet = "Hi, could you provide an update on the current project status?",
                    ReceivedAt = DateTime.Now.AddHours(-5),
                    IsImportant = true
                },
                new EmailItem
                {
                    From = "newsletter@tech.com",
                    Subject = "Weekly Tech Digest",
                    Snippet = "This week's top stories in technology...",
                    ReceivedAt = DateTime.Now.AddHours(-8),
                    IsImportant = false
                }
            };

            var emailText = string.Join("\n", emails.ConvertAll(e => $"{e.From}: {e.Subject}"));
            var summary = await _aiEngine.SummarizeTextAsync(emailText, ct);

            return new EmailSummary
            {
                UnreadCount = 12,
                Summary = summary,
                KeyEmails = emails,
                GeneratedAt = DateTime.Now
            };
        }
    }
}
EOF

# WeatherService.cs
cat > src/LifeHub.Services/Weather/WeatherService.cs << 'EOF'
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.Services.Weather
{
    /// <summary>
    /// Weather service with mock data
    /// TODO: Integrate with OpenWeatherMap or similar API
    /// </summary>
    public class WeatherService : IWeatherService
    {
        public Task<WeatherInfo> GetWeatherAsync(string location, CancellationToken ct = default)
        {
            // Mock weather data
            var random = new Random();
            var weather = new WeatherInfo
            {
                Location = location,
                Temperature = 72 + random.Next(-10, 10),
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
                        Condition = "Sunny",
                        IconCode = "sunny"
                    },
                    new WeatherForecast
                    {
                        Date = DateTime.Today.AddDays(2),
                        TempHigh = 68,
                        TempLow = 52,
                        Condition = "Rainy",
                        IconCode = "rainy"
                    },
                    new WeatherForecast
                    {
                        Date = DateTime.Today.AddDays(3),
                        TempHigh = 71,
                        TempLow = 55,
                        Condition = "Partly Cloudy",
                        IconCode = "partly-cloudy"
                    }
                }
            };

            return Task.FromResult(weather);
        }
    }
}
EOF

# FocusService.cs
cat > src/LifeHub.Services/Focus/FocusService.cs << 'EOF'
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.Services.Focus
{
    public class FocusService : IFocusService
    {
        private readonly List<FocusSession> _sessions = new();

        public Task<FocusSession> StartSessionAsync(FocusSessionType type, int durationMinutes, CancellationToken ct = default)
        {
            var session = new FocusSession
            {
                StartTime = DateTime.Now,
                DurationMinutes = durationMinutes,
                Type = type
            };
            _sessions.Add(session);
            return Task.FromResult(session);
        }

        public Task<FocusSession> EndSessionAsync(string sessionId, bool completed, CancellationToken ct = default)
        {
            var session = _sessions.FirstOrDefault(s => s.Id == sessionId);
            if (session != null)
            {
                session.EndTime = DateTime.Now;
                session.WasCompleted = completed;
            }
            return Task.FromResult(session!);
        }

        public Task<IList<FocusSession>> GetSessionsAsync(DateTime from, DateTime to, CancellationToken ct = default)
        {
            var sessions = _sessions
                .Where(s => s.StartTime >= from && s.StartTime <= to)
                .OrderByDescending(s => s.StartTime)
                .ToList();
            return Task.FromResult<IList<FocusSession>>(sessions);
        }

        public async Task<int> GetTodayFocusMinutesAsync(CancellationToken ct = default)
        {
            var today = DateTime.Today;
            var sessions = await GetSessionsAsync(today, today.AddDays(1), ct);
            return sessions
                .Where(s => s.Type == FocusSessionType.Focus && s.WasCompleted)
                .Sum(s => s.DurationMinutes);
        }
    }
}
EOF

# NoteService.cs
cat > src/LifeHub.Services/Notes/NoteService.cs << 'EOF'
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.Services.Notes
{
    public class NoteService : INoteService
    {
        private readonly List<Note> _notes = new();

        public NoteService()
        {
            SeedMockData();
        }

        public Task<IList<Note>> GetAllNotesAsync(CancellationToken ct = default)
        {
            return Task.FromResult<IList<Note>>(_notes.OrderByDescending(n => n.ModifiedAt).ToList());
        }

        public Task<Note> CreateNoteAsync(Note note, CancellationToken ct = default)
        {
            _notes.Add(note);
            return Task.FromResult(note);
        }

        public Task<Note> UpdateNoteAsync(Note note, CancellationToken ct = default)
        {
            var existing = _notes.FirstOrDefault(n => n.Id == note.Id);
            if (existing != null)
            {
                _notes.Remove(existing);
                note.ModifiedAt = DateTime.Now;
                _notes.Add(note);
            }
            return Task.FromResult(note);
        }

        public Task DeleteNoteAsync(string noteId, CancellationToken ct = default)
        {
            var existing = _notes.FirstOrDefault(n => n.Id == noteId);
            if (existing != null)
            {
                _notes.Remove(existing);
            }
            return Task.CompletedTask;
        }

        private void SeedMockData()
        {
            _notes.AddRange(new[]
            {
                new Note
                {
                    Title = "Project Ideas",
                    Content = "1. Build a personal dashboard\n2. Create a habit tracker\n3. Design a meal planner",
                    Tags = new List<string> { "ideas", "projects" }
                },
                new Note
                {
                    Title = "Meeting Notes - Jan 15",
                    Content = "Discussed Q1 goals:\n- Launch new feature\n- Improve performance\n- Meet with Samarth next Friday",
                    Tags = new List<string> { "meeting", "work" }
                }
            });
        }
    }
}
EOF

# AiEngine.cs
cat > src/LifeHub.Services/AI/AiEngine.cs << 'EOF'
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.Services.AI
{
    /// <summary>
    /// Mock AI engine for demonstration
    /// TODO: Integrate with on-device LLM (Gemini Nano, etc.)
    /// TODO: Add cloud LLM option (OpenAI, Gemini, etc.)
    /// </summary>
    public class AiEngine : IAiEngine
    {
        private readonly ITaskService _taskService;
        private readonly ICalendarService _calendarService;
        private readonly IFocusService _focusService;

        public AiEngine(ITaskService taskService, ICalendarService calendarService, IFocusService focusService)
        {
            _taskService = taskService;
            _calendarService = calendarService;
            _focusService = focusService;
        }

        public Task<string> SummarizeTextAsync(string text, CancellationToken ct = default)
        {
            // Mock summarization
            var lines = text.Split('\n').Take(3);
            var summary = $"You have important updates from {lines.Count()} sources. Key topics include meetings, project updates, and newsletters.";
            return Task.FromResult(summary);
        }

        public async Task<AiInsight> GenerateDailySummaryAsync(CancellationToken ct = default)
        {
            var today = DateTime.Today;
            var events = await _calendarService.GetEventsAsync(today, today.AddDays(1), ct);
            var tasks = await _taskService.GetAllTasksAsync(ct);
            var todayTasks = tasks.Where(t => t.DueDate?.Date == today && !t.IsCompleted).Count();
            var focusMinutes = await _focusService.GetTodayFocusMinutesAsync(ct);

            var summary = $"Today you have {events.Count} events scheduled and {todayTasks} tasks to complete. ";
            
            if (focusMinutes > 0)
            {
                summary += $"You've focused for {focusMinutes} minutes so far. ";
            }

            if (focusMinutes < 120)
            {
                summary += "Consider scheduling a longer focus session this afternoon to boost productivity.";
            }
            else
            {
                summary += "Great focus today! Keep up the momentum.";
            }

            return new AiInsight
            {
                Title = "Daily Summary",
                Content = summary,
                Type = InsightType.DailySummary
            };
        }

        public Task<IList<TaskItem>> ExtractTasksFromTextAsync(string text, CancellationToken ct = default)
        {
            var tasks = new List<TaskItem>();

            // Simple pattern matching for demo
            if (text.ToLower().Contains("meet") && text.ToLower().Contains("friday"))
            {
                tasks.Add(new TaskItem
                {
                    Title = "Meeting extracted from note",
                    Description = "Mentioned: " + text.Split('\n').FirstOrDefault(l => l.ToLower().Contains("meet")),
                    DueDate = GetNextFriday()
                });
            }

            // Look for numbered lists
            var lines = text.Split('\n');
            foreach (var line in lines)
            {
                if (System.Text.RegularExpressions.Regex.IsMatch(line.Trim(), @"^\d+\.\s+.+"))
                {
                    var taskTitle = System.Text.RegularExpressions.Regex.Replace(line.Trim(), @"^\d+\.\s+", "");
                    if (!string.IsNullOrWhiteSpace(taskTitle))
                    {
                        tasks.Add(new TaskItem { Title = taskTitle });
                    }
                }
            }

            return Task.FromResult<IList<TaskItem>>(tasks);
        }

        public Task<IList<Widget>> SuggestLayoutAsync(CancellationToken ct = default)
        {
            // Mock layout suggestions based on time of day
            var hour = DateTime.Now.Hour;
            var widgets = new List<Widget>();

            if (hour < 12)
            {
                // Morning: prioritize calendar and tasks
                widgets.Add(new Widget { Id = "calendar", Type = "Calendar", Title = "Today's Events", Order = 1, Size = WidgetSize.Large });
                widgets.Add(new Widget { Id = "tasks", Type = "Tasks", Title = "Tasks", Order = 2, Size = WidgetSize.Medium });
                widgets.Add(new Widget { Id = "weather", Type = "Weather", Title = "Weather", Order = 3, Size = WidgetSize.Small });
            }
            else
            {
                // Afternoon: prioritize focus and tasks
                widgets.Add(new Widget { Id = "focus", Type = "Focus", Title = "Focus Timer", Order = 1, Size = WidgetSize.Large });
                widgets.Add(new Widget { Id = "tasks", Type = "Tasks", Title = "Tasks", Order = 2, Size = WidgetSize.Medium });
                widgets.Add(new Widget { Id = "calendar", Type = "Calendar", Title = "Upcoming", Order = 3, Size = WidgetSize.Small });
            }

            return Task.FromResult<IList<Widget>>(widgets);
        }

        private DateTime GetNextFriday()
        {
            var today = DateTime.Today;
            var daysUntilFriday = ((int)DayOfWeek.Friday - (int)today.DayOfWeek + 7) % 7;
            if (daysUntilFriday == 0) daysUntilFriday = 7;
            return today.AddDays(daysUntilFriday);
        }
    }
}
EOF