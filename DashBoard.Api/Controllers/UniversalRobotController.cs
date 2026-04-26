using DashBoard.Api.Controllers;
using DashBoard.Api.Services;
using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using System.Data;

[ApiController]
[Route("api/universal-chart-v3")]
public class UniversalRobotController : BaseController
{
   private readonly ChartKeyNormaizer _form;
    public UniversalRobotController(dashboardContext dashboard, ChartKeyNormaizer form) : base(dashboard) {
     _form = form;
    }

    [HttpGet]
    public async Task<List<UniversalChartResponseV3>> Get(
   
    [FromQuery] int? year,
    [FromQuery] int? month,
    [FromQuery] int? quarter,
    [FromQuery] int? robotId)
    {
        var sql = @" 
SELECT
r.name as robot_name,
    block.key AS block,
    block.value->>'type' AS type,

    MAX((block.value->>'сумма')::int) AS total,

    detail.key AS detail_key,

    SUM(
        CASE 
            WHEN detail.value IS NULL THEN 0
            WHEN jsonb_typeof(detail.value) = 'number'
                THEN detail.value::int
            WHEN jsonb_typeof(detail.value) = 'string'
                 AND detail.value::text ~ '^\d+$'
                THEN (detail.value::text)::int
            ELSE 0
        END
    ) AS detail_value

FROM robots_analitic ra
CROSS JOIN LATERAL jsonb_each(ra.data_analize) AS block(key, value)

LEFT JOIN LATERAL jsonb_each(
    COALESCE(block.value->'детали', '{}'::jsonb)
) AS detail ON true
LEFT JOIN robots r ON r.id = ra.idrobots
WHERE (@year::int IS NULL OR EXTRACT(YEAR FROM ra.datestatistic) = @year::int)
  AND (@month::int IS NULL OR EXTRACT(MONTH FROM ra.datestatistic) = @month::int)
  AND (@quarter::int IS NULL OR EXTRACT(QUARTER FROM ra.datestatistic) = @quarter::int)
  AND (@robotId::int IS NULL OR ra.idrobots = @robotId)
  AND EXTRACT(DAY FROM ra.datestatistic) <> 31

GROUP BY
 r.name,
    block.key,
    block.value->>'type',
    detail.key;
";

        await using var conn = _dashboard.Database.GetDbConnection();
        await conn.OpenAsync();

        await using var cmd = conn.CreateCommand();
        cmd.CommandText = sql;

        cmd.Parameters.Add(new NpgsqlParameter("year", (object?)year ?? DBNull.Value));
        cmd.Parameters.Add(new NpgsqlParameter("month", (object?)month ?? DBNull.Value));
        cmd.Parameters.Add(new NpgsqlParameter("quarter", (object?)quarter ?? DBNull.Value));
        cmd.Parameters.Add(new NpgsqlParameter("robotId", (object?)robotId ?? DBNull.Value));

        await using var reader = await cmd.ExecuteReaderAsync();

        var map = new Dictionary<string, UniversalChartResponseV3>();

        while (await reader.ReadAsync())
        {
            var robotName = reader.IsDBNull(0) ? "Без робота" : reader.GetString(0);
            var rawBlock = reader.GetString(1);
            var block = _form.NormalizeBlock(rawBlock);
            var type = reader.IsDBNull(2) ? "Bar" : reader.GetString(2);
            var total = reader.IsDBNull(3) ? 0 : reader.GetInt32(3);
            var detailKey = reader.IsDBNull(4) ? null : reader.GetString(4);
            var value = reader.IsDBNull(5) ? 0 : reader.GetInt32(5);

            if (!map.TryGetValue(block, out var chart))
            {
                chart = new UniversalChartResponseV3
                {
                    RobotName = robotName,
                    Block = block,
                    Title = block,
                    Type = Enum.TryParse(type, true, out ChartTypeRobot t)
                        ? t
                        : ChartTypeRobot.Bar,
                    Items = new(),
                    Total = total
                };
                

                map[block] = chart;
            }

            if (!string.IsNullOrEmpty(detailKey))
            {
                var key = _form.Normalize(block, detailKey);

                var item = chart.Items.FirstOrDefault(x => x.Key == key);
                

                if (item == null)
                {
                    chart.Items.Add(new UniversalChartItemV3
                    {
                        Key = key,
                        Value = value
                    });
                }
                else
                {
                    item.Value += value;
                }

                chart.Total = total;
            }
        foreach (var item in map.Values)
        {
                chart.IsRaw = !chart.Items.Any(x => x.Value > 0);
            }
        }
        return map.Values.ToList();
    }

}