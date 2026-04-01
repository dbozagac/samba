using Api.Contracts;
using Api.Data;
using Api.Extensions;
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
    [ProducesResponseType(typeof(PagedResponse<UserResponse>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResponse<UserResponse>>> List(
        [FromQuery] ListUsersQuery query, CancellationToken ct)
    {
        var ownerUid = User.GetFirebaseUid();

        var page = Math.Max(query.Page, 1);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var baseQuery = db.Users
            .AsNoTracking()
            .Where(x => x.OwnerFirebaseUid == ownerUid);

        // Search filter
        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            baseQuery = baseQuery.Where(x =>
                x.Username.ToLower().Contains(search) ||
                x.Email.ToLower().Contains(search) ||
                x.TcNo.Contains(search) ||
                x.Phone.Contains(search));
        }

        var totalCount = await baseQuery.CountAsync(ct);

        // Sorting
        baseQuery = query.SortBy?.ToLower() switch
        {
            "username" => query.SortDesc
                ? baseQuery.OrderByDescending(x => x.Username)
                : baseQuery.OrderBy(x => x.Username),
            "email" => query.SortDesc
                ? baseQuery.OrderByDescending(x => x.Email)
                : baseQuery.OrderBy(x => x.Email),
            "createdat" or "createdatutc" => query.SortDesc
                ? baseQuery.OrderByDescending(x => x.CreatedAtUtc)
                : baseQuery.OrderBy(x => x.CreatedAtUtc),
            _ => query.SortDesc
                ? baseQuery.OrderByDescending(x => x.Id)
                : baseQuery.OrderBy(x => x.Id),
        };

        var users = await baseQuery
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => new UserResponse(
                x.Id, x.Username, x.TcNo, x.Email, x.Phone,
                x.CreatedAtUtc, x.UpdatedAtUtc))
            .ToListAsync(ct);

        var totalPages = (int)Math.Ceiling((double)totalCount / pageSize);

        return Ok(new PagedResponse<UserResponse>(users, page, pageSize, totalCount, totalPages));
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(UserResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<UserResponse>> Get(int id, CancellationToken ct)
    {
        var ownerUid = User.GetFirebaseUid();

        var user = await db.Users
            .AsNoTracking()
            .Where(x => x.Id == id && x.OwnerFirebaseUid == ownerUid)
            .Select(x => new UserResponse(
                x.Id, x.Username, x.TcNo, x.Email, x.Phone,
                x.CreatedAtUtc, x.UpdatedAtUtc))
            .FirstOrDefaultAsync(ct);

        if (user is null)
            return Problem(detail: "Kullanıcı bulunamadı.", statusCode: 404, title: "Not Found");

        return Ok(user);
    }

    [HttpPost]
    [ProducesResponseType(typeof(UserResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<UserResponse>> Create(
        [FromBody] CreateUserRequest request, CancellationToken ct)
    {
        var ownerUid = User.GetFirebaseUid();

        if (await db.Users.AnyAsync(x => x.TcNo == request.TcNo, ct))
        {
            ModelState.AddModelError("tcNo", "Bu TC No zaten kayıtlı.");
            return Conflict(new ValidationProblemDetails(ModelState)
            {
                Title = "Conflict",
                Status = StatusCodes.Status409Conflict,
                Detail = "Bu TC No zaten kayıtlı.",
            });
        }

        if (await db.Users.AnyAsync(x => x.Email == request.Email, ct))
        {
            ModelState.AddModelError("email", "Bu e-posta zaten kayıtlı.");
            return Conflict(new ValidationProblemDetails(ModelState)
            {
                Title = "Conflict",
                Status = StatusCodes.Status409Conflict,
                Detail = "Bu e-posta zaten kayıtlı.",
            });
        }

        var user = new User
        {
            OwnerFirebaseUid = ownerUid,
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
            user.Id, user.Username, user.TcNo, user.Email, user.Phone,
            user.CreatedAtUtc, user.UpdatedAtUtc);

        return CreatedAtAction(nameof(Get), new { id = user.Id }, response);
    }

    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(UserResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<UserResponse>> Update(
        int id, [FromBody] UpdateUserRequest request, CancellationToken ct)
    {
        var ownerUid = User.GetFirebaseUid();

        var user = await db.Users.FirstOrDefaultAsync(
            x => x.Id == id && x.OwnerFirebaseUid == ownerUid, ct);

        if (user is null)
            return Problem(detail: "Kullanıcı bulunamadı.", statusCode: 404, title: "Not Found");

        if (await db.Users.AnyAsync(x => x.TcNo == request.TcNo && x.Id != id, ct))
        {
            ModelState.AddModelError("tcNo", "Bu TC No başka bir kullanıcıda kayıtlı.");
            return Conflict(new ValidationProblemDetails(ModelState)
            {
                Title = "Conflict",
                Status = StatusCodes.Status409Conflict,
                Detail = "Bu TC No başka bir kullanıcıda kayıtlı.",
            });
        }

        if (await db.Users.AnyAsync(x => x.Email == request.Email && x.Id != id, ct))
        {
            ModelState.AddModelError("email", "Bu e-posta başka bir kullanıcıda kayıtlı.");
            return Conflict(new ValidationProblemDetails(ModelState)
            {
                Title = "Conflict",
                Status = StatusCodes.Status409Conflict,
                Detail = "Bu e-posta başka bir kullanıcıda kayıtlı.",
            });
        }

        user.Username = request.Username.Trim();
        user.TcNo = request.TcNo;
        user.Email = request.Email.Trim();
        user.Phone = request.Phone;
        user.UpdatedAtUtc = DateTime.UtcNow;

        await db.SaveChangesAsync(ct);

        var response = new UserResponse(
            user.Id, user.Username, user.TcNo, user.Email, user.Phone,
            user.CreatedAtUtc, user.UpdatedAtUtc);

        return Ok(response);
    }

    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id, CancellationToken ct)
    {
        var ownerUid = User.GetFirebaseUid();

        var user = await db.Users.FirstOrDefaultAsync(
            x => x.Id == id && x.OwnerFirebaseUid == ownerUid, ct);

        if (user is null)
            return Problem(detail: "Kullanıcı bulunamadı.", statusCode: 404, title: "Not Found");

        db.Users.Remove(user);
        await db.SaveChangesAsync(ct);

        return NoContent();
    }
}
