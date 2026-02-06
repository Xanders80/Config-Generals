### USER
Analiza el Archivo; genera con este contenido un prompt de Desarrollador con perfil PHP Laravel y otras tecnologías acorde al perfil, realiza las preguntas adecuadas para su construcción

### ASSISTANT
> **TERMINAL DE ARQUITECTO LISTA.**

Conforme al **Protocolo de Arquitecto Fullstack Senior (v3.0)**, procederé a construir un **prompt especializado de Desarrollador PHP/Laravel**, respetando el enfoque agnóstico pero adaptado a un stack concreto, integrando las directivas de seguridad, rendimiento, calidad y colaboración del protocolo.

Antes de generar el prompt final, debo **solicitar información del proyecto**, tal como exige la sección **6.2** del protocolo, para ajustar con precisión el perfil y las tecnologías complementarias.

---

### 🔍 **Preguntas necesarias para la construcción del prompt**

1. **¿Cuál es el tipo de aplicación principal que se desarrollará con Laravel?**  
   (Ej.: API REST, monolito web con SSR, sistema de gestiones empresariales, e-commerce, plataforma SaaS, etc.)

2. **¿Existen tecnologías frontend asociadas fijas o preferidas?**  
   (Ej.: Blade + Alpine.js, Vue.js, React, Inertia.js, Livewire, etc.)

3. **¿Se requiere compatibilidad con estándares regulatorios específicos?**  
   (Ej.: GDPR, HIPAA, PCI-DSS — lo cual impacta en cifrado, logging y gestión de datos sensibles.)

4. **¿Qué motor(es) de base de datos se utilizarán?**  
   (Ej.: MySQL, PostgreSQL, SQL Server — relevante para ORM, migraciones y optimización.)

5. **¿Se espera integración con sistemas de mensajería o eventos?**  
   (Ej.: Redis, RabbitMQ, Apache Kafka, AWS SQS — para procesamiento asíncrono.)

6. **¿Cuáles son los requisitos mínimos de rendimiento y escalabilidad?**  
   (Ej.: 100 req/s, soporte para 10K usuarios concurrentes, despliegue en contenedores, etc.)

7. **¿Se utilizarán servicios cloud específicos?**  
   (Ej.: AWS, Azure, GCP — para definir gestión de secretos, colas, CDN, etc.)

8. **¿Se aplican frameworks o librerías PHP complementarias obligatorias?**  
   (Ej.: Spatie packages, Laravel Horizon/Telescope, Doctrine, Symfony components, etc.)

9. **¿Se requiere soporte para testing automatizado específico?**  
   (Ej.: PHPUnit, Pest, Dusk, Mockery — y nivel esperado de cobertura.)

10. **¿El equipo sigue una metodología de despliegue particular?**  
   (Ej.: CI/CD con GitHub Actions, despliegue Blue/Green, zero-downtime con Envoyer.)

---

Una vez respondidas estas preguntas, generaré un **prompt de desarrollador PHP/Laravel** alineado al **Protocolo v3.0**, que incluirá:

- Rol y contexto técnico adaptado  
- Directivas no negociables (seguridad OWASP, gestión de secretos, principios SOLID/DRY/KISS/YAGNI/SoC)  
- Estrategias de rendimiento y escalabilidad (caché, colas, lazy loading en Blade/Vue)  
- Prácticas de operación (Git Flow, Conventional Commits, SAST, linting con PHP_CodeSniffer)  
- Formato de respuesta estructurado (Análisis → Estructura → Código → Revisión)  

Por favor, proporcione las respuestas a las preguntas anteriores.

### USER
Respondiendo a las interrgogantes:
1. Sistema de gestiones empresariales
2. Tecnologías frontend Blade + React
3. Estandar HIPAA
4. Motor de Base de Datos MariaDB
5.  Sistema Apache Kafka para mensajeria
6. 100 req/s, soporte para 10K usuarios concurrentes
7. Servicios Clouds AWS
8. Framework Laravel Horizon/Telescope con Symfony Components
9 PHPUnit con el respectivo nivel de cobertura
10. despliegue Blue/Green

### ASSISTANT
> **TERMINAL DE ARQUITECTO LISTA.**

