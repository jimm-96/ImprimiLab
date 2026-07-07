# ImpriLab 🧪🚀

**ImpriLab** es un ecosistema multiplataforma (Móvil y Escritorio) desarrollado en Flutter, orientado a la **gestión integral, cotización y control de stock para impresión 3D**.

Diseñado específicamente para makers, talleres y emprendimientos de manufactura aditiva (tecnologías FDM y Resina), ImpriLab permite calcular costos exactos de producción, administrar recursos e inventario en tiempo real, recibir alertas automáticas y exportar cotizaciones en formato profesional.

---

## 📱 Plataformas Soportadas

| Plataforma | Estado | Persistencia |
|------------|--------|--------------|
| Android    | ✅ Activo | SQLite nativo (`sqflite`) |
| iOS        | ✅ Activo | SQLite nativo (`sqflite`) |
| Windows    | ✅ Activo | SQLite FFI (`sqflite_common_ffi`) |
| macOS      | ✅ Activo | SQLite FFI (`sqflite_common_ffi`) |
| Linux      | 🔧 Experimental | SQLite FFI |

---

## ✨ Características Principales

### 🧮 Motor de Cálculo de Costos
Calcula costos reales de producción sumando:
- Consumo exacto de material (filamento en gramos o resina en mL) con soporte de % de merma
- Consumo eléctrico exacto según potencia de la máquina y tarifa kWh regional
- Depreciación horaria del hardware (amortización automática por vida útil)
- Tarifas personalizadas de mano de obra y post-procesado

### 🛢️ Control de Inventario Inteligente
- Gestión de stock para bobinas de filamento y botellas de resina
- **Motor deductivo automático:** descuenta y reembolsa cantidades del inventario en tiempo real según el estado de los pedidos (pendiente → en proceso → terminado)
- Sin cálculos manuales ni actualización de stock manual

### 🔔 Sistema de Notificaciones Locales
- Recordatorios diarios automáticos para verificar el stock de insumos antes de iniciar impresiones largas.
- Alertas programadas exactas de fecha límite para que ningún proyecto cruce la fecha de entrega comprometida con el cliente.
- **Alertas de Stock Bajo:** Avisa en tiempo real si el nivel de filamento o resina cae por debajo del valor límite personalizado configurado por el usuario, indicando con precisión cuál es el material que se está agotando.
- Motor completamente offline: no requiere internet ni servidores externos.

### ⚙️ Soporte Multitecnología (FDM & Resina)
Perfiles de laminación (Slicer) con parámetros específicos:
- **FDM:** altura de capa, % de relleno, velocidad, soportes, tiempo de laminación
- **Resina:** tiempo de exposición de capa normal y primera capa, tipo de exposición

### 📁 Proyectos Comerciales con Múltiples Camas
- Organización por proyectos con múltiples camas de impresión independientes
- Soporte para piezas híbridas (FDM + Resina en un mismo proyecto)
- Agrupación de proyectos en colecciones o carpetas

### 📋 Cotizador Dinámico en Tiempo Real
- Slider interactivo de margen de ganancia (%) con precio de venta actualizado al instante
- Visualización instantánea de: costo de fabricación, IVA y precio de venta sugerido
- Precio de venta final configurable sin necesidad de recalcular

### 📄 Exportación Profesional
- Generación de reportes y presupuestos en **PDF** de alta calidad (listo para imprimir o enviar)
- Exportación de resúmenes rápidos de texto para mensajería instantánea (clipboard)

### 🎓 Tutorial Interactivo Guiado
- Sistema de **Coach Marks** con 5 pasos que resalta cada elemento de la interfaz con un recorte circular/rectangular sobre fondo oscuro
- Se activa automáticamente la primera vez que se entra al Dashboard
- Puede relanzarse en cualquier momento desde el **menú ☰ → Ver tutorial**
- Burbujas de texto con diseño premium: ícono, número de paso, descripción y botón de acción
- Botón "OMITIR" disponible en todo momento para usuarios avanzados

### 🎨 Personalización Visual Completa
- **6 paletas de color:** Cyan Tech, Esmeralda, Violeta, Ámbar, Rosa Neon, Azul Cielo
- **Modo Oscuro / Claro** con toggle rápido desde el AppBar
- Tema persistido entre sesiones con `SharedPreferences`

### 🌍 Internacionalización
- Soporte para **Español** e **Inglés** con cambio dinámico en tiempo de ejecución
- Divisas regionales: CLP, ARS, MXN, USD, EUR y código personalizado
- Preconfiguración de tasas de IVA y kWh por país (Chile, Argentina, España, México, EE.UU.)

---

## 🗂️ Flujo de Trabajo de la App

```
1. Splash Screen          Siempre al iniciar — logo animado con fade-in
         ↓
2. Intro Slides (×3)      Solo primer uso — presentación del ecosistema
   • Slide 1: ¿Qué es ImpriLab?
   • Slide 2: ¿Cómo se usa? (flujo de 3 pasos)
   • Slide 3: Inventario y Alertas automáticas
         ↓
3. Onboarding             Configuración inicial: país, moneda, IVA, tarifa kWh
         ↓
4. Dashboard              Hub central de proyectos con filtros por colección
   ├── Impresoras         Registro de equipamiento (FDM / Resina)
   ├── Materiales         Inventario de filamentos y resinas
   └── Proyectos          Creación, edición y exportación de pedidos
```

---

## 🛠️ Arquitectura y Estructura del Proyecto

