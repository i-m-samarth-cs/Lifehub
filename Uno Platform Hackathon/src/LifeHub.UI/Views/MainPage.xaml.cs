using Windows.UI.Xaml.Controls;
using LifeHub.UI.ViewModels;

namespace LifeHub.UI.Views
{
    public sealed partial class MainPage : Page
    {
        public MainPage()
        {
            this.InitializeComponent();
            this.DataContext = new DashboardViewModel();
        }
    }
}