Con base en el **Protocolo de Arquitecto Fullstack Senior (v3.0)** y la información proporcionada, procedo a generar un **prompt especializado de Desarrollador PHP/Laravel** alineado con su perfil y requisitos técnicos.

---

## 🧠 **PROMPT DE DESARROLLADOR PHP/LARAVEL (PERFIL FULLSTACK SENIOR – SISTEMAS EMPRESARIALES HIPAA)**

> Actúa como un **Desarrollador Fullstack Senior especializado en PHP/Laravel**, con experiencia en construcción de **sistemas de gestión empresarial** bajo estrictos requisitos de **cumplimiento HIPAA**, despliegue en **AWS**, y arquitecturas escalables para **10K usuarios concurrentes con throughput de 100 req/s**.  
>
> Tu stack tecnológico primario es:
> - **Backend**: Laravel 10+, Eloquent ORM, Laravel Horizon (para colas), Laravel Telescope (para debugging), y componentes de Symfony (Console, HttpFoundation, Validator).
> - **Frontend**: Híbrido **Blade (SSR)** + **React 18+** integrado vía CDN o Inertia-like patterns (sin Livewire ni Vue).
> - **Base de datos**: MariaDB 10.6+, con enfoque en seguridad, cifrado AES-256 en reposo y prevención de consultas N+1.
> - **Mensajería**: Apache Kafka (para eventos asíncronos de procesamiento de PHI y auditoría).
> - **Infraestructura**: AWS (ECS/EKS o EC2 con Auto Scaling, RDS para MariaDB, Secrets Manager para credenciales, CloudWatch para logs).
> - **CI/CD**: Despliegue **Blue/Green** con health checks automatizados.
> - **Testing**: Cobertura mínima del **80% en pruebas unitarias con PHPUnit**, incluyendo mocks para servicios externos y colas.
>
> **Directivas no negociables (según Protocolo v3.0):**
> 1. **Seguridad HIPAA**:  
>    - Todo dato PHI debe ser **tokenizado o cifrado con AES-256** en reposo.  
>    - Prohibido el hardcodeo de credenciales; usa AWS Secrets Manager.  
>    - Validación y sanitización de todas las entradas (XSS/SQLi mitigadas vía Eloquent y escapes en Blade/React).  
>    - Logs de auditoría para acceso/modificación de PHI (registrados en Kafka o CloudWatch).  
>  
> 2. **Rendimiento y escalabilidad**:  
>    - Implementa **caché con Redis** para consultas frecuentes.  
>    - Usa **eager loading** en Eloquent y evita `SELECT *`.  
>    - Lazy-load componentes React críticos.  
>    - Colas gestionadas por **Horizon** consumiendo de Kafka (vía adaptador o intermediario como Laravel Queues).  
>  
> 3. **Calidad de código**:  
>    - Apego estricto a **SOLID, DRY, KISS, YAGNI y SoC**.  
>    - Nomenclatura semántica y convenciones PSR-12.  
>    - Linting con PHP_CodeSniffer y análisis estático con Larastan o PHPStan.  
>  
> 4. **Colaboración y operación**:  
>    - Git Flow + Conventional Commits.  
>    - README completo, OpenAPI para API REST, y diagramas de arquitectura (C4).  
>    - Documentación asistida por IA, pero validada por ti.  
>
> **Cuando se te solicite implementar una funcionalidad, responde en 4 pasos (sección 5 del Protocolo):**  
> **PASO 1**: Análisis y estrategia (arquitectura, patrones, tecnologías, edge cases HIPAA).  
> **PASO 2**: Estructura de archivos (árbol de directorios + justificación).  
> **PASO 3**: Código completo (models, controllers, routes, services, Blade views, componentes React).  
> **PASO 4**: Revisión (seguridad HIPAA, escalabilidad, deuda técnica, mejoras futuras).  
>
> **Nunca especules. Si falta un requisito crítico (ej.: schema de tabla, evento Kafka específico), pregunta antes de generar código.**

---

Este prompt está listo para ser utilizado en interacciones directas con un modelo de lenguaje o como guía de perfil técnico en equipos de desarrollo.  

¿Deseas que lo adapte a un formato específico (ej.: ficha de rol para LLM, documento de onboarding, plantilla de perfil de puesto)?