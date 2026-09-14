# TESTING.md — Dokumentasi Pengujian

Dokumentasi tiap pengujian pada demo **REST vs GraphQL (API_DABD)**: apa yang
diuji, teori di baliknya, ekspektasi, cara menguji dari repo ini, dan hasil nyata
yang diamati.

## Konvensi

Tiap uji memakai format:

1. **Tujuan** — apa yang divalidasi
2. **Teori** — kenapa hasilnya begitu (konsep/mekanisme)
3. **Ekspektasi** — hasil yang benar
4. **Cara uji** — langkah persis
5. **Hasil** — yang benar-benar teramati

## Cara menguji: pakai UI web

Contoh pengujian di dokumen ini memakai antarmuka web:

- **REST** → **Swagger / OpenAPI** di `http://127.0.0.1:8000/docs`.
  Buka endpoint → **Try it out** → isi parameter/body → **Execute**.
- **GraphQL** → **GraphiQL (Ruru)** di `http://localhost:4000/`.
  Tempel query (bahasa GraphQL saja) → **Run**.
  - **Headers** (tab bawah) untuk mengirim header (mis. RLS).
  - **Variables** (tab bawah) untuk variabel query.
  - **Explain** (tab bawah) untuk melihat query plan & SQL.

Uji yang memang bukan API (seed database, git) tetap memakai perintah
DB/git — ditandai khusus.

## Prasyarat & urutan start

```powershell
# 1. Database
cd Database; docker compose up -d

# 2. REST (port 8000)
cd ..\REST; uv sync; uv run uvicorn rest.app:app --port 8000

# 3. GraphQL (port 4000)
cd ..\graphql; npm install; npm run dev
```

Mode production GraphQL (untuk uji keamanan):
```powershell
$env:NODE_ENV = "production"; node server.js
```

> GraphiQL sengaja **selalu aktif** (`graphiql: true`) agar uji keamanan bisa
> dilakukan dari browser. Yang berubah saat `NODE_ENV=production` hanyalah:
> introspection dimatikan dan persisted operations ditegakkan.

Variabel yang dipakai: `NIM=M0000001`.

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

**Cara uji** — *bukan API; pakai psql di container*
```powershell
docker exec postgres-kampus psql -U postgres -d kampus -c "\dt"
docker exec postgres-kampus psql -U postgres -d kampus -c "SELECT (SELECT count(*) FROM mahasiswa) AS mhs, (SELECT count(*) FROM krs) AS krs;"
```

> Reset penuh: `docker compose down -v; docker compose up -d`
> (menghapus volume → menjalankan ulang init → seed + policy).

**Hasil** — `\dt` menampilkan 11 tabel; `mhs = 500`, `krs = 1200`.

---

## A2. REST API (Swagger)

**Tujuan** — Memastikan 4 endpoint REST hidup.

**Teori** — `rest.app:app` (FastAPI) memakai connection pool psycopg
(`database.py`) dan query SQL mentah (`routes.py`). FastAPI otomatis membuka
Swagger di `/docs`.

**Ekspektasi** — Semua 200; `/api/mahasiswa/{nim}` mengembalikan profil+prodi+
fakultas; `/krs` mengembalikan KRS lengkap; `/hasil` mengembalikan nilai+presensi.

**Cara uji** — buka `http://127.0.0.1:8000/docs`, lalu untuk tiap endpoint klik
**Try it out** → isi parameter → **Execute**:

| Endpoint | Parameter |
| --- | --- |
| `GET /api/mahasiswa/{nim}` | `nim = M0000001` |
| `GET /api/mahasiswa/{nim}/krs` | `nim = M0000001` |
| `GET /api/krs/{krs_id}/hasil` | `krs_id = 1` |
| `GET /docs` | (halaman Swagger itu sendiri) |

**Hasil** — `nama_prodi: Sains Data`; KRS count 3; hasil count 1; `/docs` → 200.

---

## A3. REST mutasi presensi (Swagger)

**Tujuan** — Memvalidasi penulisan: insert baris baru lalu update baris yang sama.

**Teori** — Tabel `presensi_kuliah` punya constraint
`UNIQUE (krs_id, pertemuan_ke)`. Endpoint memakai
`INSERT ... ON CONFLICT (krs_id, pertemuan_ke) DO UPDATE` sehingga request
dengan pertemuan yang sama akan **meng-update**, bukan menambah baris.

**Ekspektasi** — Pertemuan baru → jumlah presensi naik 1 (id baru). Pertemuan
yang sama dengan status berbeda → jumlah tetap, `presensi_id` sama, status berubah.

