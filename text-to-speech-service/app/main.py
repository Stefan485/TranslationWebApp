from fastapi import FastAPI
from fastapi.responses import FileResponse
from pydantic import BaseModel

from .model import tts_model


app = FastAPI()


class TTSRequest(BaseModel):
    text: str
    language: str = "en"


@app.get("/languages")
def languages():
    codes = tts_model.available_languages()
    return [{"code": c, "name": c} for c in codes]

@app.post("/tts")
def text_to_speech(request: TTSRequest):

    file = tts_model.generate_speech(
        request.text,
        request.language
    )

    return {
        "audio_file": file
    }

@app.post("/tts-audio")
def text_to_speech_audio(request: TTSRequest):

    file = tts_model.generate_speech(
        request.text,
        request.language
    )

    return FileResponse(file, media_type="audio/wav")