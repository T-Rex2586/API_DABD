-- ============================================================
-- RLS DEMO: roles + row level security policies
-- Dijalankan SETELAH Kampus.sql (initdb.d/zz_security.sql)
-- Nama tabel huruf kecil (dibuat tanpa kutip di Kampus.sql).
-- ============================================================
BEGIN;

-- 1. ROLE (NOLOGIN, dipakai via SET ROLE dari PostGraphile)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'kampus_anonymous') THEN
        CREATE ROLE kampus_anonymous NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'kampus_mahasiswa') THEN
        CREATE ROLE kampus_mahasiswa NOLOGIN;
    END IF;
END
$$;

GRANT USAGE ON SCHEMA public TO kampus_anonymous, kampus_mahasiswa;

-- 2. HELPER: id mahasiswa aktif dari JWT claims (pgSettings)
CREATE OR REPLACE FUNCTION current_mahasiswa_id()
RETURNS integer AS $$
    SELECT nullif(current_setting('jwt.claims.mahasiswa_id', true), '')::integer;
$$ LANGUAGE sql STABLE;

-- 3. TABEL PUBLIK: boleh dibaca semua role
ALTER TABLE fakultas ENABLE ROW LEVEL SECURITY;
ALTER TABLE program_studi ENABLE ROW LEVEL SECURITY;
ALTER TABLE mata_kuliah ENABLE ROW LEVEL SECURITY;
ALTER TABLE ruangan ENABLE ROW LEVEL SECURITY;

CREATE POLICY fakultas_read ON fakultas FOR SELECT TO kampus_anonymous, kampus_mahasiswa USING (true);
CREATE POLICY prodi_read ON program_studi FOR SELECT TO kampus_anonymous, kampus_mahasiswa USING (true);
CREATE POLICY matkul_read ON mata_kuliah FOR SELECT TO kampus_anonymous, kampus_mahasiswa USING (true);
CREATE POLICY ruangan_read ON ruangan FOR SELECT TO kampus_anonymous, kampus_mahasiswa USING (true);

GRANT SELECT ON fakultas, program_studi, mata_kuliah, ruangan
    TO kampus_anonymous, kampus_mahasiswa;

-- 4. DATA PRIBADI: mahasiswa hanya lihat baris miliknya
ALTER TABLE mahasiswa ENABLE ROW LEVEL SECURITY;
ALTER TABLE krs ENABLE ROW LEVEL SECURITY;
ALTER TABLE nilai_akhir ENABLE ROW LEVEL SECURITY;
ALTER TABLE presensi_kuliah ENABLE ROW LEVEL SECURITY;

CREATE POLICY mahasiswa_self ON mahasiswa FOR SELECT TO kampus_mahasiswa
    USING (mahasiswa_id = current_mahasiswa_id());

CREATE POLICY krs_self ON krs FOR SELECT TO kampus_mahasiswa
    USING (mahasiswa_id = current_mahasiswa_id());

CREATE POLICY nilai_self ON nilai_akhir FOR SELECT TO kampus_mahasiswa
    USING (EXISTS (
        SELECT 1 FROM krs k
        WHERE k.krs_id = nilai_akhir.krs_id
          AND k.mahasiswa_id = current_mahasiswa_id()
    ));

CREATE POLICY presensi_self ON presensi_kuliah FOR SELECT TO kampus_mahasiswa
    USING (EXISTS (
        SELECT 1 FROM krs k
        WHERE k.krs_id = presensi_kuliah.krs_id
          AND k.mahasiswa_id = current_mahasiswa_id()
    ));

GRANT SELECT ON mahasiswa, krs, nilai_akhir, presensi_kuliah
    TO kampus_mahasiswa;

-- 5. TABEL PENDUKUNG relasi (tanpa RLS, cukup grant)
GRANT SELECT ON dosen, kelas, jadwal_kuliah TO kampus_mahasiswa;

COMMIT;
