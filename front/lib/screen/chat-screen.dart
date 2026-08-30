import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/chat-provider.dart';
import '../widget/msg-bubble.dart';
import '../widget/inputBar.dart';

class ChatScreen extends ConsumerStatefulWidget{
    const ChatScreen({super.key});

    @override
    ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
    final _scrollController = ScrollController();

    void _scrollToBottom(){
        if (!_scrollController.hasClients) return;
        WidgetsBinding.instance.addPostFrameCallback((_){
            _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
            );
        });
    }

    @override
    void dispose(){
        _scrollController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context){
        final message = ref.watch(chatProvider);
        final audio = ref.read(audioServiceProvider);
        
        ref.listen(chatProvider, (prev, next) {
            if (prev == null || next.length != prev.length) {
                _scrollToBottom();
            }
        });

        return Scaffold(
            appBar: AppBar(
                title: Consumer(
                    builder: (context, ref, _) {
                        final detected = ref.watch(detectedSourceLangProvider);
                            return Text(detected == null
                                ? 'Translate chat'
                                : 'Detected language: ${detected.toUpperCase()}');
                    },
                ),
                actions: [
                    Consumer(
                        builder: (context, ref, _) {
                            final languagesAsync = ref.watch(availableLanguagesProvider);
                            final target = ref.watch(targetLangProvider);

                            return languagesAsync.when(
                                loading: () => const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                ),
                                error: (_, __) => IconButton(
                                    icon: const Icon(Icons.error_outline),
                                    onPressed: () => ref.invalidate(availableLanguagesProvider),
                                    tooltip: 'Retry loading languages',
                                ),
                                data: (languages) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                            value: languages.any((l) => l.code == target)
                                                ? target
                                                : null,
                                            hint: const Text('Target'),
                                            icon: const Icon(Icons.arrow_drop_down),
                                            onChanged: (code) {
                                                if (code != null) {
                                                    ref.read(targetLangProvider.notifier).state = code;
                                                }
                                            },
                                            items: languages
                                                .map((lang) => DropdownMenuItem(
                                                    value: lang.code,
                                                    child: Text(lang.name),
                                                    ))
                                                .toList(),
                                        ),
                                    ),
                                ),
                            );
                        },
                    ),
                ],
            ),
            body: Column(
                children: [
                    Expanded(
                        child: message.isEmpty
                            ? const Center(
                                child: Text(
                                    'Type or record a voice memo to start translating',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                ),
                            )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: message.length,
                                itemBuilder: (context, index){
                                    return MessageBubble(
                                        message: message[index],
                                        audioService: audio,
                                    );
                                },
                            ),
                    ),
                    const InputBar(),
                ],
            ),
        );
    }
}