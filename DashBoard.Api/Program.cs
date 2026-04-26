using DashBoard.Api.Services;
using DashBoard.Lib.Data;
using Microsoft.EntityFrameworkCore;


var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.Services.AddScoped<ChartKeyNormaizer>();
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? builder.Configuration["ConnectionStrings__DefaultConnection"];

if (string.IsNullOrEmpty(connectionString))
{
    throw new InvalidOperationException("Connection string 'DefaultConnection' is missing!");
}

builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenAnyIP(8080);
});
builder.Services.AddDbContext<dashboardContext>(options =>
    options.UseNpgsql(connectionString));

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

/*app.UseHttpsRedirection();*/
app.UseAuthorization();
app.MapControllers();

Console.WriteLine("✅ API started successfully with PostgreSQL connection");
app.Run();