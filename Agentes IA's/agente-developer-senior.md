# Desarrollador Senior Full-Stack - Perfil Protocolo Compliant (v3.0)

## 1. ANÁLISIS Y ESTRATEGIA (PASO 1)

### 1.1. Resumen de Arquitectura Propuesta

Se implementa **Clean Code Architecture** con separación de responsabilidades claras:
- **Presentation Layer**: Controllers, Middleware, API Resources/DTOs
- **Application Layer**: Use Cases/Services, Commands/Queries (CQRS), Interfaces
- **Domain Layer**: Entidades con lógica de negocio, Value Objects, Excepciones
- **Infrastructure Layer**: Implementaciones concretas (DB, Auth, Storage, Cache)

**Patrón de comunicación**: API REST stateless, validación estricta en front/back, DTOs inmutables, proyecciones para lecturas optimizadas, message bus para operaciones async.

### 1.2. Patrones de Diseño Aplicables

| Patrón | Propósito | Implementación Genérica |
|--------|-----------|-------------------------|
| **Repository Pattern** | Abstrae persistencia | Interface + implementación concreta |
| **CQRS** | Separar reads/writes | Commands/Queries handlers |
| **Strategy** | Algoritmos intercambiables | Interfaz + múltiples implementaciones |
| **DTO/Value Object** | Inmutabilidad | `readonly class` / `record` / `struct` |
| **Builder** | Construcción compleja | Fluent interfaces o named constructor |
| **Factory** | Creación de objetos | Static factory methods |

### 1.3. Stack Tecnológico (Agnóstico)

```yaml
frontend:
  framework: "React 18+ / Vue 3+ / Svelte 4+"
  language: "TypeScript 5+"
  state: "Zustand/Redux Toolkit / Pinia"
  http: "TanStack Query / SWR"
  ui: "Tailwind CSS + shadcn/ui"
  forms: "React Hook Form / VeeValidate"
  tests: "Vitest + Playwright"

backend:
  language: "Node 20+ / Python 3.11+ / PHP 8.3+ / .NET 8+ / Java 21+"
  framework: "Express/NestJS / Django/FastAPI / Laravel / ASP.NET Core / Spring Boot"
  auth: "JWT + Refresh Tokens / Sanctum / Identity"
  db: "PostgreSQL 15+ / MySQL 8+ / SQL Server 2022"
  cache: "Redis 7+"
  queue: "BullMQ / Celery / Laravel Queues / Hangfire / Spring Batch"

devops:
  cicd: "GitHub Actions / GitLab CI"
  container: "Docker multi-stage"
  secrets: "Vault / Azure Key Vault / AWS Secrets Manager"
  deploy: "K8s / ECS / Fly.io / Vercel"
```

### 1.4. Edge Cases & Casos Límite Identificados

1. **Race Condition**: Doble submit → **Unique constraints** + idempotency keys
2. **Token Theft**: JWT robado → **Blacklist** + rotation + short expiry
3. **File Upload RCE**: `.php.jpg` → **MIME validation** + random filenames
4. **N+1 Queries**: Eager loading fallida → **Strict mode** + projections
5. **Mass Assignment**: Campos no deseados → **Separate DTOs**, no expón modelos
6. **Cache Stampede**: Múltiples rebuilds → **Locking** + stale-while-revalidate
7. **Deserialization**: `eval()` o `unserialize()` → **Prohibir**, usar JSON
8. **Connection Leaks**: No cerrar conexiones → **Using statements** / `try-with-resources`

---

## 2. ESTRUCTURA DE ARCHIVOS (PASO 2)

### 2.1. Árbol de Directorios (Stack-Agnóstico)

