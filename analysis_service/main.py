"""
MusicLab analysis service.

One job: take a recording, return the notes that were played.

Uses Spotify's Basic Pitch model to turn raw audio into note events
(pitch, start time, end time, loudness) without needing sheet music or
MIDI input. The Flutter app compares note events between two takes to
find where a practice run diverged from a reference take.
"""

import tempfile
from pathlib import Path

from basic_pitch.inference import predict
from basic_pitch import ICASSP_2022_MODEL_PATH
from fastapi import FastAPI, HTTPException, UploadFile
from fastapi.responses import JSONResponse

app = FastAPI(title="MusicLab Analysis Service")

ALLOWED_SUFFIXES = {".m4a", ".mp3", ".wav", ".aac", ".ogg", ".flac"}


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/analyze")
async def analyze(audio: UploadFile) -> JSONResponse:
    suffix = Path(audio.filename or "").suffix.lower()
    if suffix not in ALLOWED_SUFFIXES:
        raise HTTPException(400, f"Unsupported file type: {suffix or 'unknown'}")

    with tempfile.NamedTemporaryFile(suffix=suffix) as tmp:
        tmp.write(await audio.read())
        tmp.flush()

        try:
            _, _, note_events = predict(tmp.name, ICASSP_2022_MODEL_PATH)
        except Exception as exc:  # surface the real cause instead of a bare 500
            raise HTTPException(500, f"Analysis failed: {exc}") from exc

    notes = [
        {
            "startTime": round(start, 3),
            "endTime": round(end, 3),
            "pitch": pitch,
            "amplitude": round(amplitude, 3),
        }
        for start, end, pitch, amplitude, _pitch_bends in note_events
    ]

    return JSONResponse({"notes": notes})
