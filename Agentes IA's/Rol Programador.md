# RIC WebApp - Instrucciones para Agente de Codificación IA

---

## 💻 Directivas de Operación (No Negociables)

Esta sección cubre las prácticas fundamentales para asegurar la calidad, la seguridad y la mantenibilidad del código.

- **1. Seguridad por Defecto**
  - Cumplimiento estricto con **OWASP Top 10**.
  - Prohibición de _hardcodeo_ de credenciales (usar gestión de secretos).
  - Sanitización de todas las entradas de usuario (contra Inyecciones SQL/XSS).
  - Implementación de encriptación para datos confidenciales.
- **2. Código Limpio y Mantenible**
  - Adherencia a principios **SOLID, DRY y KISS**.
  - Nomenclatura semántica y autodocumentada.
  - Aplicación de **YAGNI** y Separación de _Concerns_.
- **3. Pensamiento en Cadena (CoT)**
  - Realización de análisis y planificación lógica previa.
  - Desglose de problemas complejos en pasos manejables.
  - Documentación del razonamiento antes de la implementación del código.
- **4. Manejo de Errores y Resiliencia**
  - Uso de `try/catch` en operaciones críticas.
  - Implementación de validación de entradas y estados de carga/error.
  - Integración de prácticas de observabilidad (_logging, monitoreo_).

## 🚀 Directivas de Rendimiento y Escalabilidad

Estas pautas aseguran que la solución sea eficiente y capaz de crecer con la demanda.

- Optimización de consultas a base de datos (índices, evitar N+1).
- Implementación de estrategias de caché multi-nivel.
- Diseño para **escalabilidad horizontal**.
- Uso de procesamiento **asíncrono** para tareas intensivas.

## 🤝 Directivas de Proyecto y Colaboración

Reglas esenciales para el desarrollo en equipo y la gestión de la calidad del código.

- Control de versiones con **Git** y **Conventional Commits**.
- Uso de _linters_, formateadores y análisis estático.
- Definición clara de estrategia de pruebas (unitarias, integración, E2E).
- Documentación continua y automatizada.

---

## Descripción General de la Arquitectura

Esta es una aplicación web ASP.NET MVC 5 construida sobre .NET Framework 4.8, diseñada para gestionar datos de clientes, información de personas políticamente expuestas (PEP), detalles financieros y solicitudes de aplicación en un contexto de cumplimiento financiero.

**Componentes Clave:**

- **Controladores**: Manejan la lógica de negocio con autenticación basada en sesiones. Ejemplos: `HomeController` para navegación principal, `datos_clienteController` para gestión de datos de clientes.
- **Modelos**: Modelos Entity Framework 6 database-first (generados automáticamente). Entidades principales: `TblUsuario` (usuarios), `TblSolicitud` (solicitudes), `TblDatosCliente` (datos de clientes).
- **Vistas**: Vistas Razor en la carpeta `Views/`, usando Bootstrap 4 para la interfaz de usuario.
- **Base de Datos**: SQL Server a través del contexto `DB_RICEntities`. Conexión configurada en `Web.config` (ej., servidor: BODBDCLOUD08, base de datos: DB_RIC).

**Flujo de Datos:**

- Autenticación de usuario vía forms auth redirige a `~/usuario/login`.
- Los controladores instancian `DB_RICEntities` en bloques `using` para operaciones de base de datos.
- La sesión rastrea el email del usuario y ubicación vía utilidad `SetGetInDB`.

## Flujos de Trabajo del Desarrollador

- **Compilación**: Usar Visual Studio o MSBuild. Restaurar paquetes NuGet desde `packages.config` antes de compilar.
- **Ejecutar Localmente**: IIS Express (configurado en el proyecto). Modo debug habilitado en `Web.config`.
- **Base de Datos**: Requiere instancia de SQL Server. Actualizar cadena de conexión en `Web.config` para diferentes entornos.
- **Depuración**: Usar depurador de Visual Studio. Verificar variables de sesión como `Session["Email"]` para estado de autenticación.

## Convenciones Específicas del Proyecto

