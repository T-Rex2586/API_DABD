-- Query 1: Total kelas dan total SKS yang diampu tiap dosen (JOIN + GROUP BY)
SELECT 
    d.nip,
    d.nama_dosen,
    ps.nama_prodi,
    COUNT(k.kelas_id) AS total_kelas,
    SUM(mk.sks) AS total_sks
FROM Dosen d
JOIN Program_Studi ps ON d.prodi_id = ps.prodi_id
JOIN Kelas k ON d.dosen_id = k.dosen_id
JOIN Mata_Kuliah mk ON k.matkul_id = mk.matkul_id
GROUP BY d.nip, d.nama_dosen, ps.nama_prodi
ORDER BY total_sks DESC;


-- Query 2: Jadwal pemakaian ruangan kelas beserta mata kuliahnya
SELECT 
    r.gedung,
    r.kode_ruangan,
    r.kapasitas,
    jk.hari,
    jk.jam_mulai,
    jk.jam_selesai,
    mk.nama_matkul,
    kl.nama_kelas
FROM Jadwal_Kuliah jk
JOIN Ruangan r ON jk.ruangan_id = r.ruangan_id
JOIN Kelas kl ON jk.kelas_id = kl.kelas_id
JOIN Mata_Kuliah mk ON kl.matkul_id = mk.matkul_id
ORDER BY r.gedung, r.kode_ruangan, jk.hari;


-- Query 3: Jumlah mahasiswa aktif per program studi (COUNT + ORDER BY)
SELECT 
    ps.kode_prodi,
    ps.nama_prodi,
    ps.jenjang,
    COUNT(m.mahasiswa_id) AS total_mahasiswa
FROM Program_Studi ps
JOIN Mahasiswa m ON ps.prodi_id = m.prodi_id
WHERE m.status = 'Aktif'
GROUP BY ps.kode_prodi, ps.nama_prodi, ps.jenjang
ORDER BY total_mahasiswa DESC;


-- Query 4: Statistik pembacaan tabel pada database (Sequential vs Index Scan)
SELECT 
    schemaname,
    relname AS tabel,
    seq_scan AS total_seq_scan,
    seq_tup_read AS total_baris_dibaca,
    idx_scan AS total_idx_scan,
    n_live_tup AS estimasi_baris
FROM pg_stat_user_tables
ORDER BY seq_tup_read DESC;


-- Query 5: Rekapitulasi dan persentase kehadiran mahasiswa per prodi (CASE + SUM + GROUP BY)
SELECT 
    ps.nama_prodi,
    COUNT(pk.presensi_id) AS total_presensi,
    SUM(CASE WHEN pk.status_kehadiran = 'Hadir' THEN 1 ELSE 0 END) AS hadir,
    SUM(CASE WHEN pk.status_kehadiran <> 'Hadir' THEN 1 ELSE 0 END) AS tidak_hadir,
    ROUND(
        (SUM(CASE WHEN pk.status_kehadiran = 'Hadir' THEN 1.0 ELSE 0 END) / COUNT(pk.presensi_id)) * 100, 
        2
    ) AS persentase_hadir
FROM Presensi_Kuliah pk
JOIN KRS k ON pk.krs_id = k.krs_id
JOIN Mahasiswa m ON k.mahasiswa_id = m.mahasiswa_id
JOIN Program_Studi ps ON m.prodi_id = ps.prodi_id
GROUP BY ps.nama_prodi
ORDER BY persentase_hadir DESC;