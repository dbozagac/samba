using System.ComponentModel.DataAnnotations;

namespace Api.Contracts;

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

public sealed record UserResponse(
    int Id,
    string Username,
    string TcNo,
    string Email,
    string Phone,
    DateTime CreatedAtUtc,
    DateTime UpdatedAtUtc
);