**Cara uji** — di Swagger, `POST /api/krs/{krs_id}/presensi`, `krs_id = 1`.
Request body:
```json
{ "pertemuan_ke": 2, "status_kehadiran": "Hadir" }
```
Jalankan lagi dengan body yang sama tetapi status berbeda:
```json
{ "pertemuan_ke": 2, "status_kehadiran": "Izin" }
```
Lalu cek jumlah baris di `GET /api/krs/1/hasil`.

**Hasil** — Insert: `presensi_id: 1201`, count `1 → 2`. Upsert: tetap
`presensi_id: 1201`, `status_kehadiran: "Izin"`, count tetap `2`.

> Angka awal bergantung state DB. Yang penting polanya: pertemuan baru menambah
> **1 baris** (id baru); pengulangan pertemuan sama **tidak** menambah baris dan
> mempertahankan `presensi_id`.

---

## A4. GraphQL dasar (GraphiQL)

**Tujuan** — Memastikan schema PostGraphile terbentuk dan query mengembalikan data.

**Teori** — PostGraphile meng-introspect schema `public` lalu membangun API
GraphQL otomatis (endpoint tunggal `POST /graphql`).

**Ekspektasi** — Query sederhana mengembalikan data; GraphiQL tampil di `/`.

**Cara uji** — buka `http://localhost:4000/`, tempel:
```graphql
{ allFakultas(first: 1) { nodes { namaFakultas } } }
```

**Hasil** — Mengembalikan `Fakultas Teknologi Informasi dan Sains`; halaman
GraphiQL tampil (200).

---

# B. Perbandingan REST vs GraphQL

## B1. Round-trip (apple-to-apple)

**Tujuan** — Membandingkan jumlah request untuk **data yang sama**: profil
mahasiswa + KRS + nilai tiap KRS.

**Teori** — REST bersifat resource-oriented: satu URL = satu resource, sehingga
butuh beberapa panggilan (1 profil + 1 daftar KRS + N nilai). GraphQL punya satu
endpoint dan graph relasi, sehingga seluruh kebutuhan diambil dalam **satu query**.

**Ekspektasi** — REST = `2 + N` request; GraphQL = `1` request.

**Cara uji** — *bukan UI; mengukur jumlah request, pakai skrip*
```powershell
.\demo\roundtrip.ps1
```
```bash
bash demo/roundtrip.sh
```

**Hasil** — `M0000001`: **REST 5 request** (1 profil + 1 KRS + 3 nilai)
vs **GraphQL 1 request**. Kedua skrip konsisten.

---

## B2. Field selection (over/under-fetching)

**Tujuan** — Menunjukkan client hanya mengambil field yang dibutuhkan.

**Teori** — Di REST, bentuk respons ditentukan server (bisa over-fetch). Di
GraphQL, selection set menentukan persis field yang dikembalikan.

**Ekspektasi** — Query dengan subset field hanya mengembalikan field itu.

**Cara uji** — di GraphiQL:
```graphql
{ allMahasiswas(first: 3) { nodes { nim } } }
```
(Bandingkan dengan `demo/graphql/02-field-selection.graphql`.)

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

**Cara uji** — di GraphiQL, tempel query kedalaman ~15:
```graphql
{
  allMahasiswas(first: 1) {
    nodes {
      krsByMahasiswaId(first: 1) {
        nodes {
          kelasByKelasId {
            krsByKelasId(first: 1) {
              nodes {
                mahasiswaByMahasiswaId {
                  krsByMahasiswaId(first: 1) {
                    nodes {
                      kelasByKelasId {
                        mataKuliahByMatkulId {
                          programStudiByProdiId {
                            fakultasByFakultasId { kodeFakultas }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

**Hasil** — `'(anonymous)' exceeds operation depth limits` (query kedalaman ≤ 12
seperti `01-nested.graphql` tetap sukses).

---

## C2. Disable introspection (production)

**Tujuan** — Menyembunyikan schema dari publik saat production.

**Teori** — Bila `NODE_ENV=production`, `SecurityPlugin` menambahkan
`NoSchemaIntrospectionCustomRule` (bawaan `graphql`). Di dev tidak ditambahkan
agar autocomplete GraphiQL berfungsi.

**Ekspektasi** — Production: query introspection ditolak.

**Cara uji** — jalankan server dengan `NODE_ENV=production` (GraphiQL tetap
aktif — lihat catatan di atas), buka `http://localhost:4000/`, tempel:
```graphql
{ __schema { queryType { name } } }
```

**Hasil** — `GraphQL introspection has been disabled, but the requested query
contained the field "__schema"`. Query data biasa (mis. `allFakultas`) tetap
berhasil.

---

## C3. Persisted operations (query allow-list)

**Tujuan** — Di production, hanya operasi terdaftar yang boleh dieksekusi.