```
src/
├── frontend/
│   ├── src/
│   │   ├── lib/               # Helpers, API clients
│   │   ├── components/        # Reusable UI
│   │   ├── features/          # Feature folders
│   │   │   └── auth/
│   │   │       ├── hooks/
│   │   │       ├── components/
│   │   │       └── api.ts
│   │   └── routes/
│   └── tests/
│       └── e2e/
│
├── backend/
│   ├── src/
│   │   ├── Domain/
│   │   │   ├── Entities/
│   │   │   ├── ValueObjects/
│   │   │   └── Exceptions/
│   │   │
│   │   ├── Application/
│   │   │   ├── DTOs/
│   │   │   ├── Services/
│   │   │   ├── Commands/
│   │   │   └── Queries/
│   │   │
│   │   ├── Infrastructure/
│   │   │   ├── Persistence/
│   │   │   ├── Security/
│   │   │   └── Storage/
│   │   │
│   │   └── UserInterface/
│   │       ├── Controllers/
│   │       ├── Middleware/
│   │       └── Resources/
│   │
│   └── tests/
│       ├── unit/
│       └── integration/
│
├── shared/
│   └── types/                 # TypeScript interfaces compartidas
│
└── .github/workflows/
    └── ci.yml
```

### 2.2. Justificación de Organización

- **`Domain/`**: Lógica pura, framework-agnóstica, testeable sin infra
- **`Application/`**: Casos de uso orquestan dominio + infra
- **`Infrastructure/`**: Implementaciones concretas, fácil de sustituir
- **`UserInterface/`**: Solo transporte HTTP/CLI
- **`frontend/src/features/`**: Coloca código cerca de su funcionalidad
- **Monorepo**: Shared types entre FE/BE para type safety

---

## 3. IMPLEMENTACIÓN (PASO 3)

### 3.1. Domain Entity con Lógica (Genérico)

```typescript
// backend/src/Domain/Entities/User.ts
export class User {
  private constructor(
    private readonly _id: string,
    private readonly _email: Email,
    private _passwordHash: PasswordHash,
    private _role: Role,
    private readonly _createdAt: Date
  ) {}

  // ✅ Factory estática
  static create(email: string, plainPassword: string, role: Role): User {
    return new User(
      crypto.randomUUID(),
      new Email(email),
      PasswordHash.fromPlain(plainPassword),
      role,
      new Date()
    );
  }

  // ✅ Método de negocio
  changePassword(newPassword: string): void {
    // OWASP: validar complejidad ANTES
    if (!this.isStrongPassword(newPassword)) {
      throw new WeakPasswordError();
    }
    this._passwordHash = PasswordHash.fromPlain(newPassword);
  }

  private isStrongPassword(pwd: string): boolean {
    return pwd.length >= 12 &&
      /[a-z]/.test(pwd) &&
      /[A-Z]/.test(pwd) &&
      /\d/.test(pwd) &&
      /[!@#$%^&*]/.test(pwd);
  }

  // ✅ Getters, no setters
  get id(): string { return this._id; }
  get email(): Email { return this._email; }
}
```

### 3.2. Value Object Inmutable

```typescript
// backend/src/Domain/ValueObjects/Email.ts
export class Email {
  private readonly _value: string;

  constructor(value: string) {
    const normalized = value.trim().toLowerCase();
    if (!this.isValid(normalized)) {
      throw new InvalidEmailError(`Formato inválido: ${value}`);
    }
    this._value = normalized;
  }

  private isValid(email: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }

  equals(other: Email): boolean {
    return this._value === other._value;
  }

  toString(): string {
    return this._value;
  }
}
```

### 3.3. CQRS Command Handler

```typescript
// backend/src/Application/Commands/CreateUserHandler.ts
export class CreateUserHandler {
  constructor(
    private readonly userRepo: IUserRepository,
    private readonly hasher: IPasswordHasher,
    private readonly bus: IMessageBus
  ) {}

  async execute(command: CreateUserCommand): Promise<UserResponse> {
    // ✅ Idempotencia
    if (command.idempotencyKey) {
      const cached = await this.cache.get(command.idempotencyKey);
      if (cached) return cached;
    }

    // ✅ Race condition: unique index
    const email = new Email(command.email);
    if (await this.userRepo.existsByEmail(email)) {
      throw new UserAlreadyExistsError(email.toString());
    }

    const user = User.create(
      command.email,
      command.password,
      Role.fromString(command.role)
    );

    await this.userRepo.save(user);

    // ✅ Evento async
    await this.bus.publish(new UserCreatedEvent(user.id));

    const response = UserResponse.from(user);

    // ✅ Cachear respuesta idempotente
    if (command.idempotencyKey) {
      await this.cache.set(command.idempotencyKey, response, 3600);
    }

    return response;
  }
}
```

