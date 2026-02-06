### USER
Analiza el Archivo; genera con este contenido un prompt de Desarrollador con perfil Java y otras tecnologías acorde al perfil, realiza las preguntas adecuadas para su construcción

### ASSISTANT
> **TERMINAL DE ARQUITECTO LISTA.**

Para construir un **prompt especializado de Desarrollador Fullstack con perfil Java y tecnologías complementarias**, alineado con el *Protocolo de Arquitecto Fullstack Senior v3.0* y ajustado a su perfil técnico real, necesito confirmar o precisar ciertos aspectos clave.

Por favor, responda las siguientes preguntas:

---

### **1. Alcance del perfil técnico**
- ¿Debe el prompt reflejar un **perfil estrictamente Java Backend** (Spring Boot, Jakarta EE, etc.), o también debe incluir experiencia con **tecnologías Fullstack** como frontend (React, Blade, Thymeleaf, etc.) e infraestructura (AWS, Docker, Kafka, Elasticsearch)?
- ¿Se desea un enfoque en **arquitecturas empresariales** (microservicios, eventos, colas) o también en aplicaciones monolíticas/modulares?

### **2. Stack tecnológico preferido o requerido**
- ¿Qué versiones de **Java** y frameworks se consideran prioritarios? (Ej: Java 17/21, Spring Boot 3.x, Quarkus, Micronaut, etc.)
- ¿Debe incluir experiencia con **JPA/Hibernate**, **MyBatis**, o patrones específicos de acceso a datos?
- ¿Es relevante incluir integración con **bases de datos MariaDB, Oracle o MySQL**, tal como aparece en su perfil?

### **3. Integración con prácticas de ingeniería de software**
- ¿Se deben enfatizar herramientas y prácticas específicas como:
  - **Pruebas**: JUnit 5, Testcontainers, Mockito, etc.
  - **CI/CD**: GitHub Actions, AWS CodePipeline, Jenkins.
  - **Observabilidad**: Micrometer, Prometheus, ELK.
  - **Seguridad**: Spring Security, OAuth2, JWT, OWASP.
- ¿Debe incluir soporte para **patrones como CQRS, MediatR-equivalentes en Java** (ej: Axon, Simple CQRS lib), o arquitectura hexagonal?

### **4. Contexto de uso del prompt**
- ¿Este prompt será utilizado para:
  - Generar código a partir de descripciones funcionales?
  - Diseñar arquitecturas de sistemas?
  - Revisar y mejorar implementaciones existentes?
  - Asistir en entrevistas técnicas o documentación?

### **5. Restricciones o cumplimientos obligatorios**
- ¿Debe el perfil generado por el prompt hacer explícito cumplimiento con:
  - **HIPAA** (por mencionarse en sus memorias)?
  - **Estándares de encriptación (AES-256)** y **tokenización**?
  - **Requisitos no funcionales** como 100 req/s o 10,000 usuarios concurrentes?

---

Con sus respuestas, construiré un **prompt de rol técnico altamente específico, verificable y alineado con el Protocolo v3.0**, que refleje con precisión su experiencia como **Analista en Desarrollos de Software – Fullstack con dominio en .NET y Java**, y su enfoque en **arquitecturas empresariales seguras, escalables y mantenibles**.

### USER
Respondiendo a tus interrogantes: 
1. Spring boot con Thymeleaf e infraestructura KAFKA, Aplicacióno Monólitica/Modular
2. Ultima versiones de Java, Spring boot y demas frameworks, PA/Hibernate, on bases de datos MariaDB
3. Pruebas Junit 5, CI/CD Github Actions, Observabilidad Prometheus, Segurdiad JWT, con soporte para patrones como CQRS, MediatR-equivalentes en Java
4. Contexto de uso del prompt Tal como lo especificas
5. Perfil de generado tal como lo especificas

### ASSISTANT
> **TERMINAL DE ARQUITECTO LISTA.**

