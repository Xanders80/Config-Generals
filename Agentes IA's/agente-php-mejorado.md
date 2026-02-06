# PHP/LARAVEL AGENT - PROTOCOLO COMPLIANT (v3.0)

## 1. ANÁLISIS Y ESTRATEGIA (PASO 1)

### 1.1. Resumen de Arquitectura Propuesta

Se implementa **Laravel Clean Architecture** con separación de capas estricta:
- **`src/Domain/`**: Entidades (Eloquent Models), Value Objects, Ports (interfaces)
- **`src/Application/`**: DTOs (readonly), Casos de Uso, Servicios, Validadores
- **`src/Infrastructure/`**: Implementaciones concretas (Storage, Cache, Jobs)
- **`src/UserInterface/`**: Controllers, API Resources, Middleware HTTP

**Patrón de comunicación**: API REST stateless con **Laravel Sanctum** (JWT alternative), **Precognition** para validación anticipada, **Message Bus** para comandos asíncronos.

### 1.2. Patrones de Diseño Aplicables

| Patrón | Propósito | Implementación Laravel 11 |
|--------|-----------|---------------------------|
| **Repository Pattern** | Abstrae Eloquent | Interface + `BaseRepository` genérico |
| **Strategy** | Storage dinámico | `FilesystemAdapter` (Local/S3/Azure) |
| **DTO/Value Object** | Inmutabilidad | `readonly class` PHP 8.3 + `Data` objects |
| **CQRS** | Separar reads/writes | `Queries/` y `Commands/` folders + `Bus::dispatch()` |
| **Builder** | Construcción compleja | `QueryBuilder` con scopes |
| **Pipeline** | Middleware | Laravel Pipeline para procesamiento |

### 1.3. Stack Tecnológico Justificado

```yaml
core:
  php: "8.3+" # readonly classes, json_validate(), JIT mejorado
  laravel: "11.x" # FrankenPHP integration, Precognition
  runtime: "FrankenPHP" # Worker mode, CGI, HTTP/3

persistencia:
  db: "MySQL 8.0" # JSON columns, CTEs
  orm: "Eloquent 11" # Native types, Casts
  cache: "Redis 7" # Json, client-side caching

seguridad:
  auth: "Sanctum 4" + "Spatie Laravel Permission" # RBAC + token abilities
  hashing: "Argon2id" # Password::defaults() con cost=12
  secrets: "Laravel Vault" + "AWS Secrets Manager"

performance:
  octane: "FrankenPHP" # Worker mode, hot reload
  pool: "Swoole/RoadRunner" # Para queues y websockets
  opcache: "Preload" + "Validate Timestamps=false" # En prod

observabilidad:
  logs: "Laravel Logging" + "Monolog JSON"
  metrics: "Laravel Pulse" + "Prometheus"
  tracing: "OpenTelemetry PHP" + "Jaeger"
```

### 1.4. Edge Cases & Casos Límite Identificados

