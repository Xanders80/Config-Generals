## ASP.NET Core Agent Configuration - Web API Development

# ASP.NET Core Agent Configuration
## Role
You are an ASP.NET Core development specialist with expertise in modern web application development, RESTful APIs, and best practices for scalable, secure .NET applications.

## Tech Stack
- ASP.NET Core 8.0+
- C# 12+
- Entity Framework Core
- SQL Server 2022+
- .NET CLI for development
- xUnit for testing
- Moq for mocking
- AutoMapper for object mapping
- Swagger/OpenAPI for API documentation
- Redis for caching
- Docker for containerization
- Azure for cloud deployment

## Project Structure
```
src/
├── Controllers/         # API controllers
├── Models/             # Data models
├── Services/           # Business logic
├── Repositories/       # Data access
├── DTOs/               # Data Transfer Objects
├── Extensions/         # Custom extensions
├── Middleware/         # Custom middleware
├── Filters/            # Action filters
├── Helpers/            # Utility classes
├── Migrations/         # EF Core migrations
├── appsettings.json    # Configuration
├── appsettings.Development.json # Dev config
├── appsettings.Production.json # Prod config
└── Program.cs          # Application entry point
```

## Development Commands
- `dotnet new webapi -n MyApp` - Create new web API project
- `dotnet run` - Run the application
- `dotnet watch run` - Run with auto-reload
- `dotnet build` - Build the project
- `dotnet test` - Run unit tests
- `dotnet ef migrations add InitialCreate` - Add new migration
- `dotnet ef database update` - Apply migrations
- `dotnet ef database drop` - Drop database
- `dotnet user-secrets set "ConnectionStrings:DefaultConnection" "your_connection_string"` - Set secrets
- `dotnet publish -c Release -o ./publish` - Publish the application

## Code Style Guidelines
- Follow C# coding conventions
- Use meaningful variable and method names
- Implement proper error handling
- Use async/await pattern
- Follow SOLID principles
- Write clean, readable code
- Use dependency injection properly
- Follow ASP.NET Core best practices

## Validation Rules
### Basic Field Validation
```csharp
// Model validation attributes
public class UserCreateDto
{
    [Required(ErrorMessage = "Name is required")]
    [StringLength(100, MinimumLength = 2, ErrorMessage = "Name must be between 2 and 100 characters")]
    public string Name { get; set; }

    [Required(ErrorMessage = "Email is required")]
    [EmailAddress(ErrorMessage = "Invalid email format")]
    [StringLength(255, ErrorMessage = "Email must not exceed 255 characters")]
    public string Email { get; set; }

    [Required(ErrorMessage = "Password is required")]
    [StringLength(255, MinimumLength = 8, ErrorMessage = "Password must be at least 8 characters")]
    [RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$", 
        ErrorMessage = "Password must contain at least one uppercase, one lowercase, one number")]
    public string Password { get; set; }

    [Required(ErrorMessage = "Role is required")]
    public string Role { get; set; }
}
```

### Custom Validation
```csharp
// Custom validation attribute
public class ValidPasswordAttribute : ValidationAttribute
{
    public override bool IsValid(object value)
    {
        if (value == null)
            return false;

        var password = value.ToString();
        return password.Length >= 8 && 
               password.Any(char.IsUpper) && 
               password.Any(char.IsLower) && 
               password.Any(char.IsDigit);
    }
}

// Using custom validation
public class UserCreateDto
{
    [Required]
    [StringLength(100, MinimumLength = 2)]
    public string Name { get; set; }

    [Required]
    [EmailAddress]
    [StringLength(255)]
    public string Email { get; set; }

    [Required]
    [StringLength(255, MinimumLength = 8)]
    [ValidPassword(ErrorMessage = "Password must contain at least one uppercase, one lowercase, one number and one special character")]
    public string Password { get; set; }
}
```

## User Management
### User Model
```csharp
// Entity model
public class User
{
    public int Id { get; set; }
    
    [Required]
    [StringLength(100)]
    public string Name { get; set; }
    
    [Required]
    [EmailAddress]
    [StringLength(255)]
    public string Email { get; set; }
    
    [Required]
    [StringLength(255)]
    public string PasswordHash { get; set; }
    
    public UserRole Role { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    
    // Navigation properties
    public virtual ICollection<Post> Posts { get; set; } = new List<Post>();
}

// Enum for user roles
public enum UserRole
{
    User,
    Admin,
    Manager
}
```

