using System.ComponentModel.DataAnnotations;

namespace DashBoard.Lib.Models
{
    public class Violation
    {
        [Key]
        public int Id { get; set; }
        [Required]
        [MaxLength(100)]
        public string? ViolationName { get; set; }
    }
}