```
lib/
├── main.dart                       # Entry point — MaterialApp con ThemeState reactivo
├── models/
│   ├── material3d.dart             # Entidad: bobina de filamento o botella de resina
│   ├── piece.dart                  # Entidad: pieza individual dentro de una cama
│   ├── print_bed.dart              # Entidad: cama de impresión con lista de piezas
│   ├── printer.dart                # Entidad: impresora (FDM o Resina) con potencia y vida útil
│   ├── project.dart                # Entidad raíz: proyecto comercial + lógica de cálculo de costos
│   └── slicer_config.dart          # Entidad: perfil de laminación con parámetros por tecnología
├── screens/
│   ├── splash_screen.dart          # Pantalla de carga animada (siempre se muestra al iniciar)
│   ├── intro_slides_screen.dart    # 3 slides de presentación (solo primer uso)
│   ├── onboarding_screen.dart      # Configuración inicial regional (país, moneda, IVA, kWh)
│   ├── dashboard_screen.dart       # Hub principal con lista de proyectos y filtros
│   ├── new_project_screen.dart     # Creación de proyectos con camas y piezas
│   ├── project_detail_screen.dart  # Detalle, edición y exportación de proyectos
│   ├── printer_list_screen.dart    # Gestión del inventario de impresoras
│   ├── material_list_screen.dart   # Gestión del inventario de materiales
│   └── notification_settings_screen.dart  # Configuración de recordatorios y alertas
├── services/
│   ├── database_service.dart       # CRUD SQLite para impresoras, materiales y proyectos
│   ├── localization_service.dart   # Traducción de claves y formato de divisas
│   ├── notification_service.dart   # Motor de notificaciones locales y recurrentes
│   └── pdf_service.dart            # Generación de reportes PDF profesionales
├── state/
│   ├── app_state.dart              # Estado global: inventario, proyectos, settings + lógica de stock
│   └── theme_state.dart            # Estado del tema: paleta de color + modo claro/oscuro
└── widgets/
    ├── piece_modal.dart            # Modal de creación/edición de piezas individuales
    ├── print_bed_modal.dart        # Modal de creación/edición de camas de impresión
    └── theme_picker_button.dart    # Botón del AppBar + modal selector de paleta y modo visual

test/
├── app_state_test.dart             # Tests de lógica de estado (deducción/reembolso de stock)
├── calculations_test.dart          # Tests de precisión matemática del motor de costos
├── localization_service_test.dart  # Tests de traducciones y formato de divisas
└── models_serialization_test.dart  # Tests de serialización/deserialización JSON de entidades
```

---

## ⚙️ Tecnologías y Dependencias

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `sqflite` | ^2.3.3 | Base de datos relacional SQLite (móvil) |
| `sqflite_common_ffi` | ^2.3.2 | SQLite via FFI (escritorio) |
| `shared_preferences` | ^2.5.5 | Persistencia de preferencias y tema |
| `flutter_local_notifications` | ^22.0.1 | Notificaciones locales y recurrentes |
| `timezone` + `flutter_timezone` | ^0.11 / ^5.1 | Zonas horarias para alertas exactas |
| `pdf` + `printing` | ^3.10 / ^5.11 | Generación y visualización de PDFs |
| `image_picker` | ^1.2.2 | Selección de imágenes |
| `path_provider` + `path` | ^2.1 / ^1.9 | Acceso al sistema de archivos |
| `intl` | ^0.19.0 | Internacionalización y formato de fechas |

---

## 🚀 Instalación y Configuración Local

### 1. Clonar el repositorio
```bash
git clone https://github.com/jimm-96/ImprimiLab.git
cd ImprimiLab
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Ejecutar la aplicación
```bash
# Asegúrate de tener un emulador activo o dispositivo conectado
flutter run

# Para escritorio Windows:
flutter run -d windows
```

---

## 🧪 Pruebas y Análisis

### Suite de pruebas unitarias
Valida cálculos matemáticos, serialización de modelos, lógica de stock e internacionalización:
```bash
flutter test
```

### Análisis estático
```bash
flutter analyze
```

### Tests de integración
```bash
flutter test integration_test/
```

---

## 🐍 Herramientas Auxiliares de Python (Opcional)

Para scripts auxiliares de CI/CD o análisis externos:

```bash
# Crear y activar entorno virtual
python -m venv venv

# Windows (PowerShell)
.\venv\Scripts\Activate.ps1

# macOS / Linux
source venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt
```

---

## 🗺️ Roadmap

### ✅ Implementado
- [x] Motor de cálculo de costos FDM y Resina
- [x] Control de inventario deductivo automático
- [x] Notificaciones locales con recordatorios y alertas de deadline
- [x] Exportación PDF profesional y texto para mensajería
- [x] Internacionalización (ES / EN) con divisas regionales
- [x] Splash screen animado
- [x] Slides de presentación (Onboarding visual)
- [x] Selector de paleta de color y modo claro/oscuro persistido
- [x] Tutorial interactivo guiado con Coach Marks (5 pasos, relanzable desde el menú)
- [x] Perfil de usuario y taller local (registro, inicio de sesión y campos personalizados offline)

### 🔮 Próximamente
- [ ] **Directorio de Clientes:** Fichas detalladas con historial de proyectos y datos de contacto
- [ ] **Tablero Kanban:** Seguimiento visual del estado de producción (En cola → Imprimiendo → Post-procesado → Entregado)
- [ ] **Estadísticas y Reportes:** Dashboard de rentabilidad mensual, materiales más usados y proyectos por estado
- [ ] **Respaldo en la Nube:** Sincronización opcional de datos entre dispositivos
