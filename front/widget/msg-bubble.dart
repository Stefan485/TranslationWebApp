import 'package:flutter/material.dart';

import '../model/chat-msg.dart';
import '../services/audio-service.dart';

class MessageBubble extends StatelessWidget{
    final ChatMessage message;
    final AudioService audioService;

    const MessageBubble({
        super.key,
        required this.message,
        required this.audioService,
    });

    @override
    Widget build(BuildContext context){
        final isUser = message.isUser;
        final bg = isUser
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest;
        final fg = isUser
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface;

        return Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                    if (message.status == MessageStatus.sending)
                    SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                    )
                    else if (message.status == MessageStatus.error)
                    Text('Failed to send', style: TextStyle(color: fg))
                    else ...[
                    if (message.originalText.isNotEmpty)
                        Text(message.originalText, style: TextStyle(color: fg)),
                    if (message.translatedText != null &&
                        message.translatedText!.isNotEmpty) ...[
                        if (message.originalText.isNotEmpty)
                        Divider(color: fg.withOpacity(0.3), height: 12),
                        Text(
                        message.translatedText!,
                        style: TextStyle(color: fg, fontStyle: FontStyle.italic),
                        ),
                    ],
                    if (message.audioPath != null)
                        Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: InkWell(
                            onTap: () => audioService.playFile(message.audioPath!),
                            child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Icon(Icons.play_arrow, size: 18, color: fg),
                                const SizedBox(width: 4),
                                Text('Play', style: TextStyle(color: fg, fontSize: 12)),
                            ],
                            ),
                        ),
                        ),
                    ],
                ],
                ),
            ),
        );
    }
}