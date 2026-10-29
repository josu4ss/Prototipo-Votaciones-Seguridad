# Votación Segura — aplicación móvil + API

**Prototipo universitario de Ingeniería de Seguridad del Software** para una elección interna de una asociación. Se basa en el escenario de 12.000 socios, hasta 5.000 conexiones simultáneas y jornada de ocho horas; **esos volúmenes no han sido validados** y el código no está destinado a elecciones reales.

**Tecnologías:** Flutter/Dart (Android Studio), NestJS/TypeScript, PostgreSQL, Docker Compose.

## 1. Estructura del proyecto

```text
VotacionSegura_AndroidStudio/
├── README.md                       ← Esta guía
├── docker-compose.yml              ← Base de datos PostgreSQL local
├── configurar_flutter_windows.ps1  ← Genera el proyecto Flutter nativo
├── flutter_codigo/                 ← Código original Flutter para el generador
│   ├── pubspec.yaml
│   ├── android_debug_AndroidManifest.xml
│   └── lib/
│       ├── main.dart
│       ├── core/
│       │   ├── api_client.dart      ← REST + gestión de errores
│       │   └── session_store.dart   ← Token guardado en almacén seguro
│       ├── models/election.dart
│       └── screens/
│           ├── login_screen.dart
│           ├── election_screen.dart
│           ├── receipt_screen.dart
│           └── results_screen.dart
├── mobile_flutter/                 ← Se crea con configurar_flutter_windows.ps1
├── backend/
│   ├── .env.example
│   ├── package.json
│   ├── db/001_schema.sql
│   ├── src/
│   │   ├── main.ts
│   │   ├── app.module.ts
│   │   ├── auth/                   ← Login, JWT y guard
│   │   ├── database/               ← Pool + transacciones
│   │   ├── election/               ← Consultar, cerrar y resultados
│   │   ├── votes/                  ← Voto único + comprobante
│   │   └── scripts/seed.ts          ← Datos ficticios (BORRA VOTOS)
│   └── tests/verify-api.mjs        ← Pruebas integrales
├── diagramas/                      ← PNG + fuentes Graphviz .dot
└── SEGURIDAD_Y_PRUEBAS.md          ← Amenazas, restricciones y verificaciones
```

**Arquitectura:** cliente Flutter → JSON REST → controladores NestJS → servicios de dominio → PostgreSQL. La autorización y la regla de voto único se ejecutan siempre en el servidor, nunca en el cliente. Los módulos NestJS están agrupados por responsabilidad; la aplicación Flutter separa interfaz, modelos y servicios de API.

![Arquitectura](diagramas/01_arquitectura.png)

![Flujo de voto](diagramas/02_flujo_voto.png)

![Modelo de datos](diagramas/03_modelo_datos.png)

## 2. Requisitos previos (Windows)

- **Flutter SDK** con Android Studio y plugins Flutter/Dart. Ejecutar `flutter doctor` y corregir advertencias esenciales.
- **Node.js 22 LTS reciente o 24 LTS** y npm. NestJS requiere un Node compatible; para evitar conflictos con CLI, utilizar una versión actualizada.
- **Docker Desktop** funcionando con Docker Compose.
- **Android Emulator** iniciado desde Android Studio (Tools → Device Manager).

**Importante:** instalar solamente el plugin Flutter en Android Studio no instala el Flutter SDK. Consulta la guía oficial de Flutter: https://docs.flutter.dev/platform-integration/android/setup

### Paso A. Iniciar PostgreSQL

Abre PowerShell dentro de la carpeta raíz del proyecto:

```powershell
docker compose up -d
docker compose ps
```

El contenedor inicializa las tablas automáticamente mediante `backend/db/001_schema.sql`. PostgreSQL se publica **solo en 127.0.0.1:5433**.

### Paso B. Preparar y ejecutar NestJS

En **otra terminal PowerShell**:

```powershell
cd backend
Copy-Item .env.example .env
npm install
npm run seed
npm run start:dev
```

