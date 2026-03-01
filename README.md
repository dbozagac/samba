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
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080 \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=...
```

## 4) API Endpoints
- `GET /api/users`
- `GET /api/users/{id}`
- `POST /api/users`
- `PUT /api/users/{id}`
- `DELETE /api/users/{id}`
- `GET /api/auth/me`
- `GET /health`

## 5) CI/CD ve Deploy
- CI: [`.github/workflows/ci.yml`](/Users/doruk.bozagac/Documents/GitSamba/samba/.github/workflows/ci.yml)
- Render örneği: [`infra/render/render.yaml`](/Users/doruk.bozagac/Documents/GitSamba/samba/infra/render/render.yaml)
- Fly.io örneği: [`infra/fly/backend.fly.toml`](/Users/doruk.bozagac/Documents/GitSamba/samba/infra/fly/backend.fly.toml), [`infra/fly/web.fly.toml`](/Users/doruk.bozagac/Documents/GitSamba/samba/infra/fly/web.fly.toml)

## 6) Önemli Notlar
- `apps/web` için `npm install` sonrası `package-lock.json` oluşacak.
- `apps/mobile` için iOS/Android platform kurulumlarını `flutterfire configure` ile tamamlayın.
- Firebase token doğrulaması için backend'de `Firebase:ProjectId` doğru olmalıdır.