Con base en el **Protocolo de Arquitecto Fullstack Senior v3.0** y sus respuestas, procedo a construir un **prompt de rol técnico especializado** para un **Desarrollador Fullstack con perfil Java**, diseñado para ser utilizado en interacciones con modelos de lenguaje (IA generativa), alineado con sus preferencias verificables, su stack tecnológico real y el marco del protocolo.

---

### **PROMPT DE ROL: DESARROLLADOR FULLSTACK SENIOR – JAVA (SPRING BOOT + THYMELEAF)**

```
Actúa como un **Ingeniero de Software Fullstack Principal y Arquitecto de Sistemas**, con enfoque en **aplicaciones empresariales monolíticas/modulares escalables**, construidas sobre **Java 21**, **Spring Boot 3.x**, **Spring Security**, **Spring Data JPA/Hibernate**, y **Thymeleaf** como motor de plantillas del lado del servidor.  

Tu stack tecnológico incluye:
- **Base de datos**: MariaDB (versión 11+), con enfoque en indexación estratégica, prevención de consultas N+1, y uso de consultas parametrizadas.
- **Infraestructura**: Arquitectura basada en eventos con **Apache Kafka** para desacoplamiento asíncrono; uso de **Prometheus + Grafana** para observabilidad (métricas, logging y tracing básico); **JWT** para autenticación stateless; y despliegue en entornos cloud (preferentemente AWS).
- **Pruebas**: Cobertura con **JUnit 5**, **Testcontainers** y **Mockito**; validación de throughput y concurrencia mediante **JMeter** (requisitos: ≥100 req/s, ≥10,000 usuarios concurrentes).
- **CI/CD**: Pipelines en **GitHub Actions**, con escaneo de vulnerabilidades (Dependabot/Snyk), enforce de linters y validación de pruebas automatizadas.
- **Patrones de diseño**: Aplicación de **CQRS** (mediante librerías como Axon o implementación ligera basada en dominios), **Separation of Concerns**, **SOLID**, **DRY**, **KISS**, **YAGNI**, y uso de **MediatR-equivalent patterns en Java** (mediante un pipeline explícito: Validación → Dispatcher → Handler → AutoMapper-equivalente con MapStruct).
- **Cumplimiento**: Alineación con **OWASP Top 10**, encriptación AES-256 para datos sensibles, tokenización, y gestión segura de secretos (sin hardcoding; uso de variables de entorno o AWS Secrets Manager).

Operas bajo el **Protocolo de Arquitecto Fullstack Senior v3.0**, lo que implica:
1. **Seguridad por defecto**: todas las entradas se sanitizan, todas las salidas se escapan (Thymeleaf lo hace por defecto, pero verificas activamente), y todo el tráfico sensible se encripta.
2. **Pensamiento en cadena (CoT)**: antes de generar código, analizas el problema, identificas edge cases, propones arquitectura y patrones, y justificas tecnologías.
3. **Formato de respuesta estructurado**: sigues los cuatro pasos del protocolo: Análisis → Estructura → Implementación → Revisión de seguridad/mejoras.
4. **Transparencia técnica**: si algo no es verificable o está fuera del alcance, lo declara explícitamente.

Tu objetivo es **diseñar, revisar o generar código técnico irrefutable**, alineado con buenas prácticas empresariales, escalabilidad horizontal, y cumplimiento regulatorio (incluyendo soporte para HIPAA cuando aplique).

**No especules. No inventes. Todo dato debe ser técnicamente correcto, actual (2025) y citable.**
```

---

Este prompt cumple con:

- El **agnosticismo tecnológico controlado** del protocolo (centrado en principios, con stack concreto).
- La **especificidad realista** de su perfil profesional registrado (Java, Spring Boot, MariaDB, Kafka, Thymeleaf, etc.).
- El **énfasis en no funcionales** (seguridad, rendimiento, observabilidad, resiliencia).
- El **uso de IA como asistente**, no como autoridad (requiere revisión humana y validación).

¿Desea ajustar algún componente del prompt (por ejemplo, profundizar en CQRS, Thymeleaf vs. React, o el modelo de despliegue)?