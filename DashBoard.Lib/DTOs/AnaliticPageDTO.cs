using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace DashBoard.Lib.DTOs
{
    public class AnaliticPageDTO
    {
        [JsonPropertyName("perimeter_by_source")]
        public List<PerimeterBySourceDto> PerimeterBySource { get; set; } = new();
        [JsonPropertyName("daily_stats")]
        public List<DailyStatsDto> DailyStats { get; set; } = new();
        [JsonPropertyName("violations")]
        public List<ViolationDto> Violations { get; set; } = new();
    }
    public class PerimeterBySourceDto
    {
        [JsonPropertyName("source")]
        public string Source { get; set; } = string.Empty;
        [JsonPropertyName("sum")]
        public decimal Sum { get; set; }
    }
    public class DailyStatsDto
    {
        [JsonPropertyName("date")]
        public DateTime? Date { get; set; }

        [JsonPropertyName("all_perimeter")]
        public decimal AllPerimeter { get; set; }

        [JsonPropertyName("complete_perimeter")]
        public decimal CompletePerimeter { get; set; }

        [JsonPropertyName("remained_perimeter")]
        public decimal RemainedPerimeter { get; set; }
    }
    public class ViolationDto
    {
        [JsonPropertyName("article")]
        public string Article { get; set; } = string.Empty;

        [JsonPropertyName("object_a_week")]
        public decimal ObjectAWeek { get; set; }

        [JsonPropertyName("new_violations")]
        public decimal NewViolations { get; set; }

        [JsonPropertyName("old_violations")]
        public decimal OldViolations { get; set; }
    }
    public class PeriodFilterDto
    {
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }
        public int? Year { get; set; }
        public int? Month { get; set; }
        public int? Quarter { get; set; }
    }
    
    public class JsonResultDto
    {
        public string Data { get; set; }
    }
}

