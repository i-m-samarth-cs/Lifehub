namespace LifeHub.Core.Models;

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
