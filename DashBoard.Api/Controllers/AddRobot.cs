using DashBoard.Api.Controllers;
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

                // Безопасное добавление робота
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

                            // Безопасное получение типа
                            ChartTypeRobot chartType = ChartTypeRobot.Bar; // По умолчанию
                            if (chartData.TryGetProperty("type", out var typeEl))
                            {
                                var typeStr = typeEl.GetString() ?? "Bar";
                                Enum.TryParse(typeStr, true, out chartType);
                            }

                            // Безопасное получение суммы
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

                            // Безопасное получение деталей
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
                            // Пропускаем битые блоки
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

                // Удаляем старые аналитики
                var oldAnalytics = await _dashboard.robots_analitics
                    .Where(a => a.idrobots == id)
                    .ToListAsync();

                _dashboard.robots_analitics.RemoveRange(oldAnalytics);
                await _dashboard.SaveChangesAsync();

                // Добавляем новые аналитики
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

                return Ok(new { robotId = robot.id, message = "робот обновлен" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, $"Ошибка при обновлении {ex.Message}");
            }
        }

        // Вспомогательный метод для безопасного добавления
        private async Task SafeAddAsync<T>(DbSet<T> dbSet, T entity) where T : class
        {
            try
            {
                dbSet.Add(entity);
                await _dashboard.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                // Очищаем отслеживание неудачной записи
                _dashboard.Entry(entity).State = EntityState.Detached;

                // Пробуем ещё раз
                dbSet.Add(entity);
                await _dashboard.SaveChangesAsync();
            }
        }
    }
}