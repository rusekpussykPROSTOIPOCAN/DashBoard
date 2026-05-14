using ClosedXML.Excel;

namespace DashBoard.Api.Services
{
    public class ExcelExportService
    {
        public byte[] ExportToExcel(List<Dictionary<string, object>> rows, string sheetName)
        {
            using var workbook = new XLWorkbook();
            var sheet = workbook.Worksheets.Add(sheetName);

            if (rows.Count == 0)
            {
                sheet.Cell(1, 1).Value = "No data";
            }
            else
            {
                var headers = rows[0].Keys.ToList();

                for (int i = 0; i < headers.Count; i++)
                    sheet.Cell(1, i + 1).Value = headers[i];

                for (int r = 0; r < rows.Count; r++)
                {
                    for (int c = 0; c < headers.Count; c++)
                    {
                        var val = rows[r][headers[c]];
                        sheet.Cell(r + 2, c + 1).Value = val?.ToString() ?? "";
                    }
                }

                var headerRow = sheet.Row(1);
                headerRow.Style.Font.Bold = true;
            }

            using var stream = new MemoryStream();
            workbook.SaveAs(stream);
            return stream.ToArray();
        }
    }
}