### Authentication with Identity
```csharp
// Program.cs configuration
var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddIdentity<ApplicationUser, IdentityRole>()
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddDefaultTokenProviders();

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]))
        };
    });

// Configure authorization
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy("ManagerOnly", policy => policy.RequireRole("Manager", "Admin"));
});

var app = builder.Build();

// Use authentication and authorization middleware
app.UseAuthentication();
app.UseAuthorization();
```

## File Management
### File Upload Handling
```csharp
// Controller with file upload
[ApiController]
[Route("api/[controller]")]
public class FilesController : ControllerBase
{
    private readonly IWebHostEnvironment _env;
    private readonly ILogger<FilesController> _logger;

    public FilesController(IWebHostEnvironment env, ILogger<FilesController> logger)
    {
        _env = env;
        _logger = logger;
    }

    [HttpPost("upload")]
    public async Task<IActionResult> UploadFile(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest("No file uploaded");

        // Validate file type
        var allowedExtensions = new[] { ".jpg", ".png", ".pdf", ".docx" };
        var fileExtension = Path.GetExtension(file.FileName).ToLower();
        
        if (!allowedExtensions.Contains(fileExtension))
            return BadRequest("Invalid file type");

        // Validate file size (5MB limit)
        if (file.Length > 5 * 1024 * 1024)
            return BadRequest("File size exceeds 5MB limit");

        try
        {
            // Generate unique filename
            var fileName = $"{Guid.NewGuid()}{fileExtension}";
            var filePath = Path.Combine(_env.WebRootPath, "uploads", fileName);

            // Ensure directory exists
            Directory.CreateDirectory(Path.GetDirectoryName(filePath));

            // Save file
            using var stream = new FileStream(filePath, FileMode.Create);
            await file.CopyToAsync(stream);

            // Return file info
            var fileUrl = $"/uploads/{fileName}";
            return Ok(new { fileName, fileUrl, fileSize = file.Length });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading file");
            return StatusCode(500, "Internal server error");
        }
    }
}
```

### File Storage Service
```csharp
// File service implementation
public interface IFileService
{
    Task<string> UploadFileAsync(IFormFile file);
    Task<Stream> DownloadFileAsync(string fileName);
    Task DeleteFileAsync(string fileName);
}

public class FileService : IFileService
{
    private readonly IWebHostEnvironment _env;
    private readonly ILogger<FileService> _logger;

    public FileService(IWebHostEnvironment env, ILogger<FileService> logger)
    {
        _env = env;
        _logger = logger;
    }

    public async Task<string> UploadFileAsync(IFormFile file)
    {
        if (file == null || file.Length == 0)
            throw new ArgumentException("No file provided");

        var fileExtension = Path.GetExtension(file.FileName);
        var fileName = $"{Guid.NewGuid()}{fileExtension}";
        var filePath = Path.Combine(_env.WebRootPath, "uploads", fileName);

        Directory.CreateDirectory(Path.GetDirectoryName(filePath));

        using var stream = new FileStream(filePath, FileMode.Create);
        await file.CopyToAsync(stream);

        return $"/uploads/{fileName}";
    }

    public async Task<Stream> DownloadFileAsync(string fileName)
    {
        var filePath = Path.Combine(_env.WebRootPath, "uploads", fileName);
        
        if (!System.IO.File.Exists(filePath))
            throw new FileNotFoundException("File not found");

        return new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read);
    }

    public async Task DeleteFileAsync(string fileName)
    {
        var filePath = Path.Combine(_env.WebRootPath, "uploads", fileName);
        
        if (System.IO.File.Exists(filePath))
        {
            await Task.Run(() => System.IO.File.Delete(filePath));
        }
    }
}
```

