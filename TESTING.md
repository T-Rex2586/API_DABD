# TESTING.md — Dokumentasi Pengujian

Dokumentasi tiap pengujian pada demo **REST vs GraphQL (API_DABD)**: apa yang
diuji, teori di baliknya, ekspektasi, cara menguji dari repo ini, dan hasil nyata
yang diamati.

## Konvensi

Tiap uji memakai format:

1. **Tujuan** — apa yang divalidasi
2. **Teori** — kenapa hasilnya begitu (konsep/mekanisme)
3. **Ekspektasi** — hasil yang benar
4. **Cara uji** — perintah persis (PowerShell & bash/curl)
5. **Hasil** — yang benar-benar teramati

## Prasyarat & urutan start

```powershell
# 1. Database
cd Database; docker compose up -d

# 2. REST (port 8000)
cd ..\REST; uv sync; uv run uvicorn rest.app:app --port 8000

# 3. GraphQL (port 4000) — dev
cd ..\graphql; npm install; npm run dev
```

Mode production GraphQL (untuk uji keamanan):
```powershell
$env:NODE_ENV = "production"; node server.js
```

Variabel yang dipakai di dokumen: `NIM=M0000001`, `BASE=http://127.0.0.1:8000`,
`GQL=http://127.0.0.1:4000/graphql`.

---

# A. Basis

## A1. Seed database

**Tujuan** — Memastikan skema 11 tabel dan data sample terisi.

**Teori** — Container `postgres:17` me-mount `Database/Kampus.sql` ke
`/docker-entrypoint-initdb.d/init.sql`. Image Postgres menjalankan seluruh file
di folder itu **sekali saat volume pertama dibuat** (`initdb`). `security.sql`
di-mount sebagai `zz_security.sql` agar berjalan **setelah** `init.sql`
(urutan alfabet: `init.sql` < `zz_security.sql`).

**Ekspektasi** — 11 tabel; baris: fakultas 5, program_studi 10, dosen 30,
mahasiswa 500, mata_kuliah 40, kelas 60, krs 1200, nilai_akhir 1200,
presensi_kuliah 1200.

**Cara uji**
```powershell
# PowerShell
docker exec postgres-kampus psql -U postgres -d kampus -c "\dt"
docker exec postgres-kampus psql -U postgres -d kampus -c "SELECT (SELECT count(*) FROM mahasiswa) AS mhs, (SELECT count(*) FROM krs) AS krs;"
```
```bash
# bash
docker exec postgres-kampus psql -U postgres -d kampus -c "\dt"
docker exec postgres-kampus psql -U postgres -d kampus -c "SELECT (SELECT count(*) FROM mahasiswa) AS mhs, (SELECT count(*) FROM krs) AS krs;"
```

> Catatan: reset penuh = `docker compose down -v; docker compose up -d`
> (menghapus volume lalu menjalankan ulang init → seed + policy).

**Hasil** — `\dt` menampilkan 11 tabel; `mhs = 500`, `krs = 1200`.

---

## A2. REST API

**Tujuan** — Memastikan 4 endpoint REST + Swagger hidup.

**Teori** — `rest.app:app` (FastAPI) memakai connection pool psycopg
(`database.py`) dan query SQL mentah (`routes.py`). FastAPI otomatis membuka
`/docs`, `/redoc`, `/openapi.json`.

**Ekspektasi** — Semua 200; `/api/mahasiswa/{nim}` mengembalikan profil+prodi+
fakultas; `/krs` mengembalikan KRS lengkap; `/hasil` mengembalikan nilai+presensi.

**Cara uji**
```powershell
# PowerShell
Invoke-RestMethod "http://127.0.0.1:8000/api/mahasiswa/M0000001" | ConvertTo-Json
(Invoke-RestMethod "http://127.0.0.1:8000/api/mahasiswa/M0000001/krs").Count
(Invoke-RestMethod "http://127.0.0.1:8000/api/krs/1/hasil").Count
(Invoke-WebRequest "http://127.0.0.1:8000/docs" -UseBasicParsing).StatusCode
```
```bash
# bash
curl -s http://127.0.0.1:8000/api/mahasiswa/M0000001
curl -s http://127.0.0.1:8000/api/mahasiswa/M0000001/krs
curl -s http://127.0.0.1:8000/api/krs/1/hasil
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/docs
```

