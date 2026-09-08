from decimal import Decimal

from sqlalchemy import ForeignKey, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base


class Nilai_Akhir(Base):
    __tablename__ = "Nilai_Akhir"

    nilai_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    krs_id: Mapped[int] = mapped_column(
        ForeignKey("KRS.krs_id", ondelete="CASCADE"), unique=True, nullable=False
    )
    nilai_tugas: Mapped[Decimal] = mapped_column(Numeric(5, 2))
    nilai_uts: Mapped[Decimal] = mapped_column(Numeric(5, 2))
    nilai_uas: Mapped[Decimal] = mapped_column(Numeric(5, 2))
    nilai_angka: Mapped[Decimal] = mapped_column(Numeric(5, 2))
    nilai_huruf: Mapped[str] = mapped_column(String(2))

    krs: Mapped["KRS"] = relationship(back_populates="nilai_akhir")

    def __repr__(self) -> str:
        return f"<Nilai_Akhir krs {self.krs_id}: {self.nilai_huruf}>"


from models.KRS import KRS
