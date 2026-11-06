# ORVEXA Operaciones (app móvil)

App Flutter (Android / iOS) para administrar proyectos de hincado y bobcat, máquinas, operadores y finanzas.
Backend: Supabase, proyecto **Orvexa Projects** (`bvdidntnbimcpozhfkpl`).
Monedas: se cobra al cliente en **US$**; se paga a operadores y ayudantes en **quetzales (Q)**. El tipo de cambio se edita en Finanzas y queda guardado en cada reporte diario.

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

### Paros
En el reporte diario el operador marca si hubo paro o retraso: motivo (lluvia, falla de la máquina, falta de material, atraso del cliente, terreno, sin combustible, otro) y horas perdidas. Si no hubo producción (0 incas) el motivo es obligatorio.
- El admin ve en cada proyecto las horas perdidas por motivo y las horas atribuibles al cliente (respaldo para reclamar tiempo o cobro), y en el Panel el resumen del mes.
- Solo el admin decide si un día sin trabajo se paga (abre el reporte en el proyecto → "Pagar este día").

### Modo sin señal (operador)
- Reportes y mantenimientos se guardan primero en el teléfono y se envían solos cuando vuelve la señal (al recuperar conexión, cada 60 s, o con "Enviar ahora").
- Arriba aparece un aviso: "Sin señal · N guardados en el teléfono".
- Sin señal, la app muestra la última información descargada (proyecto, máquina, meta, historial).
- Cada registro lleva un id generado en el teléfono: si un envío se corta y se reintenta, no se duplica.
- Si el servidor rechaza algo (por ejemplo, corregir un reporte de hace más de 2 días), se marca en rojo con opción de reintentar o descartar.
- Los pendientes quedan guardados por usuario aunque se cierre la app o se cierre sesión.

Cómo se calcula el dinero:
- Ingreso = incas reportadas × precio por inca (o días reportados × tarifa diaria).
- Planilla = por cada día reportado, el pago en quetzales del operador + el del ayudante si estuvo presente. El pago y el tipo de cambio se congelan en el reporte (si cambias la tarifa o el tipo de cambio después, el histórico no cambia). En finanzas se convierte a US$.
- Proyección = meta diaria × días laborales restantes hasta completar las incas, con la planilla de las asignaciones activas, + obligaciones recurrentes + impuesto %.

### Fotos
Reportes diarios, mantenimientos y cargas de combustible aceptan hasta 4 fotos (cámara o galería). Se guardan en el teléfono y se suben al enviar, también sin señal. Se almacenan en Supabase Storage (bucket privado `evidencias`): el operador solo ve las de sus máquinas; el admin, todas.

### Mantenimiento por horómetro
- En cada máquina el admin crea planes: "Aceite de motor cada 250 h", "Engrase cada 50 h"…
- El horómetro se actualiza con el reporte diario ("Horómetro al cerrar"), mantenimientos y cargas de combustible.
- Avisos: amarillo cuando faltan 25 h o menos (o el 10 % del intervalo), rojo cuando ya se pasó. Se ven en la tarjeta del operador, en la máquina y en el Panel.
- Al registrar un mantenimiento del mismo tipo, el contador del plan se reinicia solo.

### Combustible
El operador (o el admin) registra galones, costo en Q, horómetro y foto del ticket. Se ve el gasto por máquina, galones e Q por inca, y entra como costo en Finanzas y en la utilidad de cada proyecto (con el tipo de cambio del día). Si ya registrabas el diésel como gasto fijo en Obligaciones, quita ese gasto para no contarlo dos veces.

### Cierre de planilla
Personal → "Cerrar planilla":
- Crea el periodo (quincena actual/anterior, semana o rango libre).
- Vista previa por persona: días pagados × pago diario, + bonos, − adelantos y descuentos con fecha en el periodo.
- "Cerrar y marcar pagado" congela los montos (cálculo en el servidor). Se puede reabrir para corregir.
- Recibo PDF por persona (compartir por WhatsApp, imprimir). Cada operador ve sus pagos y recibos en la pestaña "Pagos".

### Reporte PDF para el cliente
En el proyecto, ícono PDF → elige fechas → con o sin montos. Incluye producción diaria por máquina, avance total, paros y horas atribuibles al cliente.

### Recordatorios
El operador recibe una notificación a las 5:00 pm en días laborales si no ha registrado su reporte del día. Son notificaciones del propio teléfono (no necesitan internet ni servidor). Avisos push enviados desde el servidor (por ejemplo, al admin) requieren configurar Firebase con tu cuenta.

## Primer uso
1. Abre la app: como no hay administrador, muestra **Crea el administrador**. Esa cuenta queda como admin.
2. Agrega máquinas, crea al personal, crea un proyecto y asígnale máquinas.
3. Comparte el usuario y contraseña con cada operador.

Los usuarios entran con un nombre de usuario (ej. `jperez`). Internamente se guarda como `jperez@orvexa.app`.

**No hay auto-registro.** Solo el administrador crea cuentas (Personal → + Usuario). La base de datos rechaza cualquier intento de registrarse por fuera de la app.

## Compilar

Requisitos: Flutter 3.47+ y Android Studio (Android SDK, compileSdk 37) o Xcode (iOS).

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
- `migrations/0002_fotos_horometro_combustible_planilla.sql`: fotos, planes de mantenimiento, combustible y planilla. **Ya aplicado.**
- `functions/admin-users`: función que crea / edita usuarios (solo admin). **Ya desplegada.**

Seguridad: el operador solo puede ver su asignación, su proyecto y su máquina; no puede ver finanzas, ni cambiar precios ni su pago (el pago del reporte se toma de la asignación en el servidor).
