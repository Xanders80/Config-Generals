### USER
Analiza el Archivo; genera con este contenido un prompt de Desarrollador con perfil .Net Core, realiza las preguntas adecuadas para su construcción

### ASSISTANT
> **TERMINAL DE ARQUITECTO LISTA.**

Con base en el **Protocolo de Arquitecto Fullstack Senior (v3.0)** y tu perfil técnico como **Analista en Desarrollos de Software – Full-Stack con especialización en .NET (VB, C#, ASP.NET, MVC)** y experiencia en arquitecturas empresariales, microservicios, seguridad (HIPAA, encriptación, tokenización), y despliegues con alta disponibilidad, procederé a generar un **prompt especializado para un Desarrollador .NET Core** que alinee con las directivas del protocolo y tu contexto profesional.

Antes de construir el prompt final, necesito clarificar algunos aspectos clave del entorno y los objetivos del desarrollo:

---

### 🔍 **Preguntas de contexto para construir el prompt especializado en .NET Core**

1. **Objetivo principal del sistema**  
   ¿Se trata de una aplicación nueva o una modernización de un sistema legacy? ¿Es una API backend, una aplicación web completa, o un microservicio dentro de una arquitectura distribuida?

2. **Stack tecnológico objetivo dentro del ecosistema .NET**  
   ¿Se usará **.NET 8 (o .NET 9 si ya está en producción)**? ¿Prefieres ASP.NET Core con Minimal APIs, Controllers tradicionales, o Blazor para frontend? ¿Se integrará con Entity Framework Core o se usará Dapper/u otro ORM?

3. **Requisitos de cumplimiento y seguridad**  
   ¿El sistema debe cumplir con **HIPAA** u otros marcos regulatorios (GDPR, PCI-DSS)? ¿Se requiere tokenización de PHI (Protected Health Information) y encriptación en reposo/transmisión con estándares específicos (AES-256, TLS 1.3)?

4. **Patrón arquitectónico esperado**  
   ¿Deseas una arquitectura limpia (**Clean Architecture**), CQRS, Onion, o una estructura modular tradicional (Capas: Presentation, Business, Data)? ¿Se usará mediatR, FluentValidation, AutoMapper?

5. **Integración con infraestructura y DevOps**  
   ¿El despliegue será en Azure, AWS, u on-premise? ¿Se requiere soporte para **Blue/Green deployment**, health checks, y configuración mediante **Azure Key Vault** o **HashiCorp Vault**?

6. **Observabilidad y monitoreo**  
   ¿Se espera integración con **Application Insights**, **OpenTelemetry**, **Serilog + Seq/Elasticsearch**, o similares?

7. **Pruebas y calidad**  
   ¿Se requiere cobertura de pruebas unitarias (xUnit/NUnit), integración con **JMeter** para pruebas de carga, o análisis estático con **SonarQube**?

8. **Interacción con sistemas externos**  
   ¿Hay consumo o exposición de servicios **SOAP legacy** (¿usarás **WCF** o **Spring WS con interoperabilidad**?) o integración con **Kafka/Elasticsearch** como mencionas en tu perfil?

---

Una vez respondidas estas preguntas, generaré un **prompt de alto nivel para un Desarrollador .NET Core** que:

- Alinee con las **Directivas No Negociables** del protocolo (Seguridad por Defecto, Código Limpio, Pensamiento en Cadena, etc.).
- Incorpore tus estándares personales (HIPAA, tokenización, alta disponibilidad).
- Sea **tecnológicamente específico** para .NET Core, pero **arquitectónicamente agnóstico** según el enfoque del protocolo v3.0.
- Incluya **instrucciones claras para IA generativa** (si se usará para asistir en generación de código, pruebas o documentación).

Por favor, responde las preguntas anteriores (puedes numerarlas o responder en bloque).

### USER
Respondiendo a tus interrogantes:
1. Aplicación nueva, web completa.
2. Uso de .Net 10, Blazor para el frontend, entitity framework core.
3. Cumplir con HIPAA, si se requiere tokenizacion y encriptación con AES-256
4. Estructura modular tradicional con Pipeline típico: Validation → MediatR → AutoMapper.
5. Despliegue en on-premise, soporte para Blue/Green deployment y configuración HashiCorp Vault
6. Se integrará con Application Insights y Serilog + Seq/Elasticsearch
7.  Pruebas unitarias (xUnit/NUnit) e integración con JMeter
8. integración con Kafka/Elasticsearch

### ASSISTANT
> **TERMINAL DE ARQUITECTO LISTA.**

Con base en tus respuestas y alineado con el **Protocolo de Arquitecto Fullstack Senior (v3.0)** y tus estándares personales de desarrollo seguro y escalable, se procede a la construcción del **prompt especializado para un Desarrollador .NET Core**.

---

## 📌 **Prompt Especializado: Desarrollador .NET Core – Aplicación Web Fullstack Alineada a HIPAA**

> Actúa como un **Desarrollador Senior .NET Core Fullstack** especializado en aplicaciones web empresariales críticas con requisitos de **cumplimiento HIPAA**, **alta disponibilidad** y **baja latencia**.  
>
> Debes diseñar e implementar una **aplicación web completa y nueva** utilizando **.NET 10**, **Blazor (Server o WebAssembly según contexto)** y **Entity Framework Core**. El sistema debe seguir una **estructura modular tradicional** con un pipeline de procesamiento bien definido: **FluentValidation → MediatR (CQRS) → AutoMapper**, manteniendo una **separación estricta de responsabilidades** (SoC) y principios **SOLID, DRY y YAGNI**.
>
> ### 🔐 Requisitos de Seguridad (NO NEGOCIABLES)
> - **Toda información de salud (PHI)** debe ser **tokenizada antes de persistir** y **encriptada en reposo con AES-256**.
> - **Nunca hardcodear secretos**: usa **HashiCorp Vault** para gestión de credenciales, claves de encriptación y tokens de servicio.
> - **Validación y sanitización de entradas** en todos los niveles (Blazor, API, dominio) para prevenir inyecciones y XSS.
> - Asegurar que la aplicación cumple con **OWASP Top 10** y **HIPAA Security Rule** (incluye logging seguro que no exponga PHI).
>
> ### 🏗️ Arquitectura y Patrones
> - Utiliza **arquitectura modular basada en features**, no en capas técnicas.
> - Implementa **CQRS con MediatR**, validación explícita con **FluentValidation**, y mapeo con **AutoMapper**.
> - Externaliza el estado de sesión (si aplica): usa **Redis** u otra solución en memoria para soportar **despliegue Blue/Green** y **balanceo de carga sin sticky sessions**.
>
> ### 📡 Integraciones Obligatorias
> - **Kafka**: para publicar eventos de negocio (por ejemplo, tokenización completada, acceso a PHI).
> - **Elasticsearch**: para indexación segura de metadatos (nunca PHI directo); la integración debe incluir pipeline de enriquecimiento si es necesario.
> - **Application Insights** + **Serilog con salida a Seq o Elasticsearch** para observabilidad centralizada.
>
> ### 🧪 Calidad y Pruebas
> - **Pruebas unitarias** con **xUnit o NUnit**, incluyendo mocks de Vault, Kafka y repositorios.
> - **Pruebas de carga con JMeter**: define escenarios de throughput mínimo (ej. 500 req/s con p95 < 300ms).
> - Incluir **análisis estático** (SonarQube o similar) en el pipeline CI/CD.
>
> ### 📦 Despliegue y Operaciones
> - **On-premise**, con soporte para **Blue/Green deployment** mediante health checks y routing externo.
> - Scripts de **infraestructura como código (IaC)** opcionales, pero el sistema debe permitir configuración 100% externa (appsettings, Vault, environment vars).
>
> ### 📝 Documentación
> - Genera **documentación técnica automática** de la API (aunque Blazor no use API REST tradicional, documenta endpoints internos si los hay).
> - Incluye en comentarios o README: justificación de tokenización vs encriptación, estrategia de rotación de claves AES-256 y diseño de eventos en Kafka.
>
> **Entrega tu propuesta siguiendo estrictamente las cuatro fases del Protocolo v3.0**:
> 1. Análisis y Estrategia  
> 2. Estructura de Archivos  
> 3. Implementación (Código)  
> 4. Revisión de Seguridad y Mejoras  

---

Este prompt puede usarse tanto para guiar a un desarrollador humano como para instruir a un modelo de IA generativa (por ejemplo, GitHub Copilot, CodeLlama, o tú mismo como asistente técnico) en la generación de artefactos alineados con tus estándares.

¿Deseas que ahora genere una **propuesta completa de implementación** (fase 1: análisis) basada en este prompt?