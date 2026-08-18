import re


def split_sentences(text: str) -> list[str]:
    text = text.strip()

    if not text:
        return []

    # Normalize whitespace
    text = re.sub(r"\s+", " ", text)

    # Split after ., ! or ?
    sentences = re.split(
        r"(?<=[.!?])\s+",
        text
    )

    return [
        sentence.strip()
        for sentence in sentences
        if sentence.strip()
    ]


def is_complete_sentence(text: str) -> bool:
    """
    Determine whether text appears to end with
    normal sentence-ending punctuation.
    """

    text = text.strip()

    if not text:
        return False

    return bool(
        re.search(r"[.!?]$", text)
    )