using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace LifeHub.Core.Interfaces
{
    /// <summary>
    /// Abstraction for custom JSON feeds (news, finance, etc.).
    /// </summary>
    public interface ICustomFeedService
    {
        Task<IList<CustomFeedItem>> FetchAsync(string feedUrl, CancellationToken ct = default);
    }

    public sealed class CustomFeedItem
    {
        public string Id { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string? Summary { get; set; }
        public string? Url { get; set; }
        public string? Source { get; set; }
        public System.DateTimeOffset? Published { get; set; }
    }
}