**Hasil** — profil M0000001 (`nama_prodi: Sains Data`); KRS count 3; hasil count 1;
`/docs` → 200.

---

## A3. REST mutasi presensi (insert + upsert)

**Tujuan** — Memvalidasi penulisan: insert baris baru lalu update baris yang sama.

**Teori** — Tabel `presensi_kuliah` punya constraint
`UNIQUE (krs_id, pertemuan_ke)`. Endpoint memakai
`INSERT ... ON CONFLICT (krs_id, pertemuan_ke) DO UPDATE` sehingga request
dengan pertemuan yang sama akan **meng-update**, bukan menambah baris.

**Ekspektasi** — Pertemuan baru → jumlah presensi +1 (id baru). Pertemuan yang
sama dengan status berbeda → jumlah tetap, `presensi_id` sama, status berubah.

**Cara uji**
```powershell
# PowerShell
# insert pertemuan 2
Invoke-RestMethod "http://127.0.0.1:8000/api/krs/1/presensi" -Method Post -ContentType "application/json" -Body '{"pertemuan_ke":2,"status_kehadiran":"Hadir"}'
# upsert pertemuan 2 dengan status berbeda
Invoke-RestMethod "http://127.0.0.1:8000/api/krs/1/presensi" -Method Post -ContentType "application/json" -Body '{"pertemuan_ke":2,"status_kehadiran":"Izin"}'
(Invoke-RestMethod "http://127.0.0.1:8000/api/krs/1/hasil").Count
```
```bash
# bash
curl -s -X POST http://127.0.0.1:8000/api/krs/1/presensi -H 'content-type: application/json' -d '{"pertemuan_ke":2,"status_kehadiran":"Hadir"}'
curl -s -X POST http://127.0.0.1:8000/api/krs/1/presensi -H 'content-type: application/json' -d '{"pertemuan_ke":2,"status_kehadiran":"Izin"}'
curl -s http://127.0.0.1:8000/api/krs/1/hasil
```

**Hasil** — Insert: `presensi_id: 1201`, count `1 → 2`. Upsert: tetap
`presensi_id: 1201`, `status_kehadiran: "Izin"`, count tetap `2`.

> Angka awal bergantung state DB. Yang penting polanya: pertemuan baru menambah
> **1 baris** (id baru); pengulangan pertemuan sama **tidak** menambah baris dan
> mempertahankan `presensi_id`.

---

## A4. GraphQL dasar

**Tujuan** — Memastikan schema PostGraphile terbentuk dan query mengembalikan data.

**Teori** — PostGraphile meng-introspect schema `public` lalu membangun API
GraphQL otomatis (endpoint tunggal `POST /graphql`).

**Ekspektasi** — Query sederhana & bertingkat mengembalikan data; GraphiQL tampil di `/`.

**Cara uji**
```powershell
# PowerShell
Invoke-RestMethod http://127.0.0.1:4000/graphql -Method Post -ContentType "application/json" -Body '{"query":"{ allFakultas(first:1){ nodes { namaFakultas } } }"}'
(Invoke-WebRequest http://127.0.0.1:4000/ -UseBasicParsing).StatusCode
```
```bash
# bash
curl -s http://127.0.0.1:4000/graphql -H 'content-type: application/json' -d '{"query":"{ allFakultas(first:1){ nodes { namaFakultas } } }"}'
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:4000/
```

**Hasil** — Query mengembalikan `Fakultas Teknologi Informasi dan Sains`;
GraphiQL di `/` → 200 `text/html`.

---

# B. Perbandingan REST vs GraphQL

## B1. Round-trip (apple-to-apple)

**Tujuan** — Membandingkan jumlah request untuk **data yang sama**: profil
mahasiswa + KRS + nilai tiap KRS.

**Teori** — REST bersifat resource-oriented: satu URL = satu resource, sehingga
butuh beberapa panggilan (1 profil + 1 daftar KRS + N nilai). GraphQL punya satu
endpoint dan graph relasi, sehingga seluruh kebutuhan diambil dalam **satu query**.

**Ekspektasi** — REST = `2 + N` request; GraphQL = `1` request.

