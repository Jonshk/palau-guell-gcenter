# Indoor Nav — prueba de oficina (v0.1)

Prototipo Flutter **independiente** alojado en una rama del repositorio de Palau Güell. No cambia la aplicación de producción ni GCenter.

## Instalación

1. Instalar Flutter y Android SDK.
2. Crear un proyecto Flutter Android base: `flutter create --platforms android indoor_nav_pilot` en una carpeta de trabajo nueva.
3. Sustituir `pubspec.yaml` y `lib/main.dart` por los archivos de este directorio.
4. Añadir en `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>` y antes de `<application>`: `<uses-permission android:name="android.permission.CAMERA" />`.
5. Ejecutar `flutter pub get` y `flutter run` con el teléfono conectado y depuración USB autorizada.
6. Para generar APK de prueba: `flutter build apk --debug`. Se encuentra en `build/app/outputs/flutter-apk/app-debug.apk`.

## Prueba

1. Entrenar: seleccionar cada zona y capturar 5–10 referencias desde distintos ángulos, con permiso.
2. Cerrar por completo la aplicación y abrirla otra vez.
3. Visitante: seleccionar destino y pulsar «Iniciar localización automática».
4. La cámara toma una imagen cada 3 segundos sin mostrar vista previa; el mapa muestra solo una ubicación **probable** cuando supera umbrales heurísticos.
5. Registrar aciertos, fallos, condiciones de iluminación y confusiones entre zonas.

## Limitaciones

Este prototipo usa diferencias de miniaturas normalizadas, no SLAM, ni una red VPR, ni geometría 3D. Puede fallar con cambios de perspectiva, luz, pasillos parecidos y movimiento. No estima coordenadas métricas ni sigue continuamente los pasos. El mapa y las conexiones son ejemplos, NO la geometría real de la oficina. Para una prueba más sólida: descriptores locales, verificación geométrica, ARCore y calibración de mapa. La cámara requiere permiso de Android y debe ver el entorno. No graba vídeo ni almacena fotografías: guarda vectores derivados de cada captura.
