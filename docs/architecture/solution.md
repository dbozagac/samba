# Solution Design

## Chosen Stack
- Backend: ASP.NET Core Web API (net10.0)
- Database: PostgreSQL
- Auth: Firebase Authentication (ID Token)
- Web: Next.js + React + TypeScript
- Mobile: Flutter
- Deployment: Docker + GitHub Actions + Render/Fly.io

## High-Level Architecture
1. `apps/backend` exposes REST endpoints under `/api/*`.
2. `apps/web` and `apps/mobile` call the same backend endpoints.
3. Firebase signs users in; clients attach `Bearer <idToken>`.
4. Backend validates token issuer/audience against Firebase Project ID.
5. PostgreSQL persists application data.

## API Contract
- `GET /api/users`
- `GET /api/users/{id}`
- `POST /api/users`
- `PUT /api/users/{id}`
- `DELETE /api/users/{id}`
- `GET /api/auth/me`

## Security
- Every business endpoint is protected with `[Authorize]`.
- CORS is scoped by `Cors:AllowedOrigins`.
- Firebase token validation uses issuer `https://securetoken.google.com/{projectId}` and audience `{projectId}`.

## Scalability Notes
- Backend and web deploy independently.
- PostgreSQL can be moved from container to managed service without code changes.
- Redis cache/queue can be added later for high read/write traffic.

## Alternative Tech Options
- Web alternatives: Nuxt, SvelteKit.
- Mobile alternatives: React Native (Expo), Kotlin Multiplatform.
- Auth alternatives: Keycloak, Auth0, custom JWT provider.

