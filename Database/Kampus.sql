BEGIN;

-- ============================================================
-- 1. BERSIHKAN TABEL LAMA
-- ============================================================
DROP TABLE IF EXISTS Presensi_Kuliah CASCADE;
DROP TABLE IF EXISTS Nilai_Akhir CASCADE;
DROP TABLE IF EXISTS KRS CASCADE;
DROP TABLE IF EXISTS Jadwal_Kuliah CASCADE;
DROP TABLE IF EXISTS Kelas CASCADE;
DROP TABLE IF EXISTS Mata_Kuliah CASCADE;
DROP TABLE IF EXISTS Mahasiswa CASCADE;
DROP TABLE IF EXISTS Dosen CASCADE;
DROP TABLE IF EXISTS Ruangan CASCADE;
DROP TABLE IF EXISTS Program_Studi CASCADE;
DROP TABLE IF EXISTS Fakultas CASCADE;

-- ============================================================
-- 2. BIKIN SKEMA TABEL (11 ENTITAS)
-- ============================================================
CREATE TABLE Fakultas (
    fakultas_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kode_fakultas VARCHAR(10) UNIQUE NOT NULL,
    nama_fakultas VARCHAR(100) NOT NULL
);

CREATE TABLE Program_Studi (
    prodi_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fakultas_id INT NOT NULL REFERENCES Fakultas(fakultas_id),
    kode_prodi VARCHAR(10) UNIQUE NOT NULL,
    nama_prodi VARCHAR(100) NOT NULL,
    jenjang VARCHAR(10) DEFAULT 'S1'
);

CREATE TABLE Ruangan (
    ruangan_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kode_ruangan VARCHAR(20) UNIQUE NOT NULL,
    gedung VARCHAR(50) NOT NULL,
    kapasitas INT NOT NULL CHECK (kapasitas > 0)
);

