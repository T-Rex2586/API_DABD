from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base


class Dosen(Base):
    __tablename__ = "Dosen"

    dosen_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    prodi_id: Mapped[int] = mapped_column(ForeignKey("Program_Studi.prodi_id"), nullable=False)
    nip: Mapped[str] = mapped_column(String(25), unique=True, nullable=False)
    nama_dosen: Mapped[str] = mapped_column(String(120), nullable=False)
    email: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)

    prodi: Mapped["Program_Studi"] = relationship(back_populates="dosen")
    kelas: Mapped[list["Kelas"]] = relationship(back_populates="dosen")

    def __repr__(self) -> str:
        return f"<Dosen {self.nip}: {self.nama_dosen}>"


from models.Program_studi import Program_Studi
from models.Kelas import Kelas
