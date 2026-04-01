# Samba Monorepo

Bu repo aşağıdaki yapıda çalışır:

- `apps/backend`: ASP.NET Core Web API + PostgreSQL + Firebase JWT doğrulama
- `apps/web`: Next.js (React + TypeScript)
- `apps/mobile`: Flutter
- `infra`: Docker/Render/Fly.io deploy dosyaları

## 1) Mimarinin Özeti

- Tek backend servis (`apps/backend`) hem web hem mobil için ortak API sunar.
- Kimlik doğrulama Firebase Authentication ile yapılır.
- Web ve mobil istemciler Firebase ID token alıp API'ye `Bearer` olarak gönderir.
- Veriler PostgreSQL'de tutulur.

Detay: [docs/architecture/solution.md](/Users/doruk.bozagac/Documents/GitSamba/samba/docs/architecture/solution.md)

## 2) Lokal Geliştirme (Docker ile)

1. `.env.example` dosyasını kopyalayın:

```bash
cp .env.example .env
```

2. Firebase değişkenlerini doldurun (`.env`).
3. Çalıştırın:

```bash
docker compose up --build
```

Servisler:

- Web: `http://localhost:3000`
- Backend: `http://localhost:8080`
- Postgres: `localhost:5432`

## 3) Lokal Geliştirme (Servisleri ayrı çalıştırma)

### Backend

```bash
cd apps/backend
dotnet restore
dotnet run
```

### Web

```bash
cd apps/web
cp .env.example .env.local
npm install
npm run dev
```

### Mobile

```bash
cd apps/mobile
cp ../../.env.mobile.example .env.mobile
flutter pub get
flutter run --dart-define-from-file=.env.mobile
```

`API_BASE_URL` boş bırakılırsa Android emülatörde `10.0.2.2`, iOS simülatörde `127.0.0.1` kullanılır.

## 4) API Endpoints

- `GET /api/users?page=&pageSize=&search=&sortBy=&sortDesc=` (paginated)
- `GET /api/users/{id}`
- `POST /api/users`
- `PUT /api/users/{id}`
- `DELETE /api/users/{id}`
- `GET /api/auth/me`
- `GET /health` (anonymous, DB readiness)
- `GET /openapi/v1.json` (development only)

## 5) CI/CD ve Deploy

- CI: [`.github/workflows/ci.yml`](/Users/doruk.bozagac/Documents/GitSamba/samba/.github/workflows/ci.yml)
- Render örneği: [`infra/render/render.yaml`](/Users/doruk.bozagac/Documents/GitSamba/samba/infra/render/render.yaml)
- Fly.io örneği: [`infra/fly/backend.fly.toml`](/Users/doruk.bozagac/Documents/GitSamba/samba/infra/fly/backend.fly.toml), [`infra/fly/web.fly.toml`](/Users/doruk.bozagac/Documents/GitSamba/samba/infra/fly/web.fly.toml)

## 6) Önemli Notlar

- `apps/web` için `npm install` sonrası `package-lock.json` oluşacak.
- iOS/Android/Web için Firebase proje kimlikleri aynı `projectId` altında olmalı.
- Mobilde Google Sign-In için `GOOGLE_WEB_CLIENT_ID` (Android + iOS), iOS'ta ayrıca `GOOGLE_IOS_CLIENT_ID` girin.
- Firebase token doğrulaması için backend'de `Firebase:ProjectId` doğru olmalıdır.
