using DashBoard.Web.Components;
using MudBlazor.Services;
using DashBoard.Web.Services;

var builder = WebApplication.CreateBuilder(args);


var apiUrl = Environment.GetEnvironmentVariable("API_URL");

// Если переменная не задана (локальный запуск), используем localhost
if (string.IsNullOrEmpty(apiUrl))
{
    apiUrl = "http://localhost:8080";
}

builder.Services.AddMudServices();



builder.Services.AddHttpClient("ApiClient", c =>
{
    c.BaseAddress = new Uri(apiUrl);
});

builder.Services.AddScoped<ApiService>(sp =>
{
    var clientFactory = sp.GetRequiredService<IHttpClientFactory>();
    return new ApiService(clientFactory.CreateClient("ApiClient"));
});



builder.Services.AddRazorComponents()
       .AddInteractiveServerComponents();

var app = builder.Build();


if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseAntiforgery();

app.MapStaticAssets();
app.MapRazorComponents<App>()
   .AddInteractiveServerRenderMode();

app.Run();