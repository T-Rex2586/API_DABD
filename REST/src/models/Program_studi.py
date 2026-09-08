from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base


class Program_Studi(Base):
    __tablename__ = "Program_Studi"

    prodi_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    fakultas_id: Mapped[int] = mapped_column(ForeignKey("Fakultas.fakultas_id"), nullable=False)
    kode_prodi: Mapped[str] = mapped_column(String(10), unique=True, nullable=False)
    nama_prodi: Mapped[str] = mapped_column(String(100), nullable=False)
    jenjang: Mapped[str] = mapped_column(String(10), default="S1")

    fakultas: Mapped["Fakultas"] = relationship(back_populates="program_studi")
    mahasiswa: Mapped[list["Mahasiswa"]] = relationship(back_populates="prodi")
    dosen: Mapped[list["Dosen"]] = relationship(back_populates="prodi")
    matakuliah: Mapped[list["Matakuliah"]] = relationship(back_populates="prodi")

    def __repr__(self) -> str:
        return f"<Program_Studi {self.kode_prodi}: {self.nama_prodi}>"


from models.Fakultas import Fakultas
from models.Mahasiswa import Mahasiswa
from models.Dosen import Dosen
from models.Matakuliah import Matakuliah
