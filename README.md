<img width="985" height="631" alt="image" src="https://github.com/user-attachments/assets/e34d8ecd-154b-4fec-a754-102e41230150" />
# ⚡ KPlayer Titanium

![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?style=flat-square&logo=windows)
![Language](https://img.shields.io/badge/Language-C%23%20%7C%20WPF-512BD4?style=flat-square&logo=c-sharp)
![Engine](https://img.shields.io/badge/Engine-libmpv%20%7C%20DirectX-FF004D?style=flat-square)

**KPlayer Titanium** es un reproductor de video de alto rendimiento ("High-Fidelity") desarrollado nativamente en **C# y WPF**.

A diferencia de los reproductores convencionales, KPlayer está diseñado como un motor gráfico dedicado. Utiliza acceso directo a **DirectX 11 (D3D11)** y **libmpv** para ofrecer funciones avanzadas como interpolación de movimiento por GPU (Efecto Telenovela), sincronización VRR (FreeSync/G-Sync) y escalado mediante Shaders.

---

## 🚀 Características Principales

### 🎞️ Motor de Movimiento Dual
KPlayer ofrece dos filosofías de visualización opuestas pero perfeccionadas:
1.  **Modo Cine Purista (Native 24p):** Utiliza *Reclocking* de audio/video para sincronizar matemáticamente videos de 23.976fps con monitores de 48Hz/72Hz/144Hz. Cero *judder*, fluidez cinematográfica original.
2.  **Modo Telenovela (Sphinx Interpolation):** Utiliza la potencia de la GPU y el algoritmo `tscale=sphinx` para generar cuadros intermedios, convirtiendo contenido de 24fps en 60fps, 120fps o 144fps fluidos.

### 🎮 Tecnologías Gaming Aplicadas a Video
* **Pantalla Exclusiva (D3D11 Exclusive):** Se salta el compositor de Windows (DWM) para reducir la latencia y asegurar una estabilidad de frames perfecta.
* **Soporte VRR (FreeSync / G-Sync):** El motor ajusta dinámicamente la velocidad del video (`display-resample`) para que coincida con el refresco del monitor.

### 🎨 Calidad de Imagen "Titanium"
* **Escalado Anime4K:** Integración nativa de shaders GLSL para escalado de Anime en tiempo real (Modos HD y Ultra).
* **HDR Tone Mapping:** Algoritmos seleccionables (Clip, Reinhard, Hable) para ver contenido HDR en pantallas SDR sin colores lavados.
* **Decodificación por Hardware:** Soporte completo para `d3d11va` (Native) y `auto-copy`.

### 💎 Interfaz Moderna (UI)
* Diseño oscuro minimalista con acentos **Rosa Neón (#FF004D)**.
* Controles flotantes y sliders de precisión.
* Sin bordes (WindowChrome nativo) con soporte completo para arrastrar y soltar.

---

## 🛠️ Requisitos del Sistema

* **SO:** Windows 10 o Windows 11 (x64).
* **GPU:** Tarjeta gráfica compatible con DirectX 11 (NVIDIA, AMD o Intel Moderno).
    * *Recomendado para interpolación:* GTX 1050 / RX 560 o superior.
* **Runtime:** .NET 6.0 o superior.

---

## 📥 Instalación y Estructura

Para compilar o ejecutar el proyecto, necesitas asegurar la siguiente estructura de carpetas junto al ejecutable (`KPlayer.exe`):

```text
KPlayer/
├── KPlayer.exe
├── mpv-2.dll          <-- NECESARIO (Librería libmpv compilada)
└── shaders/           <-- NECESARIO (Archivos .glsl para Anime4K)
    ├── Anime4K_Clamp_Highlights.glsl
    ├── Anime4K_Restore_CNN_M.glsl
    └── ...
