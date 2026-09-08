from sqlalchemy import ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base


class Kelas(Base):
    __tablename__ = "Kelas"
    __table_args__ = (
        UniqueConstraint(
            "matkul_id",
            "nama_kelas",
            "semester",
            "tahun_akademik",
            name="uq_kelas_periode",
        ),
    )

    kelas_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    matkul_id: Mapped[int] = mapped_column(ForeignKey("Mata_Kuliah.matkul_id"), nullable=False)
    dosen_id: Mapped[int] = mapped_column(ForeignKey("Dosen.dosen_id"), nullable=False)
    nama_kelas: Mapped[str] = mapped_column(String(5), nullable=False)
    semester: Mapped[str] = mapped_column(String(10), nullable=False)
    tahun_akademik: Mapped[str] = mapped_column(String(10), nullable=False)

    matakuliah: Mapped["Matakuliah"] = relationship(back_populates="kelas")
    dosen: Mapped["Dosen"] = relationship(back_populates="kelas")
    jadwal_kuliah: Mapped["Jadwal_Kuliah"] = relationship(back_populates="kelas", uselist=False)
    krs: Mapped[list["KRS"]] = relationship(back_populates="kelas")

    def __repr__(self) -> str:
        return f"<Kelas {self.nama_kelas} ({self.semester} {self.tahun_akademik})>"


from models.Matakuliah import Matakuliah
from models.Dosen import Dosen
from models.Jadwal_Kuliah import Jadwal_Kuliah
from models.KRS import KRS