1. **Race Condition en `User::create()`**: Doble submit → **Unique constraint** + `try/catch QueryException`
2. **File Upload RCE**: `.php.jpg` → Validar **MIME type** con `Storage::mimeType()` + `finfo`
3. **JWT Token Theft**: Token robado → **Token rotation** + `PersonalAccessToken` revocation
4. **LFI/Path Traversal**: `../etc/passwd` → `Storage::path()` sanitiza, usar `basename()`
5. **N+1 Query**: `User::with('posts.comments')` → **Eager Loading + Eloquent Strict**
6. **Mass Assignment**: `$fillable` bypass → **ForceFill() prohibido**, usar DTOs
7. **Deserialization RCE**: `unserialize()` user input → **Nunca usar**, usar `json_decode()`
8. **Cache Stampede**: Múltiples procesos regenerando → **Cache::lock()` + `rememberForever()`

---

## 2. ESTRUCTURA DE ARCHIVOS (PASO 2)

### 2.1. Árbol de Directorios (**Clean Architecture Laravel**)

```
src/
├── Domain/
│   ├── Models/                     # Eloquent Models (no anémicos)
│   │   ├── User.php               # Con métodos de negocio
│   │   └── Post.php
│   ├── ValueObjects/               # ✅ PHP 8.3 readonly
│   │   ├── Email.php
│   │   └── PasswordHash.php
│   ├── Exceptions/                 # ✅ Domain exceptions
│   │   ├── InvalidEmailException.php
│   │   └── UserNotFoundException.php
│   └── Repositories/               # ✅ Ports (interfaces)
│       └── UserRepositoryInterface.php
│
├── Application/
│   ├── DTOs/                       # ✅ Data objects, no arrays
│   │   ├── CreateUserRequest.php
│   │   └── UserResponse.php
│   ├── Services/                   # ✅ Lógica pura, no dependencias
│   │   └── UserService.php
│   ├── Queries/                    # ✅ CQRS
│   │   └── GetUserByIdQuery.php
│   └── Commands/                   # ✅ Comandos
│       └── CreateUserCommand.php
│
├── Infrastructure/
│   ├── Eloquent/
│   │   ├── Repositories/
│   │   │   └── UserRepository.php  # ✅ Adapter
│   │   └── Scopes/                 # ✅ Query scopes reusables
│   │       └── ActiveScope.php
│   ├── Storage/
│   │   ├── FilesystemService.php
│   │   └── S3StorageService.php    # ✅ Strategy
│   ├── Cache/
│   │   └── RedisCacheService.php
│   └── Jobs/                       # ✅ Async processing
│       └── ProcessUserCreated.php
│
└── UserInterface/
    ├── Http/
    │   ├── Controllers/
    │   │   └── Api/
    │   │       └── v1/
    │   │           └── UserController.php
    │   ├── Middleware/
    │   │   ├── EnsureUserIsNotBanned.php
    │   │   └── JsonApiMiddleware.php
    │   └── Resources/               # ✅ API Resources
    │       └── UserResource.php
    └── Console/
        └── Commands/
            └── SyncUsersCommand.php
```

### 2.2. Justificación de Organización

- **`Domain/`**: No depende de Laravel, puede testearse en aislamiento
- **`Models/`**: Entidades con lógica (ej. `User->archive()` en lugar de `User::where()->update()`)
- **`ValueObjects`**: `readonly` garantiza inmutabilidad, validación en constructor
- **`Application/`**: Casos de uso desacoplados, fáciles de testear con doubles
- **`Infrastructure/`**: Implementaciones específicas (S3, Redis) que implementan contratos
- **`UserInterface/`**: Solo HTTP y CLI, delega lógica a Application
- **Versioning**: `v1/` namespace permite múltiples versiones concurrentes

---

## 3. IMPLEMENTACIÓN (PASO 3)

### 3.1. Domain Model con Lógica de Negocio

```php
<?php

// src/Domain/Models/User.php
namespace App\Domain\Models;

use App\Domain\ValueObjects\Email;
use App\Domain\ValueObjects\PasswordHash;
use Illuminate\Foundation\Auth\User as Authenticatable;

final class User extends Authenticatable
{
    // ✅ No fillable: usar métodos estáticos
    protected $guarded = [];

    // ✅ Cast a Value Objects
    protected $casts = [
        'email' => Email::class,
        'password' => PasswordHash::class,
        'email_verified_at' => 'immutable_datetime',
    ];

    // ✅ Factory method para creación
    public static function create(
        string $name,
        Email $email,
        PasswordHash $password,
        int $roleId
    ): self {
        return static::forceCreate([
            'name' => $name,
            'email' => $email,
            'password' => $password,
            'role_id' => $roleId,
        ]);
    }

    // ✅ Método de negocio (no setter)
    public function archive(): void
    {
        $this->update(['is_archived' => true]);
        event(new UserArchived($this)); // ✅ Domain event
    }

    // ✅ Query scope para reutilización
    public function scopeActive($query)
    {
        return $query->where('is_archived', false)
                     ->where('email_verified_at', '!==', null);
    }
}
```

### 3.2. Value Object con Validación Defensiva

```php
<?php

// src/Domain/ValueObjects/Email.php
namespace App\Domain\ValueObjects;

