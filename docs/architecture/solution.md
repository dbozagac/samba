# Solution Design

## Chosen Stack

- Backend: ASP.NET Core Web API (net10.0)
- Database: PostgreSQL
- Auth: Firebase Authentication (ID Token) — Google Sign-In on all clients
- Web: Next.js + React + TypeScript
- Mobile: Flutter (iOS & Android) — Google Sign-In (no anonymous auth)
- Deployment: Docker + GitHub Actions + Render/Fly.io

## High-Level Architecture

1. `apps/backend` exposes REST endpoints under `/api/*`.
2. `apps/web` and `apps/mobile` call the same backend endpoints.
3. Firebase signs users in via Google; clients attach `Bearer <idToken>`.
4. Backend validates token issuer/audience against Firebase Project ID.
5. PostgreSQL persists application data.
6. Each record is scoped to its owner via `OwnerFirebaseUid`.

## API Contract

- `GET  /api/users?page=&pageSize=&search=&sortBy=&sortDesc=` → `PagedResponse<UserResponse>`
- `GET  /api/users/{id}`
- `POST /api/users`
- `PUT  /api/users/{id}`
- `DELETE /api/users/{id}`
- `GET  /api/auth/me`
- `GET  /health` (anonymous, with DB readiness check)
- `GET  /openapi/v1.json` (development only)

## Error Model

All error responses follow RFC 7807 ProblemDetails:

```json
{
  "type": "https://tools.ietf.org/html/rfc7807",
  "title": "Conflict",
  "status": 409,
  "detail": "Bu TC No zaten kayıtlı.",
  "errors": { "tcNo": ["Bu TC No zaten kayıtlı."] }
}
```

## Security

- Every business endpoint is protected with `[Authorize]`.
- Owner scope: queries filter by `OwnerFirebaseUid` extracted from JWT claims.
- CORS is scoped by `Cors:AllowedOrigins`.
- Firebase token validation uses issuer `https://securetoken.google.com/{projectId}` and audience `{projectId}`.
- Rate limiting: fixed window (100 req/min per client).
- Request-ID propagation via `X-Request-Id` header.

## Database

- ORM: Entity Framework Core 10 with Npgsql provider.
- Schema management: EF Migrations (startup auto-applies pending migrations; falls back to EnsureCreated when no migrations exist).
- Unique indexes on `TcNo` and `Email`.
- Index on `OwnerFirebaseUid` for tenant-scoped queries.

### Migration Commands

```bash
cd apps/backend
dotnet ef migrations add <MigrationName>
dotnet ef database update
```

## Scalability Notes

- Backend and web deploy independently.
- PostgreSQL can be moved from container to managed service without code changes.
- Redis cache/queue can be added later for high read/write traffic.
- Pagination prevents unbounded data retrieval.

## Alternative Tech Options

- Web alternatives: Nuxt, SvelteKit.
- Mobile alternatives: React Native (Expo), Kotlin Multiplatform.
- Auth alternatives: Keycloak, Auth0, custom JWT provider.