## Database Best Practices
### Entity Framework Core
```csharp
// DbContext configuration
public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) 
        : base(options) { }

    public DbSet<User> Users { get; set; }
    public DbSet<Post> Posts { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure relationships
        modelBuilder.Entity<User>()
            .HasMany(u => u.Posts)
            .WithOne(p => p.User)
            .HasForeignKey(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Configure enum to string conversion
        modelBuilder.Entity<User>()
            .Property(u => u.Role)
            .HasConversion<string>();
    }
}

// Repository pattern implementation
public interface IRepository<T> where T : class
{
    Task<T> GetByIdAsync(int id);
    Task<IEnumerable<T>> GetAllAsync();
    Task AddAsync(T entity);
    Task UpdateAsync(T entity);
    Task DeleteAsync(T entity);
    Task SaveChangesAsync();
}

public class Repository<T> : IRepository<T> where T : class
{
    protected readonly ApplicationDbContext _context;
    protected readonly DbSet<T> _dbSet;

    public Repository(ApplicationDbContext context)
    {
        _context = context;
        _dbSet = context.Set<T>();
    }

    public async Task<T> GetByIdAsync(int id)
    {
        return await _dbSet.FindAsync(id);
    }

    public async Task<IEnumerable<T>> GetAllAsync()
    {
        return await _dbSet.ToListAsync();
    }

    public async Task AddAsync(T entity)
    {
        await _dbSet.AddAsync(entity);
    }

    public async Task UpdateAsync(T entity)
    {
        _dbSet.Update(entity);
    }

    public async Task DeleteAsync(T entity)
    {
        _dbSet.Remove(entity);
    }

    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }
}
```

### Query Optimization
```csharp
// Service with optimized queries
public class UserService : IUserService
{
    private readonly IRepository<User> _userRepository;
    private readonly IMapper _mapper;

    public UserService(IRepository<User> userRepository, IMapper mapper)
    {
        _userRepository = userRepository;
        _mapper = mapper;
    }

    public async Task<UserDto> GetUserByIdAsync(int id)
    {
        var user = await _userRepository.GetByIdAsync(id);
        if (user == null)
            throw new KeyNotFoundException("User not found");

        return _mapper.Map<UserDto>(user);
    }

    public async Task<PagedResult<UserDto>> GetUsersAsync(int pageNumber, int pageSize)
    {
        var users = await _userRepository.GetAllAsync();
        
        // Pagination
        var pagedUsers = users
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        // Mapping
        var userDtos = _mapper.Map<List<UserDto>>(pagedUsers);

        return new PagedResult<UserDto>
        {
            Items = userDtos,
            TotalCount = users.Count,
            PageNumber = pageNumber,
            PageSize = pageSize
        };
    }

    public async Task<UserDto> CreateUserAsync(UserCreateDto userDto)
    {
        // Check if email already exists
        var existingUser = await _userRepository.GetAllAsync();
        if (existingUser.Any(u => u.Email == userDto.Email))
            throw new InvalidOperationException("Email already exists");

        var user = _mapper.Map<User>(userDto);
        user.PasswordHash = HashPassword(userDto.Password);

        await _userRepository.AddAsync(user);
        await _userRepository.SaveChangesAsync();

        return _mapper.Map<UserDto>(user);
    }
}
```

## Security Best Practices
### Input Validation
```csharp
// Controller with validation
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpPost]
    public async Task<IActionResult> CreateUser([FromBody] UserCreateDto userDto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var createdUser = await _userService.CreateUserAsync(userDto);
            return CreatedAtAction(nameof(GetUserById), new { id = createdUser.Id }, createdUser);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = ex.Message });
        }
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetUserById(int id)
    {
        try
        {
            var user = await _userService.GetUserByIdAsync(id);
            return Ok(user);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }
}
```

### Authentication Security
```csharp
// JWT Token Service
public interface IJwtTokenService
{
    string GenerateToken(User user);
    int? ValidateToken(string token);
}

public class JwtTokenService : IJwtTokenService
{
    private readonly IConfiguration _configuration;

    public JwtTokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public string GenerateToken(User user)
    {
        var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]));
        var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Role, user.Role.ToString())
        };

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.Now.AddHours(1),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public int? ValidateToken(string token)
    {
        var tokenHandler = new JwtSecurityTokenHandler();
        var key = Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]);

        try
        {
            tokenHandler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidIssuer = _configuration["Jwt:Issuer"],
                ValidAudience = _configuration["Jwt:Audience"],
                ClockSkew = TimeSpan.Zero,
                IssuerSigningKey = new SymmetricSecurityKey(key)
            }, out SecurityToken validatedToken);

            var jwtToken = (JwtSecurityToken)validatedToken;
            var userId = int.Parse(jwtToken.Claims.First(x => x.Type == ClaimTypes.NameIdentifier).Value);

            return userId;
        }
        catch
        {
            return null;
        }
    }
}
```

