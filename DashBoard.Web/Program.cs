
using DashBoard.Lib.DTOs;
using DashBoard.Web.Components;
using DashBoard.Web.Services;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.JSInterop;
using MudBlazor.Services;

var builder = WebApplication.CreateBuilder(args);


var apiUrl = Environment.GetEnvironmentVariable("API_URL");


if (string.IsNullOrEmpty(apiUrl))
{
    apiUrl = "https://localhost/api";
}
builder.Services.AddMudServices();
builder.Services.AddAuthentication("Cookies")
    .AddCookie("Cookies", options =>
    {
        options.LoginPath = "/login";
        options.AccessDeniedPath = "/login";
    });
builder.Services.AddAuthorizationCore();
builder.Services.AddCascadingAuthenticationState();
builder.Services.AddScoped<AuthenticationStateProvider, CustomAuthStateProvider>();
builder.Services.AddHttpClient("ApiClient", c =>
{
    c.BaseAddress = new Uri(apiUrl);
});

builder.Services.AddSingleton<UserState>();
builder.Services.AddScoped<ApiService>(sp =>
{
    var clientFactory = sp.GetRequiredService<IHttpClientFactory>();
    var jsRuntime = sp.GetRequiredService<IJSRuntime>();
    return new ApiService(clientFactory.CreateClient("ApiClient"), jsRuntime);
});


builder.Services.AddRazorComponents()
       .AddInteractiveServerComponents();

var app = builder.Build();


if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    app.UseHsts();
}


app.UseAntiforgery();

app.MapStaticAssets();
app.MapRazorComponents<App>()
   .AddInteractiveServerRenderMode();

app.Run();