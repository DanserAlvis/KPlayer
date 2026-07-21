// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../models/player_status.dart';

/// Binding deliberately kept small: all player operations go through mpv's
/// stable client API, rather than composing shell commands.
class LibmpvService {
  DynamicLibrary? _library;
  Pointer<Void>? _handle;

  bool get isInitialized => _handle != null;

  Future<void> initialize() async {
    if (isInitialized) {
      return;
    }
    if (!Platform.isWindows) {
      throw UnsupportedError('KPlayerF actualmente solo admite Windows.');
    }

    try {
      _library = DynamicLibrary.open('libmpv-2.dll');
      final handle = _create()();
      if (handle == nullptr) {
        throw StateError('libmpv no pudo crear una instancia.');
      }
      _handle = handle;

      _setOption('terminal', 'no');
      _setOption('input-default-bindings', 'yes');
      _setOption('force-window', 'yes');
      _setOption('keep-open', 'yes');
      _setOption('hwdec', 'auto-safe');

      final result = _initialize()(handle);
      if (result < 0) {
        _destroy();
        throw StateError('mpv_initialize falló (código $result).');
      }
    } on Object catch (error) {
      _destroy();
      throw StateError(
        'No se pudo iniciar libmpv. Instala libmpv-2.dll junto al ejecutable. '
        'Detalle: $error',
      );
    }
  }

  Future<void> loadFile(String filePath) async {
    _requireInitialized();
    _command(['loadfile', filePath, 'replace']);
  }

  Future<void> play() async => _setProperty('pause', 'no');

  Future<void> pause() async => _setProperty('pause', 'yes');

  Future<void> seek(Duration position) async {
    _command(['seek', '${position.inMilliseconds / 1000}', 'absolute']);
  }

  Future<void> setAudioTrack(int trackId) async {
    _setProperty('aid', '$trackId');
  }

  Future<void> setSubtitleTrack(int? trackId) async {
    _setProperty('sid', trackId?.toString() ?? 'no');
  }

  Future<void> applyShader(String shaderPath) async {
    final file = File(shaderPath);
    if (!await file.exists()) {
      throw ArgumentError.value(shaderPath, 'shaderPath');
    }
    _command(['change-list', 'glsl-shaders', 'set', file.absolute.path]);
  }

  Future<void> removeShaders() async {
    _command(['change-list', 'glsl-shaders', 'clr']);
  }

  Future<PlayerStatus> getStatus() async {
    _requireInitialized();
    final position = _numberProperty('time-pos');
    final duration = _numberProperty('duration');
    final paused = _stringProperty('pause')?.toLowerCase() == 'yes';
    return PlayerStatus(
      isPlaying: !paused && position != null,
      position: Duration(milliseconds: ((position ?? 0) * 1000).round()),
      duration: Duration(milliseconds: ((duration ?? 0) * 1000).round()),
    );
  }

  void _command(List<String> arguments) {
    _requireInitialized();
    final argv = calloc<Pointer<Utf8>>(arguments.length + 1);
    final nativeArguments =
        arguments.map((value) => value.toNativeUtf8()).toList();
    try {
      for (var index = 0; index < nativeArguments.length; index++) {
        argv[index] = nativeArguments[index];
      }
      argv[arguments.length] = nullptr;
      final result = _commandNative()(_handle!, argv);
      if (result < 0)
        throw StateError('mpv rechazó el comando (código $result).');
    } finally {
      for (final argument in nativeArguments) {
        calloc.free(argument);
      }
      calloc.free(argv);
    }
  }

  void _setOption(String name, String value) {
    final nativeName = name.toNativeUtf8();
    final nativeValue = value.toNativeUtf8();
    try {
      final result = _setOptionString()(_handle!, nativeName, nativeValue);
      if (result < 0)
        throw StateError('No se pudo configurar $name ($result).');
    } finally {
      calloc.free(nativeName);
      calloc.free(nativeValue);
    }
  }

  void _setProperty(String name, String value) {
    _requireInitialized();
    final nativeName = name.toNativeUtf8();
    final nativeValue = value.toNativeUtf8();
    try {
      final result = _setPropertyString()(_handle!, nativeName, nativeValue);
      if (result < 0)
        throw StateError('No se pudo actualizar $name ($result).');
    } finally {
      calloc.free(nativeName);
      calloc.free(nativeValue);
    }
  }

  String? _stringProperty(String name) {
    final nativeName = name.toNativeUtf8();
    try {
      final value = _getPropertyString()(_handle!, nativeName);
      if (value == nullptr) return null;
      try {
        return value.toDartString();
      } finally {
        _free()(value.cast<Void>());
      }
    } finally {
      calloc.free(nativeName);
    }
  }

  double? _numberProperty(String name) =>
      double.tryParse(_stringProperty(name) ?? '');

  void _requireInitialized() {
    if (!isInitialized) throw StateError('libmpv aún no está inicializado.');
  }

  Pointer<Void> Function() _create() => _library!
      .lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>(
          'mpv_create');
  int Function(Pointer<Void>) _initialize() => _library!.lookupFunction<
      Int32 Function(Pointer<Void>),
      int Function(Pointer<Void>)>('mpv_initialize');
  int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>)
      _setOptionString() => _library!.lookupFunction<
          Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>),
          int Function(Pointer<Void>, Pointer<Utf8>,
              Pointer<Utf8>)>('mpv_set_option_string');
  int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>)
      _setPropertyString() => _library!.lookupFunction<
          Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>),
          int Function(Pointer<Void>, Pointer<Utf8>,
              Pointer<Utf8>)>('mpv_set_property_string');
  int Function(Pointer<Void>, Pointer<Pointer<Utf8>>) _commandNative() =>
      _library!.lookupFunction<
          Int32 Function(Pointer<Void>, Pointer<Pointer<Utf8>>),
          int Function(Pointer<Void>, Pointer<Pointer<Utf8>>)>('mpv_command');
  Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>) _getPropertyString() =>
      _library!.lookupFunction<
          Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>),
          Pointer<Utf8> Function(
              Pointer<Void>, Pointer<Utf8>)>('mpv_get_property_string');
  void Function(Pointer<Void>) _free() => _library!.lookupFunction<
      Void Function(Pointer<Void>), void Function(Pointer<Void>)>('mpv_free');
  void Function(Pointer<Void>) _terminateDestroy() => _library!.lookupFunction<
      Void Function(Pointer<Void>),
      void Function(Pointer<Void>)>('mpv_terminate_destroy');

  void _destroy() {
    final handle = _handle;
    if (handle != null && handle != nullptr && _library != null)
      _terminateDestroy()(handle);
    _handle = null;
  }

  void dispose() => _destroy();
}
