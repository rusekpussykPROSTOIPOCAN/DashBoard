using ClosedXML.Excel;
using ClosedXML.Graphics;
using DashBoard.Api.Services;
using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using NpgsqlTypes;
using System.Text.Json;

namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api/universal-chart-v3")]
    public class UniversalRobotController : BaseController
    {
        public UniversalRobotController(dashboardContext dashboard) : base(dashboard)
        {
        }
        [HttpGet("export-robots-pivot")]
        public async Task<IActionResult> ExportRobotsPivot(
     [FromServices] ExcelExportService excelService,
     int? year = null,
     int? quarter = null)
        {
            try
            {
                // Сначала получаем ВСЕХ роботов
                var allRobots = await _dashboard.robots
                    .Where(r => r.robots_analitics.Any(ra => ra.isactive == true))
                    .Select(r => r.name)
                    .ToListAsync();

                var sql = @" 
            SELECT
                r.name as robot_name,
                EXTRACT(MONTH FROM ra.datestatistic) as month_num,
                EXTRACT(YEAR FROM ra.datestatistic) as year_num,
                ra.data_analize
            FROM robots_analitic ra
            LEFT JOIN robots r ON r.id = ra.idrobots
            WHERE ra.isactive = true";

                var parameters = new List<NpgsqlParameter>();

                if (year.HasValue)
                {
                    sql += " AND EXTRACT(YEAR FROM ra.datestatistic) = @yr";
                    parameters.Add(new NpgsqlParameter("yr", year.Value));
                }
                if (quarter.HasValue)
                {
                    int startMonth = (quarter.Value - 1) * 3 + 1;
                    int endMonth = startMonth + 2;
                    sql += " AND EXTRACT(MONTH FROM ra.datestatistic) BETWEEN @sm AND @em";
                    parameters.Add(new NpgsqlParameter("sm", startMonth));
                    parameters.Add(new NpgsqlParameter("em", endMonth));
                }

                sql += " ORDER BY r.name, year_num, month_num";

                await using var conn = _dashboard.Database.GetDbConnection();
                await conn.OpenAsync();
                await using var cmd = conn.CreateCommand();
                cmd.CommandText = sql;
                cmd.Parameters.AddRange(parameters.ToArray());
                await using var reader = await cmd.ExecuteReaderAsync();

                var monthNames = new[] { "", "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
                                  "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь" };

                var robotData = new Dictionary<string, Dictionary<string, Dictionary<string, Dictionary<string, int>>>>();
                var sumData = new Dictionary<string, Dictionary<string, Dictionary<string, int>>>();
                var allMonthsSet = new HashSet<string>();
                var allBlocksSet = new HashSet<string>();

                while (await reader.ReadAsync())
                {
                    var robotName = reader.GetString(0);
                    var monthNum = reader.GetInt32(1);
                    var yearNum = reader.GetInt32(2);
                    var jsonData = reader.GetString(3);

                    var monthLabel = $"{monthNames[monthNum]} {yearNum}";
                    allMonthsSet.Add(monthLabel);

                    if (!robotData.ContainsKey(robotName))
                        robotData[robotName] = new Dictionary<string, Dictionary<string, Dictionary<string, int>>>();

                    if (!robotData[robotName].ContainsKey(monthLabel))
                        robotData[robotName][monthLabel] = new Dictionary<string, Dictionary<string, int>>();

                    if (!sumData.ContainsKey(robotName))
                        sumData[robotName] = new Dictionary<string, Dictionary<string, int>>();
                    if (!sumData[robotName].ContainsKey(monthLabel))
                        sumData[robotName][monthLabel] = new Dictionary<string, int>();

                    Dictionary<string, JsonElement>? blocks = null;
                    try { blocks = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(jsonData); }
                    catch { continue; }

                    if (blocks == null) continue;

                    foreach (var kvpBlock in blocks)
                    {
                        var blockName = kvpBlock.Key;
                        allBlocksSet.Add(blockName);
                        var blockValue = kvpBlock.Value;
                        if (blockValue.ValueKind != JsonValueKind.Object) continue;

                        int blockSum = 0;
                        if (blockValue.TryGetProperty("сумма", out var sumEl) && sumEl.ValueKind == JsonValueKind.Number)
                            blockSum = sumEl.GetInt32();

                        sumData[robotName][monthLabel][blockName] = blockSum;

                        JsonElement detailsEl;
                        if ((blockValue.TryGetProperty("детали", out detailsEl) ||
                             blockValue.TryGetProperty("Details", out detailsEl)) &&
                            detailsEl.ValueKind == JsonValueKind.Object)
                        {
                            if (!robotData[robotName][monthLabel].ContainsKey(blockName))
                                robotData[robotName][monthLabel][blockName] = new Dictionary<string, int>();

                            foreach (var detail in detailsEl.EnumerateObject())
                            {
                                if (detail.Value.ValueKind == JsonValueKind.Number)
                                    robotData[robotName][monthLabel][blockName][detail.Name] = detail.Value.GetInt32();
                            }
                        }
                    }
                }

                var sortedMonths = allMonthsSet.OrderBy(m => m).ToList();

                // Excel
                using var workbook = new XLWorkbook();
                var sheet = workbook.Worksheets.Add("Сводка");

                int row = 1;
                int col;

                sheet.Cell(row, 1).Value = "Роботы";
                sheet.Cell(row, 1).Style.Font.Bold = true;
                row++;

                // Заголовки месяцев
                sheet.Cell(row, 1).Value = "";
                col = 2;
                foreach (var m in sortedMonths)
                {
                    sheet.Cell(row, col).Value = m;
                    sheet.Cell(row, col).Style.Font.Bold = true;
                    col++;
                }
                row++;

                // Используем allRobots вместо robotData.Keys, чтобы сохранить порядок и не пропускать
                foreach (var rName in allRobots.OrderBy(r => r))
                {
                    sheet.Cell(row, 1).Value = rName;
                    sheet.Cell(row, 1).Style.Font.Bold = true;
                    row++;

                    if (!robotData.ContainsKey(rName))
                    {
                        row++;
                        continue;
                    }

                    foreach (var blockName in allBlocksSet.OrderBy(b => b))
                    {
                        sheet.Cell(row, 1).Value = blockName;
                        row++;

                        // Собираем все детали
                        var allDetails = new HashSet<string>();
                        if (robotData.ContainsKey(rName))
                        {
                            foreach (var monthKvp in robotData[rName])
                            {
                                if (monthKvp.Value.ContainsKey(blockName))
                                {
                                    foreach (var d in monthKvp.Value[blockName].Keys)
                                        allDetails.Add(d);
                                }
                            }
                        }

                        foreach (var detail in allDetails.OrderBy(d => d))
                        {
                            sheet.Cell(row, 1).Value = "  " + detail;

                            col = 2;
                            foreach (var m in sortedMonths)
                            {
                                if (robotData[rName].ContainsKey(m) &&
                                    robotData[rName][m].ContainsKey(blockName) &&
                                    robotData[rName][m][blockName].ContainsKey(detail))
                                {
                                    sheet.Cell(row, col).Value = robotData[rName][m][blockName][detail];
                                }
                                col++;
                            }
                            row++;
                        }

                        // Сумма
                        sheet.Cell(row, 1).Value = "  Сумма";
                        sheet.Cell(row, 1).Style.Font.Bold = true;

                        col = 2;
                        foreach (var m in sortedMonths)
                        {
                            if (sumData.ContainsKey(rName) &&
                                sumData[rName].ContainsKey(m) &&
                                sumData[rName][m].ContainsKey(blockName))
                            {
                                sheet.Cell(row, col).Value = sumData[rName][m][blockName];
                            }
                            col++;
                        }
                        row++;
                        row++;
                    }
                    row++;
                }

                sheet.Column(1).Width = 50;
                for (int i = 2; i <= col + 1; i++)
                    sheet.Column(i).Width = 15;

                using var stream = new MemoryStream();
                workbook.SaveAs(stream);

                var base64 = Convert.ToBase64String(stream.ToArray());
                var fileName = $"robots_pivot_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx";

                return Ok(new { base64, fileName });
            }
            catch (Exception ex)
            {
                return Ok(new { error = ex.Message });
            }
        }
        [HttpGet]
        public async Task<IActionResult> Get(
     [FromQuery] int? year,
     [FromQuery] int? month,
     [FromQuery] int? quarter,
     [FromQuery] int? robotId)
        {
            try
            {
                var sql = @" 
            SELECT
                r.id as robot_id,
                r.name as robot_name,
                block.key AS block,
                COALESCE(block.value->>'Type', block.value->>'type') AS type,
                detail.key AS detail_key,
                SUM(
                    CASE
                        WHEN detail.key IS NULL
                            THEN (block.value->>'сумма')::int
                        ELSE
                            CASE 
                                WHEN jsonb_typeof(detail.value) = 'number'
                                    THEN detail.value::int
                                WHEN jsonb_typeof(detail.value) = 'string'
                                     AND detail.value::text ~ '^\d+$'
                                    THEN (detail.value::text)::int
                                ELSE 0
                            END
                    END
                ) AS detail_value
            FROM robots_analitic ra
            CROSS JOIN LATERAL jsonb_each(ra.data_analize) AS block(key, value)
            LEFT JOIN LATERAL jsonb_each(
                COALESCE(block.value->'Details', block.value->'детали', '{}'::jsonb)
            ) AS detail ON true
            LEFT JOIN robots r ON r.id = ra.idrobots
            WHERE ra.isactive = true";

                var parameters = new List<NpgsqlParameter>();

                if (year.HasValue)
                {
                    sql += " AND EXTRACT(YEAR FROM ra.datestatistic) = @year";
                    parameters.Add(new NpgsqlParameter("year", year.Value));
                }
                if (month.HasValue)
                {
                    sql += " AND EXTRACT(MONTH FROM ra.datestatistic) = @month";
                    parameters.Add(new NpgsqlParameter("month", month.Value));
                }
                if (quarter.HasValue)
                {
                    sql += " AND EXTRACT(QUARTER FROM ra.datestatistic) = @quarter";
                    parameters.Add(new NpgsqlParameter("quarter", quarter.Value));
                }
                if (robotId.HasValue)
                {
                    sql += " AND ra.idrobots = @robotId";
                    parameters.Add(new NpgsqlParameter("robotId", robotId.Value));
                }

                sql += " GROUP BY r.id, r.name, block.key, block.value, detail.key ORDER BY r.name, block.key";

                await using var conn = _dashboard.Database.GetDbConnection();
                await conn.OpenAsync();
                await using var cmd = conn.CreateCommand();
                cmd.CommandText = sql;
                cmd.Parameters.AddRange(parameters.ToArray());
                await using var reader = await cmd.ExecuteReaderAsync();

                // Ключ: robotId_block - чтобы не смешивать роботов
                var map = new Dictionary<string, UniversalChartResponseV3>();

                while (await reader.ReadAsync())
                {
                    var robotID = reader.IsDBNull(0) ? 0 : reader.GetInt32(0);
                    var robotName = reader.IsDBNull(1) ? "Без робота" : reader.GetString(1);
                    var block = reader.GetString(2);
                    var type = reader.IsDBNull(3) ? "Bar" : reader.GetString(3);
                    var detailKey = reader.IsDBNull(4) ? null : reader.GetString(4);
                    var value = reader.IsDBNull(5) ? 0 : reader.GetInt32(5);

                    // Уникальный ключ: робот + блок
                    var mapKey = $"{robotID}_{block}";

                    if (!map.TryGetValue(mapKey, out var chart))
                    {
                        chart = new UniversalChartResponseV3
                        {
                            RobotId = robotID,
                            RobotName = robotName,
                            Block = block,
                            Title = block,
                            Type = Enum.TryParse(type, true, out ChartTypeRobot t) ? t : ChartTypeRobot.Bar,
                            Items = new(),
                            Total = 0
                        };
                        map[mapKey] = chart;
                    }

                    if (!string.IsNullOrEmpty(detailKey))
                    {
                        var item = chart.Items.FirstOrDefault(x => x.Key == detailKey);
                        if (item == null)
                            chart.Items.Add(new UniversalChartItemV3 { Key = detailKey, Value = value });
                        else
                            item.Value += value;

                        chart.Total += value;
                    }
                }

                foreach (var item in map.Values)
                {
                    item.IsRaw = !item.Items.Any(x => x.Value > 0);
                }

                return Ok(map.Values.ToList());
            }
            catch (Exception ex)
            {
                return Ok(new { error = ex.Message });
            }
        }

        [HttpPost("update")]
        public async Task<IActionResult> Update([FromBody] UpdateChartRequest update)
        {
            try
            {
                await using var conn = _dashboard.Database.GetDbConnection();
                await conn.OpenAsync();

                await using var cmd = (NpgsqlCommand)conn.CreateCommand();

                var details = update.Items
                    .GroupBy(x => x.Key)
                    .ToDictionary(x => x.Key, x => x.Sum(v => v.Value));

                var blockObject = new ChartBlockDto
                {
                    Type = update.Type,
                    Sum = details.Sum(x => x.Value),
                    Details = details
                };

                var json = JsonSerializer.Serialize(blockObject);

                cmd.CommandText = @"
                    UPDATE robots_analitic
                    SET data_analize = jsonb_set(
                        COALESCE(data_analize, '{}'::jsonb),
                        ARRAY[@block],
                        @json::jsonb,
                        true
                    )
                    WHERE idrobots = @robotId
                    AND EXTRACT(YEAR FROM datestatistic) = @year
                    AND EXTRACT(MONTH FROM datestatistic) = @month";

                cmd.Parameters.Add("block", NpgsqlDbType.Text).Value = update.Block;
                cmd.Parameters.Add("json", NpgsqlDbType.Jsonb).Value = json;
                cmd.Parameters.Add("robotId", NpgsqlDbType.Integer).Value = update.RobotId;
                cmd.Parameters.Add("year", NpgsqlDbType.Integer).Value = update.Year;
                cmd.Parameters.Add("month", NpgsqlDbType.Integer).Value = update.Month;

                await cmd.ExecuteNonQueryAsync();

                return Ok(new { message = "Обновлено" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка обновления: {ex.Message}");
            }
        }
    }
}