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
