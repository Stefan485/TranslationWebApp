import torch
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM


class TranslationModel:
    def __init__(self):
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model_name = "facebook/nllb-200-1.3B"

        print(f"Loading NLLB-200 1.3B on {self.device}")

        self.tokenizer = AutoTokenizer.from_pretrained(
            self.model_name
        )

        self.model = AutoModelForSeq2SeqLM.from_pretrained(
            self.model_name
        )

        self.model.to(self.device)
        self.model.eval()

        print("NLLB-200 1.3B loaded successfully")

    def get_nllb_language(self, language: str) -> str:
        languages = {
            "en": "eng_Latn",
            "de": "deu_Latn",
            "fr": "fra_Latn",
            "es": "spa_Latn",
            "it": "ita_Latn",
            "ja": "jpn_Jpan",
            "ko": "kor_Hang",
            "pl": "pol_Latn",
            "pt": "por_Latn",
            "ru": "rus_Cyrl",
            "tr": "tur_Latn",
            "zh": "zho_Hans",
            "sr": "srp_Cyrl",
            "hr": "hrv_Latn",
        }

        if language not in languages:
            raise ValueError(
                f"Unsupported language: {language}"
            )

        return languages[language]

    def translate(
        self,
        text: str,
        source_language: str,
        target_language: str
    ) -> str:

        source_language = self.get_nllb_language(
            source_language
        )

        target_language = self.get_nllb_language(
            target_language
        )

        self.tokenizer.src_lang = source_language

        inputs = self.tokenizer(
            text,
            return_tensors="pt",
            truncation=True,
            max_length=512
        ).to(self.device)

        target_language_id = self.tokenizer.convert_tokens_to_ids(
            target_language
        )

        with torch.no_grad():
            generated_tokens = self.model.generate(
                **inputs,
                forced_bos_token_id=target_language_id,
                max_length=200,
                num_beams=5
            )

        translation = self.tokenizer.batch_decode(
            generated_tokens,
            skip_special_tokens=True
        )[0]

        return translation.strip()


translation_model = TranslationModel()