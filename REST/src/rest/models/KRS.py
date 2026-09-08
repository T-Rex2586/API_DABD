from datetime import date

from sqlalchemy import Date, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base


class KRS(Base):
    __tablename__ = "KRS"
    __table_args__ = (
        UniqueConstraint("mahasiswa_id", "kelas_id", name="uq_krs_mhs_kelas"),
    )

    krs_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    mahasiswa_id: Mapped[int] = mapped_column(ForeignKey("Mahasiswa.mahasiswa_id"), nullable=False)
    kelas_id: Mapped[int] = mapped_column(ForeignKey("Kelas.kelas_id"), nullable=False)
    tanggal_ambil: Mapped[date] = mapped_column(Date, default=date.today)
    status_persetujuan: Mapped[str] = mapped_column(String(20), default="Disetujui")

    mahasiswa: Mapped["Mahasiswa"] = relationship(back_populates="krs")
    kelas: Mapped["Kelas"] = relationship(back_populates="krs")
    nilai_akhir: Mapped["Nilai_Akhir"] = relationship(back_populates="krs", uselist=False)
    presensi: Mapped[list["Presensi_Kuliah"]] = relationship(back_populates="krs")

    def __repr__(self) -> str:
        return f"<KRS {self.mahasiswa_id} - kelas {self.kelas_id}>"


from models.Mahasiswa import Mahasiswa
from models.Kelas import Kelas
from models.Nilai_Akhir import Nilai_Akhir
from models.Presensi import Presensi_Kuliah