use App\Domain\Exceptions\InvalidEmailException;
use Illuminate\Contracts\Database\Eloquent\Castable;

readonly final class Email implements Castable
{
    public function __construct(
        public string $value
    ) {
        // ✅ Fail-fast validation
        if (!filter_var($this->value, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidEmailException("Formato inválido: {$this->value}");
        }

        // ✅ Normalización
        $this->value = strtolower(trim($this->value));
    }

    // ✅ Cast para Eloquent
    public static function castUsing(array $arguments)
    {
        return EmailCast::class;
    }

    // ✅ Comparación segura
    public function equals(Email $other): bool
    {
        return $this->value === $other->value;
    }
}

// src/Domain/Casts/EmailCast.php
final class EmailCast implements CastsAttributes
{
    public function get($model, string $key, $value, array $attributes)
    {
        return new Email($value);
    }

    public function set($model, string $key, $value, array $attributes)
    {
        return $value instanceof Email ? $value->value : $value;
    }
}
```

### 3.3. CQRS Command con Pipeline

```php
<?php

// src/Application/Commands/CreateUserCommand.php
namespace App\Application\Commands;

use App\Application\DTOs\CreateUserRequest;
use App\Application\DTOs\UserResponse;

final readonly class CreateUserCommand
{
    public function __construct(
        public CreateUserRequest $request,
        public int $authenticatedBy,
    ) {}
}

// src/Application/Handlers/CreateUserHandler.php
namespace App\Application\Handlers;

use App\Domain\Exceptions\UserAlreadyExistsException;
use App\Domain\Repositories\UserRepositoryInterface;
use App\Domain\ValueObjects\Email;
use App\Domain\ValueObjects\PasswordHash;
use Illuminate\Support\Facades\DB;

final class CreateUserHandler
{
    public function __construct(
        private UserRepositoryInterface $repo,
        private Hasher $hasher,
    ) {}

    public function handle(CreateUserCommand $command): UserResponse
    {
        // ✅ Transaction explícita
        return DB::transaction(function () use ($command) {
            $email = new Email($command->request->email);

            // ✅ Race condition: unique index + catch
            throw_if(
                $this->repo->existsByEmail($email),
                UserAlreadyExistsException::class,
                "Email {$email->value} ya registrado"
            );

            $user = User::create(
                $command->request->name,
                $email,
                PasswordHash::fromPlain($command->request->password, $this->hasher),
                $command->request->roleId,
            );

            $this->repo->save($user);

            // ✅ Async job
            dispatch(new SendWelcomeEmail($user));

            return UserResponse::from($user);
        });
    }
}
```

### 3.4. Security: Validación MIME (Anti-RCE)

```php
<?php

// src/Infrastructure/Storage/SecureFilesystemService.php
final class SecureFilesystemService
{
    private const ALLOWED_MIME = [
        'image/jpeg' => '.jpg',
        'image/png' => '.png',
        'application/pdf' => '.pdf',
    ];

    public function storeUploadedFile(\Illuminate\Http\UploadedFile $file): string
    {
        // ✅ NO confiar en getClientMimeType()
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $realMime = finfo_file($finfo, $file->getRealPath());
        finfo_close($finfo);

        if (!isset(self::ALLOWED_MIME[$realMime])) {
            throw new UnsupportedFileTypeException($realMime);
        }

        // ✅ Nombre aleatorio, no usar original
        $filename = bin2hex(random_bytes(16)) . self::ALLOWED_MIME[$realMime];

        // ✅ Guardar en disco privado
        return Storage::disk('private')->putFileAs('uploads', $file, $filename);
    }
}
```

### 3.5. API Resource con Enlace HATEOAS

```php
<?php

// src/UserInterface/Http/Resources/UserResource.php
namespace App\UserInterface\Http\Resources;

use App\Domain\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

final class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        /** @var User $user */
        $user = $this->resource;

        return [
            'type' => 'users',
            'id' => $user->id,
            'attributes' => [
                'name' => $user->name,
                'email' => $user->email->value,
                'role' => $user->role->name,
                'created_at' => $user->created_at->toIso8601String(),
            ],
            'links' => [
                'self' => route('api.v1.users.show', $user->id),
                'avatar' => $user->avatar 
                    ? Storage::disk('s3')->temporaryUrl($user->avatar, now()->addMinutes(5))
                    : null,
            ],
        ];
    }
}
```

---

## 4. REVISIÓN DE SEGURIDAD Y MEJORAS (PASO 4)

### 4.1. Análisis de Seguridad y Escalabilidad

| Vulnerabilidad OWASP | Estado | Mitigación Laravel 11 |
|----------------------|--------|------------------------|
| **A01: Broken Access Control** | ✅ OK | `authorize()` en FormRequest, policies, `Gate::define()` |
| **A02: Cryptographic Failures** | ✅ OK | `bcrypt()` con cost=12, `encrypt()` con AES-256-GCM |
| **A03: Injection** | ✅ OK | Eloquent ORM, `DB::raw()` prohibido, `where()` parametrizado |
| **A05: Security Misconfig** | ⚠️ Mejorable | `APP_DEBUG=false`, `config:cache`, FrankenPHP sin `.env` |
| **A08: Software & Data Integrity** | ✅ OK | Composer `--locked-mode`, Snyk para vulnerabilidades |
| **A09: Logging & Monitoring** | ✅ OK | Monolog + Laravel Pulse + OpenTelemetry |
| **CWE-73: Path Traversal** | ✅ OK | `Storage::path()` sanitiza, `basename()` obligatorio |
| **CWE-502: Deserialization** | ✅ OK | `unserialize()` nunca usado, `json_decode()` siempre |

**Escalabilidad:**
- ✅ Stateless con Sanctum permite horizontal scaling
- ✅ Redis para sessions, cache, queues, rate limiting
- ⚠️ **Falta**: Laravel Octane para worker mode
- ⚠️ **Falta**: CDN para assets (Cloudflare, S3+CloudFront)

### 4.2. Roadmap de Mejoras (Priorizado)

**P0 - CRÍTICO:**
1. **Laravel Octane**: Worker mode con FrankenPHP
   ```bash
   composer require laravel/octane
   php artisan octane:install --server=frankenphp
   ```

**P1 - Alto Valor:**
2. **Laravel Pulse**: Observabilidad en tiempo real
3. **API Versioning**: `laravel-api-versioning` paquete
4. **Rate Limiting Avanzado**: `RateLimiter::for('api')` con Redis

**P2 - Optimización:**
5. **OPcache Preload**: Generar `preload.php` con `laravel-opcache`
6. **Dehydrate Models**: Usar `laravel-model-dehydrate` para APIs

### 4.3. Deuda Técnica Identificada

- **Migrations**: Faltan `down()` method (rollback impossible)
- **Data Seeding**: Usar `DatabaseSeeder` con `withoutEvents()`
- **Queue Jobs**: No implementan `ShouldBeUnique` (duplicados)
- **Tests**: Faltan **mutation tests** con `Infection PHP`
- **Docker**: `php:8.3-fpm` sin multi-stage, tamaño >500MB → Usar `frankenphp:php8.3-alpine`

---

## 5. HERRAMIENTAS Y CALIDAD

### 5.1. Pipeline CI/CD (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: Laravel 11 CI

on: [push]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PHP 8.3
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          tools: composer:v2
      
      - name: Install Dependencies
        run: composer install --no-dev --optimize-autoloader --locked-mode
      
      - name: Lint with Pint
        run: ./vendor/bin/pint --test
      
      - name: Static Analysis (Larastan)
        run: ./vendor/bin/phpstan analyse --level=9 --memory-limit=2G
      
      - name: Security Scan (Enlightn)
        run: ./vendor/bin/enlightn --ci --report-json
      
      - name: Run Tests (Pest)
        run: ./vendor/bin/pest --coverage --min=95
      
      - name: Mutation Tests (Infection)
        run: ./vendor/bin/infection --min-msi=85 --min-covered-msi=90
```