CREATE TABLE Dosen (
    dosen_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    prodi_id INT NOT NULL REFERENCES Program_Studi(prodi_id),
    nip VARCHAR(25) UNIQUE NOT NULL,
    nama_dosen VARCHAR(120) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE Mahasiswa (
    mahasiswa_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    prodi_id INT NOT NULL REFERENCES Program_Studi(prodi_id),
    nim VARCHAR(20) UNIQUE NOT NULL,
    nama_mahasiswa VARCHAR(120) NOT NULL,
    angkatan INT NOT NULL,
    status VARCHAR(20) DEFAULT 'Aktif'
);

CREATE TABLE Mata_Kuliah (
    matkul_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    prodi_id INT NOT NULL REFERENCES Program_Studi(prodi_id),
    kode_matkul VARCHAR(15) UNIQUE NOT NULL,
    nama_matkul VARCHAR(100) NOT NULL,
    sks INT NOT NULL CHECK (sks BETWEEN 1 AND 6)
);

CREATE TABLE Kelas (
    kelas_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    matkul_id INT NOT NULL REFERENCES Mata_Kuliah(matkul_id),
    dosen_id INT NOT NULL REFERENCES Dosen(dosen_id),
    nama_kelas VARCHAR(5) NOT NULL,
    semester VARCHAR(10) NOT NULL,
    tahun_akademik VARCHAR(10) NOT NULL,
    CONSTRAINT uq_kelas_periode UNIQUE (matkul_id, nama_kelas, semester, tahun_akademik)
);

CREATE TABLE Jadwal_Kuliah (
    jadwal_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kelas_id INT UNIQUE NOT NULL REFERENCES Kelas(kelas_id),
    ruangan_id INT NOT NULL REFERENCES Ruangan(ruangan_id),
    hari VARCHAR(10) NOT NULL,
    jam_mulai TIME NOT NULL,
    jam_selesai TIME NOT NULL
);

CREATE TABLE KRS (
    krs_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    mahasiswa_id INT NOT NULL REFERENCES Mahasiswa(mahasiswa_id),
    kelas_id INT NOT NULL REFERENCES Kelas(kelas_id),
    tanggal_ambil DATE DEFAULT CURRENT_DATE,
    status_persetujuan VARCHAR(20) DEFAULT 'Disetujui',
    CONSTRAINT uq_krs_mhs_kelas UNIQUE (mahasiswa_id, kelas_id)
);

CREATE TABLE Nilai_Akhir (
    nilai_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    krs_id BIGINT UNIQUE NOT NULL REFERENCES KRS(krs_id) ON DELETE CASCADE,
    nilai_tugas NUMERIC(5, 2) CHECK (nilai_tugas BETWEEN 0 AND 100),
    nilai_uts NUMERIC(5, 2) CHECK (nilai_uts BETWEEN 0 AND 100),
    nilai_uas NUMERIC(5, 2) CHECK (nilai_uas BETWEEN 0 AND 100),
    nilai_angka NUMERIC(5, 2),
    nilai_huruf CHAR(2)
);

CREATE TABLE Presensi_Kuliah (
    presensi_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    krs_id BIGINT NOT NULL REFERENCES KRS(krs_id) ON DELETE CASCADE,
    pertemuan_ke INT NOT NULL CHECK (pertemuan_ke BETWEEN 1 AND 16),
    status_kehadiran VARCHAR(15) NOT NULL,
    waktu_presensi TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_presensi_pertemuan UNIQUE (krs_id, pertemuan_ke)
);

-- ============================================================
-- 3. ISI DATA SAMPLE (>1000 ROW)
-- ============================================================

-- Data Master Fakultas & Prodi
INSERT INTO Fakultas (kode_fakultas, nama_fakultas) VALUES
('FTIS', 'Fakultas Teknologi Informasi dan Sains'),
('FT', 'Fakultas Teknik'),
('FEB', 'Fakultas Ekonomi dan Bisnis'),
('FK', 'Fakultas Kedokteran'),
('FH', 'Fakultas Hukum');

INSERT INTO Program_Studi (fakultas_id, kode_prodi, nama_prodi) VALUES
(1, 'SD', 'Sains Data'),
(1, 'IF', 'Informatika'),
(1, 'SI', 'Sistem Informasi'),
(2, 'TE', 'Teknik Elektro'),
(2, 'TI', 'Teknik Industri'),
(3, 'MN', 'Manajemen'),
(3, 'AK', 'Akuntansi'),
(3, 'EP', 'Ekonomi Pembangunan'),
(4, 'KD', 'Kedokteran'),
(5, 'IH', 'Ilmu Hukum');

-- Ruangan, Dosen, Mahasiswa
INSERT INTO Ruangan (kode_ruangan, gedung, kapasitas)
SELECT 
    'R-' || LPAD(i::TEXT, 3, '0'),
    'Gedung Kuliah Bersama ' || ((i % 3) + 1),
    40
FROM generate_series(1, 15) AS s(i);

INSERT INTO Dosen (prodi_id, nip, nama_dosen, email)
SELECT 
    ((i - 1) % 10) + 1,
    '1985' || LPAD(i::TEXT, 8, '0'),
    'Dosen Pengampu ' || i,
    'dosen' || i || '@univ.ac.id'
FROM generate_series(1, 30) AS s(i);

INSERT INTO Mahasiswa (prodi_id, nim, nama_mahasiswa, angkatan)
SELECT 
    ((i - 1) % 10) + 1,
    'M0' || LPAD(i::TEXT, 6, '0'),
    'Mahasiswa ' || i,
    2023 + (i % 3)
FROM generate_series(1, 500) AS s(i);

-- Matkul, Kelas, Jadwal
INSERT INTO Mata_Kuliah (prodi_id, kode_matkul, nama_matkul, sks)
SELECT 
    ((i - 1) % 10) + 1,
    'MK-' || LPAD(i::TEXT, 4, '0'),
    'Mata Kuliah Inti ' || i,
    (i % 3) + 2
FROM generate_series(1, 40) AS s(i);

INSERT INTO Kelas (matkul_id, dosen_id, nama_kelas, semester, tahun_akademik)
SELECT 
    ((i - 1) % 40) + 1,
    ((i - 1) % 30) + 1,
    CHR(65 + (i % 3)),
    'Ganjil',
    '2026/2027'
FROM generate_series(1, 60) AS s(i);

INSERT INTO Jadwal_Kuliah (kelas_id, ruangan_id, hari, jam_mulai, jam_selesai)
SELECT 
    i,
    ((i - 1) % 15) + 1,
    (ARRAY['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'])[((i - 1) % 5) + 1],
    '08:00:00'::TIME + (((i % 4) * 2) || ' hours')::INTERVAL,
    '09:40:00'::TIME + (((i % 4) * 2) || ' hours')::INTERVAL
FROM generate_series(1, 60) AS s(i);

-- Transaksi KRS (1200 baris)
INSERT INTO KRS (mahasiswa_id, kelas_id, status_persetujuan)
SELECT 
    mhs.id,
    kls.id,
    'Disetujui'
FROM (
    SELECT 
        ((i - 1) % 500) + 1 AS id,
        ((i - 1) % 60) + 1 AS kelas_shift,
        i
    FROM generate_series(1, 1200) AS s(i)
) t
CROSS JOIN LATERAL (
    SELECT ((t.kelas_shift + (t.i % 5)) % 60) + 1 AS id
) kls
JOIN LATERAL (
    SELECT t.id AS id
) mhs ON TRUE
ON CONFLICT (mahasiswa_id, kelas_id) DO NOTHING;

-- Nilai Akhir (1200 baris)
INSERT INTO Nilai_Akhir (krs_id, nilai_tugas, nilai_uts, nilai_uas, nilai_angka, nilai_huruf)
SELECT 
    krs_id,
    tugas,
    uts,
    uas,
    total,
    CASE 
        WHEN total >= 85 THEN 'A'
        WHEN total >= 75 THEN 'B'
        WHEN total >= 60 THEN 'C'
        WHEN total >= 50 THEN 'D'
        ELSE 'E'
    END
FROM (
    SELECT 
        krs_id,
        (60 + (krs_id % 35))::NUMERIC(5,2) AS tugas,
        (65 + (krs_id % 30))::NUMERIC(5,2) AS uts,
        (70 + (krs_id % 28))::NUMERIC(5,2) AS uas,
        (
            ((60 + (krs_id % 35)) * 0.3) + 
            ((65 + (krs_id % 30)) * 0.3) + 
            ((70 + (krs_id % 28)) * 0.4)
        )::NUMERIC(5,2) AS total
    FROM KRS
) score;

-- Presensi Kuliah (1200 baris)
INSERT INTO Presensi_Kuliah (krs_id, pertemuan_ke, status_kehadiran)
SELECT 
    krs_id,
    1,
    CASE WHEN (krs_id % 10 = 0) THEN 'Izin' ELSE 'Hadir' END
FROM KRS;

COMMIT;