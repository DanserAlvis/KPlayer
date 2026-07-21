import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/player_status.dart';
import '../services/libmpv_service.dart';

class PlayerProvider extends ChangeNotifier {
  PlayerProvider({LibmpvService? service})
      : _service = service ?? LibmpvService() {
    unawaited(initialize());
  }

  final LibmpvService _service;
  Timer? _statusTimer;
  bool _refreshing = false;

  PlayerPhase phase = PlayerPhase.initializing;
  String? currentFile;
  String? activeShader;
  List<String> availableShaders = const [];
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  String message = 'Iniciando libmpv…';

  bool get isInitialized => _service.isInitialized;
  bool get isPlaying => phase == PlayerPhase.playing;
  bool get hasMedia => currentFile != null;
  bool get canSeek => duration > Duration.zero;

  Future<void> initialize() async {
    try {
      await _service.initialize();
      await refreshShaders();
      phase = PlayerPhase.ready;
      message = 'Listo. El vídeo se abre en la ventana de libmpv.';
      _statusTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        unawaited(refreshStatus());
      });
    } on Object catch (error) {
      phase = PlayerPhase.error;
      message = '$error';
    }
    notifyListeners();
  }

  Future<void> openFile(String path) async {
    if (!await File(path).exists()) {
      _setError('No se encontró el archivo seleccionado.');
      return;
    }
    try {
      phase = PlayerPhase.loading;
      message = 'Abriendo ${File(path).uri.pathSegments.last}…';
      notifyListeners();
      await _service.loadFile(path);
      currentFile = path;
      phase = PlayerPhase.playing;
      message = File(path).uri.pathSegments.last;
    } on Object catch (error) {
      _setError('$error');
      return;
    }
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (!hasMedia) return;
    try {
      if (isPlaying) {
        await _service.pause();
        phase = PlayerPhase.paused;
      } else {
        await _service.play();
        phase = PlayerPhase.playing;
      }
      notifyListeners();
    } on Object catch (error) {
      _setError('$error');
    }
  }

  Future<void> seek(Duration value) async {
    if (!canSeek) return;
    try {
      await _service.seek(value);
      position = value;
      notifyListeners();
    } on Object catch (error) {
      _setError('$error');
    }
  }

  Future<void> refreshShaders() async {
    final folder = await _shaderDirectory();
    if (!await folder.exists()) await folder.create(recursive: true);
    final shaders = <String>[];
    await for (final entity in folder.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.glsl')) {
        shaders.add(entity.path);
      }
    }
    shaders.sort();
    availableShaders = shaders;
  }

  Future<void> applyShader(String path) async {
    try {
      await _service.applyShader(path);
      activeShader = path;
      message = 'Shader activo: ${File(path).uri.pathSegments.last}';
      notifyListeners();
    } on Object catch (error) {
      _setError('$error');
    }
  }

  Future<void> removeShader() async {
    try {
      await _service.removeShaders();
      activeShader = null;
      message = 'Shaders desactivados.';
      notifyListeners();
    } on Object catch (error) {
      _setError('$error');
    }
  }

  Future<Directory> shaderDirectory() => _shaderDirectory();

  Future<void> refreshStatus() async {
    if (_refreshing || !isInitialized || !hasMedia) return;
    _refreshing = true;
    try {
      final status = await _service.getStatus();
      position = status.position;
      duration = status.duration;
      if (phase != PlayerPhase.loading && phase != PlayerPhase.error) {
        phase = status.isPlaying ? PlayerPhase.playing : PlayerPhase.paused;
      }
      notifyListeners();
    } catch (_) {
      // mpv can briefly reject reads while opening or closing a file.
    } finally {
      _refreshing = false;
    }
  }

  Future<Directory> _shaderDirectory() async {
    final appData = Platform.environment['APPDATA'];
    final base =
        appData == null || appData.isEmpty ? Directory.current.path : appData;
    return Directory(
        '$base${Platform.pathSeparator}KPlayerF${Platform.pathSeparator}shaders');
  }

  void _setError(String error) {
    phase = PlayerPhase.error;
    message = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _service.dispose();
    super.dispose();
  }
}
