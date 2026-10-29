# Controles, amenazas y verificaciones del prototipo

## Modelo de amenaza

**Activos:** identidad del socio, habilitación, voto, candidaturas, claves/tokens, proceso de conteo, registro de auditoría y disponibilidad del servicio. **Atacantes posibles:** socio malicioso, atacante de credenciales, cuenta admin comprometida, operador de infraestructura, malware del dispositivo y atacante DoS. **Confianza:** Flutter es cliente no confiable; servidor autoriza; BD impone reglas; operador/DBA sigue siendo riesgo de confianza.

| ID | Amenaza/vulnerabilidad | Consecuencia | Control implementado | Prueba sugerida | Pendiente |
|---|---|---|---|---|---|
| R01 | Suplantación por contraseña robada | Voto no autorizado | Argon2id, JWT firmado, validación de habilitación | Login con clave incorrecta → 401 | MFA, alertas de acceso |
| R02 | Fuerza bruta de login | Toma de cuentas | 5 intentos/min por IP | 6 intentos → 429 | Límite por cuenta y control distribuido |
| R03 | Modificar `candidateId` / SQLi | Registrar candidatura inválida | UUID validado + SQL parametrizado + FK compuesta | UUID inventado → 404, UUID malformado → 400 | DAST/SAST |
| R04 | Votar dos veces (incluida carrera) | Integridad comprometida | UNIQUE + bloqueo + transacción | Dos POST → uno 201 y otro 409 | Pruebas de alta concurrencia |
| R05 | Usuario no habilitado | Voto indebido | DB enabled + validación JWT + voto | `enabled=false` → 401/403 | Control de padrón actualizado |
| R06 | Admin cambia selección | Integridad comprometida | Sin endpoint para editar `ballots`; insert-only app | POST sin ruta → 404 | Roles DB separados, control de cambios |
| R07 | Ver resultados antes del cierre | Coacción / influencia | Endpoint responde 403 hasta cierre | GET mientras abierta → 403 | Verificación auditada de publicación |
| R08 | Relación socio-selección por misma tabla | Pérdida del secreto | `ballots` no tiene `user_id` ni comprobante | Inspección esquema | Criptografía E2E, mezcla, revisión de metadatos |
| R09 | Borrado de eventos | Encubrimiento | Trigger bloquea UPDATE/DELETE de auditoría | UPDATE → error | SIEM externo, almacenamiento WORM |
| R10 | Interceptar sesión HTTP | Robo token/credenciales | Secure Storage (en dispositivo) | Revisar tráfico | HTTPS obligatorio fuera de demo |
| R11 | DoS o caída de servidor | Exclusión de electores | Rate limit básico | Carga controlada | CDN/WAF/HA, ensayos 5.000 concurrentes |
| R12 | Dependencia vulnerable / CVE | RCE o fuga | Inventario npm / pub | `npm audit` / `flutter pub outdated` | SBOM, gestión CVE, KEV, parcheo |
| R13 | Eliminación/alteración de BD por operador | Fraude, pérdida de votos | No resuelto por la aplicación | Auditoría independiente | Roles DB de mínimos privilegios, cifrado, E2E |
| R14 | Error humano/caída de BD | Pérdida de participación | Transacción ACID | Simular fallo en operación de prueba | Backups/PITR, replicación y restauración validada |

## CWE y CVE — clasificación adecuada

- **CWE-287**: autenticación incorrecta (riesgo potencial si se debilita el login).
- **CWE-862**: falta de autorización (si la API permitiera cerrar sin rol ADMIN).
- **CWE-89**: inyección SQL (el ejemplo usa sentencias parametrizadas).
- **CWE-362**: condición de carrera (evitada para voto duplicado mediante transacciones/restricción UNIQUE en una base única).
- **CWE-200**: exposición de información sensible (por divulgar voto/identidad).

**CVE no es CWE**: una CWE identifica una clase de debilidad, mientras un CVE identifica una vulnerabilidad concreta en un componente específico y versión. Sin inventario de versiones instaladas **no es válido atribuir un CVE concreto a este proyecto**. Analiza dependencias reales con:

```powershell
cd backend
npm audit
npm outdated
cd ..\mobile_flutter
flutter pub outdated
flutter pub deps
```

Luego valida cada alerta con el fabricante, https://www.cve.org, https://nvd.nist.gov y https://www.cisa.gov/known-exploited-vulnerabilities-catalog. La existencia de una alerta no demuestra explotación; prioriza exposición, versión afectada, CVSS y evidencia de explotación real.

## Pruebas manuales rápidas con Postman

1. `POST http://localhost:3000/api/auth/login`, Body JSON:

```json
{"email":"socio1@example.com","password":"DemoVoto#2026!"}
```

2. Copia el campo `accessToken` y configúralo como **Bearer Token** en Postman. No pegues tokens reales en capturas académicas.
3. `GET /api/election` y copia un `candidates[0].id`.
4. `POST /api/votes`, Body `{"candidateId":"UUID_DEL_CANDIDATO"}`. Debe devolver **201** y comprobante.
5. Repite el mismo POST: **409 Conflict**.
6. Antes del cierre, `GET /api/election/results`: **403 Forbidden**.
7. Inicia sesión con admin y `POST /api/election/close`: **201**.
8. `GET /api/election/results`: **200** y votos por candidatura.

**Concurrencia:** escribe un test que haga dos solicitudes POST simultáneas con el mismo token; la BD debe aceptar una sola. `npm run test:api` cubre la repetición secuencial; aún falta una prueba de carrera automatizada con carga.

## Reglas de privacidad

- No almacenar domicilio, empleador, ingresos, religión, diagnósticos ni foto facial para este escenario sin evaluación jurídica y necesidad demostrada.
- El recibo no puede mostrar selección.
- No mostrar resultados parciales.
- El padrón y el tratamiento de cédulas requieren revisión de finalidad, proporcionalidad, base jurídica y retención según la Ley Orgánica de Protección de Datos Personales de Ecuador y normas pertinentes a la asociación.
- No prometer secreto perfecto: el prototipo **carece de diseño criptográfico electoral verificable**.

## Reglas pendientes antes de pilotaje real

1. Autenticación multifactor sólida, recuperación de cuentas segura y manejo de sesiones revocables.
2. HTTPS con configuración comprobada, certificate pinning si procede y seguridad perimetral.
3. Verificación criptográfica extremo a extremo, mecanismo anti-coacción definido y auditoría externa del protocolo.
4. Roles de BD independientes, secretos gestionados fuera del código y auditoría WORM externa.
5. Accesibilidad, pruebas sobre dispositivos comprometidos, pruebas de carga y plan de continuidad.
6. Consentimiento/transparencia y evaluación de impacto cuando corresponda.

**Referencias principales:** OWASP MASVS (https://mas.owasp.org/MASVS/), OWASP ASVS (https://owasp.org/www-project-application-security-verification-standard/), MITRE CWE (https://cwe.mitre.org/), CVE Program (https://www.cve.org/), CISA KEV (https://www.cisa.gov/known-exploited-vulnerabilities-catalog), PostgreSQL docs (https://www.postgresql.org/docs/current/). Consulta: 29-10-2026.
