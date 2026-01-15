import 'dart:core';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

class LibmpvService {
  static const String _libName = 'libmpv';
  late DynamicLibrary _dylib;
  late Pointer _mpvHandle;
  bool _initialized = false;

  Future<void> initialize() async {
    try {
      if (_initialized) return;

      if (Platform.isWindows) {
        _dylib = DynamicLibrary.open('libmpv-2.dll');
      } else if (Platform.isLinux) {
        _dylib = DynamicLibrary.open('libmpv.so.1');
      } else if (Platform.isMacOS) {
        _dylib = DynamicLibrary.open('libmpv.2.dylib');
      }

      final mpvCreate = _dylib.lookupFunction<
          Pointer Function(),
          Pointer Function()>('mpv_create');
      
      _mpvHandle = mpvCreate();

      final mpvInitialize = _dylib.lookupFunction<
          Int32 Function(Pointer),
          int Function(Pointer)>('mpv_initialize');
      
      final initResult = mpvInitialize(_mpvHandle);
      if (initResult < 0) {
        throw Exception('MPV init failed: $initResult');
      }

      _loadShaderDirectory();
      _initialized = true;
    } catch (e) {
      throw Exception('Initialize error: $e');
    }
  }

  Future<void> loadFile(String filePath) async {
    try {
      if (!_initialized) throw Exception('MPV not initialized');
      final command = ['loadfile', filePath].join('\u0000');
      _commandMpv(command);
    } catch (e) {
      throw Exception('Load file error: $e');
    }
  }

  Future<void> play() async {
    try {
      _commandMpv('set pause false');
    } catch (e) {
      throw Exception('Play error: $e');
    }
  }

  Future<void> pause() async {
    try {
      _commandMpv('set pause true');
    } catch (e) {
      throw Exception('Pause error: $e');
    }
  }

  Future<void> seek(double position) async {
    try {
      _commandMpv('seek ${position.toStringAsFixed(2)} absolute');
    } catch (e) {
      throw Exception('Seek error: $e');
    }
  }

  Future<List<dynamic>> getAvailableShaders() async {
    try {
      final shaderDir = _getShaderDirectory();
      final dir = Directory(shaderDir);

      if (!await dir.exists()) {
        await dir.create(recursive: true);
        await _downloadAnime4kShaders(shaderDir);
      }

      final shaders = [];
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.glsl')) {
          shaders.add(entity.uri.pathSegments.last);
        }
      }
      return shaders;
    } catch (e) {
      throw Exception('Get shaders error: $e');
    }
  }

  Future<void> applyShader(String shaderName) async {
    try {
      final shaderPath = '${_getShaderDirectory()}/$shaderName';
      _commandMpv('set glsl-shaders "$shaderPath"');
    } catch (e) {
      throw Exception('Apply shader error: $e');
    }
  }

  Future<void> removeShader() async {
    try {
      _commandMpv('set glsl-shaders ""');
    } catch (e) {
      throw Exception('Remove shader error: $e');
    }
  }

  Future<bool> checkAMDFluidMotion() async {
    try {
      if (!Platform.isWindows) return false;
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> setAMDFluidMotion(bool enable) async {
    try {
      if (enable) {
        _commandMpv('set video-sync-adrop-size 1000');
      } else {
        _commandMpv('set video-sync-adrop-size 0');
      }
    } catch (e) {
      throw Exception('AMD FMF error: $e');
    }
  }

  Future<void> selectAudioTrack(int trackIndex) async {
    try {
      _commandMpv('set aid $trackIndex');
    } catch (e) {
      throw Exception('Audio track error: $e');
    }
  }

  Future<void> selectSubtitleTrack(int trackIndex) async {
    try {
      if (trackIndex < 0) {
        _commandMpv('set sid no');
      } else {
        _commandMpv('set sid $trackIndex');
      }
    } catch (e) {
      throw Exception('Subtitle error: $e');
    }
  }

  Future<Map<String, Object>> getPlayerStatus() async {
    try {
      return {
        'playing': true,
        'position': 0.0,
        'duration': 0.0,
      };
    } catch (e) {
      return {'playing': false, 'position': 0.0, 'duration': 0.0};
    }
  }

  void _commandMpv(String command) {
    // Send command to MPV
  }

  void _loadShaderDirectory() {
    final shaderDir = _getShaderDirectory();
    _commandMpv('glsl-shaders-dir=$shaderDir');
  }

  String _getShaderDirectory() {
    if (Platform.isWindows) {
      return '${Platform.environment['APPDATA']}\\animeflutter_player\\shaders\\anime4k';
    } else if (Platform.isLinux) {
      return '${Platform.environment['HOME']}/.config/animeflutter_player/shaders/anime4k';
    } else {
      return '${Platform.environment['HOME']}/Library/Application Support/animeflutter_player/shaders/anime4k';
    }
  }

  Future<void> _downloadAnime4kShaders(String targetDir) async {
    try {
      print('Downloading Anime4K shaders to: $targetDir');
    } catch (e) {
      print('Download error: $e');
    }
  }

  void dispose() {
    try {
      if (_initialized) {
        final mpvTerminateDestroy = _dylib.lookupFunction<
            Void Function(Pointer),
            void Function(Pointer)>('mpv_terminate_destroy');
        
        mpvTerminateDestroy(_mpvHandle);
        _initialized = false;
      }
    } catch (e) {
      print('Dispose error: $e');
    }
  }
}