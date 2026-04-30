namespace DashBoard.Web.NormalizeRobots
{
    public class NormalizerRobots
    {
        public static string Key(string key)
       => key?.Replace("_", " ").Trim();

        public static string Block(string block)
            => block?.Replace("_", " ").Trim();
    }
}
