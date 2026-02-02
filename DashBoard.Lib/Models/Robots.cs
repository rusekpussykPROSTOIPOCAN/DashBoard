using System.ComponentModel.DataAnnotations;

namespace DashBoard.Lib.Models
{
    public class Robots
    {
        [Key]
        public int Id { get; set; }
        [Required]
        [MaxLength(100)]
        public string? RobotName { get; set; }
        
        public int Id_field { get; set; }

        public virtual ICollection<Field> Fields { get; set; } =new List<Field>();
    }
}
