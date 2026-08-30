import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/chat-provider.dart';

class InputBar extends ConsumerStatefulWidget{
    const InputBar({super.key});

    @override
    ConsumerState<InputBar> createState()  => _InputBarState();
}

class _InputBarState extends ConsumerState<InputBar>{
    final _controller = TextEditingController();
    bool _isRecording = false;
    Duration _recordDuration = Duration.zero;
    Timer? _timer;

    void _sendText(){
        final text = _controller.text;
        if(text.trim().isEmpty) return;
        ref.read(chatProvider.notifier).sendTypedText(text);
        _controller.clear();
    }

    Future<void> _startRecording() async{
        final audio = ref.read(audioServiceProvider);
        try{
            await audio.startRecording();
            setState((){
                _isRecording = true;
                _recordDuration = Duration.zero;
            });
        } catch (e){
            if(mounted){
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mic permission needed: $e')),
                );
            }
        }
    }

    Future<void> _stopAndSendRecording() async{
        _timer?.cancel();
        final audio = ref.read(audioServiceProvider);
        final file = await audio.stopRecording();
        setState(() => _isRecording = false);
        if (file != null){
            ref.read(chatProvider.notifier).sendVoiceMemo(file);
        }
    }

    Future<void> _cancelRecording() async{
        _timer?.cancel();
        final audio = ref.read(audioServiceProvider);
        setState(() => _isRecording = false);
    }

    String _formatDuration(Duration d){
        final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
        final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
        return '$m:$s';
    }

    @override
    Widget build(BuildContext context){
        return SafeArea(
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, -1),
                        ),
                    ],
                ),
                child: _isRecording ? _buildRecordingRow() : _buildTypingRow(),
            ),
        );
    }

    Widget _buildTypingRow(){
        return Row(
            children: [
                Expanded(
                child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendText(),
                    decoration: InputDecoration(
                    hintText: 'Type a message…',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                    ),
                    filled: true,
                    ),
                ),
                ),
                const SizedBox(width: 6),
                ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, value, _) {
                    final hasText = value.text.trim().isNotEmpty;
                    return IconButton(
                    icon: Icon(hasText ? Icons.send : Icons.mic),
                    onPressed: hasText ? _sendText : _startRecording,
                    );
                },
                ),
            ],
        );
    }

    Widget _buildRecordingRow(){
        return Row(
            children: [
                IconButton(
                    icon: Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                    ),
                    iconSize: 30,
                    onPressed: _stopAndSendRecording,
                ),
                const SizedBox(width: 4),
                _PulsingDot(),
                const SizedBox(width: 8),
                Text(_formatDuration(_recordDuration)),
                const Spacer(),
                const Text('Recording…'),
                const Spacer(),
                IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                iconSize: 30,
                onPressed: _stopAndSendRecording,
                ),
            ],
        );
    }
}

class _PulsingDot extends StatefulWidget{
    @override
    State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin{
    late final AnimationController _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    @override
    void dispose(){
        _controller.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context){
        return FadeTransition(
            opacity: _controller,
            child: const CircleAvatar(radius: 5, backgroundColor: Colors.red),
        );
    }
}