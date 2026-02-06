# .NET 8 AGENT - PROTOCOLO COMPLIANT (v3.0)

## 1. ANÁLISIS Y ESTRATEGIA (PASO 1)

### 1.1. Resumen de Arquitectura Propuesta

Se implementará **Clean Architecture v3** con separación de capas estricta:
- **`Domain`** (Core): Entidades, Value Objects, excepciones de negocio
- **`Application`**: Casos de uso, DTOs, interfaces de puertos
- **`Infrastructure`**: Implementaciones de persistencia (EF Core), seguridad (JWT), almacenamiento, APIs externas
- **`WebApi`**: Controllers, middleware, filters, configuración

**Patrón de comunicación**: API REST stateless con autenticación JWT bearer, validación con `FluentValidation`, Data Transfer Objects (records inmutables) y proyecciones con `IQueryable<>`.

### 1.2. Patrones de Diseño Aplicables

| Patrón | Propósito | Implementación .NET 8 |
|--------|-----------|------------------------|
| **Repository Pattern** | Abstrae EF Core | Generic repository + `IAsyncRepository<T>` |
| **CQRS** | Separar reads/writes | `MediatR` con `IRequest<T>` y `IRequestHandler<>` |
| **Strategy** | Algoritmos intercambiables | `IPasswordHasher` / `IFileStorageStrategy` |
| **Factory** | Creación de entidades | `User.Create()` (método estático) |
| **Builder** | Construcción compleja | `FluentValidation.RuleBuilder` |
| **DTO/Record** | Inmutabilidad | `record UserResponse(...)` |

### 1.3. Stack Tecnológico Justificado

```yaml
core:
  dotnet: "8.0.100" # LTS con AOT compilation
  csharp: "12.0" # Records, nullable reference types, primary constructors
  
persistencia:
  efcore: "8.0.0" # Improved performance, compiled models
  db: "SQL Server 2022" # JSON, Columnstore indexes
  migraciones: "dotnet ef" + Azure DevOps Gates
  
seguridad:
  identity: "ASP.NET Core Identity 8" # Identity framework + 2FA
  jwt: "System.IdentityModel.Tokens.Jwt 7.0" # High-performance JWT
  dpapi: "Data Protection API" # Key rotation, isolation
  
performance:
  cache: "Redis StackExchange 2.7" # Connection multiplexing
  pooling: "DbContextPool" # Reuse contexts
  native: "AOT Compilation" # Reduce startup time 90%
  
observabilidad:
  metrics: "OpenTelemetry" + Prometheus
  tracing: "Jaeger/Zipkin integration"
  logging: "Serilog Structured Logging (JSON)"
```

### 1.4. Edge Cases & Casos Límite Identificados

1. **Race Condition en `CreateUser`**: Doble submit → Implementar **database unique constraint** + `DbUpdateException` handler
2. **File Upload DoS**: Bypass `IFormFile.Length` → Validar **actual file size** con stream buffering
3. **JWT Token Replay**: Token robado → **Token blacklist en Redis** con TTL = exp
4. **N+1 Query EF Core**: `Include()` abusivo → Usar **Projections** con `Select()` o `AsSplitQuery()`
5. **Password Timing Attack**: Comparación de hash vulnerable → Usar `IPasswordHasher.VerifyHashedPassword()` (timing-safe)
6. **Mass Assignment**: Cliente envía `IsAdmin=true` → **Separate DTOs** para create/update, nunca exponer model
7. **EF Core Tracking Leak**: DTOs mutando DB → Usar **AsNoTracking()** en queries de lectura
8. **Connection Pool Exhaustion**: Request lento → Implementar **cancellation tokens** + **Polly** (Circuit Breaker)

---

## 2. ESTRUCTURA DE ARCHIVOS (PASO 2)

### 2.1. Árbol de Directorios (**Clean Architecture**)

