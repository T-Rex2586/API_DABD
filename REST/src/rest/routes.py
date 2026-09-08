from fastapi import APIRouter, Depends, HTTPException
from psycopg import Connection

from rest.database import get_db
from rest.schemas import (
    HasilKRSItem,
    KRSItem,
    MahasiswaOut,
    PresensiOut,
    PresensiRequest,
)

router = APIRouter(prefix="/api")


@router.get("/mahasiswa/{nim}", response_model=MahasiswaOut)
def get_mahasiswa(nim: str, db: Connection = Depends(get_db)):
    with db.cursor() as cur:
        cur.execute(
            """
            SELECT m.nim, m.nama_mahasiswa, m.angkatan, m.status,
                   p.nama_prodi, f.nama_fakultas
            FROM Mahasiswa m
            JOIN Program_Studi p ON m.prodi_id = p.prodi_id
            JOIN Fakultas f ON p.fakultas_id = f.fakultas_id
            WHERE m.nim = %s
            """,
            (nim,),
        )
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Mahasiswa not found")
    return MahasiswaOut(
        nim=row[0],
        nama_mahasiswa=row[1],
        angkatan=row[2],
        status=row[3],
        nama_prodi=row[4],
        nama_fakultas=row[5],
    )


@router.get("/mahasiswa/{nim}/krs", response_model=list[KRSItem])
def get_krs_mahasiswa(nim: str, db: Connection = Depends(get_db)):
    with db.cursor() as cur:
        cur.execute(
            """
            SELECT k.krs_id, k.tanggal_ambil, k.status_persetujuan,
                   kl.nama_kelas, kl.semester, kl.tahun_akademik,
                   mk.kode_matkul, mk.nama_matkul, mk.sks,
                   d.nama_dosen, d.email,
                   j.hari, j.jam_mulai, j.jam_selesai,
                   r.kode_ruangan, r.gedung
            FROM KRS k
            JOIN Mahasiswa m ON k.mahasiswa_id = m.mahasiswa_id
            JOIN Kelas kl ON k.kelas_id = kl.kelas_id
            JOIN Mata_Kuliah mk ON kl.matkul_id = mk.matkul_id
            JOIN Dosen d ON kl.dosen_id = d.dosen_id
            LEFT JOIN Jadwal_Kuliah j ON j.kelas_id = kl.kelas_id
            LEFT JOIN Ruangan r ON j.ruangan_id = r.ruangan_id
            WHERE m.nim = %s
            """,
            (nim,),
        )
        rows = cur.fetchall()
    return [
        KRSItem(
            krs_id=r[0],
            tanggal_ambil=r[1],
            status_persetujuan=r[2],
            nama_kelas=r[3],
            semester=r[4],
            tahun_akademik=r[5],
            kode_matkul=r[6],
            nama_matkul=r[7],
            sks=r[8],
            nama_dosen=r[9],
            email=r[10],
            hari=r[11],
            jam_mulai=str(r[12]) if r[12] else None,
            jam_selesai=str(r[13]) if r[13] else None,
            kode_ruangan=r[14],
            gedung=r[15],
        )
        for r in rows
    ]


@router.get("/krs/{krs_id}/hasil", response_model=list[HasilKRSItem])
def get_hasil_krs(krs_id: int, db: Connection = Depends(get_db)):
    with db.cursor() as cur:
        cur.execute(
            """
            SELECT na.nilai_tugas, na.nilai_uts, na.nilai_uas, na.nilai_angka, na.nilai_huruf,
                   pk.pertemuan_ke, pk.status_kehadiran, pk.waktu_presensi
            FROM KRS k
            LEFT JOIN Nilai_Akhir na ON na.krs_id = k.krs_id
            LEFT JOIN Presensi_Kuliah pk ON pk.krs_id = k.krs_id
            WHERE k.krs_id = %s
            ORDER BY pk.pertemuan_ke
            """,
            (krs_id,),
        )
        rows = cur.fetchall()
    return [
        HasilKRSItem(
            nilai_tugas=r[0],
            nilai_uts=r[1],
            nilai_uas=r[2],
            nilai_angka=r[3],
            nilai_huruf=r[4],
            pertemuan_ke=r[5],
            status_kehadiran=r[6],
            waktu_presensi=r[7],
        )
        for r in rows
    ]


@router.post("/krs/{krs_id}/presensi", response_model=PresensiOut)
def create_presensi(
    krs_id: int, body: PresensiRequest, db: Connection = Depends(get_db)
):
    with db.cursor() as cur:
        cur.execute(
            """
            INSERT INTO Presensi_Kuliah (krs_id, pertemuan_ke, status_kehadiran)
            VALUES (%s, %s, %s)
            ON CONFLICT (krs_id, pertemuan_ke)
            DO UPDATE SET status_kehadiran = EXCLUDED.status_kehadiran,
                          waktu_presensi = CURRENT_TIMESTAMP
            RETURNING presensi_id, krs_id, pertemuan_ke, status_kehadiran, waktu_presensi
            """,
            (krs_id, body.pertemuan_ke, body.status_kehadiran),
        )
        row = cur.fetchone()
        db.commit()
    return PresensiOut(
        presensi_id=row[0],
        krs_id=row[1],
        pertemuan_ke=row[2],
        status_kehadiran=row[3],
        waktu_presensi=row[4],
    )