## Performance Optimization
### Caching
```csharp
// Service with caching
public interface IProductService
{
    Task<ProductDto> GetProductByIdAsync(int id);
    Task<IEnumerable<ProductDto>> GetProductsAsync();
}

public class ProductService : IProductService
{
    private readonly IProductRepository _productRepository;
    private readonly IMemoryCache _cache;
    private readonly ILogger<ProductService> _logger;

    public ProductService(IProductRepository productRepository, IMemoryCache cache, ILogger<ProductService> logger)
    {
        _productRepository = productRepository;
        _cache = cache;
        _logger = logger;
    }

    public async Task<ProductDto> GetProductByIdAsync(int id)
    {
        var cacheKey = $"product_{id}";
        
        if (!_cache.TryGetValue(cacheKey, out ProductDto productDto))
        {
            _logger.LogInformation("Cache miss for product {Id}", id);
            
            var product = await _productRepository.GetByIdAsync(id);
            if (product == null)
                throw new KeyNotFoundException("Product not found");

            productDto = _mapper.Map<ProductDto>(product);
            
            var cacheEntryOptions = new MemoryCacheEntryOptions()
                .SetAbsoluteExpiration(TimeSpan.FromMinutes(30));
            
            _cache.Set(cacheKey, productDto, cacheEntryOptions);
        }
        else
        {
            _logger.LogInformation("Cache hit for product {Id}", id);
        }

        return productDto;
    }

    public async Task<IEnumerable<ProductDto>> GetProductsAsync()
    {
        var cacheKey = "all_products";
        
        if (!_cache.TryGetValue(cacheKey, out IEnumerable<ProductDto> products))
        {
            _logger.LogInformation("Cache miss for all products");
            
            var allProducts = await _productRepository.GetAllAsync();
            products = _mapper.Map<IEnumerable<ProductDto>>(allProducts);
            
            var cacheEntryOptions = new MemoryCacheEntryOptions()
                .SetAbsoluteExpiration(TimeSpan.FromMinutes(15));
            
            _cache.Set(cacheKey, products, cacheEntryOptions);
        }
        else
        {
            _logger.LogInformation("Cache hit for all products");
        }

        return products;
    }
}
```

### Query Optimization
```csharp
// Repository with optimized queries
public class ProductRepository : IRepository<Product>, IProductRepository
{
    private readonly ApplicationDbContext _context;
    private readonly IMapper _mapper;

    public ProductRepository(ApplicationDbContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    public async Task<Product> GetByIdAsync(int id)
    {
        return await _context.Products
            .Include(p => p.Category)
            .FirstOrDefaultAsync(p => p.Id == id);
    }

    public async Task<IEnumerable<Product>> GetAllAsync()
    {
        return await _context.Products
            .Include(p => p.Category)
            .ToListAsync();
    }

    public async Task<PagedResult<Product>> GetPagedAsync(int pageNumber, int pageSize)
    {
        var query = _context.Products.AsQueryable();
        
        var totalItems = await query.CountAsync();
        var items = await query
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<Product>
        {
            Items = items,
            TotalCount = totalItems,
            PageNumber = pageNumber,
            PageSize = pageSize
        };
    }
}
```

## Error Handling
### Custom Exception Handling
```csharp
// Custom exceptions
public class UserNotFoundException : Exception
{
    public UserNotFoundException(string message) : base(message) { }
}

public class ProductNotFoundException : Exception
{
    public ProductNotFoundException(string message) : base(message) { }
}

// Global exception handler
public class ExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionMiddleware> _logger;

    public ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An unhandled exception occurred");
            await HandleExceptionAsync(context, ex);
        }
    }

    private static Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;

        var response = new
        {
            StatusCode = context.Response.StatusCode,
            Message = "Internal Server Error",
            Detailed = exception.Message
        };

        return context.Response.WriteAsync(JsonConvert.SerializeObject(response));
    }
}

// Program.cs configuration
app.UseMiddleware<ExceptionMiddleware>();
```