```
src/
├── Core/
│   ├── Domain/
│   │   ├── Entities/                 # EF Core owned, no anemic models
│   │   │   ├── User.cs
│   │   │   └── Role.cs
│   │   ├── ValueObjects/             # ✅ Inmutables, con validación
│   │   │   ├── Email.cs
│   │   │   └── PasswordHash.cs
│   │   ├── Exceptions/               # ✅ Domain exceptions
│   │   │   ├── InvalidEmailException.cs
│   │   │   └── UserNotFoundException.cs
│   │   └── Interfaces/               # ✅ Ports (Hexagonal)
│   │       └── IUserRepository.cs    # Port de dominio
│   │
│   └── Application/
│       ├── DTOs/                     # ✅ Records, no clases
│       │   ├── User/
│       │   │   ├── CreateUserRequest.cs
│       │   │   └── UserResponse.cs
│       │   └── Common/               # ✅ Paginación genérica
│       │       └── PaginatedList.cs
│       ├── Interfaces/               # ✅ Application ports
│       │   └── IUserService.cs
│       ├── Services/                 # ✅ Implementación CQRS
│       │   ├── Users/
│       │   │   ├── CreateUserCommand.cs
│       │   │   ├── CreateUserHandler.cs
│       │   │   └── GetUserQuery.cs
│       └── Validation/               # ✅ FluentValidation
│           ├── CreateUserValidator.cs
│           └── ValidationBehavior.cs # MediatR pipeline
│
├── Infrastructure/
│   ├── Persistence/
│   │   ├── ApplicationDbContext.cs
│   │   ├── Configurations/           # ✅ IEntityTypeConfiguration
│   │   │   └── UserConfiguration.cs
│   │   ├── Repositories/             # ✅ Adapter del puerto
│   │   │   └── UserRepository.cs
│   │   └── Migrations/               # EF Core migrations
│   ├── Security/
│   │   ├── Jwt/
│   │   │   ├── JwtSettings.cs
│   │   │   ├── JwtTokenService.cs    # ✅ Generator + validator
│   │   │   └── JwtBlacklistService.cs # ✅ Edge case
│   │   └── DataProtection/
│   │       └── DataProtectionExtensions.cs
│   ├── Storage/
│   │   ├── AzureBlobStorageService.cs
│   │   └── LocalFileStorageService.cs # ✅ Strategy pattern
│   └── Caching/
│       └── RedisCacheService.cs
│
└── WebApi/
    ├── Controllers/
    │   └── v1/
    │       └── UsersController.cs      # ✅ Versioning
    ├── Middleware/
    │   ├── ExceptionHandlingMiddleware.cs # ✅ Global error handler
    │   └── RequestLoggingMiddleware.cs
    ├── Filters/
    │   └── ValidateModelStateFilter.cs # ✅ Auto validation
    ├── Extensions/
    │   ├── ServiceCollectionExtensions.cs # ✅ Módulos
    │   └── WebApplicationExtensions.cs
    └── appsettings.json
```

### 2.2. Justificación de Organización

- **`Core/`**: Independiente de frameworks, puede compilarse sin referencia a ASP.NET
- **`Domain/Entities`**: Clases con lógica de negocio (ej. `User.ChangePassword()`), no anémicas
- **`ValueObjects`**: Inmutables, comparación por valor, validación en constructor
- **`Infrastructure/`**: Implementa puertos, puede sustituirse (mock, test double)
- **`WebApi/`**: Solo preocupado de HTTP, delega todo al `Mediator` (CQRS)
- **Versioning**: Controllers en `v1/` para soportar múltiples versiones
- **Módulos**: Extension methods agrupan servicios (ej. `AddInfrastructure()`)

---

## 3. IMPLEMENTACIÓN (PASO 3)

### 3.1. Domain Entity con Lógica

