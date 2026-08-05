from fastapi import FastAPI, UploadFile, File
from tempfile import NamedTemporaryFile

from .model import transcribe_audio


app = FastAPI(
    title="Speech-to-Text Service"
)


@app.get("/")
def root():
    return {
        "service": "stt",
        "status": "running"
    }


@app.post("/transcribe")
async def transcribe(
    file: UploadFile = File(...)
):

    with NamedTemporaryFile(
        suffix=".wav"
    ) as temp:

        temp.write(await file.read())
        temp.flush()

        result = transcribe_audio(
            temp.name
        )

    return result