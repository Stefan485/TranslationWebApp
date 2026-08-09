from fastapi import FastAPI
from pydantic import BaseModel

from .model import tts_model


app = FastAPI()


class TTSRequest(BaseModel):
    text: str
    language: str = "en"


@app.post("/tts")
def text_to_speech(request: TTSRequest):

    file = tts_model.generate_speech(
        request.text,
        request.language
    )

    return {
        "audio_file": file
    }