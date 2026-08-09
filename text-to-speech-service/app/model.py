import os
import uuid

import numpy as np
import scipy.io.wavfile as wavfile
import torch
from dotenv import load_dotenv
from transformers import AutoProcessor, BarkModel


class TTSModel:
    def __init__(self):
        self.device = "cuda" if torch.cuda.is_available() else "cpu"

        print(f"Loading Bark on {self.device}")

        self.processor = AutoProcessor.from_pretrained(
            "suno/bark"
        )

        self.model = BarkModel.from_pretrained("suno/bark",)
        self.model.to(self.device)

        self.model.eval()

        print("Bark loaded successfully")

    def available_languages(self):
        """
        Return a list of available languages.
        """

        return [
            "en", # English
            "de", # German
            "fr", # French
            "es", # Spanish
            "it", # Italian
            "ja", # Japanese
            "ko", # Korean
            "pl", # Polish
            "pt", # Portuguese
            "ru", # Russian
            "tr", # Turkish
            "zh", # Chinese simplified
        ]

    def get_voice(self, language: str):
        """
        Map language codes to Bark voices.
        """

        voices = {
            "en": "v2/en_speaker_0",
            "de": "v2/de_speaker_0",
            "fr": "v2/fr_speaker_0",
            "es": "v2/es_speaker_0",
            "it": "v2/it_speaker_0",
            "ja": "v2/ja_speaker_0",
            "ko": "v2/ko_speaker_0",
            "pl": "v2/pl_speaker_0",
            "pt": "v2/pt_speaker_0",
            "ru": "v2/ru_speaker_0",
            "tr": "v2/tr_speaker_0",
            "zh": "v2/zh_speaker_0",
        }

        if language not in voices:
            raise ValueError(
                f"Unsupported language: {language}"
            )

        return voices[language]

    def generate_speech(
        self,
        text: str,
        language: str = "en",
        output_dir: str = "audio"
    ):
        """
        Generate speech from text.

        Returns path to WAV file.
        """

        os.makedirs(output_dir, exist_ok=True)

        voice = self.get_voice(language)

        inputs = self.processor(
            text,
            voice_preset=voice
        )

        inputs = {
            key: value.to(self.device)
            for key, value in inputs.items()
        }

        print(f"Generating speech: {text}")

        with torch.no_grad():
            audio = self.model.generate(
                **inputs
            )

        audio = audio.cpu().numpy().squeeze()

        # Normalize audio
        audio = audio / max(abs(audio).max(), 1e-8)

        # Add a small amount of silence at the end.
        # This prevents the audio from ending abruptly.
        sample_rate = self.model.generation_config.sample_rate

        silence_duration = 0.2
        silence_samples = int(
            sample_rate * silence_duration
        )

        silence = np.zeros(
            silence_samples,
            dtype=audio.dtype
        )

        audio = np.concatenate(
            [audio, silence]
        )

        # Convert to 16-bit PCM WAV
        audio = (audio * 32767).astype(np.int16)

        filename = f"{uuid.uuid4()}.wav"

        filepath = os.path.join(
            output_dir,
            filename
        )

        wavfile.write(
            filepath,
            sample_rate,
            audio
        )

        print(f"Audio saved to: {filepath}")

        return filepath


load_dotenv()

HF_TOKEN = os.getenv("HF_TOKEN")

tts_model = TTSModel()