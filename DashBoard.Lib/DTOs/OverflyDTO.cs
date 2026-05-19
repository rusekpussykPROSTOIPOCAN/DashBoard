using System.Text.Json.Serialization;

namespace DashBoard.Lib.DTOs
{
    public class OverflyDTO
    {
        public double CountStatus { get; set; }
        public List<OverflyDates> OverflyDates { get; set; } = new();
        public List<OverflyStatusCount> overflyStatusCounts { get; set; } = new();
        public List<OverflyByDistricts> overflyByDistricts { get; set; } = new();
    }

    public class OverflyByDistricts
    {
        public string DistrictName { get; set; } = string.Empty;
        public int Count { get; set; }
    }

    public class OverflyStatusCount
    {
        public string StatusName { get; set; } = string.Empty;
        public int Count { get; set; }
    }

    public class OverflyDates
    {
        public double Count { get; set; }
        public DateOnly dateFly { get; set; }
        public int? Year { get; set; }
        public int? Quarter { get; set; }
        public int? Month { get; set; }
    }

    public class OverflySimpleDTO
    {
        public double TotalCount { get; set; }
        public List<OverflyDates> overflyDates { get; set; } = new();
    }

    public class OverflyBlock2Item
    {
        public int Id { get; set; }
        public int? IdStatus { get; set; }
        public string StatusName { get; set; } = "";
        public int? IdAddress { get; set; }
        public string AddressName { get; set; } = "";
        public int? IdDistrict { get; set; }
        public string DistrictName { get; set; } = "";
        public double? Square { get; set; }
        public DateOnly? DateGetMaterials { get; set; }
        public string? UserId { get; set; }

        [JsonIgnore]
        public DateTime? DateGetMaterialsDateTime
        {
            get => DateGetMaterials?.ToDateTime(TimeOnly.MinValue);
            set => DateGetMaterials = value.HasValue ? DateOnly.FromDateTime(value.Value) : null;
        }
    }
    public class OverflyBlock1Request
    {
        public int? IdDistrict { get; set; }
        public int? IdAddress { get; set; }
        public string? UserId { get; set; }
        public string? ViolationName { get; set; }
        public int? QuantityNewViolation { get; set; }
        public int? IdViolation { get; set; }
        public DateOnly? DateDetection { get; set; }
    }
    public class OverflyBlock1Item
    {
        public int Id { get; set; }
        public int? IdDistrict { get; set; }
        public string? UserId { get; set; }
        public string DistrictName { get; set; } = "";
        public int? IdAddress { get; set; }
        public int? QuantityNewViolation { get; set; }
        public int? IdViolation { get; set; }
        public string ViolationName { get; set; } = "";
        public DateOnly? DateDetection { get; set; }

        [JsonIgnore]
        public DateTime? DateDetectionDateTime
        {
            get => DateDetection?.ToDateTime(TimeOnly.MinValue);
            set => DateDetection = value.HasValue ? DateOnly.FromDateTime(value.Value) : null;
        }
    }

    public class SelectItem
    {
        public int Id { get; set; }
        public string Name { get; set; } = "";
    }
    public class OverflyBlock2Request
    {
        public int? IdStatus { get; set; }
        public int? IdAddress { get; set; }
        public string? UserId { get; set; }
        public string? AddressName { get; set; }
        public int? IdDistrict { get; set; }
        public double? Square { get; set; }
        public DateOnly? DateGetMaterials { get; set; }
    }
}