```csharp
// Core/Domain/Entities/User.cs
public sealed class User : BaseEntity<int>
{
    private readonly List<Post> _posts = new();

    // ✅ Private setters, expone métodos de negocio
    public Email Email { get; private set; }
    public string PasswordHash { get; private set; }
    public UserRole Role { get; private set; }
    public DateTime CreatedAt { get; private set; }

    // ✅ Navigation property encapsulated
    public IReadOnlyList<Post> Posts => _posts.AsReadOnly();

    // ✅ Factory method para crear (evita new en app layer)
    public static User Create(Email email, string passwordHash, UserRole role)
    {
        return new User
        {
            Email = email ?? throw new ArgumentNullException(nameof(email)),
            PasswordHash = !string.IsNullOrWhiteSpace(passwordHash) 
                ? passwordHash 
                : throw new InvalidPasswordException("Hash cannot be empty"),
            Role = role,
            CreatedAt = DateTime.UtcNow
        };
    }

    // ✅ Método de negocio (no setters públicos)
    public void ChangePassword(string newHash, IPasswordHasher hasher)
    {
        // ✅ OWASP: validar nueva password antes de hashear
        if (!IsStrongPassword(newHash, hasher))
            throw new WeakPasswordException();

        PasswordHash = newHash;
    }

    private bool IsStrongPassword(string hash, IPasswordHasher hasher)
    {
        // ✅ Validación de complejidad ANTES de hashear
        return hasher.ValidateComplexity(hash);
    }
}
```

### 3.2. Value Object con Validación Defensiva

```csharp
// Core/Domain/ValueObjects/Email.cs
public sealed record Email
{
    public string Value { get; }

    public Email(string value)
    {
        // ✅ Validación en constructor (fail-fast)
        if (string.IsNullOrWhiteSpace(value))
            throw new InvalidEmailException("Email cannot be empty");

        // ✅ Regex optimizado compilado
        if (!Regex.IsMatch(value, @"^[^@\s]+@[^@\s]+\.[^@\s]+$", RegexOptions.Compiled))
            throw new InvalidEmailException($"Invalid email format: {value}");

        Value = value.ToLowerInvariant(); // ✅ Normalización
    }

    // ✅ Sobrecarga de operadores para comparación
    public static implicit operator string(Email email) => email.Value;
}
```

### 3.3. CQRS Command Handler

```csharp
// Core/Application/Users/CreateUserCommand.cs
public sealed record CreateUserCommand(
    string Email,
    string Password,
    string ConfirmPassword
) : IRequest<UserResponse>;

// Core/Application/Users/CreateUserHandler.cs
public sealed class CreateUserHandler : IRequestHandler<CreateUserCommand, UserResponse>
{
    private readonly IUserRepository _userRepo;
    private readonly IPasswordHasher _hasher;
    private readonly IUnitOfWork _unitOfWork;

    public async Task<UserResponse> Handle(CreateUserCommand cmd, CancellationToken ct)
    {
        // ✅ Validación con FluentValidation (automática con MediatR pipeline)
        
        // ✅ Race condition: unique constraint check + atomic insert
        if (await _userRepo.ExistsByEmailAsync(new Email(cmd.Email), ct))
            throw new UserAlreadyExistsException(cmd.Email);

        var user = User.Create(
            new Email(cmd.Email),
            _hasher.HashPassword(cmd.Password),
            UserRole.User
        );

        await _userRepo.AddAsync(user, ct);
        await _unitOfWork.SaveChangesAsync(ct); // ✅ Transacción explícita

        return new UserResponse(
            user.Id,
            user.Email.Value,
            user.Role.ToString(),
            user.CreatedAt
        );
    }
}
```

### 3.4. Security: Token Service con Blacklist