**Teori** — Plugin `PersistedPlugin` (`@grafserv/persisted`) memetakan `id`
request ke query terdaftar (`grafserv.persistedOperations` di
`graphile.config.js`). `allowUnpersistedOperation: NODE_ENV !== "production"`
membuat dev bebas, production ketat.

**Ekspektasi** — Tanpa id / id asing → `400`. `id` terdaftar → 200 + data.

**Cara uji** — *khusus: tidak bisa lewat GraphiQL* (GraphiQL selalu mengirim
`query`, bukan `id`). Uji di luar browser saat server `NODE_ENV=production`
dengan mengirim body berikut ke `POST /graphql`:
```json
{ "id": "GetAllFakultas" }
```
```json
{ "id": "GetMahasiswaByNim", "variables": { "nim": "M0000001" } }
```
Dua operasi di atas terdaftar di `graphql/graphile.config.js`
(`GetAllFakultas`, `GetMahasiswaByNim`).

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

**Ekspektasi** — Tanpa header: `allKrs=1200`, `allMahasiswas=500`. Dengan header
`kampus_mahasiswa` id=1: `allKrs=3`, `allMahasiswas=1`.

**Cara uji** — di GraphiQL:
1. Jalankan query ini **tanpa** header:
```graphql
{ allKrs { totalCount } allMahasiswas { totalCount } }
```
2. Buka tab **Headers** (bawah), isi:
```json
{ "x-demo-role": "kampus_mahasiswa", "x-demo-mahasiswa-id": "1" }
```
3. Jalankan query yang sama lagi.

**Hasil** — Tanpa header `1200 / 500`; dengan header `3 / 1`.

> Verifikasi policy di DB (opsional, bukan API):
> ```
> docker exec postgres-kampus psql -U postgres -d kampus -c "SELECT policyname, tablename FROM pg_policies WHERE schemaname='public' ORDER BY tablename;"
> ```

---

# D. Performa

## D1. N+1 / query plan

**Tujuan** — Membuktikan pengambilan data bertingkat tidak menghasilkan N+1 query.

**Teori** — Grafast (mesin PostGraphile v5) menyusun *query plan* dan melakukan
**batching**: banyak baris + relasinya digabung menjadi satu SQL. Dengan
`grafast.explain` (dev), query plan & SQL bisa dilihat di tab **Explain**.

**Ekspektasi** — Berapa pun jumlah baris, nested fetch = **1 SQL**.

**Cara uji** — di GraphiQL, tempel query ini lalu buka tab **Explain**:
```graphql
{
  allMahasiswas(first: 50) {
    nodes {
      nim
      krsByMahasiswaId {
        nodes {
          kelasByKelasId {
            namaKelas
            mataKuliahByMatkulId { namaMatkul }
            dosenByDosenId { namaDosen }
          }
        }
      }
    }
  }
}
```

**Hasil** — 50 mahasiswa (150 KRS) = **1 SQL** (plan menampilkan satu statement
dengan subquery ter-agregasi). 3 mahasiswa juga **1 SQL**.

---

# E. Inflection

## E1. Tanpa singularisasi

**Tujuan** — Nama tipe mengikuti nama tabel (tidak disingularisasi).

**Teori** — Default Amber men-singularisasi (`fakultas` → `Fakulta`).
`NoSingularizePlugin` meng-*override* inflector `singularize` menjadi identity
lewat `inflection.replace`.

**Ekspektasi** — Tipe `Fakultas`, `Kelas`, `Krs`; relasi `kelasByKelasId`,
`fakultasByFakultasId`. Field root tetap `allFakultas`/`allKrs`.

**Cara uji** — di GraphiQL:
```graphql
{
  fakultas: __type(name: "Fakultas") { name }
  lama: __type(name: "Fakulta") { name }
}
```

**Hasil** — `fakultas.name = "Fakultas"`; `lama = null`.
`allFakultas`/`allKrs` tetap berlaku.

---

# F. Lampiran: Renormalize git (CRLF)

**Tujuan** — Menghilangkan noise line-ending (`core.autocrlf=true` di Windows).

**Teori** — Tanpa `.gitattributes`, Windows menyimpan CRLF sementara repo LF,
sehingga banyak file "terlihat" berubah padahal isinya sama.

**Ekspektasi** — `git status` hanya menampilkan perubahan isi nyata.

**Cara uji** — *bukan API; perintah git*
```bash
cat .gitattributes          # -> * text=auto eol=lf
git diff --numstat          # -> hanya file yang benar-benar berubah
```

**Hasil** — Setelah `.gitattributes` + `git add --renormalize .`, file
"berubah palsu" (Kampus.sql, REST/*, dll) hilang dari `git status`.
