# DEMO — REST vs GraphQL (API_DABD)

Perbandingan REST (FastAPI) vs GraphQL (PostGraphile v5) di atas satu database
PostgreSQL `kampus`, sekaligus eksplorasi aspek keamanan & performa GraphQL.

> Dokumentasi tiap pengujian (tujuan, teori, ekspektasi, cara uji, hasil):
> lihat [TESTING.md](TESTING.md).

## Prasyarat

- Docker Desktop (backend WSL2) — menjalankan PostgreSQL 17
- Node.js >= 18 (diuji v24)
- `uv` (menjalankan REST / Python 3.14)

## Struktur

| Folder | Isi |
| --- | --- |
| `Database/` | `Kampus.sql` (schema + seed), `security.sql` (role + RLS), `docker-compose.yml` |
| `REST/` | FastAPI, endpoint `/api/...` (+ `/docs`) |
| `graphql/` | PostGraphile v5 + Express + plugin keamanan (`plugins.js`) |
| `demo/` | Aset demo: query GraphQL, request REST, skrip hitung round-trip |

## Menjalankan (urutan)

### 1. Database
```powershell
cd Database
docker compose up -d
```
Reset penuh (re-seed + terapkan `security.sql`):
```powershell
docker compose down -v; docker compose up -d
```

### 2. REST (FastAPI) — port 8000
```powershell
cd REST
uv sync
uv run uvicorn rest.app:app --port 8000
```

### 3. GraphQL (PostGraphile) — port 4000
```powershell
cd graphql
npm install
npm run dev        # dev: GraphiQL aktif, introspection aktif
```
Mode production (keamanan ketat):
```powershell
$env:NODE_ENV = "production"; node server.js
```

## Checklist verifikasi

| # | Uji | Cara | Ekspektasi |
| --- | --- | --- | --- |
| 1 | DB ter-seed | `docker exec postgres-kampus psql -U postgres -d kampus -c "select count(*) from mahasiswa;"` | 500 |
| 2 | REST hidup | `GET http://127.0.0.1:8000/docs` | 200 |
| 3 | GraphQL hidup | buka `http://localhost:4000/` | GraphiQL tampil |
| 4 | Query bertingkat | `demo/graphql/01-nested.graphql` | data + **1 SQL** (lihat Explain) |
| 5 | Depth limit | query sangat dalam (lihat `03` catatan) | ditolak `exceeds operation depth limits` |
| 6 | Introspection prod | `NODE_ENV=production` lalu query `__schema` | ditolak `GraphQL introspection has been disabled` |
| 7 | Persisted ops (prod) | kirim `{ "id": "GetAllFakultas" }` | 200; tanpa id / id asing | ditolak `400` |
| 8 | RLS | header `x-demo-role: kampus_mahasiswa`, `x-demo-mahasiswa-id: 1` | `allKrs.totalCount` 1200 → 3, `allMahasiswas` 500 → 1 |

## REST vs GraphQL — apple to apple

Kebutuhan: **profil mahasiswa + daftar KRS + nilai tiap KRS**.

- REST: `GET /api/mahasiswa/{nim}` (1) + `GET /api/mahasiswa/{nim}/krs` (1) +
  `GET /api/krs/{id}/hasil` untuk **tiap** KRS (N) = **2 + N request**.
- GraphQL: **1 request** (`demo/graphql/01-nested.graphql`).

Jalankan skrip pembanding:
```powershell
# Windows
pwsh -File demo/roundtrip.ps1
# Linux / macOS
bash demo/roundtrip.sh
```

## Aspek GraphQL yang didemokan

- **Satu endpoint, field dipilih client** (`demo/graphql/02-field-selection.graphql`).
- **Tidak ada N+1**: satu query bertingkat = **1 SQL** (Grafast query planning).
  Bukti: aktifkan `grafast.explain` (dev) lalu lihat `extensions.explain.operations`
  bertipe `sql` di respons, atau tab Explain di Ruru/GraphiQL.
- **Keamanan**:
  - Depth limit (`@graphile/depth-limit`) — cegah query terlalu dalam.
  - Disable introspection hanya di `NODE_ENV=production`.
  - Persisted operations / query allow-list (`@grafserv/persisted`): di production
    hanya query terdaftar yang boleh dieksekusi.
  - RLS di level database (bukan hanya aplikasi) via `pgSettings.role`.
- **Trade-off caching**: REST punya caching HTTP natural per-URL (ETag/CDN),
  GraphQL satu endpoint POST sehingga caching bergantung pada persisted query +
  client normalized cache (Apollo/Relay/urql).

## Catatan penamaan schema

Inflection Amber men-singularisasi nama (mis. `fakultas` → `Fakulta`). Plugin
`NoSingularizePlugin` mematikannya, sehingga tipe = nama tabel:

- Tipe: `Fakultas`, `Kelas`, `Krs` (bukan `Fakulta`, `Kela`, `Kr`)
- Root field tetap: `allFakultas`, `allKrs`, `allKelas`, `allMahasiswas`
- Relasi sekarang: `kelasByKelasId`, `fakultasByFakultasId` (bukan `kela...`, `fakulta...`)

## Header demo (RLS)

```
x-demo-role: kampus_mahasiswa
x-demo-mahasiswa-id: 1
```
Tanpa header → role superuser (lihat semua). `kampus_anonymous` juga tersedia
(hanya tabel publik: fakultas, program_studi, mata_kuliah, ruangan).
