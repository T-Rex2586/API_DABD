from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel


class MahasiswaOut(BaseModel):
    nim: str
    nama_mahasiswa: str
    angkatan: int
    status: str
    nama_prodi: str
    nama_fakultas: str


class KRSItem(BaseModel):
    krs_id: int
    tanggal_ambil: date
    status_persetujuan: str
    nama_kelas: str
    semester: str
    tahun_akademik: str
    kode_matkul: str
    nama_matkul: str
    sks: int
    nama_dosen: str
    email: str
    hari: str | None = None
    jam_mulai: str | None = None
    jam_selesai: str | None = None
    kode_ruangan: str | None = None
    gedung: str | None = None


class HasilKRSItem(BaseModel):
    nilai_tugas: Decimal | None = None
    nilai_uts: Decimal | None = None
    nilai_uas: Decimal | None = None
    nilai_angka: Decimal | None = None
    nilai_huruf: str | None = None
    pertemuan_ke: int | None = None
    status_kehadiran: str | None = None
    waktu_presensi: datetime | None = None


class PresensiRequest(BaseModel):
    pertemuan_ke: int
    status_kehadiran: str


class PresensiOut(BaseModel):
    presensi_id: int
    krs_id: int
    pertemuan_ke: int
    status_kehadiran: str
    waktu_presensi: datetime
