using ClosedXML.Excel;
namespace DashBoard.Api.Service
{
    public class ExcelInputService
    {
        public List<Dictionary<string,string>> ParseExcel(Stream fileStream)
        {
            var result = new List<Dictionary<string,string>>();
            using var worckbook = new XLWorkbook(fileStream);
            var sheet = worckbook.Worksheet(1);
            var headers = new List<string>();
            var firstRow = true;

            foreach (var row in sheet.RowsUsed())
            {
                if (firstRow)
                {
                    foreach (var cell in row.Cells())
                    {
                        headers.Add(cell.GetString().Trim());
                    }
                    firstRow = false;
                    continue;
                }            
                
                var rowData = new Dictionary<string, string>();
                for (int i = 0; i < headers.Count; i++)
                {
                    var cell = row.Cell(i + 1);
                    rowData[headers[i]] = cell.GetString().Trim();
                }
                result.Add(rowData);
            }
            return result;
        }
    }
}
