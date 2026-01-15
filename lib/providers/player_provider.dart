import 'package:flutter/foundation.dart';
import 'dart:io';
import '../services/libmpv_service.dart';

class PlayerProvider extends ChangeNotifier {
  late LibmpvService _mpvService;
  
  String? currentFile;
  bool isPlaying = false;
  bool isInitialized = false;
  double currentPosition = 0;
  double duration = 0;
  
  List audioTracks = [];
  List subtitleTracks = [];
  int selectedAudioTrack = 0;
  int selectedSubtitleTrack = -1;
  
  List availableShaders = [];
  String? activeShader;
  
  bool amdFmfAvailable = false;
  bool amdFmfEnabled = false;
  
  String playerInfo = '';

  PlayerProvider() {
    _mpvService = LibmpvService();
    _initializePlayer();
  }

  Future _initializePlayer() async {
    try {
      await _mpvService.initialize();
      availableShaders = await _mpvService.getAvailableShaders();
      amdFmfAvailable = await _mpvService.checkAMDFluidMotion();
      isInitialized = true;
      playerInfo = 'Reproductor listo. Shaders: ${availableShaders.length}';
      notifyListeners();
    } catch (e) {
      playerInfo = 'Error: $e';
      notifyListeners();
    }
  }

  Future openFile(String path) async {
    try {
      if (!await File(path).exists()) {
        playerInfo = 'Archivo no encontrado';
        notifyListeners();
        return;
      }
      await _mpvService.loadFile(path);
      currentFile = path;
      playerInfo = 'Reproduciendo: ${File(path).uri.pathSegments.last}';
      notifyListeners();
    } catch (e) {
      playerInfo = 'Error: $e';
      notifyListeners();
    }
  }

  Future play() async {
    try {
      await _mpvService.play();
      isPlaying = true;
      notifyListeners();
    } catch (e) {
      playerInfo = 'Error: $e';
      notifyListeners();
    }
  }

  Future pause() async {
    try {
      await _mpvService.pause();
      isPlaying = false;
      notifyListeners();
    } catch (e) {
      playerInfo = 'Error: $e';
      notifyListeners();
    }
  }

  Future togglePlayPause() async {
    isPlaying ? await pause() : await play();
  }

  Future seek(double position) async {
    try {
      await _mpvService.seek(position);
      currentPosition = position;
      notifyListeners();
    } catch (e) {
      playerInfo = 'Error: $e';
      notifyListeners();
    }
  }

  Future applyShader(String shaderName) async {
    try {
      await _mpvService.applyShader(shaderName);
      activeShader = shaderName;
      playerInfo = 'Shader: $shaderName';
      notifyListeners();
    } catch (e) {
      playerInfo = 'Error: $e';
      notifyListeners();
    }
  }

  Future removeShader() async {
    try {
      await _mpvService.removeShader();
      activeShader = null;
      playerInfo = 'Shader removido';
      notifyListeners();
    } catch (e) {
      playerInfo = 'Error: $e';
      notifyListeners();
    }
  }

  Future toggleAMDFluidMotion(bool enable) async {
    try {
      if (amdFmfAvailable) {
        await _mpvService.setAMDFluidMotion(enable);
        amdFmfEnabled = enable;
        playerInfo = 'AMD FMF: ${enable ? "ON" : "OFF"}';
        notifyListeners();
      }
    } catch (e) {
      playerInfo = 'Error: $e';
      notifyListeners();
    }
  }

  Future setAudioTrack(int trackIndex) async {
    try {
      await _mpvService.selectAudioTrack(trackIndex);
      selectedAudioTrack = trackIndex;
      notifyListeners();
    } catch (e) {
      playerInfo = 'Error audio: $e';
      notifyListeners();
    }
  }

  Future setSubtitleTrack(int trackIndex) async {
    try {
      await _mpvService.selectSubtitleTrack(trackIndex);
      selectedSubtitleTrack = trackIndex;
      notifyListeners();
    } catch (e) {
      playerInfo = 'Error subtítulo: $e';
      notifyListeners();
    }
  }

  Future updatePlayerStatus() async {
    try {
      final status = await _mpvService.getPlayerStatus();
      isPlaying = status['playing'] ?? false;
      currentPosition = status['position'] ?? 0;
      duration = status['duration'] ?? 0;
      notifyListeners();
    } catch (e) {
      // Silent error
    }
  }

  @override
  void dispose() {
    _mpvService.dispose();
    super.dispose();
  }
}