from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base


class Fakultas(Base):
    __tablename__ = "Fakultas"

    fakultas_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    kode_fakultas: Mapped[str] = mapped_column(String(10), unique=True, nullable=False)
    nama_fakultas: Mapped[str] = mapped_column(String(100), nullable=False)

    program_studi: Mapped[list["Program_Studi"]] = relationship(back_populates="fakultas")

    def __repr__(self) -> str:
        return f"<Fakultas {self.kode_fakultas}: {self.nama_fakultas}>"


from models.Program_studi import Program_Studi
