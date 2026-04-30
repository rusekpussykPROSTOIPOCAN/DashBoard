using DashBoard.Api.Controllers;
using DashBoard.Api.Services;
using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using NpgsqlTypes;
using System.Data;
using System.Text.Json;

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
    r.id as robot_id,
    r.name as robot_name,

    block.key AS block,
   COALESCE(
    block.value->>'Type',
    block.value->>'type'
) AS type,

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
   COALESCE(
    block.value->'Details',
    block.value->'детали',
    '{}'::jsonb
)
) AS detail ON true

LEFT JOIN robots r ON r.id = ra.idrobots

WHERE 
     
   EXTRACT(YEAR FROM ra.datestatistic)::int =
COALESCE(@year, EXTRACT(YEAR FROM ra.datestatistic)::int)

AND EXTRACT(MONTH FROM ra.datestatistic)::int =
COALESCE(@month, EXTRACT(MONTH FROM ra.datestatistic)::int)

AND EXTRACT(QUARTER FROM ra.datestatistic)::int =
COALESCE(@quarter, EXTRACT(QUARTER FROM ra.datestatistic)::int)

AND ra.idrobots =
COALESCE(@robotId, ra.idrobots)

GROUP BY
    r.id,
    r.name,
    block.key,
block.value,
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
            var robotID = reader.IsDBNull(0) ? 0 : reader.GetInt32(0);
            var robotName = reader.IsDBNull(1) ? "Без робота" : reader.GetString(1);
            var rawBlock = reader.GetString(2);
            var block = rawBlock;
            var type = reader.IsDBNull(3) ? "Bar" : reader.GetString(3);
           
            var detailKey = reader.IsDBNull(4) ? null : reader.GetString(4);
            var value = reader.IsDBNull(5) ? 0 : reader.GetInt32(5);

            if (!map.TryGetValue(block, out var chart))
            {
                chart = new UniversalChartResponseV3
                {
                    RobotId = robotID,
                    RobotName = robotName,
                    Block = block,
                    Title = block,
                    Type = Enum.TryParse(type, true, out ChartTypeRobot t)
                        ? t
                        : ChartTypeRobot.Bar,
                    Items = new(),
                    Total = 0
                };
                

                map[block] = chart;
            }

            if (!string.IsNullOrEmpty(detailKey))
            {
                var key = detailKey;

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

                chart.Total +=value;
            }
            else
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

                chart.Total += value;
            }
        }
            foreach (var item in map.Values)
        {
                item.IsRaw = !item.Items.Any(x => x.Value > 0);
            }
        return map.Values.ToList();
    }


    [HttpPost("update")]
    public async Task<IActionResult> Update([FromBody] UpdateChartRequest update)
    {

        await using var conn = _dashboard.Database.GetDbConnection();
        await conn.OpenAsync();

        await using var cmd = (NpgsqlCommand)conn.CreateCommand();

        // 1. собираем details
        var details = update.Items
            .GroupBy(x => x.Key)
            .ToDictionary(
                x => x.Key,
                x => x.Sum(v => v.Value)
            );

        // 2. собираем блок
        var blockObject = new ChartBlockDto
        {
            Type = update.Type, 
            Sum = details.Sum(x => x.Value),
            Details = details
        };

        var json = JsonSerializer.Serialize(blockObject);

        // 3. обновление
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
AND EXTRACT(MONTH FROM datestatistic) = @month;
";

        cmd.Parameters.Add("block", NpgsqlDbType.Text).Value = update.Block;
        cmd.Parameters.Add("json", NpgsqlDbType.Jsonb).Value = json;
        cmd.Parameters.Add("robotId", NpgsqlDbType.Integer).Value = update.RobotId;
        cmd.Parameters.Add("year", NpgsqlDbType.Integer).Value = update.Year;
        cmd.Parameters.Add("month", NpgsqlDbType.Integer).Value = update.Month;

        await cmd.ExecuteNonQueryAsync();

        return Ok();
    }

}