La primera vez `npm install` descarga paquetes desde npm. Espera a que aparezca el mensaje de la API. Prueba en navegador:

`http://localhost:3000/api/health`

Respuesta esperada: `{"status":"ok"}`.

**ATENCIÓN:** `npm run seed` es solo de desarrollo y **elimina los votos y usuarios anteriores** para cargar cuentas de prueba. Nunca ejecutarlo con datos reales. No publicar `.env`.

### Paso C. Generar la aplicación Flutter para Android Studio

En la **carpeta raíz** del proyecto, ejecuta:

```powershell
.\configurar_flutter_windows.ps1
```

El script usa `flutter create`, integra todo el código Dart de `flutter_codigo`, prepara el manifiesto Android para el **tráfico HTTP local exclusivamente en modo debug** y ejecuta `flutter pub get`.

Si PowerShell bloquea scripts por políticas de tu equipo, hazlo manualmente (desde la raíz):

```powershell
flutter create --project-name votacion_segura mobile_flutter
Copy-Item 'flutter_codigo\lib\*' 'mobile_flutter\lib' -Recurse -Force
Copy-Item 'flutter_codigo\pubspec.yaml' 'mobile_flutter\pubspec.yaml' -Force
Copy-Item 'flutter_codigo\android_debug_AndroidManifest.xml' 'mobile_flutter\android\app\src\debug\AndroidManifest.xml' -Force
```

En ese caso agrega esta línea **dentro del manifest principal, como hija de `<manifest>` y antes de `<application>`**, si no existe:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

El archivo está en `mobile_flutter/android/app/src/main/AndroidManifest.xml`. Luego:

```powershell
cd mobile_flutter
flutter pub get
```

### Paso D. Abrir en Android Studio y ejecutar

1. Android Studio → **Open** → carpeta `mobile_flutter`.
2. Abre **Tools → Device Manager** e inicia un emulador Android.
3. Comprueba que la API NestJS siga corriendo.
4. Pulsa **Run** (triángulo verde) o en una terminal dentro de `mobile_flutter` ejecuta `flutter run`.
5. En el emulador la API se consulta en `http://10.0.2.2:3000/api`: **10.0.2.2 es la máquina Windows anfitriona**, no la IP del contenedor Docker.

**Teléfono físico:** usa la IP local del PC, en una red de laboratorio confiable. Primero configura `BIND_HOST=0.0.0.0` **solo para desarrollo** en `backend/.env`, reinicia la API y ejecuta:

```powershell
flutter run --dart-define=API_BASE_URL=http://IP_DE_TU_PC:3000/api
```

Cambia `IP_DE_TU_PC` por tu IP real; permite el acceso en el firewall según corresponda. **No envíes credenciales reales por HTTP.** En producción es obligatorio HTTPS, sin excepciones cleartext.

## 3. Credenciales para probar el sistema

Todos son **usuarios ficticios** cargados por el seed local:

| Perfil | Correo | Contraseña |
|---|---|---|
| Socio 1 | `socio1@example.com` | `DemoVoto#2026!` |
| Socio 2 | `socio2@example.com` | `DemoVoto#2026!` |
| Administrador | `admin@example.com` | `DemoVoto#2026!` |

- Socio 1 inicia sesión y elige una de las tres listas.
- Confirma el voto: se registra y recibe comprobante **sin revelar la candidatura**.
- Si intenta votar otra vez, el servidor rechaza con HTTP 409 (o interfaz bloqueada previamente).
- Si intenta consultar resultados durante la jornada, recibe HTTP 403.
- Administrador inicia sesión y pulsa **Cerrar elección**. Tras el cierre, cualquier cuenta autenticada puede consultar el conteo.
- Si necesitas repetir toda la práctica desde cero, vuelve a ejecutar `npm run seed` en un entorno exclusivamente de pruebas.

## 4. Endpoints REST implementados

Todos empiezan por `/api`. Excepto `login` y `health`, exigen `Authorization: Bearer <JWT>`.

