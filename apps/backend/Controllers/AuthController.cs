using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    [HttpGet("me")]
    [Authorize]
    public IActionResult Me()
    {
        var user = new
        {
            uid = User.FindFirst("user_id")?.Value ?? User.FindFirst("sub")?.Value,
            email = User.FindFirst("email")?.Value,
            name = User.FindFirst("name")?.Value,
            issuer = User.FindFirst("iss")?.Value,
        };

        return Ok(user);
    }
}