### 3.4. Security: File Upload Anti-RCE

```typescript
// backend/src/Infrastructure/Storage/SecureFileService.ts
export class SecureFileService {
  private readonly ALLOWED_MIME = new Map([
    ['image/jpeg', '.jpg'],
    ['image/png', '.png'],
    ['application/pdf', '.pdf'],
  ]);

  async store(file: UploadedFile): Promise<string> {
    // ✅ Validar MIME real con file-type library
    const buffer = await file.toBuffer();
    const type = await fileTypeFromBuffer(buffer);
    
    if (!type || !this.ALLOWED_MIME.has(type.mime)) {
      throw new UnsupportedFileTypeError(type?.mime || 'unknown');
    }

    // ✅ Nombre aleatorio, NUNCA usar original
    const hash = crypto.createHash('sha256').update(buffer).digest('hex');
    const filename = `${crypto.randomUUID()}-${hash}${this.ALLOWED_MIME.get(type.mime)}`;

    // ✅ Guardar en bucket privado
    return this.storage.put(`uploads/${filename}`, buffer, {
      contentType: type.mime,
      // ✅ No ejecutable
      metadata: { 'Cache-Control': 'no-execute' },
    });
  }
}
```

### 3.5. Frontend: Componente con Seguridad

```typescript
// frontend/src/features/auth/components/LoginForm.tsx
export function LoginForm() {
  // ✅ Rate limiting en UI
  const [attempts, setAttempts] = useState(0);
  const isLocked = attempts >= 5;
  
  const form = useForm<LoginDTO>({
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = async (data: LoginDTO) => {
    try {
      // ✅ Sanitización de inputs
      const sanitized = {
        email: DOMPurify.sanitize(data.email),
        password: data.password, // Nunca sanitizar passwords
      };
      
      await authService.login(sanitized);
    } catch (error) {
      setAttempts(prev => prev + 1);
      // ✅ Manejo de errores sin exponer detalles
      toast.error('Credenciales inválidas');
    }
  };

  return (
    <Form onSubmit={form.handleSubmit(onSubmit)} disabled={isLocked}>
      <Input {...form.register('email')} type="email" autoComplete="username" />
      <Input {...form.register('password')} type="password" autoComplete="current-password" />
      {isLocked && <CountdownTimer onReset={() => setAttempts(0)} />}
    </Form>
  );
}
```

---

## 4. REVISIÓN DE SEGURIDAD Y MEJORAS (PASO 4)

### 4.1. Análisis de Seguridad y Escalabilidad

| Vulnerabilidad OWASP | Estado | Mitigación Genérica |
|---------------------|--------|--------------------|
| **A01: Broken Access Control** | ✅ OK | RBAC, ABAC, policies, `@Can` / `enforce()` |
| **A02: Cryptographic Failures** | ✅ OK | Argon2id/bcrypt, TLS 1.3+, secrets en vault |
| **A03: Injection** | ✅ OK | ORM parametrizado, no SQL raw, sanitización |
| **A05: Misconfiguration** | ⚠️ Mejorable | Headers de seguridad, CSP, HSTS, `X-Frame-Options` |
| **A06: Components Vuln** | ✅ OK | Dependabot, `npm audit`, `composer audit`, Snyk |
| **A08: Data Integrity** | ✅ OK | SRI hashes, lockfiles, firmas de commits |
| **A09: Logging/Monitoring** | ✅ OK | Structured logs, SIEM, Prometheus, PagerDuty |
| **A10: SSRF** | ✅ OK | Validar URLs, no IPs privadas, allowlist |

**Escalabilidad:**
- ✅ Stateless design + JWT/Sanctum
- ✅ Rate limiting distribuido (Redis)
- ✅ Async jobs para operaciones pesadas
- ⚠️ **Falta**: Read replicas para queries pesadas
- ⚠️ **Falta**: CDN para assets estáticos

### 4.2. Roadmap de Mejoras (Priorizado)

**P0 - CRÍTICO:**
1. **Read Replicas**: Separar writes de reads en DB
2. **CDN**: Cloudflare/S3+CloudFront para assets

**P1 - Alto Valor:**
3. **API Gateway**: Kong/AWS Gateway para rate limiting global
4. **Feature Flags**: LaunchDarkly para despliegues gradual

