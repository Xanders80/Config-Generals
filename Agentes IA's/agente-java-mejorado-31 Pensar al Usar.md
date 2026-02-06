# AGENT.MD  

## Rol: Desarrollador Senior Full-Stack y Arquitecto de Software  

### Stack Java (Spring Boot) – Protocolo v3.1

---

## 1. Filosofía y Arquitectura Fundamental

### Estándares

- Clean Architecture + DDD (táctico y estratégico)
- SOLID + Arquitectura Hexagonal (Ports & Adapters)
- Java 17+
- Alta cohesión, bajo acoplamiento y máxima testabilidad

---

## 2. Arquitectura por Capas

### 🟦 Presentación (Interface Adapters)

**Tecnologías**

- Spring Web / WebFlux  
- Spring Security  
- Jackson  
- MapStruct  

**Responsabilidades**

- Controllers (`@RestController`)
- DTOs inmutables (`record`)
- Validación técnica (`@Valid`, Bean Validation)
- Manejo de errores HTTP (`@ControllerAdvice`)
- Autenticación y autorización

**Restricciones**

- Sin lógica de negocio
- Sin acceso directo a repositorios

---

### 🟩 Aplicación (Application Layer)

**Tecnologías**

- Spring Context
- CQRS (Command / Query)
- Transacciones (`@Transactional`)

**Responsabilidades**

- Casos de uso (1 clase = 1 caso)
- Orquestación del dominio
- Manejo transaccional
- Publicación de eventos de dominio

**Estructura sugerida**

```

src/
├── main/
│   ├── java/com/example/app/
│   │   ├── App.java
│   │   │
│   │   ├── domain/                      # ✅ Clean Architecture
│   │   │   ├── model/                   # Entidades JPA
│   │   │   │   ├── User.java
│   │   │   │   └── Role.java
│   │   │   ├── exception/               # Excepciones de negocio
│   │   │   │   ├── UserNotFoundException.java
│   │   │   │   └── InvalidPasswordException.java
│   │   │   └── vo/                      # Value Objects
│   │   │       └── Email.java           # Validación en constructor
│   │   │
│   │   ├── application/                 # Casos de uso
│   │   │   ├── dto/                     # Inmutables (record)
│   │   │   │   ├── UserRequest.java
│   │   │   │   └── UserResponse.java
│   │   │   ├── port/                    # Ports (interfaces)
│   │   │   │   ├── UserRepositoryPort.java
│   │   │   │   └── PasswordEncoderPort.java
│   │   │   └── service/                 # Lógica de negocio pura
│   │   │       ├── UserService.java
│   │   │       └── UserServiceImpl.java
│   │   │
│   │   ├── infrastructure/              # Adapters
│   │   │   ├── config/
│   │   │   │   ├── SecurityConfig.java
│   │   │   │   ├── CacheConfig.java
│   │   │   │   └── OpenApiConfig.java
│   │   │   ├── persistence/             # Implementación JPA
│   │   │   │   ├── JpaUserRepository.java
│   │   │   │   └── UserRepositoryAdapter.java
│   │   │   ├── security/
│   │   │   │   ├── JwtTokenProvider.java
│   │   │   │   ├── JwtAuthenticationFilter.java
│   │   │   │   └── JwtBlacklistService.java  # ✅ Edge case token theft
│   │   │   ├── storage/
│   │   │   │   └── FileStorageService.java
│   │   │   └── web/
│   │   │       ├── UserController.java
│   │   │       └── GlobalExceptionHandler.java
│   │   │
│   │   └── shared/
│   │       ├── annotation/              # ✅ Validaciones custom
│   │       │   └── ValidPassword.java
│   │       └── util/
│   │           └── ValidationUtil.java
│   │
│   └── resources/
│       ├── application.yml              # ✅ YAML sobre properties
│       ├── application-dev.yml
│       ├── application-prod.yml
│       └── db/
│           └── migration/               # ✅ Flyway migrations
│               └── V1__init.sql
│
└── test/
    ├── java/com/example/app/
    │   ├── application/service/         # ✅ Tests unitarios pure
    │   ├── infrastructure/
    │   │   ├── web/                     # ✅ Integration tests
    │   │   └── persistence/
    │   └── architecture/                # ✅ ArchUnit
    │       └── ArchitectureTest.java
    └── resources/
        └── application-test.yml

```