**Cara uji**
```powershell
# PowerShell
.\demo\roundtrip.ps1
```
```bash
# bash (Linux/macOS atau Git Bash)
bash demo/roundtrip.sh
```

**Hasil** — `M0000001`: **REST 5 request** (1 profil + 1 KRS + 3 nilai)
vs **GraphQL 1 request**. Kedua skrip konsisten.

---

## B2. Field selection (over/under-fetching)

**Tujuan** — Menunjukkan client hanya mengambil field yang dibutuhkan.

**Teori** — Di REST, bentuk respons ditentukan server (bisa over-fetch). Di
GraphQL, selection set menentukan persis field yang dikembalikan.

**Ekspektasi** — Query dengan subset field hanya mengembalikan field itu
(mis. hanya `namaDosen`).

**Cara uji** — Jalankan `demo/graphql/02-field-selection.graphql` di GraphiQL,
atau:
```bash
curl -s http://127.0.0.1:4000/graphql -H 'content-type: application/json' \
  -d '{"query":"{ allMahasiswas(first:3){ nodes { nim } } }"}'
```

**Hasil** — Hanya `nim` yang dikembalikan (tanpa field lain), membuktikan
tidak ada over-fetching.

---

# C. Keamanan GraphQL

## C1. Depth limit

**Tujuan** — Menolak query yang terlalu dalam (mitigasi DoS lewat query bersarang).

**Teori** — Plugin `SecurityPlugin` (`graphql/plugins.js`) menyuntikkan aturan
`depthLimit({ maxDepth: 12, maxListDepth: 4, maxSelfReferentialDepth: 2 })` dari
`@graphile/depth-limit` ke `event.validationRules` pada hook `setPreset`. Aturan
ini divalidasi **sebelum** eksekusi.

**Ekspektasi** — Query kedalaman > 12 ditolak dengan pesan
`exceeds operation depth limits`.

**Cara uji**
```powershell
# PowerShell — query kedalaman ~15
$q = '{ allMahasiswas(first: 1) { nodes { krsByMahasiswaId(first: 1) { nodes { kelasByKelasId { krsByKelasId(first: 1) { nodes { mahasiswaByMahasiswaId { krsByMahasiswaId(first: 1) { nodes { kelasByKelasId { mataKuliahByMatkulId { programStudiByProdiId { fakultasByFakultasId { kodeFakultas } } } } } } } } } } } } } } }'
$body = @{ query = $q } | ConvertTo-Json
Invoke-RestMethod http://127.0.0.1:4000/graphql -Method Post -ContentType "application/json" -Body $body
```
```bash
# bash
curl -s http://127.0.0.1:4000/graphql -H 'content-type: application/json' \
  -d '{"query":"{ allMahasiswas(first: 1) { nodes { krsByMahasiswaId(first: 1) { nodes { kelasByKelasId { krsByKelasId(first: 1) { nodes { mahasiswaByMahasiswaId { krsByMahasiswaId(first: 1) { nodes { kelasByKelasId { mataKuliahByMatkulId { programStudiByProdiId { fakultasByFakultasId { kodeFakultas } } } } } } } } } } } } } } }"}'
```

**Hasil** — `400` + `'(anonymous)' exceeds operation depth limits` (query
kedalaman ≤ 12 seperti `01-nested.graphql` tetap sukses).

---

## C2. Disable introspection (dev vs production)

**Tujuan** — Menyembunyikan schema dari publik di production.

**Teori** — Bila `NODE_ENV=production`, `SecurityPlugin` menambahkan
`NoSchemaIntrospectionCustomRule` (bawaan `graphql`). Di dev tidak ditambahkan
agar GraphiQL/autocomplete tetap berfungsi. `graphiql` juga mati di production.

**Ekspektasi** — Dev: introspection jalan. Production: `400 GraphQL introspection
has been disabled`.

**Cara uji**
```powershell
# PowerShell — restart dulu dengan NODE_ENV=production
Invoke-RestMethod http://127.0.0.1:4000/graphql -Method Post -ContentType "application/json" -Body '{"query":"{ __schema { queryType { name } } }"}'
```
```bash
# bash
curl -s -i http://127.0.0.1:4000/graphql -H 'content-type: application/json' \
  -d '{"query":"{ __schema { queryType { name } } }"}'
```

