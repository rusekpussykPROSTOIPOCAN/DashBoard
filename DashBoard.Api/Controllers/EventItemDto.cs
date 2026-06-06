namespace DashBoard.Api.Controllers
{
    internal class EventItemDto
    {
        public object UserName { get; set; }
        public string Action { get; set; }
        public string Description { get; set; }
        public DateTime? CreatedAt { get; set; }
    }
}