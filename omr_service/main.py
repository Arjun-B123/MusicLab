"""
MusicLab OMR (optical music recognition) service.

One job: given a photo or PDF of sheet music, try to read off the time
signature printed at the start of the piece, using the open-source oemer
model. Best-effort — real-world photos (skewed, poorly lit, handwritten)
can confuse any OMR system, so the Flutter app always treats this as a
suggestion the user confirms or overrides, never a silent fact.
"""

import subprocess
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

import fitz  # PyMuPDF
from fastapi import FastAPI, HTTPException, UploadFile
from fastapi.responses import JSONResponse

app = FastAPI(title="MusicLab OMR Service")

IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png"}


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


def _pdf_first_page_to_png(pdf_path: Path, out_path: Path) -> None:
    doc = fitz.open(pdf_path)
    try:
        page = doc.load_page(0)
        pixmap = page.get_pixmap(dpi=300)
        pixmap.save(out_path)
    finally:
        doc.close()


def _extract_time_signature(musicxml_path: Path) -> str | None:
    tree = ET.parse(musicxml_path)
    time_el = tree.getroot().find(".//attributes/time")
    if time_el is None:
        return None

    beats = time_el.findtext("beats")
    beat_type = time_el.findtext("beat-type")
    if not beats or not beat_type:
        return None

    return f"{beats}/{beat_type}"


@app.post("/detect-time-signature")
async def detect_time_signature(sheet_music: UploadFile) -> JSONResponse:
    suffix = Path(sheet_music.filename or "").suffix.lower()
    if suffix not in IMAGE_SUFFIXES and suffix != ".pdf":
        raise HTTPException(400, f"Unsupported file type: {suffix or 'unknown'}")

    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_dir_path = Path(tmp_dir)
        uploaded_path = tmp_dir_path / f"input{suffix}"
        uploaded_path.write_bytes(await sheet_music.read())

        if suffix == ".pdf":
            image_path = tmp_dir_path / "page1.png"
            try:
                _pdf_first_page_to_png(uploaded_path, image_path)
            except Exception as exc:
                raise HTTPException(400, f"Couldn't read PDF: {exc}") from exc
        else:
            image_path = uploaded_path

        try:
            subprocess.run(
                ["oemer", str(image_path), "--output-path", str(tmp_dir_path)],
                check=True,
                capture_output=True,
                timeout=300,
            )
        except subprocess.CalledProcessError as exc:
            return JSONResponse(
                {
                    "timeSignature": None,
                    "error": f"OMR failed: {exc.stderr.decode(errors='replace')[-500:]}",
                }
            )
        except subprocess.TimeoutExpired:
            return JSONResponse(
                {"timeSignature": None, "error": "OMR timed out"}
            )

        musicxml_files = list(tmp_dir_path.glob("*.musicxml"))
        if not musicxml_files:
            return JSONResponse(
                {"timeSignature": None, "error": "No MusicXML produced"}
            )

        try:
            time_signature = _extract_time_signature(musicxml_files[0])
        except Exception as exc:
            return JSONResponse(
                {"timeSignature": None, "error": f"Couldn't parse result: {exc}"}
            )

        return JSONResponse({"timeSignature": time_signature})
