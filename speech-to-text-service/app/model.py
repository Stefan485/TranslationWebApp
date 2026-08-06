from faster_whisper import WhisperModel


print("Loading Whisper model")

model = WhisperModel(
    "medium",
    device="cuda",
    compute_type="float16"
)

print("Whisper model loaded")


def transcribe_audio(filename: str):

    segments, info = model.transcribe(
        filename,
        beam_size=10,
        vad_filter=True,
        vad_parameters=dict(
            min_silence_duration_ms=500
        ),
        temperature=[0.0, 0.2, 0.4, 0.6]
    )
    text = ""

    for segment in segments:
        text += segment.text

    return {
        "text": text.strip(),
        "language": info.language,
        "language_probability": info.language_probability
    }