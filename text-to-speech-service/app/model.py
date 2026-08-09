import torch
import scipy.io.wavfile as wavfile
from transformers import AutoProcessor, BarkModel
import uuid
import os


class TTSModel:
    def __init__(self):
        self.device = "cuda" if torch.cuda.is_available() else "cpu"

        print(f"Loading Bark on {self.device}")

        self.processor = AutoProcessor.from_pretrained(
            "suno/bark"
        )

        self.model = BarkModel.from_pretrained(
            "suno/bark",
            torch_dtype=torch.float16 if self.device == "cuda" else torch.float32
        )

        if self.device == "cuda":
            self.model.to("cuda")

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
            "zh"  # Chinese simplified
        ]

    def get_voice(self, language: str):
        """
        Map language codes to Bark voices.
        """

        voices = {
            "en": "v2/en_speaker_6",
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

        return voices.get(language, "v2/en_speaker_6")


    def generate_speech(
        self,
        text: str,
        language: str = "en",
        output_dir: str = "audio"
    ):
        """
        Generate speech from text.

        Returns path to wav file.
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


        with torch.no_grad():
            audio = self.model.generate(
                **inputs
            )


        audio = audio.cpu().numpy().squeeze()


        filename = f"{uuid.uuid4()}.wav"

        filepath = os.path.join(
            output_dir,
            filename
        )


        wavfile.write(
            filepath,
            self.model.generation_config.sample_rate,
            audio
        )


        return filepath


# Load once when service starts
tts_model = TTSModel()