**Hasil** — Production: `400` +
`GraphQL introspection has been disabled, but the requested query contained the
field "__schema"`. Query data biasa tetap 200. Dev: introspection mengembalikan
schema.

---

## C3. Persisted operations (query allow-list)

**Tujuan** — Di production, hanya operasi terdaftar yang boleh dieksekusi.

**Teori** — Plugin `PersistedPlugin` (`@grafserv/persisted`) memetakan `id`
request ke query terdaftar (`grafserv.persistedOperations` di
`graphile.config.js`). `allowUnpersistedOperation: NODE_ENV !== "production"`
membuat dev bebas, production ketat.

**Ekspektasi** — Tanpa id / id asing → `400`. `id` terdaftar → 200 + data.

**Cara uji** (`NODE_ENV=production`)
```powershell
# PowerShell
Invoke-RestMethod http://127.0.0.1:4000/graphql -Method Post -ContentType "application/json" -Body '{"id":"GetAllFakultas"}'
Invoke-RestMethod http://127.0.0.1:4000/graphql -Method Post -ContentType "application/json" -Body '{"id":"GetMahasiswaByNim","variables":{"nim":"M0000001"}}'
Invoke-RestMethod http://127.0.0.1:4000/graphql -Method Post -ContentType "application/json" -Body '{"query":"{ allFakultas { nodes { namaFakultas } } }"}'
```
```bash
# bash
curl -s http://127.0.0.1:4000/graphql -H 'content-type: application/json' -d '{"id":"GetAllFakultas"}'
curl -s http://127.0.0.1:4000/graphql -H 'content-type: application/json' -d '{"id":"GetMahasiswaByNim","variables":{"nim":"M0000001"}}'
curl -s -i http://127.0.0.1:4000/graphql -H 'content-type: application/json' -d '{"id":"NopeNotAllowed"}'
```

**Hasil** — `GetAllFakultas` → 200 (5 fakultas); `GetMahasiswaByNim` → 200
(M0000001); tanpa id / id asing → `400 "Persisted operations are enabled on this
server, please provide an approved document id."`.

---

## C4. Row Level Security (RLS) + role switching

**Tujuan** — Membatasi baris data di level database sesuai identitas pemanggil.

**Teori** — `Database/security.sql` membuat role `kampus_anonymous` &
`kampus_mahasiswa`, mengaktifkan RLS, dan menetapkan policy (mis. mahasiswa hanya
melihat barisnya). `graphile.config.js` memetakan header `x-demo-role` &
`x-demo-mahasiswa-id` ke `pgSettings.role` dan `jwt.claims.mahasiswa_id`;
PostGraphile menjalankan `SET ROLE` per request sehingga policy berlaku. Tanpa
header, koneksi memakai superuser `postgres` yang **bypass RLS**.

**Ekspektasi** — Tanpa header: `allKrs=1200`, `allMahasiswas=500`. Header
`kampus_mahasiswa` id=1: `allKrs=3`, `allMahasiswas=1`.

**Cara uji**
```powershell
# PowerShell — tanpa header
Invoke-RestMethod http://127.0.0.1:4000/graphql -Method Post -ContentType "application/json" -Body '{"query":"{ allKrs { totalCount } allMahasiswas { totalCount } }"}'
# dengan header
$h = @{ "x-demo-role"="kampus_mahasiswa"; "x-demo-mahasiswa-id"="1" }
Invoke-RestMethod http://127.0.0.1:4000/graphql -Method Post -Headers $h -ContentType "application/json" -Body '{"query":"{ allKrs { totalCount } allMahasiswas { totalCount } }"}'
```
```bash
# bash
curl -s http://127.0.0.1:4000/graphql -H 'content-type: application/json' -d '{"query":"{ allKrs { totalCount } allMahasiswas { totalCount } }"}'
curl -s http://127.0.0.1:4000/graphql -H 'content-type: application/json' \
  -H 'x-demo-role: kampus_mahasiswa' -H 'x-demo-mahasiswa-id: 1' \
  -d '{"query":"{ allKrs { totalCount } allMahasiswas { totalCount } }"}'
```

