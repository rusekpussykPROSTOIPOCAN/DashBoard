using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using DashBoard.Lib.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using System.Text.Json;

namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api/autocomplete-robots")]
    public class RobotsController : BaseController
    {
        public RobotsController(dashboardContext dashboard) : base(dashboard)
        {
        }
        [HttpGet]
        public async Task<IActionResult> GetDetails(string? search)
        {
            var query = _dashboard.robots.AsQueryable();
            if (!string.IsNullOrWhiteSpace(search))
            {
                query = query.Where(x => EF.Functions.ILike(x.name, $"%{search}%"));
            }
          var result  = await query.OrderBy(x=>x.name).Select(x=> new RobotDto
          {
              Id = x.id,
              Name = x.name
          }).ToListAsync();
            return Ok(result);
        }
    }
   


}
