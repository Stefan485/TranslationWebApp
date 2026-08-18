from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from .model import translation_model
from .context import ConversationContext
from .text_processing import split_sentences


app = FastAPI(
    title="Machine Translation Service"
)


# --------------------------------------------------
# Request models
# --------------------------------------------------
class TranslationRequest(BaseModel):
    text: str
    source_language: str
    target_language: str


class ContextTranslationRequest(BaseModel):
    text: str
    source_language: str
    target_language: str

    # Previous sentences from the conversation
    context: list[str] = Field(
        default_factory=list
    )


class TranslationResponse(BaseModel):
    translation: str
    source_language: str
    target_language: str


# --------------------------------------------------
# Health check
# --------------------------------------------------
@app.get("/")
def root():
    return {
        "service": "machine-translation",
        "status": "running"
    }


# --------------------------------------------------
# Normal translation
# --------------------------------------------------
@app.post(
    "/translate",
    response_model=TranslationResponse
)
def translate(request: TranslationRequest):

    try:
        translation = translation_model.translate(
            text=request.text,
            source_language=request.source_language,
            target_language=request.target_language
        )

        return TranslationResponse(
            translation=translation,
            source_language=request.source_language,
            target_language=request.target_language
        )

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e)
        )


# --------------------------------------------------
# Context-aware translation
# --------------------------------------------------
@app.post(
    "/translate/context",
    response_model=TranslationResponse
)
def translate_with_context(
    request: ContextTranslationRequest
):

    try:
        context = request.context[-5:]

        if context:
            translation_input = "\n".join(
                context + [request.text]
            )
        else:
            translation_input = request.text

        translation = translation_model.translate(
            text=translation_input,
            source_language=request.source_language,
            target_language=request.target_language
        )

        return TranslationResponse(
            translation=translation,
            source_language=request.source_language,
            target_language=request.target_language
        )

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e)
        )