| Método | Ruta | Permiso | Respuesta / regla |
|---|---|---|---|
| GET | `/health` | Público | Estado de API |
| POST | `/auth/login` | Público (limitado) | JWT, rol y nombre |
| GET | `/election` | Autenticado | Candidaturas, estado y participación personal |
| POST | `/votes` | Solo socio | Un voto; `{ "candidateId": "UUID" }` |
| GET | `/votes/me` | Autenticado | Comprobante de participación, sin selección |
| GET | `/election/results` | Autenticado | Votos por lista **solo después del cierre** |
| POST | `/election/close` | Solo ADMIN | Cierra y registra auditoría |

Ver `SEGURIDAD_Y_PRUEBAS.md` para los casos de prueba y su fundamento.

## 5. Cómo verificar automáticamente el backend

Con API iniciada y una base recién cargada con `npm run seed`:

```powershell
cd backend
npm run test:api
```

Este script verifica login, voto duplicado, candidatura inválida, resultados antes del cierre, rol de administrador, cierre y resultados posteriores. **Modifica el estado electoral de la demo**, por lo que requiere reiniciar el seed si se desea volver a votar.

## 6. Correspondencia con los requisitos del enunciado

| Req. | Propuesta del prototipo |
|---|---|
| V01 | Consulta candidaturas, emisión, resultados tras cierre. Padrón público **no implementado** para evitar exposición. |
| V02 | Nombre, número de socio, correo, habilitación. **Cédula no incluida** por minimización provisional. |
| V03 | No guarda domicilio, ingreso, religión, empleador ni preferencias políticas. |
| V04 | No guarda datos médicos ni biometría facial. |
| V05 | Login con contraseña Argon2id + JWT. **MFA por correo y recuperación segura pendientes**. |
| V06 | Registros de participación separados de papeletas; **no garantiza anonimato E2E**. |
| V07 | Comprobante acredita participación, sin indicar candidato. |
| V08 | Admin no dispone de función para alterar papeletas. |
| V09 | Resultados parciales bloqueados; se muestran tras cierre. |
| V10 | Registra login, participación y cierre; sin endpoint de borrado. |
| V11 | Unicidad por `(election_id,user_id)` en BD, **no por IP**. |
| V12 | Una BD Docker local es suficiente **solo para demo**, no para 5.000 concurrentes. |
| V13 | Backups, replicación, HA y plan de recuperación **pendientes**. |
| V14 | No publica números de cédula ni vincula formalmente identidad a papeleta. Retención **pendiente de política institucional**. |

## 7. Limitaciones críticas para una elección real

**NO desplegar este MVP para votos de personas reales**. La separación en dos tablas **no prueba secreto ni verificabilidad extremo a extremo**: un operador de infraestructura con privilegios elevados, datos auxiliares y correlaciones puede reconstruir información; y la app móvil/servidor pueden ser comprometidos. Hacen falta revisión criptográfica especializada, elección de un protocolo verificable, gestión independiente de claves, multifactor, protección contra ataques DDoS, segmentación/roles separados de DB, auditoría externa, disponibilidad demostrada, accesibilidad, retención y respuesta a incidentes.

Tampoco se ha demostrado capacidad para 5.000 conexiones simultáneas. Realiza pruebas de carga, modela picos de inicio y cierre, y mide p95/p99, throughput, errores, bloqueos de transacciones y recuperación.

**Fuentes oficiales:**
- Flutter y Android Studio: https://docs.flutter.dev/platform-integration/android/setup
- NestJS: https://docs.nestjs.com/first-steps
- Seguridad de apps móviles OWASP MASVS: https://mas.owasp.org/MASVS/
- OWASP MASVS-AUTH: https://mas.owasp.org/MASVS/07-MASVS-AUTH/
- NestJS rate limiting: https://docs.nestjs.com/security/rate-limiting
- PostgreSQL integridad/constraints: https://www.postgresql.org/docs/current/ddl-constraints.html

Fecha de consulta de las fuentes tecnológicas: **29 de octubre de 2026**.