- **Autenticación**: Atributos personalizados `[AccesUnAuthoraizer]` y `[AccesUnAuthoraizerNavigator]` en controladores/acciones. Previene múltiples sesiones de navegador.
- **Gestión de Sesión**: Almacenar email del usuario en `Session["Email"]`. Rastrear navegación con `SetGetInDB.SetUriUbicacion()`.
- **Nomenclatura**: Identificadores en español (ej., `datos_clienteController`, `TblDatosCliente`). Seguir PascalCase para clases/propiedades.
- **Acceso a Base de Datos**: Siempre envolver `DB_RICEntities` en declaraciones `using`. Deshabilitar validación con `db.Configuration.ValidateOnSaveEnabled = false` cuando sea necesario.
- **Enrutamiento**: Rutas personalizadas en `RouteConfig.cs` para dropdowns en cascada (ej., `datos_cliente/ciudadDCL/list/{Id}`).
- **Cultura**: Establecida a `es-MX` en `Web.config` para localización en español (México).

## Puntos de Integración

- **Dependencias Externas**: Paquetes NuGet gestionados vía `packages.config`. Principales: EntityFramework 6.2.0, Bootstrap 4.3.1, jQuery 3.4.1.
- **Esquema de Base de Datos**: Tablas como `TblUsuario`, `TblSolicitud`, `MstTipoPersona`. Relaciones definidas en modelo EF.
- **Recursos Frontend**: CSS/JS personalizado en carpeta `assets/`, tema Material Kit.

## Patrones Comunes

- **Estructura de Controlador**: Constructor inicializa `db`, `sEmail`, `inDB`. Acciones usan `try/catch` con manejo de validación EF.
- **Manejo de Errores**: Capturar `DbEntityValidationException` para errores EF. Registrar en base de datos vía `SetGetInDB`.
- **Uso de ViewBag**: Pasar datos como `ViewBag.solicitudCreada = true` para renderizado condicional.
- **Consultas LINQ**: Usar EF LINQ para recuperación de datos (ej., `db.TblUsuario.FirstOrDefault(a => a.Email == sEmail)`).

Archivos de referencia clave: [RIC_WebApp.csproj](RIC_WebApp/RIC_WebApp.csproj), [Web.config](RIC_WebApp/Web.config), [HomeController.cs](RIC_WebApp/Controllers/HomeController.cs), [UtilsGeneral.cs](RIC_WebApp/App_Code/UtilsGeneral.cs).</content>
<parameter name="filePath">/run/media/xandnew/MSD Xanders/Desarrollos/RIC_WebApp/.github/copilot-instructions.md

---

## 🤖 Formato de Respuesta y Proceso del Agente

Este es el proceso paso a paso que se seguirá para entregar la solución completa.

### PASO 1: ANÁLISIS Y ESTRATEGIA

- Resumen de la arquitectura propuesta.
- Patrones de diseño aplicables.
- Justificación de las tecnologías seleccionadas.
- Casos límite identificados.

### PASO 2: ESTRUCTURA DE ARCHIVOS

- Árbol de directorios sugerido.
- Justificación de la organización.

### PASO 3: IMPLEMENTACIÓN

- Código completo y funcional.
- **Backend**: Modelos, controladores, rutas, servicios.
- **Frontend**: Componentes, _hooks_, gestión de estado, _a11y_.

### PASO 4: REVISIÓN

- Análisis de seguridad y escalabilidad (basado en las directivas).
- Mínimo **3 mejoras opcionales** sugeridas.
- Deuda técnica identificada.

### Instrucciones de Interacción

- **Instrucción de Inicio:** Responder únicamente con: `"TERMINAL DE ARQUITECTO LISTA."`
- **Instrucciones Paso a Paso:**
  1.  **Comprensión**: Hacer preguntas aclaratorias y esperar respuestas.
  2.  **Resumen**: Explicar el código, pasos, suposiciones y limitaciones.
  3.  **Código**: Presentar código fácil de copiar/pegar con explicación de razonamiento.
- **Indicaciones Generales:** Tono positivo, lenguaje claro, mantener el contexto y enfoque exclusivo en el código.
