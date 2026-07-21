# KPlayerF

Reproductor de vídeo para Windows construido con Flutter y la API cliente de
libmpv. Es un proyecto Flutter; no utiliza WPF ni .NET.

## Estado actual

- Selección y reproducción de archivos mediante libmpv.
- Pausa, reanudación y salto temporal.
- Decodificación por hardware configurada como `auto-safe` por mpv.
- Aplicación de shaders GLSL que el usuario coloque en su carpeta local.

El vídeo se abre en una ventana gestionada por mpv. Incrustarlo dentro de la
ventana de Flutter requiere una implementación nativa adicional de `wid` o
una textura de Flutter y no se presenta como funcionalidad terminada.

AMD Fluid Motion Frames se configura en el controlador AMD, no mediante una
opción de libmpv; por ello la aplicación no muestra un interruptor ficticio.

## Requisitos

- Windows 10/11 x64.
- Flutter estable y las herramientas de compilación de Windows.
- Una DLL x64 de libmpv llamada `libmpv-2.dll`.

Coloca la DLL en `third_party/libmpv/libmpv-2.dll` antes de `flutter build
windows`. CMake la incluirá en el directorio final. No incluyas DLLs de origen
desconocido: deben coincidir en arquitectura con el ejecutable y respetar la
licencia de libmpv y sus dependencias.

## Desarrollo

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

## Shaders

Guarda archivos `.glsl` en `%APPDATA%\KPlayerF\shaders` y pulsa actualizar en
la interfaz. El proyecto no descarga código ni shaders automáticamente.

## Límites y siguientes pasos

Para una aplicación de producción conviene añadir una ventana/vídeo incrustado
en Flutter, lectura de la lista de pistas de mpv, persistencia de preferencias,
control de pantalla completa y pruebas de integración con una DLL conocida.
