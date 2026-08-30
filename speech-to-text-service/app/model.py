from faster_whisper import WhisperModel
import os
import torch
from dotenv import load_dotenv
from faster_whisper import WhisperModel

load_dotenv()

HF_TOKEN = os.getenv("HF_TOKEN")


print("Loading Whisper model")

model = WhisperModel(
    "large-v3",
    device="cuda",
    compute_type="float16"
)

print("Whisper model loaded")


def transcribe_audio(filename: str):
    try:
        segments, info = model.transcribe(
            filename,
            beam_size=5,
            vad_filter=True,
            vad_parameters=dict(
                min_silence_duration_ms=500
            )
        )
        text = ""

        for segment in segments:
            text += segment.text

        return {
            "text": text.strip(),
            "language": info.language,
            "language_probability": info.language_probability
        }

    finally:
        import gc

        gc.collect()
        # faster-whisper/CTranslate2 manages its own CUDA memory.
        # This clears PyTorch's unused CUDA cache if there is any.
        if torch.cuda.is_available():
            torch.cuda.empty_cache()