### Logging
```csharp
// Service with logging
public class OrderService : IOrderService
{
    private readonly IOrderRepository _orderRepository;
    private readonly ILogger<OrderService> _logger;

    public OrderService(IOrderRepository orderRepository, ILogger<OrderService> logger)
    {
        _orderRepository = orderRepository;
        _logger = logger;
    }

    public async Task<OrderDto> CreateOrderAsync(OrderCreateDto orderDto)
    {
        _logger.LogInformation("Creating order for user {UserId}", orderDto.UserId);
        
        try
        {
            var order = _mapper.Map<Order>(orderDto);
            await _orderRepository.AddAsync(order);
            await _orderRepository.SaveChangesAsync();

            _logger.LogInformation("Order created successfully with ID {OrderId}", order.Id);
            return _mapper.Map<OrderDto>(order);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating order for user {UserId}", orderDto.UserId);
            throw;
        }
    }
}
```

## Testing Best Practices
### Unit Testing
```csharp
// Service test
public class UserServiceTests
{
    private readonly Mock<IUserRepository> _userRepositoryMock;
    private readonly Mock<IMapper> _mapperMock;
    private readonly UserService _userService;

    public UserServiceTests()
    {
        _userRepositoryMock = new Mock<IUserRepository>();
        _mapperMock = new Mock<IMapper>();
        _userService = new UserService(_userRepositoryMock.Object, _mapperMock.Object);
    }

    [Fact]
    public async Task CreateUserAsync_ValidUser_ReturnsUserDto()
    {
        // Arrange
        var userDto = new UserCreateDto
        {
            Name = "John Doe",
            Email = "john@example.com",
            Password = "Password123!",
            Role = "User"
        };

        var user = new User
        {
            Id = 1,
            Name = "John Doe",
            Email = "john@example.com",
            Role = UserRole.User
        };

        _userRepositoryMock.Setup(r => r.GetAllAsync())
            .ReturnsAsync(new List<User>());
        
        _mapperMock.Setup(m => m.Map<User>(userDto))
            .Returns(user);
        
        _mapperMock.Setup(m => m.Map<UserDto>(user))
            .Returns(new UserDto { Id = 1, Name = "John Doe", Email = "john@example.com" });

        // Act
        var result = await _userService.CreateUserAsync(userDto);

        // Assert
        Assert.NotNull(result);
        Assert.Equal(1, result.Id);
        Assert.Equal("John Doe", result.Name);
        Assert.Equal("john@example.com", result.Email);
        
        _userRepositoryMock.Verify(r => r.AddAsync(user), Times.Once);
        _userRepositoryMock.Verify(r => r.SaveChangesAsync(), Times.Once);
    }

    [Fact]
    public async Task CreateUserAsync_DuplicateEmail_ThrowsException()
    {
        // Arrange
        var userDto = new UserCreateDto
        {
            Name = "John Doe",
            Email = "john@example.com",
            Password = "Password123!",
            Role = "User"
        };

        var existingUsers = new List<User>
        {
            new User { Id = 2, Email = "john@example.com" }
        };

        _userRepositoryMock.Setup(r => r.GetAllAsync())
            .ReturnsAsync(existingUsers);

        // Act & Assert
        await Assert.ThrowsAsync<InvalidOperationException>(() => _userService.CreateUserAsync(userDto));
    }
}
```

### Integration Testing
```csharp
// Controller test
public class UsersControllerIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;

    public UsersControllerIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetUserById_ExistingUser_ReturnsUser()
    {
        // Arrange
        var userId = 1;

        // Act
        var response = await _client.GetAsync($"/api/users/{userId}");

        // Assert
        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadAsStringAsync();
        var user = JsonConvert.DeserializeObject<UserDto>(content);

        Assert.NotNull(user);
        Assert.Equal(userId, user.Id);
    }

    [Fact]
    public async Task GetUserById_NonExistingUser_ReturnsNotFound()
    {
        // Arrange
        var userId = 999;

        // Act
        var response = await _client.GetAsync($"/api/users/{userId}");

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
```

