from dataclasses import dataclass


@dataclass
class ConversationSentence:
    source: str
    translation: str


class ConversationContext:
    def __init__(self, max_sentences: int = 5):
        self.max_sentences = max_sentences
        self.history: list[ConversationSentence] = []

    def add(
        self,
        source: str,
        translation: str
    ):
        self.history.append(
            ConversationSentence(
                source=source,
                translation=translation
            )
        )

        # Keep only the last N sentences
        self.history = self.history[
            -self.max_sentences:
        ]

    def get_source_context(self) -> list[str]:
        """
        Return the source-language sentences that
        should be supplied as context.
        """

        return [
            item.source
            for item in self.history
        ]

    def get_history(self) -> list[ConversationSentence]:
        return self.history.copy()

    def clear(self):
        self.history.clear()

    def __len__(self):
        return len(self.history)