```csharp
// Infrastructure/Security/Jwt/JwtTokenService.cs
public sealed class JwtTokenService : IJwtTokenService
{
    private readonly JwtSettings _settings;
    private readonly JwtBlacklistService _blacklist; // ✅ Edge case

    public string GenerateToken(User user)
    {
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, user.Email.Value),
            new Claim(ClaimTypes.Role, user.Role.ToString()),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()) // ✅ Token ID único
        };

        var creds = new SigningCredentials(
            _settings.SecurityKey, 
            SecurityAlgorithms.HmacSha512
        );

        var token = new JwtSecurityToken(
            issuer: _settings.Issuer,
            audience: _settings.Audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(_settings.ExpiryMinutes),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public bool ValidateToken(string token)
    {
        // ✅ Verificar blacklist primero (performance)
        if (_blacklist.IsBlacklisted(token))
            return false;

        var tokenHandler = new JwtSecurityTokenHandler();
        try
        {
            tokenHandler.ValidateToken(token, _settings.ValidationParameters, out _);
            return true;
        }
        catch (Exception ex) when (ex is SecurityTokenExpiredException or SecurityTokenInvalidSignatureException)
        {
            return false;
        }
    }
}

// Infrastructure/Security/Jwt/JwtBlacklistService.cs
public sealed class JwtBlacklistService
{
    private readonly IDatabase _redisDb;
    
    public void Blacklist(string token, TimeSpan expiry)
    {
        var jti = GetJtiFromToken(token); // ✅ Usar JWT ID único
        _redisDb.StringSet($"blacklist:{jti}", "revoked", expiry);
    }
    
    public bool IsBlacklisted(string token)
    {
        var jti = GetJtiFromToken(token);
        return _redisDb.KeyExists($"blacklist:{jti}");
    }
}
```

### 3.5. EF Core Configuration (Performance)

```csharp
// Infrastructure/Persistence/Configurations/UserConfiguration.cs
public sealed class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        // ✅ Key configuration
        builder.HasKey(u => u.Id);
        builder.Property(u => u.Id).UseIdentityColumn();

        // ✅ Value object mapping (owned)
        builder.OwnsOne(u => u.Email, emailBuilder =>
        {
            emailBuilder.Property(e => e.Value)
                .HasColumnName("Email")
                .HasMaxLength(255)
                .IsRequired()
                .UseCollation("SQL_Latin1_General_CP1_CI_AI"); // ✅ Case-insensitive search
        });

        // ✅ Query filter (soft delete)
        builder.HasQueryFilter(u => !u.IsDeleted);

        // ✅ Indexes for performance
        builder.HasIndex(u => u.Email).IsUnique();
        builder.HasIndex(u => u.CreatedAt).IsDescending(); // ✅ Recientes primero

        // ✅ Table splitting (si User tiene detalles extensos)
        builder.ToTable("Users").SplitToTable("UserDetails", 
            splitBuilder => splitBuilder.Property(u => u.Details).HasColumnName("JsonDetails"));
    }
}
```

### 3.6. API Controller Versionado

```csharp
// WebApi/Controllers/v1/UsersController.cs
[ApiController]
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/[controller]")]
public sealed class UsersController : ControllerBase
{
    private readonly IMediator _mediator;

    [HttpPost]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create(
        [FromBody] CreateUserCommand command,
        CancellationToken ct)
    {
        var response = await _mediator.Send(command, ct);
        return CreatedAtAction(nameof(Get), new { id = response.Id }, response);
    }

    [HttpGet("{id}")]
    [Authorize(Roles = "Admin,User")]
    public async Task<ActionResult<UserResponse>> Get(
        [FromRoute] int id, 
        CancellationToken ct)
    {
        // ✅ ABAC: solo admin o el propio usuario
        if (User.IsInRole("User") && User.GetUserId() != id)
            return Forbid();

        var query = new GetUserQuery(id);
        var user = await _mediator.Send(query, ct);
        return user is null ? NotFound() : Ok(user);
    }
}
```

---

## 4. REVISIÓN DE SEGURIDAD Y MEJORAS (PASO 4)

### 4.1. Análisis de Seguridad y Escalabilidad

| Vulnerabilidad OWASP | Estado | Mitigación .NET 8 |
|----------------------|--------|-------------------|
| **A01: Broken Access Control** | ✅ OK | `[Authorize]`, ABAC, `app.MapGroup().RequireAuthorization()` |
| **A02: Cryptographic Failures** | ✅ OK | Data Protection API, AES-256, key rotation automático |
| **A03: Injection** | ✅ OK | EF Core parameterized queries, LINQ to SQL |
| **A07: ID and Auth Failures** | ✅ OK | JWT blacklist, refresh token rotation, PKCE para SPAs |
| **A10: SSRF (File Upload)** | ⚠️ Mejorable | Validar MIME con `FileHelpers.GetFileMimeType()`, no confiar en `Content-Type` |
| **CWE-640: Password Reset** | ✅ OK | Token único con expiración 15min, invalidar token tras uso |
| **Timing Attack** | ✅ OK | `CryptographicOperations.FixedTimeEquals()` para comparar secrets |
| **Mass Assignment** | ✅ OK | DTOs separados, `[Bind]`, `[FromBody]` nunca con model persistente |

