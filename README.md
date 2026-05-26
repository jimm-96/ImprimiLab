# ImprimiLab 🖨️

ImprimiLab es una aplicación móvil desarrollada en Flutter orientada a la **gestión de impresiones 3D**. Su propósito es facilitar la organización, seguimiento y administración de trabajos de impresión, clientes y recursos en un entorno de manufactura aditiva.

## Características (Propuestas / En Desarrollo)
* **Gestión de Trabajos:** Registro de modelos 3D, tiempos estimados de impresión y costos.
* **Seguimiento de Estados:** Control del progreso de cada pedido (En cola, Imprimiendo, Finalizado, Entregado).
* **Inventario de Filamentos:** Control de materiales (PLA, ABS, PETG, resina, etc.), colores, peso restante disponible y precio por gramo.
* **Directorio de Clientes:** Administración de información de contacto y pedidos vinculados a cada cliente.

## Tecnologías Utilizadas
* [Flutter](https://flutter.dev/) - Framework de desarrollo UI creado por Google.
* [Dart](https://dart.dev/) - Lenguaje de programación.

## Requisitos Previos
Para poder clonar y compilar esta aplicación, necesitarás tener instalado lo siguiente en tu entorno de desarrollo:
* Base: [Git](https://git-scm.com)
* SDK: [Flutter SDK](https://docs.flutter.dev/get-started/install) (asegúrate de que incluya soporte para la versión requerida de Dart).
* IDE: [Visual Studio Code](https://code.visualstudio.com/) (con la extensión de Flutter) o [Android Studio](https://developer.android.com/studio).

## Cómo Empezar Localmente

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/jimm-96/ImprimiLab.git
   ```
2. **Navegar al directorio del proyecto:**
   ```bash
   cd ImprimiLab
   ```
3. **Instalar las dependencias necesarias:**
   ```bash
   flutter pub get
   ```
4. **Conectar un dispositivo o emulador y ejecutar la aplicación:**
   ```bash
   flutter run
   ```

## Estructura del Proyecto Recomendada
En la carpeta `lib/` (donde reside el código base) se sugiere utilizar esta organización a medida que avance el proyecto:
* `main.dart`: Punto de entrada principal de la app.
* `screens/` o `pages/`: Las diferentes pantallas o vistas de la aplicación.
* `widgets/`: Componentes gráficos reutilizables (botones personalizados, tarjetas, etc.).
* `models/`: Clases que representan los datos de la app (Usuario, Impresión, Filamento).
* `services/` o `providers/`: Lógica para llamadas a bases de datos o manejo del estado.

## Notas
Este proyecto aun se encuentra en fase de desarrollo muy temprana.
