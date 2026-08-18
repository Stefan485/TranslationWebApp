import torch
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM


class TranslationModel:
    def __init__(self):
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model_name = "facebook/nllb-200-1.3B"

        print(f"Loading NLLB-200 1.3B on {self.device}")

        # Load tokenizer
        self.tokenizer = AutoTokenizer.from_pretrained(
            self.model_name
        )

        # Load model
        self.model = AutoModelForSeq2SeqLM.from_pretrained(
            self.model_name,
        )

        self.model.to(self.device)
        self.model.eval()

        print("NLLB-200 1.3B loaded successfully")

    def translate(
        self,
        text: str,
        source_language: str,
        target_language: str
        ) -> str:

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