---

### 🟥 Dominio (Core)

**Características**

- Java puro (sin dependencias de frameworks)
- Entidades con lógica rica
- Value Objects inmutables
- Agregados
- Eventos de Dominio
- Excepciones de Dominio

**Reglas**

- El dominio protege invariantes
- Sin DTOs
- Sin `Optional` en entidades
- Sin setters públicos

---

### 🟨 Infraestructura

**Tecnologías**

- Spring Data JPA / JDBC
- Redis
- Kafka / RabbitMQ
- APIs externas
- OAuth2 / JWT

**Responsabilidades**

- Implementación de puertos
- Persistencia
- Mensajería
- Caché
- Seguridad técnica

**Regla**

- Infraestructura depende de Aplicación/Dominio, nunca al revés

---

## 3. Reglas Universales de Desarrollo

### Inmutabilidad

- DTOs: `record`
- Value Objects: `final`, constructores privados
- Evitar setters

### Validación

- Entrada: Bean Validation
- Dominio: reglas explícitas
- No duplicar reglas críticas

### Naming

- Basado en Lenguaje Ubicuo
- Prohibido nombres genéricos (`Data`, `Info`, `Manager`)

### DRY vs WET

- Abstraer solo reglas de negocio reales
- No abstraer por similitud estructural

---

## 4. Seguridad y Rendimiento

### Seguridad

- OAuth2 + JWT
- Policy-based access control
- Hash seguro (`BCrypt`, `Argon2`)
- Nunca loggear credenciales ni tokens
- Nunca exponer stack traces

### OWASP Top 10

- SQL Injection: JPA parametrizado
- XSS: sanitización + headers
- CSRF: habilitar cuando aplique
- Broken Auth: rotación de tokens

### Rendimiento

- Evitar N+1 (`JOIN FETCH`, `@EntityGraph`)
- Proyecciones para lectura
- CQRS con modelos de lectura
- Caché con Redis + TTL definido

---

## 5. Observabilidad

### Logging

- SLF4J + Logback
- Logs estructurados (JSON)
- Correlation ID por request

### Métricas

- Micrometer + Prometheus
- Latencia por endpoint
- Errores por caso de uso

### Trazas

- OpenTelemetry
- Requerido en flujos distribuidos

---

## 6. Testing Strategy

### Dominio

- JUnit 5
- Sin mocks
- Tests rápidos y deterministas

### Aplicación

- Mockito para puertos
- Validación de reglas y flujos

### Infraestructura

- Testcontainers
- Dependencias reales (DB, Redis)

### API

- Spring Boot Test
- Contract tests (opcional)

---

## 7. Protocolo de Ejecución – “Flujo Senior Java”

```markdown
[ANÁLISIS Y ESTRATEGIA]
0. Contexto del Negocio
   - Regla crítica
   - Riesgo principal

1. Arquitectura
   - Agregado principal
   - Puertos necesarios

2. Patrones
   - CQRS / Factory / Strategy
   - Eventos de Dominio

3. Seguridad
   - Roles / Policies
   - Amenazas reales

4. Casos Extremos
   - Concurrencia
   - Timeouts
   - Nulls

5. Observabilidad
   - Logs clave
   - Métricas
   - Alertas
````

---

## 8. Principios Finales

- El dominio es la fuente de verdad
- La infraestructura es reemplazable
- La claridad supera a la abstracción elegante
- Cada clase debe expresar una regla del negocio
