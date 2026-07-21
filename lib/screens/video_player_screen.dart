import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/player_status.dart';
import '../providers/player_provider.dart';

class VideoPlayerScreen extends StatelessWidget {
  const VideoPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) => Scaffold(
        appBar: AppBar(
          title: const Text('KPlayerF'),
          actions: [
            IconButton(
              tooltip: 'Abrir vídeo',
              onPressed: player.isInitialized ? () => _pickFile(context) : null,
              icon: const Icon(Icons.folder_open_outlined),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatusPanel(
                    player: player, onOpen: () => _pickFile(context)),
              ),
              const SizedBox(height: 16),
              _PlaybackControls(player: player),
              const SizedBox(height: 16),
              _ShaderControls(player: player),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    final path = result?.files.singleOrNull?.path;
    if (path != null && context.mounted) {
      await context.read<PlayerProvider>().openFile(path);
    }
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.player, required this.onOpen});
  final PlayerProvider player;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final error = player.phase == PlayerPhase.error;
    return Card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(error ? Icons.error_outline : Icons.play_circle_outline,
                  size: 48,
                  color: error ? Theme.of(context).colorScheme.error : null),
              const SizedBox(height: 12),
              Text(player.message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
              if (!player.hasMedia) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                    onPressed: player.isInitialized ? onOpen : null,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Seleccionar vídeo')),
              ],
              if (player.hasMedia) ...[
                const SizedBox(height: 8),
                Text(
                    'El vídeo se reproduce en la ventana independiente de mpv.',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    final max = player.duration.inMilliseconds.toDouble();
    final value = player.position.inMilliseconds
        .toDouble()
        .clamp(0, max == 0 ? 1 : max)
        .toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            IconButton(
                onPressed: player.hasMedia ? player.togglePlayPause : null,
                icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow)),
            Expanded(
                child: Text(
                    '${_format(player.position)} / ${_format(player.duration)}')),
          ]),
          Slider(
              value: value,
              max: max == 0 ? 1 : max,
              onChanged: player.canSeek
                  ? (next) => player.seek(Duration(milliseconds: next.round()))
                  : null),
        ]),
      ),
    );
  }

  String _format(Duration value) =>
      '${value.inMinutes.remainder(60).toString().padLeft(2, '0')}:${value.inSeconds.remainder(60).toString().padLeft(2, '0')}';
}

class _ShaderControls extends StatelessWidget {
  const _ShaderControls({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const Icon(Icons.auto_fix_high_outlined),
          const SizedBox(width: 12),
          Expanded(
              child: DropdownButton<String>(
            isExpanded: true,
            value: player.activeShader,
            hint: Text(player.availableShaders.isEmpty
                ? 'Añade archivos .glsl a %APPDATA%\\KPlayerF\\shaders'
                : 'Seleccionar shader'),
            items: player.availableShaders
                .map((path) => DropdownMenuItem(
                    value: path, child: Text(File(path).uri.pathSegments.last)))
                .toList(),
            onChanged: player.availableShaders.isEmpty
                ? null
                : (path) {
                    if (path != null) player.applyShader(path);
                  },
          )),
          IconButton(
              tooltip: 'Actualizar shaders',
              onPressed: player.refreshShaders,
              icon: const Icon(Icons.refresh)),
          IconButton(
              tooltip: 'Quitar shaders',
              onPressed:
                  player.activeShader == null ? null : player.removeShader,
              icon: const Icon(Icons.layers_clear)),
        ]),
      ),
    );
  }
}
