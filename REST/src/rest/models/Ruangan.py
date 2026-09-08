from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base


class Ruangan(Base):
    __tablename__ = "Ruangan"

    ruangan_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    kode_ruangan: Mapped[str] = mapped_column(String(20), unique=True, nullable=False)
    gedung: Mapped[str] = mapped_column(String(50), nullable=False)
    kapasitas: Mapped[int] = mapped_column(nullable=False)

    jadwal_kuliah: Mapped[list["Jadwal_Kuliah"]] = relationship(back_populates="ruangan")

    def __repr__(self) -> str:
        return f"<Ruangan {self.kode_ruangan}: {self.gedung}>"


from models.Jadwal_Kuliah import Jadwal_Kuliah
