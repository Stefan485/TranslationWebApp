import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
    final AudioRecorder _recorder = AudioRecorder();
    final AudioPlayer _player = AudioPlayer();

    bool _recording = false;
    bool get _isRecording => _recording;

Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_memo_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
        const RecordConfig(
            encoder: AudioEncoder.aacLc,
        ),
        path: path,
    );

    _recording = true;
}

    Future<File?> stopRecording() async {
        final path = await _recorder.stop();
        _recording = false;

        if (path == null) return null;

        return File(path);
    }

    Future<void> cancelRecording() async {
        await _recorder.cancel();
        _recording = false;
    }

    Future<void> playFile(String path) async {
        await _player.play(DeviceFileSource(path));
    }

    Future<String> saveAudioBytes(
        List<int> bytes, {
        String ext = 'mp3',
    }) async {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.$ext';

        final file = File(path);

        await file.writeAsBytes(bytes);

        return path;
    }

    void dispose() {
        _recorder.dispose();
        _player.dispose();
    }
}