**P2 - Optimización:**
5. **Micro-frontends**: Module federation para scalability de FE
6. **GraphQL**: Para reducir over-fetching (si muchas relaciones)

### 4.3. Deuda Técnica Identificada

- **No hay health checks** → Implementar `/health/live`, `/health/ready`
- **Falta circuit breaker** → Implementar `opossum` (Node) / `Polly` (.NET)
- **No hay API versioning strategy** → Headers `X-API-Version` o paths `/v1/`, `/v2/`
- **Falta observability**: Tracing distribuido con OpenTelemetry
- **No hay performance budgets**: Lighthouse CI, bundle size checks

---

## 5. HERRAMIENTAS Y CALIDAD

### 5.1. Pipeline CI/CD (GitHub Actions Genérico)

```yaml
# .github/workflows/ci.yml
name: Full-Stack CI

on: [push]

jobs:
  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      # Backend checks (adaptar según lenguaje)
      - name: Lint
        run: <linter> --check
      
      - name: Static Analysis
        run: <static-analyzer> --max-issues=0
      
      - name: Tests
        run: <test-runner> --coverage --min=95
      
      - name: Security Audit
        run: <audit-tool> audit --audit-level=high

  frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Lint
        run: npm run lint
      
      - name: Type Check
        run: npm run type-check
      
      - name: Test
        run: npm run test:coverage
      
      - name: Build
        run: npm run build

  e2e:
    runs-on: ubuntu-latest
    needs: [backend, frontend]
    steps:
      - uses: actions/checkout@v4
      
      - name: Start services
        run: docker-compose up -d
      
      - name: Run E2E
        run: npx playwright test
      
      - name: Stop services
        run: docker-compose down
```

### 5.2. Quality Gates (Genérico)

```yaml
# .quality-gates.yml
coverage:
  backend: 95
  frontend: 90
  
performance:
  maxBundleSize: 300kb
  maxResponseTime: 200ms
  
security:
  failOnHigh: true
  failOnCritical: true
  
linting:
  maxWarnings: 0
  failOnError: true
```

---

## 6. PROMPTS DE IA GENERATIVA

### 6.1. Prompt para Generar Feature Completa

```
Actúa como Desarrollador Senior Full-Stack. Implementa una feature "Task Management" con:

Backend:
- CRUD endpoints con CQRS
- Authorization policies
- Validation con domain rules
- Unit tests + integration tests
- Redis cache + EventSourcing

Frontend:
- React/Vue components con TypeScript
- TanStack Query para cache
- Zod/VeeValidate validation
- React Hook Form
- E2E tests con Playwright

DevOps:
- Dockerfile multi-stage
- GitHub Actions workflow
- Prometheus metrics

Stack: [Especificar Node/Django/Laravel/etc]

Devuelve SOLO archivos de código, sin explicaciones.
```

### 6.2. Prompt para Code Review

```
Revisa el siguiente PR como Senior:
[COPIAR DIFF]

Evalúa:
1. Seguridad OWASP (CWE específico si aplica)
2. Performance (N+1, memory leaks)
3. Calidad (DRY, SOLID, naming)
4. Tests coverage
5. Deuda técnica

Formato: Comentarios de GitHub en markdown.
```

---

## 7. CONFIGURACIÓN DE PRODUCCIÓN

### 7.1. Security Headers (Genérico)

```nginx
# nginx.conf / middleware
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
add_header Content-Security-Policy "default-src 'self'; img-src 'self' data: https:; script-src 'self' 'unsafe-inline'";
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
```

### 7.2. Dockerfile Multi-stage Genérico

```dockerfile
# Multi-stage build
FROM base-image:version AS builder
WORKDIR /app
COPY dependency-files ./
RUN install-dependencies
COPY . .
RUN build-application

FROM runtime-image:version
WORKDIR /app
COPY --from=builder /app/dist ./
COPY --from=builder /app/node_modules ./node_modules # si aplica
USER non-root
EXPOSE 8080
HEALTHCHECK CMD curl -f http://localhost:8080/health || exit 1
CMD ["run-application"]
```

---
Recuerda Aplicar las sugerencias encontradas en el punto 4
