# ImpriLab

ImpriLab es una aplicación móvil desarrollada en Flutter orientada a la **gestión integral y cotización de impresiones 3D**. Su propósito es facilitar a los makers y emprendimientos de manufactura aditiva (tanto en FDM como en Resina) la organización de sus pedidos, el cálculo preciso de costos de producción y la administración de sus recursos.

## Características Actuales (MVP Implementado)

* **Cálculo Avanzado de Costos:** Calcula el costo real de producción sumando consumo de material, gasto eléctrico (KWh y consumo de la máquina), depreciación de la impresora por horas de uso, y mano de obra.
* **Soporte Multitecnología (FDM y Resina):** Perfiles de laminación (Slicer) independientes. Permite registrar parámetros específicos como tiempos de exposición para resina, o temperaturas y relleno para FDM.
* **Gestión Completa de Proyectos (Pedidos):** 
  * Inclusión de múltiples piezas por proyecto.
  * Tiempos y fechas de entrega exactos.
  * Niveles de prioridad (Alta, Media, Baja).
  * Opciones de post-procesado (Lijado/Limpieza, Pintura/Imprimación).
  * Adjunte de evidencia fotográfica del modelo o pieza.
* **Cotizador Inteligente:** Sugiere un precio de venta final basado en el costo total de producción y un margen de ganancia (%) ajustable en tiempo real mediante un slider.
* **Gestión de Inventario:** Registro detallado de impresoras (vida útil, costo, consumo en Watts) y materiales (resinas y filamentos, precio, cantidad disponible).
* **Exportación Rápida:** Función de copiado rápido al portapapeles de un resumen detallado del proyecto (incluyendo fechas y precios) listo para enviar por mensaje al cliente.
* **Auto-guardado (Borradores):** Persistencia local de datos al crear un nuevo proyecto para no perder información si se cierra la pantalla accidentalmente.

## Tecnologías y Paquetes Utilizados
* **Framework:** [Flutter](https://flutter.dev/) - Framework de desarrollo UI multiplataforma.
* **Lenguaje:** [Dart](https://dart.dev/)
* **Persistencia:** shared_preferences - Para el guardado persistente del estado global de la app, impresoras, materiales y borradores de proyectos en formato JSON.
* **Documentación / Reportes:** [pdf](https://pub.dev/packages/pdf) y [printing](https://pub.dev/packages/printing) - Para la generación, visualización e impresión directa de cotizaciones detalladas en formato PDF.
* **Multimedia:** image_picker - Para la captura y selección de imágenes locales de referencia.
* **Gestión de Versiones de Dependencias:** Se utiliza el archivo `pubspec.lock` para garantizar la consistencia exacta de todas las dependencias del proyecto al trabajar desde computadores diferentes. Al clonar el repositorio, basta con ejecutar `flutter pub get` para reconstruir el entorno exacto.

## Requisitos Previos
Para clonar y ejecutar esta aplicación, necesitas configurar tu entorno de desarrollo con:
* [Git](https://git-scm.com)
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Asegúrate de tener instaladas las dependencias de Android/iOS según corresponda).
* IDE recomendado: [Visual Studio Code](https://code.visualstudio.com/) (con la extensión de Flutter) o [Android Studio](https://developer.android.com/studio).

## Cómo Empezar Localmente

### Desarrollo Flutter

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/jimm-96/ImprimiLab.git
   ```

2. **Navegar al directorio del proyecto:**
   ```bash
   cd ImprimiLab
   ```

3. **Instalar las dependencias del proyecto:**
   ```bash
   flutter pub get
   ```
   *(Nota: Esto leerá el archivo `pubspec.yaml` e instalará las versiones congeladas especificadas en `pubspec.lock`, asegurando que no haya problemas de compatibilidad entre computadores).*

4. **Conectar un dispositivo o emulador y ejecutar la aplicación:**
   ```bash
   flutter run
   ```

### Scripts y Herramientas Auxiliares de Python (Opcional)

Si utilizas scripts auxiliares de Python en el proyecto (por ejemplo, para formateo automático de código, análisis estático con linters o automatización de análisis como SonarQube), debes configurar un entorno aislado (VENV) para evitar conflictos globales:

1. **Crear el entorno virtual (VENV):**
   ```bash
   python -m venv venv
   ```

2. **Activar el entorno virtual:**
   * **En Windows (PowerShell):**
     ```powershell
     .\venv\Scripts\Activate.ps1
     ```
   * **En macOS/Linux:**
     ```bash
     source venv/bin/activate
     ```

3. **Instalar las herramientas de desarrollo:**
   ```bash
   pip install -r requirements.txt
   ```

## Arquitectura y Estructura del Proyecto Recomendada

A medida que el proyecto siga escalando fuera del MVP, se recomienda transicionar a la siguiente arquitectura de carpetas dentro de lib/:

* main.dart: Punto de entrada y configuración de tema.
* models/: Definición de clases de negocio (Printer, Material3D, Piece, Project, SlicerConfig).
* screens/: Pantallas principales (DashboardScreen, NewProjectScreen, ProjectDetailScreen, etc.).
* widgets/: Componentes UI reutilizables (tarjetas de proyectos, modales de ingreso).
* state/ o providers/: Gestión global del estado de la aplicación.
* services/: Lógica de persistencia (SharedPreferences, futura base de datos) y utilidades externas.

## Roadmap (Próximas Mejoras)

* **Directorio de Clientes:** Administración de información de contacto y vinculación con proyectos.
* **Seguimiento de Estados:** Tablero tipo Kanban para el progreso de pedidos (En cola, Imprimiendo, Post-procesado, Finalizado, Entregado).
* **Migración de Estado:** Transición de ChangeNotifier a Riverpod o Provider para un escalado más robusto.
* **Base de Datos:** Implementación de SQLite o Firebase para persistencia permanente de proyectos finalizados y control de stock en tiempo real.
