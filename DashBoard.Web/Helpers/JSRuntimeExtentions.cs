
using Microsoft.JSInterop;

namespace DashBoard.Web.Helpers
{
    public static class JSRuntimeExtensions
    {
        public static async Task<string?> GetUserId(this IJSRuntime js)
        {
            try
            {
                var userId = await js.InvokeAsync<string>("eval", "localStorage.getItem('userId')");
                return userId?.Trim('"', '\'');
            }
            catch
            {
                return null;
            }
        }

        public static async Task<string?> GetUserName(this IJSRuntime js)
        {
            try
            {
                var name = await js.InvokeAsync<string>("eval", "localStorage.getItem('userName')");
                return name?.Trim('"', '\'');
            }
            catch
            {
                return null;
            }
        }
    }
}