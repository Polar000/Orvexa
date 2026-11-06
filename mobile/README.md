# ORVEXA Operaciones (app móvil)

App Flutter (Android / iOS) para administrar proyectos de hincado y bobcat, máquinas, operadores y finanzas.
Backend: Supabase, proyecto **Orvexa Projects** (`bvdidntnbimcpozhfkpl`). Moneda: US$.

## Roles

**Administrador**
- **Panel**: incas de hoy vs meta, incas e ingresos del mes, utilidad, alertas (máquinas sin reporte hoy, máquinas en mantenimiento, obligaciones vencidas), gráfico de producción de 14 días, ingresos vs costos (6 meses reales + 3 proyectados), proyección por proyecto.
- **Proyectos**: crear hincado / bobcat / otro. Incas totales, meta diaria, precio por inca (o tarifa por día), fecha de inicio y días laborales por semana → calcula días necesarios, fecha de fin y valor del contrato. Detalle con avance, ritmo real, fin estimado, dinero y reportes.
- **Asignaciones** (dentro del proyecto): máquina + operador + ayudante (solo hincadoras) + pago diario de cada uno + meta diaria de la máquina.
- **Máquinas**: tipo, estado, pago diario sugerido al operador y ayudante, horómetro, historial de mantenimiento.
- **Personal**: crear operadores, ayudantes y admins (usuario + contraseña), desactivar, cambiar contraseña, planilla del mes.
- **Finanzas**: estado del mes (ingresos, planilla, mantenimiento, gastos fijos, impuestos, utilidad), proyección de 6 meses, obligaciones (renta, seguros, combustible, impuestos… únicas o recurrentes) con "marcar pagado", % de impuesto sobre ingresos y % de carga patronal.

**Operador**
- Ve su proyecto, máquina, ayudante, meta diaria y su pago.
- Registra las incas del día (puede corregir hasta 2 días atrás), horas, si vino el ayudante y observaciones.
- Registra mantenimiento (tipo, descripción, horómetro, costo).
- Historial de sus reportes.

**Ayudante**: ve su asignación y reportes (no registra producción).

Cómo se calcula el dinero:
- Ingreso = incas reportadas × precio por inca (o días reportados × tarifa diaria).
- Planilla = por cada día reportado, el pago del operador + el del ayudante si estuvo presente. El pago se congela en el reporte (si cambias la tarifa después, el histórico no cambia).
- Proyección = meta diaria × días laborales restantes hasta completar las incas, con la planilla de las asignaciones activas, + obligaciones recurrentes + impuesto %.

## Primer uso
1. Abre la app: como no hay administrador, muestra **Crea el administrador**. Esa cuenta queda como admin.
2. Agrega máquinas, crea al personal, crea un proyecto y asígnale máquinas.
3. Comparte el usuario y contraseña con cada operador.

Los usuarios entran con un nombre de usuario (ej. `jperez`). Internamente se guarda como `jperez@orvexa.app`.

## Compilar

Requisitos: Flutter 3.47+ y Android Studio (Android SDK) o Xcode (iOS).

```bash
cd mobile
flutter pub get
flutter run                       # en un teléfono conectado o emulador
flutter build apk --release       # APK para instalar en Android: build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle           # para Google Play
flutter build ipa                 # iOS (en Mac con Xcode)
```

Antes de publicar en Play Store cambia el `applicationId` (`com.orvexa.orvexa_app`) si quieres otro, y configura la firma de release.

## Pruebas
```bash
flutter test                                   # cálculos + pantallas
flutter test --update-goldens test/screens_test.dart   # regenera capturas en test/goldens/
```

## Backend (carpeta `../supabase`)
- `migrations/0001_orvexa_operaciones.sql`: tablas, reglas de seguridad por rol (RLS) y disparadores. **Ya aplicado** en el proyecto Orvexa Projects.
- `functions/admin-users`: función que crea / edita usuarios (solo admin). **Ya desplegada.**

Seguridad: el operador solo puede ver su asignación, su proyecto y su máquina; no puede ver finanzas, ni cambiar precios ni su pago (el pago del reporte se toma de la asignación en el servidor).
