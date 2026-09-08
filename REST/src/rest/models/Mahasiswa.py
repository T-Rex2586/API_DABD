from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base


class Mahasiswa(Base):
    __tablename__ = "Mahasiswa"

    mahasiswa_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    prodi_id: Mapped[int] = mapped_column(ForeignKey("Program_Studi.prodi_id"), nullable=False)
    nim: Mapped[str] = mapped_column(String(20), unique=True, nullable=False)
    nama_mahasiswa: Mapped[str] = mapped_column(String(120), nullable=False)
    angkatan: Mapped[int] = mapped_column(nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="Aktif")

    prodi: Mapped["Program_Studi"] = relationship(back_populates="mahasiswa")
    krs: Mapped[list["KRS"]] = relationship(back_populates="mahasiswa")

    def __repr__(self) -> str:
        return f"<Mahasiswa {self.nim}: {self.nama_mahasiswa}>"


from models.Program_studi import Program_Studi
from models.KRS import KRS
