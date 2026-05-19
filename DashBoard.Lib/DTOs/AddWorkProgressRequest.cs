using System.Text.Json.Serialization;

namespace DashBoard.Lib.DTOs
{


    public class WorkProgressListItem
    {
        public int Id { get; set; }
        public string SourseName { get; set; } = "";
        public int AllPerimeter { get; set; }
        public int CompletePerimeter { get; set; }
        public DateTime CreateAt { get; set; }
        public string? CreatedByUser { get; set; }
    }

    public class ArticleDto
    {
        [JsonPropertyName("id")]
        public int Id { get; set; }

        [JsonPropertyName("article1")]
        public string? Article1 { get; set; }
    }

    public class SourceDto
    {
        [JsonPropertyName("id")]
        public int Id { get; set; }

        [JsonPropertyName("source")]
        public string? Source { get; set; }
    }
    public class AddWorkProgressRequest
    {
        public int IdSourse { get; set; }
        public string? CustomSourceName { get; set; }
        public int AllPerimeter { get; set; }
        public int CompletePerimeter { get; set; }
        public int RemainedPerimeter { get; set; }
        public string? Comment { get; set; }
        public string? UserId { get; set; }
        public List<ViolationRequest> Violations { get; set; } = new();
    }

    public class ViolationRequest
    {
        public int IdArticle { get; set; }
        public string? CustomArticleName { get; set; }
        public int ViolationsWeek { get; set; }
        public int NewViolations { get; set; }
        public int OldViolations { get; set; }
    }

    public class AddWorkProgressResult
    {
        public int id { get; set; }
        public string message { get; set; }
        public int violations_count { get; set; }
    }
    public class ViolationItem
    {
        public int IdArticle { get; set; }
        public int? ViolationsWeek { get; set; }
        public int? NewViolations { get; set; }
        public int? OldViolations { get; set; }
    }
    
    public class EditWorkProgressRequest
    {
        public int Id { get; set; }
        public int IdSourse { get; set; }
        public int AllPerimeter { get; set; }
        public int CompletePerimeter { get; set; }
        public int RemainedPerimeter { get; set; }
        public string? Comment { get; set; }
        public string? UserId { get; set; }
        public List<ViolationRequest> Violations { get; set; } = new();
    }
    public class WorkProgressResponce  
    {
        public int Id { get; set; }
        public int IdSourse { get; set; }
        public string SourseName { get; set; }
        public int AllPerimeter { get; set; }
        public int CompletePerimeter { get; set; }
        public int RemainedPerimeter { get; set; }
        public string? Comment { get; set; }
        public DateTime CreateAt { get; set; }
        public List<ViolationsResponse> Violations { get; set; }
    }

    public class ViolationsResponse  
    {
        [JsonPropertyName("id")]
        public int Id { get; set; }

        [JsonPropertyName("idArticle")]
        public int IdArticle { get; set; }

        [JsonPropertyName("articleName")]
        public string ArticleName { get; set; } = "";

        [JsonPropertyName("violationsWeek")]
        public int ViolationsWeek { get; set; }

        [JsonPropertyName("newViolations")]
        public int NewViolations { get; set; }

        [JsonPropertyName("oldViolations")]
        public int OldViolations { get; set; }
    }


}
