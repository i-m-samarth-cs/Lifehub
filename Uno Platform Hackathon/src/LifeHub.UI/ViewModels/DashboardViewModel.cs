using System.Collections.ObjectModel;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.UI.ViewModels
{
    public class DashboardViewModel
    {
        public ObservableCollection<string> Widgets { get; } = new();

        public DashboardViewModel()
        {
            Widgets.Add("Calendar");
            Widgets.Add("Tasks");
            Widgets.Add("FocusTimer");
            Widgets.Add("Weather");
            Widgets.Add("Notes");
        }

        // Example method to load widget content via services (expand later)
        public async Task<string> GetEmailSummaryAsync(IEmailSummaryService emailService)
        {
            var sample = new[] { "Meeting at 10", "Invoice due", "Welcome aboard" };
            return await emailService.SummarizeEmailsAsync(sample);
        }
    }
}
