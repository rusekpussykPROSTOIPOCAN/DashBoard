using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.JSInterop;
using System.Security.Claims;
using System.Text.Json;

public class CustomAuthStateProvider : AuthenticationStateProvider
{
    private readonly IJSRuntime _js;

    public CustomAuthStateProvider(IJSRuntime js)
    {
        _js = js;
    }

    public override async Task<AuthenticationState> GetAuthenticationStateAsync()
    {
        var identity = new ClaimsIdentity();

        try
        {
            var token = await _js.InvokeAsync<string>("eval", "localStorage.getItem('authToken')");

            if (!string.IsNullOrEmpty(token))
            {
                var claims = ParseClaimsFromJwt(token);
                identity = new ClaimsIdentity(claims, "jwt");
            }
        }
        catch { }

        return new AuthenticationState(new ClaimsPrincipal(identity));
    }

    private IEnumerable<Claim> ParseClaimsFromJwt(string jwt)
    {
        var claims = new List<Claim>();
        try
        {
            var payload = jwt.Split('.')[1];
            var jsonBytes = Convert.FromBase64String(PadBase64(payload));
            using var doc = JsonDocument.Parse(jsonBytes);
            var root = doc.RootElement;

            foreach (var prop in root.EnumerateObject())
            {
                var value = prop.Value.ToString();

                if (prop.Name.Contains("role", StringComparison.OrdinalIgnoreCase))
                {
                    claims.Add(new Claim(ClaimTypes.Role, value));
                }
                else
                {
                    claims.Add(new Claim(prop.Name, value));
                }
            }
        }
        catch { }
        return claims;
    }

    private string PadBase64(string base64)
    {
        switch (base64.Length % 4)
        {
            case 2: base64 += "=="; break;
            case 3: base64 += "="; break;
        }
        return base64.Replace('-', '+').Replace('_', '/');
    }

    public void NotifyAuthenticationChanged()
    {
        NotifyAuthenticationStateChanged(GetAuthenticationStateAsync());
    }
}