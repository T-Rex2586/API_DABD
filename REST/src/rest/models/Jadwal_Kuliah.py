from datetime import time

from sqlalchemy import ForeignKey, String, Time
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base


class Jadwal_Kuliah(Base):
    __tablename__ = "Jadwal_Kuliah"

    jadwal_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    kelas_id: Mapped[int] = mapped_column(
        ForeignKey("Kelas.kelas_id"), unique=True, nullable=False
    )
    ruangan_id: Mapped[int] = mapped_column(ForeignKey("Ruangan.ruangan_id"), nullable=False)
    hari: Mapped[str] = mapped_column(String(10), nullable=False)
    jam_mulai: Mapped[time] = mapped_column(Time, nullable=False)
    jam_selesai: Mapped[time] = mapped_column(Time, nullable=False)

    kelas: Mapped["Kelas"] = relationship(back_populates="jadwal_kuliah")
    ruangan: Mapped["Ruangan"] = relationship(back_populates="jadwal_kuliah")

    def __repr__(self) -> str:
        return f"<Jadwal_Kuliah {self.hari} {self.jam_mulai}-{self.jam_selesai}>"


from models.Kelas import Kelas
from models.Ruangan import Ruangan