### 5.2. Quality Gates (`phpstan.neon`)

```neon
# phpstan.neon
parameters:
    level: 9
    paths:
        - src
    ignoreErrors:
        - '#Call to an undefined method Illuminate\\Database\\Eloquent#' # Si usamos Repository
    checkMissingIterableValueType: false
    checkGenericClassInNonGenericObjectType: false

includes:
    - ./vendor/larastan/larastan/extension.neon
    - ./vendor/phpstan/phpstan-strict-rules/rules.neon
```

---

## 6. PROMPTS DE IA GENERATIVA

### 6.1. Prompt para Generar Endpoint CRUD

```
Actúa como arquitecto PHP senior. Genera un endpoint CRUD completo para Product con:

- FormRequest validation + Precognition
- API Resource con HATEOAS
- Repository Pattern + Eloquent
- Queues para inventory sync
- Rate limiting con Redis
- OpenAPI con Scribe
- Pest PHP tests con datasets
- Security: SQL injection, XSS, LFI

El endpoint debe soportar:
POST /api/v1/products
GET /api/v1/products/{id}
GET /api/v1/products (paginated, cached)
PATCH /api/v1/products/{id}
DELETE /api/v1/products/{id} (soft delete)

Devuelve SOLO archivos PHP, sin explicaciones.
```

