using DashBoard.Api.Service;
using DashBoard.Api.Services;
using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using DashBoard.Lib.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api/robot-add")]
    public class AddRobot : BaseController
    {
        public AddRobot(dashboardContext dashboard) : base(dashboard)
        {
        }

        [HttpPost("upload-robots")]
        public async Task<IActionResult> UploadRobots(
    IFormFile file,
    [FromServices] ExcelInputService importService)
        {
            if (file == null || file.Length == 0)
                return BadRequest("Файл не выбран");

            try
            {
                using var stream = file.OpenReadStream();
                var rows = importService.ParseExcel(stream);

                var imported = 0;
                var errors = new List<string>();

                var groups = rows
                    .GroupBy(r => new
                    {
                        Robot = r.GetValueOrDefault("Робот", ""),
                        Date = r.GetValueOrDefault("Дата", "")
                    })
                    .ToList();

                foreach (var group in groups)
                {
                    try
                    {
                        var robotName = group.Key.Robot;
                        var dateStr = group.Key.Date;

                        if (string.IsNullOrWhiteSpace(robotName) || string.IsNullOrWhiteSpace(dateStr))
                            continue;

                        var robot = await _dashboard.robots
                            .FirstOrDefaultAsync(r => r.name.ToLower() == robotName.ToLower());

                        if (robot == null)
                        {
                            robot = new robot
                            {
                                name = robotName,
                                short_name = group.First().GetValueOrDefault("Короткое название", robotName)
                            };
                            _dashboard.robots.Add(robot);
                            await _dashboard.SaveChangesAsync();
                        }

                        if (!DateOnly.TryParse(dateStr, out var date))
                        {
                            if (DateTime.TryParse(dateStr, out var dt))
                                date = DateOnly.FromDateTime(dt);
                            else continue;
                        }

                        var countAppStr = group.First().GetValueOrDefault("Количество заявок", "0");
                        int? countApplications = int.TryParse(countAppStr, out int ca) ? ca : null;

                        
                        var blocks = new Dictionary<string, object>();

                        var blockGroups = group
                            .Where(r => !string.IsNullOrWhiteSpace(r.GetValueOrDefault("Название блока", "")))
                            .GroupBy(r => r.GetValueOrDefault("Название блока", ""));

                        foreach (var blockGroup in blockGroups)
                        {
                            var blockName = blockGroup.Key;
                            var details = new Dictionary<string, int>();
                            int sum = 0;

                            foreach (var row in blockGroup)
                            {
                                var key = row.GetValueOrDefault("Деталь", "");
                                var valueStr = row.GetValueOrDefault("Значение детали", "0");

                                if (string.IsNullOrWhiteSpace(key)) continue;
                                if (key == "Сумма") continue; 

                                if (int.TryParse(valueStr, out int value))
                                {
                                    details[key] = value;
                                    sum += value;
                                }
                            }

                            
                            var sumRow = blockGroup.FirstOrDefault(r => r.GetValueOrDefault("Значение детали", "") == "Сумма");
                            if (sumRow != null && int.TryParse(sumRow.GetValueOrDefault("Значение детали", "0"), out int totalSum))
                                sum = totalSum;

                            if (details.Any())
                            {
                                blocks[blockName] = new
                                {
                                    type = details.Count > 5 ? "Bar" : "Pie",
                                    сумма = sum,
                                    детали = details
                                };
                            }
                        }

                        if (!blocks.Any()) continue;

                        var json = JsonSerializer.Serialize(blocks);

                        var existing = await _dashboard.robots_analitics
                            .FirstOrDefaultAsync(ra => ra.idrobots == robot.id && ra.datestatistic == date);

                        if (existing != null)
                        {
                            existing.data_analize = json;
                            existing.count_application = countApplications;
                        }
                        else
                        {
                            _dashboard.robots_analitics.Add(new robots_analitic
                            {
                                idrobots = robot.id,
                                datestatistic = date,
                                data_analize = json,
                                isactive = true,
                                count_application = countApplications
                            });
                        }

                        imported++;
                    }
                    catch (Exception ex)
                    {
                        errors.Add($"{group.Key.Robot} ({group.Key.Date}): {ex.Message}");
                    }
                }

                await _dashboard.SaveChangesAsync();
                await LogEvent("Импорт роботов", $"Загружено {imported} записей из Excel");

                return Ok(new { message = $"Импортировано записей: {imported}", errors });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка: {ex.Message}");
            }
        }


        [HttpPost]
        public async Task<IActionResult> CreateRobot([FromBody] CreateRobotRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Robot.Name))
                return BadRequest("Название робота обязательно");

            await using var transaction = await _dashboard.Database.BeginTransactionAsync();
            try
            {
                var robot = new robot
                {
                    name = request.Robot.Name,
                    short_name = request.Robot.ShortName
                };

               
                await SafeAddAsync(_dashboard.robots, robot);

                foreach (var item in request.Periods)
                {
                    if (item.Month == null) continue;

                    var block = new Dictionary<string, object>();
                    foreach (var chart in item.Charts)
                    {
                        block[chart.Title] = new
                        {
                            type = chart.Type.ToString(),
                            сумма = chart.Sum,
                            детали = chart.Details
                        };
                    }

                    var analitic = new robots_analitic
                    {
                        idrobots = robot.id,
                        datestatistic = DateOnly.FromDateTime(item.Month.Value),
                        count_application = item.CountApplications,
                        data_analize = JsonSerializer.Serialize(block),
                        isactive = true
                    };

                    _dashboard.robots_analitics.Add(analitic);
                }

                await _dashboard.SaveChangesAsync();
                await transaction.CommitAsync();
                await LogEvent("Создание робота", $"Новый робот {robot.name} - {robot.short_name} добавлен", request.UserId);
                return Ok(new { robotId = robot.id, message = "Робот создан" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return BadRequest(ex.Message);
            }
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetRobotEdit(int id)
        {
            try
            {
                var robot = await _dashboard.robots.FirstOrDefaultAsync(x => x.id == id);
                if (robot == null) return NotFound("Нет такого робота");

                var analitics = await _dashboard.robots_analitics
                    .Where(a => a.idrobots == id)
                    .OrderBy(a => a.datestatistic)
                    .ToListAsync();

                var periods = new List<PeriodGroupDTO>();

                foreach (var item in analitics)
                {
                    var period = new PeriodGroupDTO
                    {
                        Month = item.datestatistic.ToDateTime(TimeOnly.MinValue),
                        CountApplications = item.count_application,
                        Charts = new List<NewChartBlockDto>()
                    };

                    Dictionary<string, JsonElement> dataBlocks;
                    try
                    {
                        dataBlocks = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(item.data_analize)
                            ?? new Dictionary<string, JsonElement>();
                    }
                    catch
                    {
                        continue;
                    }

                    foreach (var block in dataBlocks)
                    {
                        try
                        {
                            var chartData = block.Value;

                            ChartTypeRobot chartType = ChartTypeRobot.Bar; 
                            if (chartData.TryGetProperty("type", out var typeEl))
                            {
                                var typeStr = typeEl.GetString() ?? "Bar";
                                Enum.TryParse(typeStr, true, out chartType);
                            }

                            double sum = 0;
                            if (chartData.TryGetProperty("сумма", out var sumEl))
                                sum = sumEl.GetDouble();

                            var chart = new NewChartBlockDto
                            {
                                Title = block.Key,
                                Type = chartType,
                                Sum = sum,
                                Details = new Dictionary<string, double>()
                            };

                        
                            if (chartData.TryGetProperty("детали", out var detailsEl))
                            {
                                foreach (var detail in detailsEl.EnumerateObject())
                                {
                                    chart.Details[detail.Name] = detail.Value.GetDouble();
                                }
                            }
                            else if (chartData.TryGetProperty("Details", out detailsEl))
                            {
                                foreach (var detail in detailsEl.EnumerateObject())
                                {
                                    chart.Details[detail.Name] = detail.Value.GetDouble();
                                }
                            }

                            period.Charts.Add(chart);
                        }
                        catch
                        {
                           
                            continue;
                        }
                    }

                    periods.Add(period);
                }

                var response = new EditRobot
                {
                    Id = robot.id,
                    Name = robot.name,
                    ShortName = robot.short_name,
                    CountApplications = analitics.Sum(a => a.count_application ?? 0),
                    Periods = periods
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                return Ok(new { error = ex.Message, detail = ex.InnerException?.Message });
            }
        }

        [HttpPut("robot-update/{id}")]
        public async Task<IActionResult> UpdateRobot(int id, [FromBody] UpdateRobotRequest request)
        {
            if (id != request.RobotId)
                return BadRequest("Несоответствие id");

            await using var transaction = await _dashboard.Database.BeginTransactionAsync();
            try
            {
                var robot = await _dashboard.robots.FirstOrDefaultAsync(x => x.id == id);
                if (robot == null)
                    return NotFound("No Robots");

                robot.name = request.Robot.Name;
                robot.short_name = request.Robot.ShortName;

               
                var oldAnalytics = await _dashboard.robots_analitics
                    .Where(a => a.idrobots == id)
                    .ToListAsync();

                _dashboard.robots_analitics.RemoveRange(oldAnalytics);
                await _dashboard.SaveChangesAsync();

                
                foreach (var period in request.Periods)
                {
                    if (period.Month == null) continue;

                    var block = new Dictionary<string, object>();
                    foreach (var chart in period.Charts)
                    {
                        if (string.IsNullOrWhiteSpace(chart.Title)) continue;

                        block[chart.Title] = new
                        {
                            type = chart.Type.ToString(),
                            сумма = chart.Sum,
                            детали = chart.Details
                        };
                    }

                    if (block.Any())
                    {
                        var newAnalitic = new robots_analitic
                        {
                            idrobots = robot.id,
                            datestatistic = DateOnly.FromDateTime(period.Month.Value),
                            data_analize = JsonSerializer.Serialize(block),
                            count_application = period.CountApplications,
                            isactive = true
                        };

                        _dashboard.robots_analitics.Add(newAnalitic);
                    }
                }

                await _dashboard.SaveChangesAsync();
                await transaction.CommitAsync();
                await LogEvent("Обновление робота", $"Обновленный робот {robot.name} - {robot.short_name}", request.UserId);
                return Ok(new { robotId = robot.id, message = "робот обновлен" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, $"Ошибка при обновлении {ex.Message}");
            }
        }

      
        private async Task SafeAddAsync<T>(DbSet<T> dbSet, T entity) where T : class
        {
            try
            {
                dbSet.Add(entity);
                await _dashboard.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
            
                _dashboard.Entry(entity).State = EntityState.Detached;

                dbSet.Add(entity);
                await _dashboard.SaveChangesAsync();
            }
        }
    }
}