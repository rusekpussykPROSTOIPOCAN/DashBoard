using DashBoard.Lib.Models;
using Microsoft.JSInterop;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using static System.Net.WebRequestMethods;
namespace DashBoard.Web.Services
{
    public class ApiService
    {
        private readonly HttpClient _httpClient;
        private readonly IJSRuntime _jsRuntime;

        public ApiService(HttpClient httpClient, IJSRuntime jsRuntime)
        {
            _httpClient = httpClient;
            _jsRuntime = jsRuntime;
        }
        public async Task AddAuthHeader()
        {
            try
            {
                var token = await _jsRuntime.InvokeAsync<string>("eval", "localStorage.getItem('authToken')");
                if (!string.IsNullOrEmpty(token) && token != "null" && token != "undefined")
                {
                    token = token.Trim('"', '\'');
                    _httpClient.DefaultRequestHeaders.Authorization =
                        new AuthenticationHeaderValue("Bearer", token);
                }
            }
            catch { }
        }
        public async Task<T> PutAsync<T>(string url, object data)
        {
            var response = await _httpClient.PutAsJsonAsync(url, data);
            response.EnsureSuccessStatusCode();
            return await response.Content.ReadFromJsonAsync<T>();
        }
        public async Task<T?> GetAsync<T>(string endpoint)
        {
            await AddAuthHeader();
            return await _httpClient.GetFromJsonAsync<T>(endpoint);
        }
        public async Task DeleteAsync(string url)
        {
            var response = await _httpClient.DeleteAsync(url);
            response.EnsureSuccessStatusCode();
        }
        public async Task<T?> PostAsync<T>(string endpoint, object data)
        {
            await AddAuthHeader();
            try
            {
                var json = JsonSerializer.Serialize(data, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });



                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync(endpoint, content);

                var responseBody = await response.Content.ReadAsStringAsync();


                if (response.IsSuccessStatusCode)
                {
                    if (string.IsNullOrEmpty(responseBody))
                    {
                        return default;
                    }
                    return JsonSerializer.Deserialize<T>(responseBody, new JsonSerializerOptions
                    {
                        PropertyNameCaseInsensitive = true
                    });
                }
                else
                {
                    throw new HttpRequestException($"Status: {response.StatusCode}, Body: {responseBody}");
                }
            }
            catch (Exception ex)
            {

                throw;
            }
        }

        public async Task<T?> PostFormAsync<T>(string endpoint, MultipartFormDataContent content)
        {
            var response = await _httpClient.PostAsync(endpoint, content);
            response.EnsureSuccessStatusCode();
            return await response.Content.ReadFromJsonAsync<T>();
        }
        public async Task<string> GetJsonAnalitic(
            DateTime? dateFrom = null,
            DateTime? dateTo = null,
            int? year = null,
            int? month = null,
            int? quarter = null)
        {
            var query = new List<string>();

            if (dateFrom.HasValue) query.Add($"dateFrom={dateFrom:yyyy-MM-dd}");
            if (dateTo.HasValue) query.Add($"dateTo={dateTo:yyyy-MM-dd}");
            if (year.HasValue) query.Add($"year={year}");
            if (month.HasValue) query.Add($"month={month}");
            if (quarter.HasValue) query.Add($"quarter={quarter}");

            
            var url = "api/getTableAnalitic" + (query.Any() ? "?" + string.Join("&", query) : "");

            return await _httpClient.GetStringAsync(url);
        }
    }
}