Cek policy di database:
```bash
docker exec postgres-kampus psql -U postgres -d kampus -c "SELECT policyname, tablename FROM pg_policies WHERE schemaname='public' ORDER BY tablename;"
docker exec postgres-kampus psql -U postgres -d kampus -c "SELECT relname, relrowsecurity FROM pg_class WHERE relname IN ('fakultas','krs','mahasiswa','nilai_akhir','presensi_kuliah');"
```

**Hasil** — Tanpa header `1200 / 500`; dengan header `3 / 1`. 8 policy, RLS aktif
di 5 tabel.

---

# D. Performa

## D1. N+1 / query plan

**Tujuan** — Membuktikan pengambilan data bertingkat tidak menghasilkan N+1 query.

**Teori** — Grafast (mesin PostGraphile v5) menyusun *query plan* dan melakukan
**batching**: puluhan baris + relasinya digabung menjadi satu SQL (memakai
subquery/join ter-agregasi). Dengan `grafast.explain` (dev), respons memuat
`extensions.explain.operations`; entri bertipe `sql` menampilkan query yang
dieksekusi.

**Ekspektasi** — Berapa pun jumlah baris, nested fetch = **1 SQL**.

> `grafast.explain` hanya aktif di dev (`NODE_ENV !== "production"`). Di
> production, `extensions.explain` tidak ada.

**Cara uji**
```powershell
# PowerShell — hitung operasi SQL untuk 50 mahasiswa
$q = '{ allMahasiswas(first: 50) { nodes { nim krsByMahasiswaId { nodes { kelasByKelasId { namaKelas mataKuliahByMatkulId { namaMatkul } dosenByDosenId { namaDosen } } } } } } }'
$body = @{ query = $q } | ConvertTo-Json
$r = Invoke-RestMethod http://127.0.0.1:4000/graphql -Method Post -ContentType "application/json" -Body $body
"SQL statements: " + @($r.extensions.explain.operations | Where-Object { $_.type -eq 'sql' }).Count
```
```bash
# bash
curl -s http://127.0.0.1:4000/graphql -H 'content-type: application/json' \
  -d '{"query":"{ allMahasiswas(first: 50) { nodes { nim krsByMahasiswaId { nodes { kelasByKelasId { namaKelas } } } } } }"}' \
  | grep -o '"type":"sql"' | wc -l
```

Alternatif GUI: buka GraphiQL/Ruru, jalankan query, lihat tab **Explain**.

**Hasil** — 3 mahasiswa (9 KRS) = **1 SQL**; 50 mahasiswa (150 KRS) = **1 SQL**.

---

# E. Inflection

## E1. Tanpa singularisasi

**Tujuan** — Nama tipe mengikuti nama tabel (tidak disingularisasi).

**Teori** — Default Amber men-singularisasi (`fakultas` → `Fakulta`).
`NoSingularizePlugin` meng-*override* inflector `singularize` menjadi identity
lewat `inflection.replace`.

**Ekspektasi** — Tipe `Fakultas`, `Kelas`, `Krs`; relasi `kelasByKelasId`,
`fakultasByFakultasId`. Field root tetap `allFakultas`/`allKrs`.

**Cara uji** — Jalankan di GraphiQL:
```graphql
{ fakultas: __type(name: "Fakultas") { name } lama: __type(name: "Fakulta") { name } }
```
atau:
```bash
curl -s http://127.0.0.1:4000/graphql -H 'content-type: application/json' \
  -d '{"query":"{ fakultas: __type(name: \"Fakultas\") { name } lama: __type(name: \"Fakulta\") { name } }"}'
```

**Hasil** — `Fakultas` ada; `Fakulta` `null`. `allFakultas`/`allKrs` tetap berlaku.

---

# F. Lampiran: Renormalize git (CRLF)

**Tujuan** — Menghilangkan noise line-ending (`core.autocrlf=true` di Windows).

**Teori** — Tanpa `.gitattributes`, Windows menyimpan CRLF sementara repo LF,
sehingga banyak file "terlihat" berubah padahal isinya sama.

**Ekspektasi** — `git status` hanya menampilkan perubahan isi nyata.

**Cara uji**
```bash
cat .gitattributes          # -> * text=auto eol=lf
git diff --numstat          # -> hanya file yang benar-benar berubah
```

**Hasil** — Setelah `.gitattributes` + `git add --renormalize .`, file
"berubah palsu" (Kampus.sql, REST/*, dll) hilang dari `git status`.
