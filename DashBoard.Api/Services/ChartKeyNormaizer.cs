using System.Text.RegularExpressions;

namespace DashBoard.Api.Services
{
    public class ChartKeyNormaizer
    {
        public string Normalize(string block, string key)
        {
            if (string.IsNullOrWhiteSpace(key))
                return key;

       
         

            
            if (_rules.TryGetValue(block, out var rule))
                key = rule(key);

            return key;

        }

        private readonly Dictionary<string, Func<string, string>> _rules = new()
        {
            ["количество проведенных проверок"] =
        key => Regex.Replace(key, @"^\S+\s+(по|на)\s+", ""),
            ["количество_сформированных_отчетов"] =
        key => Regex.Replace(key, @"^\S+\s+(по|на)\s+", ""),

           
        };
        public string NormalizeBlock(string block)
        {
            if (string.IsNullOrWhiteSpace(block))
                return block;

            return block
                .Replace("_", " ")
                .Trim();
        }
    }
}
  