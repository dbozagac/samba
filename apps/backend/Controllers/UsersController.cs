using Api.Contracts;
using Api.Data;
using Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsersController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<List<UserResponse>>> List(CancellationToken ct)
    {
        var users = await db.Users
            .AsNoTracking()
            .OrderByDescending(x => x.Id)
            .Select(x => new UserResponse(
                x.Id,
                x.Username,
                x.TcNo,
                x.Email,
                x.Phone,
                x.CreatedAtUtc,
                x.UpdatedAtUtc
            ))
            .ToListAsync(ct);

        return Ok(users);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<UserResponse>> Get(int id, CancellationToken ct)
    {
        var user = await db.Users
            .AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => new UserResponse(
                x.Id,
                x.Username,
                x.TcNo,
                x.Email,
                x.Phone,
                x.CreatedAtUtc,
                x.UpdatedAtUtc
            ))
            .FirstOrDefaultAsync(ct);

        return user is null ? NotFound() : Ok(user);
    }

    [HttpPost]
    public async Task<ActionResult<UserResponse>> Create([FromBody] CreateUserRequest request, CancellationToken ct)
    {
        if (await db.Users.AnyAsync(x => x.TcNo == request.TcNo, ct))
        {
            return Conflict(new { field = "tcNo", message = "Bu TC No zaten kayıtlı." });
        }

        if (await db.Users.AnyAsync(x => x.Email == request.Email, ct))
        {
            return Conflict(new { field = "email", message = "Bu e-posta zaten kayıtlı." });
        }

        var user = new User
        {
            Username = request.Username.Trim(),
            TcNo = request.TcNo,
            Email = request.Email.Trim(),
            Phone = request.Phone,
            CreatedAtUtc = DateTime.UtcNow,
            UpdatedAtUtc = DateTime.UtcNow,
        };

        db.Users.Add(user);
        await db.SaveChangesAsync(ct);

        var response = new UserResponse(
            user.Id,
            user.Username,
            user.TcNo,
            user.Email,
            user.Phone,
            user.CreatedAtUtc,
            user.UpdatedAtUtc
        );

        return CreatedAtAction(nameof(Get), new { id = user.Id }, response);
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<UserResponse>> Update(int id, [FromBody] UpdateUserRequest request, CancellationToken ct)
    {
        var user = await db.Users.FirstOrDefaultAsync(x => x.Id == id, ct);
        if (user is null)
        {
            return NotFound();
        }

        if (await db.Users.AnyAsync(x => x.TcNo == request.TcNo && x.Id != id, ct))
        {
            return Conflict(new { field = "tcNo", message = "Bu TC No başka bir kullanıcıda kayıtlı." });
        }

        if (await db.Users.AnyAsync(x => x.Email == request.Email && x.Id != id, ct))
        {
            return Conflict(new { field = "email", message = "Bu e-posta başka bir kullanıcıda kayıtlı." });
        }

        user.Username = request.Username.Trim();
        user.TcNo = request.TcNo;
        user.Email = request.Email.Trim();
        user.Phone = request.Phone;
        user.UpdatedAtUtc = DateTime.UtcNow;

        await db.SaveChangesAsync(ct);

        var response = new UserResponse(
            user.Id,
            user.Username,
            user.TcNo,
            user.Email,
            user.Phone,
            user.CreatedAtUtc,
            user.UpdatedAtUtc
        );

        return Ok(response);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id, CancellationToken ct)
    {
        var user = await db.Users.FirstOrDefaultAsync(x => x.Id == id, ct);
        if (user is null)
        {
            return NotFound();
        }

        db.Users.Remove(user);
        await db.SaveChangesAsync(ct);

        return NoContent();
    }
}
