import sounddevice as sd
import soundfile as sf
from scipy.signal import resample_poly

RECORD_RATE = 48000
WHISPER_RATE = 16000
CHANNELS = 1
DURATION = 10
DEVICE = 4
OUTPUT = "./utils/audio/test.wav"

print(f"Using device: {sd.query_devices(DEVICE)['name']}")
print(f"Recording for {DURATION} seconds")
print("Speak now!")

audio = sd.rec(
    int(DURATION * RECORD_RATE),
    samplerate=RECORD_RATE,
    channels=CHANNELS,
    device=DEVICE,
    dtype="float32"
)

sd.wait()

print("Recording finished.")

audio_16k = resample_poly(
    audio[:, 0],
    WHISPER_RATE,
    RECORD_RATE
)

sf.write(
    OUTPUT,
    audio_16k,
    WHISPER_RATE
)

print(f"Saved to {OUTPUT}")