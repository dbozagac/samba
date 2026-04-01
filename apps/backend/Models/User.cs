namespace Api.Models;

public class User
{
    public int Id { get; set; }

    /// <summary>Firebase UID of the owner who created this record.</summary>
    public string OwnerFirebaseUid { get; set; } = string.Empty;

    public string Username { get; set; } = string.Empty;

    public string TcNo { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string Phone { get; set; } = string.Empty;

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
}
