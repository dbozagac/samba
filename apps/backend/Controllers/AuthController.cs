using Api.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    [HttpGet("me")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public IActionResult Me()
    {
        var response = new
        {
            uid = User.GetFirebaseUid(),
            email = User.GetEmail(),
            name = User.GetDisplayName(),
            issuer = User.FindFirst("iss")?.Value,
        };

        return Ok(response);
    }
}
