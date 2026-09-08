from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base


class Matakuliah(Base):
    __tablename__ = "Mata_Kuliah"

    matkul_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    prodi_id: Mapped[int] = mapped_column(ForeignKey("Program_Studi.prodi_id"), nullable=False)
    kode_matkul: Mapped[str] = mapped_column(String(15), unique=True, nullable=False)
    nama_matkul: Mapped[str] = mapped_column(String(100), nullable=False)
    sks: Mapped[int] = mapped_column(nullable=False)

    prodi: Mapped["Program_Studi"] = relationship(back_populates="matakuliah")
    kelas: Mapped[list["Kelas"]] = relationship(back_populates="matakuliah")

    def __repr__(self) -> str:
        return f"<Matakuliah {self.kode_matkul}: {self.nama_matkul}>"


from models.Program_studi import Program_Studi
from models.Kelas import Kelas