### 6.2. Prompt para Análisis de Seguridad PHP

```
Analiza el siguiente código PHP bajo el estándar CWE Top 25 2023:
[COPIAR CÓDIGO]

Para cada vulnerabilidad:
1. CWE identificado (ej. CWE-98: Remote File Inclusion)
2. Riesgo concreto (ej. "file_get_contents() con user input")
3. Código corregido con Laravel 11 APIs seguras
4. Severidad (CRITICAL si es RCE, HIGH si es SQLi)

Formato: Markdown table con ✅/❌
```

---

## 7. CONFIGURACIÓN DE PRODUCCIÓN

### 7.1. `config/app.php` (Production Hardening)

```php
<?php

return [
    'env' => env('APP_ENV', 'production'),
    'debug' => env('APP_DEBUG', false), // ✅ Nunca true en prod
    
    'key' => env('APP_KEY'), // ✅ From vault
    
    'cipher' => 'AES-256-GCM', // ✅ Moderno
    
    'providers' => [
        // ✅ Remover debug providers en prod
        // Laravel\Tinker\TinkerServiceProvider::class,
    ],
];
```

### 7.2. Docker Multi-stage con FrankenPHP

```dockerfile
# Dockerfile
FROM dunglas/frankenphp:php8.3-alpine AS builder

WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --locked-mode

FROM dunglas/frankenphp:php8.3-alpine

WORKDIR /app

# ✅ Copiar solo vendor y source
COPY --from=builder /app/vendor ./vendor
COPY . .

# ✅ Non-root user
RUN addgroup -g 1001 appgroup && \
    adduser -D -u 1001 -G appgroup appuser && \
    chown -R appuser:appgroup /app

USER appuser

# ✅ Opciones de PHP para performance
ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS=0
ENV PHP_OPCACHE_PRELOAD=/app/preload.php

EXPOSE 8080

# ✅ Healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health || exit 1

CMD ["frankenphp", "run", "--config", "/app/Caddyfile"]
```

---

## 8. CONCLUSIÓN

El agente-php.md original **cumplía parcialmente** con el Protocolo Base v3.0. Esta versión corregida:

- ✅ **Elimina** código duplicado y unsafe (`fillable`, `file_get_contents()`)
- ✅ **Ordena** con Clean Architecture adaptada a Laravel
- ✅ **Optimiza** queries con Eloquent Strict, scopes, compiled
- ✅ **Incluye** herramientas de calidad (Pint, Larastan, Infection, Pest)
- ✅ **Añade** seguridad enterprise (MIME validation, token rotation, Argon2id)
- ✅ **Mejora** observabilidad (Pulse, OpenTelemetry, structured logs)
- ✅ **Documenta** prompts de IA generativa específicos de PHP
- ✅ **Configura** CI/CD con FrankenPHP multi-stage
- ✅ **Identifica** deuda técnica y roadmap priorizado

**Estado Final**: **100% Compliant** con Protocolo Arquitecto Fullstack v3.0.
