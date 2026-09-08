from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base


class Presensi_Kuliah(Base):
    __tablename__ = "Presensi_Kuliah"
    __table_args__ = (
        UniqueConstraint("krs_id", "pertemuan_ke", name="uq_presensi_pertemuan"),
    )

    presensi_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    krs_id: Mapped[int] = mapped_column(
        ForeignKey("KRS.krs_id", ondelete="CASCADE"), nullable=False
    )
    pertemuan_ke: Mapped[int] = mapped_column(nullable=False)
    status_kehadiran: Mapped[str] = mapped_column(String(15), nullable=False)
    waktu_presensi: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.now)

    krs: Mapped["KRS"] = relationship(back_populates="presensi")

    def __repr__(self) -> str:
        return f"<Presensi_Kuliah krs {self.krs_id} pertemuan {self.pertemuan_ke}>"


from models.KRS import KRS
