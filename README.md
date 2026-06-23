# ImpriLab 🧪🚀

ImpriLab es una aplicación multiplataforma (Móvil y Escritorio) desarrollada en Flutter orientada a la **gestión integral, cotización y control de stock para impresión 3D**. 

Diseñada específicamente para makers, talleres y emprendimientos de manufactura aditiva (tanto en tecnología FDM como en Resina), ImpriLab permite calcular costos exactos de producción, administrar recursos e inventario en tiempo real y exportar cotizaciones detalladas en formato profesional.

---

## 📱 Plataformas Soportadas

*   **Móvil:** Android & iOS (Persistencia SQLite nativa).
*   **Escritorio:** Windows & macOS (Persistencia SQLite mediante enlace FFI nativo).

---

## ✨ Características Principales

*   **🧮 Cálculo Avanzado de Costos:** Calcula costos reales sumando consumo exacto de material (con soporte para porcentaje de merma), consumo eléctrico (según potencia de máquina y tarifa de luz local), depreciación horaria del equipo y tarifas de mano de obra.
*   **🛢️ Control de Inventario en Tiempo Real:** Gestión de stock para filamentos y resinas. La aplicación deduce y reembolsa de manera inteligente las cantidades consumidas al crear, modificar o eliminar proyectos (pedidos).
*   **⚙️ Soporte Multitecnología (FDM & Resina):** Parámetros específicos para cada tecnología mediante perfiles de laminación (Slicer) dedicados (ej. tiempo de exposición para resina, altura de capa y soportes para FDM).
*   **📁 Gestión de Proyectos (Camas de Impresión Múltiples):** Permite organizar cada trabajo en múltiples camas de impresión independientes, conteniendo una o varias piezas cada una.
*   **📋 Cotizador y Margen Dinámico:** Configuración en tiempo real del margen de ganancia (%) mediante un slider interactivo, con visualización instantánea de costos de fabricación, IVA y precios de venta sugeridos.
*   **📄 Exportación Profesional (PDF & Portapapeles):** Generación directa de reportes y presupuestos en PDF con formato de alta calidad listos para imprimir o enviar, así como resúmenes rápidos de texto para mensajería instantánea.
*   **💾 Persistencia Local Híbrida:** Base de datos relacional SQLite para el almacenamiento estructurado de impresoras, materiales y proyectos, combinada con almacenamiento seguro de preferencias del usuario.

---

## 🛠️ Arquitectura y Estructura del Proyecto

El proyecto sigue una estructura limpia, modular y escalable para facilitar el mantenimiento y la extensibilidad:

```
lib/
├── models/             # Entidades del dominio (Project, PrintBed, Piece, Printer, Material3D, SlicerConfig)
├── screens/            # Vistas y flujos principales de la UI (Dashboard, NewProject, ProjectDetail, etc.)
├── services/           # Servicios externos y lógica de persistencia (DatabaseService, PdfService, LocalizationService)
├── state/              # Manejo de estado centralizado (AppState con lógica de stock e internacionalización)
└── widgets/            # Componentes UI reutilizables y modales extraídos (PrintBedModal, PieceModal, etc.)
test/
└── calculations_test.dart  # Suite completa de pruebas unitarias (cálculos matemáticos, stock e inventario)
```

---

## ⚙️ Tecnologías y Dependencias Core

*   **Framework:** [Flutter](https://flutter.dev/) (SDK >= 3.11.5)
*   **Lenguaje:** [Dart](https://dart.dev/)
*   **Motor de Base de Datos:** `sqflite` (Móvil) & `sqflite_common_ffi` (Desktop)
*   **Reportes y PDF:** `pdf` & `printing`
*   **Acceso Multimedia:** `image_picker`
*   **Internacionalización:** Localización integrada con soporte dinámico para divisas (CLP, MXN, USD, EUR, ARS).

---

## 🚀 Instalación y Configuración Local

### 1. Clonar el repositorio
```bash
git clone https://github.com/jimm-96/ImprimiLab.git
cd ImprimiLab
```

### 2. Configurar dependencias
Instala los paquetes necesarios definidos en el archivo `pubspec.yaml` (garantizando versiones idénticas usando `pubspec.lock`):
```bash
flutter pub get
```

### 3. Ejecutar la Aplicación
Asegúrate de tener un emulador activo o un dispositivo físico conectado:
```bash
flutter run
```

---

## 🧪 Pruebas Unitarias y Análisis Estático

Para garantizar la fiabilidad del software y la precisión matemática del cotizador:

### Ejecutar Suite de Pruebas
Valida los cálculos del costo de fabricación, depreciación horaria, cálculos eléctricos, margen de venta sugerida y flujos de stock en `AppState`:
```bash
flutter test
```

### Ejecutar Análisis Estático (Linter)
Verifica que el código mantenga los estándares de calidad definidos por la comunidad Flutter:
```bash
flutter analyze
```

---

## 🐍 Herramientas Auxiliares de Python (Opcional)

Si utilizas scripts auxiliares de Python en el proyecto (por ejemplo, para integraciones CI/CD o análisis estáticos externos):

1. **Crear Entorno Virtual:**
   ```bash
   python -m venv venv
   ```
2. **Activar Entorno Virtual:**
   * En **Windows (PowerShell):** `.\venv\Scripts\Activate.ps1`
   * En **macOS/Linux:** `source venv/bin/activate`
3. **Instalar Dependencias:**
   ```bash
   pip install -r requirements.txt
   ```

---

## 🗺️ Roadmap de Futuras Mejoras

*   [ ] **Directorio de Clientes:** Vinculación de proyectos con fichas detalladas de clientes y datos de contacto.
*   [ ] **Tablero Kanban:** Seguimiento visual del estado de producción de cada cama de impresión (En cola ➡️ Imprimiendo ➡️ Post-procesado ➡️ Entregado).
*   [ ] **Migración de Estado Avanzada:** Integración de Riverpod para mejorar la escalabilidad y testabilidad en la UI.