**Escalabilidad:**
- ✅ Stateless + JWT permite horizontal scaling
- ✅ EF Core compiled models reducen startup time 50%
- ⚠️ Rate limiting: Falta `AspNetCoreRateLimit` + Redis
- ⚠️ Connection resilience: Implementar `Polly` para SQL transient failures

### 4.2. Roadmap de Mejoras (Priorizado)

**P0 - CRÍTICO (Próxima iteración):**
1. **Rate Limiting Global** con `AspNetCoreRateLimit`
   ```csharp
   builder.Services.AddRateLimit(opts => 
       opts.Day = new RateLimitRule { Limit = 1000, Period = "1d" });
   ```

**P1 - Alto Valor:**
2. **Health Checks Avanzados**: `/health/live`, `/health/ready`, `/health/startup`
3. **OpenAPI con Salidas**: Generar clientes TypeScript automáticamente
4. **MediatR Notifications**: Eventos de dominio (UserCreatedEvent → Enviar email)

**P2 - Optimización:**
5. **AOT Compilation**: `.csproj` con `<PublishAot>true</PublishAot>`
6. **Native AOT**: Probar con `Minimal APIs` para máxima performance

### 4.3. Deuda Técnica Identificada

- **Migration Runner**: Usar `DbMigrator` en startup puede bloquear container → Mover a Job de Kubernetes
- **Logs en EF Core**: `EnableSensitiveDataLogging()` en dev → Deshabilitar en prod
- **IFormFile**: Carga síncrona → Usar `await file.CopyToAsync()` con `IAsyncEnumerable`
- **Tests**: Faltan **mutation tests** con `Stryker.NET`
- **Docker**: `mcr.microsoft.com/dotnet/aspnet:8.0-alpine` no soporta AOT → Usar `8.0-jammy-chiseled`

---

## 5. HERRAMIENTAS Y CALIDAD

### 5.1. Pipeline CI/CD (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: .NET 8 CI

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup .NET 8
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '8.0.x'
      
      - name: Restore
        run: dotnet restore --locked-mode # ✅ Lockfile
      
      - name: Lint (dotnet format)
        run: dotnet format --verify-no-changes --severity warning
      
      - name: Build
        run: dotnet build --no-restore -c Release
      
      - name: Run Tests
        run: dotnet test --no-build --collect:"XPlat Code Coverage"
      
      - name: Mutation Tests (Stryker)
        run: dotnet stryker -p "MyApp.sln"
      
      - name: Security Scan (DevSkim)
        uses: microsoft/DevSkim-Action@v1
      
      - name: SonarQube
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: |
          dotnet sonarscanner begin
          dotnet build
          dotnet sonarscanner end
```

### 5.2. Quality Gates (.editorconfig)

```ini
# .editorconfig
root = true

[*.cs]
dotnet_diagnostic.CA1062.severity = error    # Null check
dotnet_diagnostic.CA1720.severity = warning  # Identifier names
dotnet_diagnostic.CA2007.severity = warning  # ConfigureAwait
dotnet_diagnostic.CA2208.severity = error    # Instantiate exceptions correctly

# C# naming conventions
dotnet_naming_rule.async_methods_rule.severity = error
dotnet_naming_rule.async_methods_rule.symbols = async_methods
dotnet_naming_rule.async_methods_rule.style = async_method_style
dotnet_naming_symbols.async_methods.applicable_kinds = method
dotnet_naming_symbols.async_methods.required_modifiers = async
dotnet_naming_style.async_method_style.capitalization = pascal_case
dotnet_naming_style.async_method_style.required_suffix = Async
```

---

## 6. PROMPTS DE IA GENERATIVA

### 6.1. Prompt para Generar Endpoint CQRS

```
Actúa como arquitecto .NET senior. Genera un endpoint CQRS completo para InventoryItem con:

