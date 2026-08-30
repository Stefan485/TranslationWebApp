enum MessageType{text, voice}

enum MessageStatus{sending, sent, error}

class ChatMessage{
    final String id;
    final MessageType type;
    final String originalText;
    final String? translatedText;
    final String? audioPath;
    final bool isUser;

    final DateTime timestamp;
    final MessageStatus status;

    const ChatMessage({
        required this.id,
        required this.type,
        required this.originalText,
        required this.isUser,
        required this.timestamp,
        this.translatedText,
        this.audioPath,
        this.status = MessageStatus.sent,
    });

    ChatMessage copyWith({
        String? originalText,
        String? translatedText,
        String? audioPath,
        MessageStatus? status,
    }){
        return ChatMessage(
            id: id,
            type: type,
            originalText: originalText ?? this.originalText,
            isUser: isUser,
            timestamp: timestamp,
            translatedText: translatedText ?? this.translatedText,
            audioPath: audioPath ?? this.audioPath,
            status: status ?? this.status,
        );
    }
}