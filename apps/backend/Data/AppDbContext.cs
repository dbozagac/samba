using Api.Models;
using Microsoft.EntityFrameworkCore;

namespace Api.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        var user = modelBuilder.Entity<User>();
        user.ToTable("users");
        user.HasKey(x => x.Id);
        user.Property(x => x.Username).HasMaxLength(100).IsRequired();
        user.Property(x => x.TcNo).HasMaxLength(11).IsRequired();
        user.Property(x => x.Email).HasMaxLength(255).IsRequired();
        user.Property(x => x.Phone).HasMaxLength(20).IsRequired();
        user.Property(x => x.CreatedAtUtc).IsRequired();
        user.Property(x => x.UpdatedAtUtc).IsRequired();

        user.HasIndex(x => x.TcNo).IsUnique();
        user.HasIndex(x => x.Email).IsUnique();
    }
}
