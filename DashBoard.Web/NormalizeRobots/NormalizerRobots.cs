
using System.Text.RegularExpressions;

namespace DashBoard.Web.NormalizeRobots
{
    public class NormalizerRobots
    {

        public static string Block(string block)
              => block?.Replace("_", " ").Trim();
        public static string Normalizer(string block, string key)
        {

            if (string.IsNullOrWhiteSpace(key))
                return key;

            if (_rules.TryGetValue(block, out var rule))
                key = rule(key);

            return key;
        }

        private static readonly Dictionary<string, Func<string, string>> _rules = new()
        {
            ["количество_проведенных_проверок"] =
            key => Regex.Replace(key, @"^\S+\s+(по|на)\s+", ""),
            ["количество_сформированных_отчетов"] =
            key => Regex.Replace(key, @"^\S+\s+(по|на)\s+", ""),


        };

       

    }
}
