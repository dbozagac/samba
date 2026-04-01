using System.Security.Claims;

namespace Api.Extensions;

public static class ClaimsPrincipalExtensions
{
    /// <summary>
    /// Extracts the Firebase UID from the JWT claims.
    /// Firebase tokens include "user_id" and "sub" claims.
    /// </summary>
    public static string GetFirebaseUid(this ClaimsPrincipal principal)
    {
        return principal.FindFirst("user_id")?.Value
            ?? principal.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? principal.FindFirst("sub")?.Value
            ?? throw new UnauthorizedAccessException("Firebase UID not found in token claims.");
    }

    public static string? GetEmail(this ClaimsPrincipal principal)
    {
        return principal.FindFirst("email")?.Value
            ?? principal.FindFirst(ClaimTypes.Email)?.Value;
    }

    public static string? GetDisplayName(this ClaimsPrincipal principal)
    {
        return principal.FindFirst("name")?.Value
            ?? principal.FindFirst(ClaimTypes.Name)?.Value;
    }
}
