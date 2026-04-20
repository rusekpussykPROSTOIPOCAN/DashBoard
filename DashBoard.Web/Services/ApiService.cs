using DashBoard.Lib.Models;
using System.Text;
using System.Text.Json;
namespace DashBoard.Web.Services
{
    public class ApiService
    {
        private readonly HttpClient _httpClient;
        public ApiService(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }
        public async Task<T?> GetAsync<T>(string endpoint)
        {
            return await _httpClient.GetFromJsonAsync<T>(endpoint);
        }
        public async Task<T?> PostAsync<T>(string endpoint, object data)
        {
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

            // Вот здесь исправление: api/getTableAnalitic
            var url = "api/getTableAnalitic" + (query.Any() ? "?" + string.Join("&", query) : "");

            return await _httpClient.GetStringAsync(url);
        }
    }
}