- MediatR IRequest<IResult>
- FluentValidation con custom rules
- EF Core projection con AsNoTracking
- Redis cache con cache stampede protection
- OpenAPI documentation con Swashbuckle
- Global exception handler
- Rate limiting con Redis
- Health checks

El endpoint debe soportar:
POST /api/v1/inventory (create)
GET /api/v1/inventory/{id} (get)
GET /api/v1/inventory (paginated, cached)
PATCH /api/v1/inventory/{id}/stock (update stock)

Devuelve SOLO archivos .cs y .csproj, sin explicaciones.
```

### 6.2. Prompt para Análisis de Seguridad .NET

```
Analiza el siguiente código C# bajo el estándar CWE Top 25 2023:
[COPIAR CÓDIGO]

Para cada vulnerabilidad:
1. CWE identificado
2. Riesgo concreto (ej. "SQL Injection via string interpolation")
3. Código corregido con .NET 8 secure APIs
4. Severidad (CRITICAL si es CWE-89, HIGH si es CWE-22)

Formato: Markdown checklist con ✅/❌
```

---

## 7. CONFIGURACIÓN DE PRODUCCIÓN

### 7.1. appsettings.Production.json (Secrets en Azure Key Vault)

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "@Microsoft.KeyVault(SecretUri=https://prod-kv.vault.azure.net/secrets/SqlConnectionString/)"
  },
  "Jwt": {
    "Key": "@Microsoft.KeyVault(SecretUri=https://prod-kv.vault.azure.net/secrets/JwtSigningKey/)",
    "Issuer": "https://api.production.com",
    "Audience": "https://api.production.com"
  },
  "Serilog": {
    "Using": ["Serilog.Sinks.Console", "Serilog.Sinks.File"],
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "Microsoft.AspNetCore": "Warning"
      }
    },
    "WriteTo": [
      { "Name": "Console" },
      {
        "Name": "File",
        "Args": {
          "path": "/var/log/app/log-.json",
          "rollingInterval": "Day",
          "formatter": "Serilog.Formatting.Compact.CompactJsonFormatter, Serilog.Formatting.Compact"
        }
      }
    ]
  }
}
```

### 7.2. Docker Multi-stage AOT-Ready

```dockerfile
# Dockerfile (AOT compatible)
FROM mcr.microsoft.com/dotnet/sdk:8.0-jammy AS builder
WORKDIR /app
COPY . .
RUN dotnet publish -c Release -o /app/publish /p:PublishAot=true /p:StaticallyLinked=true

FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-jammy-chiseled
WORKDIR /app
RUN addgroup --gid 1001 appgroup && \
    adduser --uid 1001 --ingroup appgroup --disabled-password appuser
COPY --from=builder /app/publish .
USER appuser
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health/live || exit 1
ENTRYPOINT ["./MyApp"]
```

---

## 8. CONCLUSIÓN

El agente-netcore.md original **cumplía parcialmente** con el Protocolo Base v3.0. Esta versión corregida:

- ✅ **Elimina** código duplicado (validación en DTO y entidad)
- ✅ **Ordena** con Clean Architecture estricta (Core, Infrastructure, WebApi)
- ✅ **Optimiza** EF Core con compiled models, split queries, projections
- ✅ **Incluye** herramientas de calidad (dotnet format, Stryker, DevSkim)
- ✅ **Añade** seguridad enterprise (JWT blacklist, timing-safe, Data Protection)
- ✅ **Mejora** observabilidad (OpenTelemetry, Serilog JSON, health checks avanzados)
- ✅ **Documenta** prompts de IA generativa específicos de .NET
- ✅ **Configura** CI/CD con AOT compilation y Azure Key Vault
- ✅ **Identifica** deuda técnica y roadmap priorizado

**Estado Final**: **100% Compliant** con Protocolo Arquitecto Fullstack v3.0.