## API Development
### REST API with DTOs
```csharp
// DTOs
public class UserDto
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Email { get; set; }
    public string Role { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class UserCreateDto
{
    [Required]
    [StringLength(100)]
    public string Name { get; set; }

    [Required]
    [EmailAddress]
    [StringLength(255)]
    public string Email { get; set; }

    [Required]
    [StringLength(255)]
    public string Password { get; set; }

    [Required]
    public string Role { get; set; }
}

// Controller
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly IMapper _mapper;

    public UsersController(IUserService userService, IMapper mapper)
    {
        _userService = userService;
        _mapper = mapper;
    }

    [HttpGet]
    public async Task<IActionResult> GetUsers([FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 10)
    {
        var pagedResult = await _userService.GetUsersAsync(pageNumber, pageSize);
        return Ok(pagedResult);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetUserById(int id)
    {
        var user = await _userService.GetUserByIdAsync(id);
        return Ok(user);
    }

    [HttpPost]
    public async Task<IActionResult> CreateUser([FromBody] UserCreateDto userDto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var createdUser = await _userService.CreateUserAsync(userDto);
        return CreatedAtAction(nameof(GetUserById), new { id = createdUser.Id }, createdUser);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateUser(int id, [FromBody] UserUpdateDto userDto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var updatedUser = await _userService.UpdateUserAsync(id, userDto);
        return Ok(updatedUser);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUser(int id)
    {
        await _userService.DeleteUserAsync(id);
        return NoContent();
    }
}
```

## Dependency Management
### Project File (csproj)
```xml
<Project Sdk="Microsoft.NET.Sdk.Web">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <UserSecretsId>aspnet-app-secrets</UserSecretsId>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="AutoMapper" Version="12.0.0" />
    <PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="8.0.0" />
    <PackageReference Include="Microsoft.AspNetCore.Identity" Version="8.0.0" />
    <PackageReference Include="Microsoft.AspNetCore.Identity.EntityFrameworkCore" Version="8.0.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore" Version="8.0.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="8.0.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="8.0.0" />
    <PackageReference Include="Swashbuckle.AspNetCore" Version="6.5.0" />
    <PackageReference Include="xunit" Version="2.4.2" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.4.5" />
    <PackageReference Include="Moq" Version="4.18.4" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.8.0" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\Data\ApplicationDbContext.csproj" />
    <ProjectReference Include="..\Models\Models.csproj" />
    <ProjectReference Include="..\Services\Services.csproj" />
  </ItemGroup>

</Project>
```

### Configuration
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=MyAppDb;Trusted_Connection=True;MultipleActiveResultSets=true"
  },
  "Jwt": {
    "Key": "your-super-secret-key-that-should-be-long-and-random",
    "Issuer": "https://localhost:7123",
    "Audience": "https://localhost:7123"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

## Deployment Best Practices
### Docker Configuration
```dockerfile
# Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["MyApp.csproj", "./"]
RUN dotnet restore "MyApp.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "MyApp.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "MyApp.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MyApp.dll"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "80:80"
    environment:
      - ConnectionStrings:DefaultConnection=Server=db;Database=MyAppDb;User Id=sa;Password=Your_password123;
    depends_on:
      - db

  db:
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=Your_password123
    ports:
      - "1433:1433"
    volumes:
      - sql-data:/var/opt/mssql/data

volumes:
  sql-data:
```

## Monitoring and Maintenance
### Health Checks
```csharp
// Health check services
public class DatabaseHealthCheck : IHealthCheck
{
    private readonly ApplicationDbContext _context;

    public DatabaseHealthCheck(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            await _context.Database.CanConnectAsync(cancellationToken);
            return HealthCheckResult.Healthy("Database connection successful");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Database connection failed", ex);
        }
    }
}

// Program.cs configuration
builder.Services.AddHealthChecks()
    .AddDbContextCheck<ApplicationDbContext>()
    .AddCheck<DatabaseHealthCheck>("Database");

app.MapHealthChecks("/health");
```

### Swagger/OpenAPI Documentation
```csharp
// Program.cs configuration
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "My ASP.NET Core Web API",
        Version = "v1",
        Description = "A sample API for demonstration purposes"
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter your JWT token in the format: Bearer {token}"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "My API V1");
    c.DefaultModelsExpandDepth(-1);
});
```
