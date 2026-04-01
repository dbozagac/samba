using System.ComponentModel.DataAnnotations;

namespace Api.Contracts;

// ── Requests ────────────────────────────────────────────────

public sealed record CreateUserRequest(
    [Required(ErrorMessage = "Kullanıcı adı zorunludur."), MaxLength(100, ErrorMessage = "Kullanıcı adı en fazla 100 karakter olabilir.")] string Username,
    [Required(ErrorMessage = "TC No zorunludur."), RegularExpression(@"^\d{11}$", ErrorMessage = "TC No 11 haneli sayı olmalıdır.")] string TcNo,
    [Required(ErrorMessage = "E-posta zorunludur."), EmailAddress(ErrorMessage = "Geçerli bir e-posta giriniz."), MaxLength(255, ErrorMessage = "E-posta en fazla 255 karakter olabilir.")] string Email,
    [Required(ErrorMessage = "Telefon zorunludur."), RegularExpression(@"^\+?\d{10,15}$", ErrorMessage = "Telefon 10-15 haneli olmalıdır.")] string Phone
);

public sealed record UpdateUserRequest(
    [Required(ErrorMessage = "Kullanıcı adı zorunludur."), MaxLength(100, ErrorMessage = "Kullanıcı adı en fazla 100 karakter olabilir.")] string Username,
    [Required(ErrorMessage = "TC No zorunludur."), RegularExpression(@"^\d{11}$", ErrorMessage = "TC No 11 haneli sayı olmalıdır.")] string TcNo,
    [Required(ErrorMessage = "E-posta zorunludur."), EmailAddress(ErrorMessage = "Geçerli bir e-posta giriniz."), MaxLength(255, ErrorMessage = "E-posta en fazla 255 karakter olabilir.")] string Email,
    [Required(ErrorMessage = "Telefon zorunludur."), RegularExpression(@"^\+?\d{10,15}$", ErrorMessage = "Telefon 10-15 haneli olmalıdır.")] string Phone
);

// ── Responses ───────────────────────────────────────────────

public sealed record UserResponse(
    int Id,
    string Username,
    string TcNo,
    string Email,
    string Phone,
    DateTime CreatedAtUtc,
    DateTime UpdatedAtUtc
);

public sealed record PagedResponse<T>(
    List<T> Items,
    int Page,
    int PageSize,
    int TotalCount,
    int TotalPages
);

// ── Query ───────────────────────────────────────────────────

public sealed record ListUsersQuery
{
    public int Page { get; init; } = 1;
    public int PageSize { get; init; } = 20;
    public string? Search { get; init; }
    public string SortBy { get; init; } = "id";
    public bool SortDesc { get; init; } = true;
}
