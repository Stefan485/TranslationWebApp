from faster_whisper import WhisperModel


print("Loading Whisper model")

model = WhisperModel(
    "small",
    device="cuda",
    compute_type="float16"
)

print("Whisper model loaded")


def transcribe_audio(filename: str):

    segments, info = model.transcribe(
        filename,
        beam_size=5
    )

    text = ""

    for segment in segments:
        text += segment.text

    return {
        "text": text.strip(),
        "language": info.language,
        "language_probability": info.language_probability
    }