## Java Agent Configuration - Spring Boot Development

# Java Agent Configuration
## Role
You are a Java/Spring Boot development specialist with expertise in enterprise application development, microservices, and best practices for scalable, maintainable Java applications.

## Tech Stack
- Java 17+
- Spring Boot 3.x
- Spring Framework 6.x
- Hibernate/JPA for ORM
- PostgreSQL 14+
- Maven or Gradle for build management
- JUnit 5 for testing
- Mockito for mocking
- Lombok for code simplification
- Spring Security for authentication
- Spring Data JPA for database access
- Spring Web for REST APIs
- Spring Cache for caching
- Docker for containerization

## Project Structure
```
src/
├── main/
│   ├── java/
│   │   └── com/
│   │       └── example/
│   │           └── app/
│   │               ├── config/          # Configuration classes
│   │               ├── controller/      # REST controllers
│   │               ├── dto/            # Data Transfer Objects
│   │               ├── entity/         # JPA entities
│   │               ├── exception/      # Custom exceptions
│   │               ├── repository/     # Spring Data repositories
│   │               ├── service/        # Business logic
│   │               ├── util/           # Utility classes
│   │               └── App.java        # Main application class
│   └── resources/
│       ├── application.properties    # Configuration
│       ├── application-dev.properties # Development config
│       ├── application-prod.properties # Production config
│       ├── static/                  # Static resources
│       └── templates/               # Template files
└── test/
    └── java/
        └── com/
            └── example/
                └── app/
                    ├── controller/
                    ├── service/
                    └── repository/
```

## Build and Development Commands
- `./mvnw clean install` - Build and test the project (Maven)
- `./gradlew build` - Build and test the project (Gradle)
- `./mvnw spring-boot:run` - Run the application
- `./gradlew bootRun` - Run the application
- `./mvnw test` - Run unit tests
- `./gradlew test` - Run unit tests
- `./mvnw spring-boot:repackage` - Package the application
- `docker-compose up` - Start Docker services
- `java -jar target/app.jar` - Run packaged application

## Code Style Guidelines
- Follow Java Code Conventions
- Use meaningful variable and method names
- Implement proper error handling
- Use type declarations
- Follow SOLID principles
- Write clean, readable code
- Use Lombok annotations for boilerplate reduction
- Follow Spring best practices

## Validation Rules
### Basic Field Validation
```java
// Entity validation with Jakarta Validation
@Entity
@Table(name = "users")
public class User {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @NotBlank(message = "Name is required")
    @Size(min = 2, max = 100, message = "Name must be between 2 and 100 characters")
    private String name;
    
    @Email(message = "Email should be valid")
    @NotBlank(message = "Email is required")
    @Size(max = 255, message = "Email must not exceed 255 characters")
    private String email;
    
    @NotBlank(message = "Password is required")
    @Size(min = 8, max = 255, message = "Password must be between 8 and 255 characters")
    private String password;
    
    @Enumerated(EnumType.STRING)
    private Role role;
    
    // Getters and setters with Lombok
}
```

### Custom Validation
```java
// Custom validator
@Target({ElementType.FIELD, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = PasswordValidator.class)
public @interface ValidPassword {
    String message() default "Password must contain at least one uppercase, one lowercase, one number and one special character";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}

public class PasswordValidator implements ConstraintValidator<ValidPassword, String> {
    private static final String PASSWORD_PATTERN = 
        "^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%^&+=])(?=\\S+$).{8,}$";
    
    @Override
    public boolean isValid(String password, ConstraintValidatorContext context) {
        if (password == null) {
            return false;
        }
        return password.matches(PASSWORD_PATTERN);
    }
}
```

## User Management
### User Entity
```java
@Entity
@Table(name = "users")
public class User {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @NotBlank
    @Size(min = 2, max = 100)
    private String name;
    
    @Email
    @NotBlank
    @Size(max = 255)
    private String email;
    
    @NotBlank
    @Size(min = 8, max = 255)
    private String password;
    
    @Enumerated(EnumType.STRING)
    private Role role;
    
    @CreatedDate
    private LocalDateTime createdAt;
    
    @LastModifiedDate
    private LocalDateTime updatedAt;
    
    // Relationships
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "role_id")
    private Role role;
    
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Post> posts = new ArrayList<>();
    
    // Getters, setters, and constructors with Lombok
}

// Role enum
public enum Role {
    USER, ADMIN, MANAGER
}
```

### Authentication with Spring Security
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )
            .addFilterBefore(jwtAuthenticationFilter(), UsernamePasswordAuthenticationFilter.class)
            .csrf(csrf -> csrf.disable());
        
        return http.build();
    }
    
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
    
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authConfig) throws Exception {
        return authConfig.getAuthenticationManager();
    }
}
```

## File Management
### File Upload Handling
```java
@RestController
@RequestMapping("/api/files")
public class FileController {
    
    @PostMapping("/upload")
    public ResponseEntity<FileResponse> uploadFile(@RequestParam("file") MultipartFile file) {
        // Validate file
        if (file.isEmpty()) {
            throw new FileUploadException("File is empty");
        }
        
        // Validate file type and size
        String contentType = file.getContentType();
        if (!contentType.startsWith("image/")) {
            throw new FileUploadException("Only image files are allowed");
        }
        
        if (file.getSize() > 5 * 1024 * 1024) { // 5MB
            throw new FileUploadException("File size exceeds 5MB");
        }
        
        // Save file
        String fileName = fileStorageService.storeFile(file);
        
        // Create response
        String fileDownloadUri = ServletUriComponentsBuilder.fromCurrentContextPath()
            .path("/downloadFile/")
            .path(fileName)
            .toUriString();
        
        FileResponse response = new FileResponse(
            fileName, fileDownloadUri, contentType, file.getSize());
        
        return ResponseEntity.status(HttpStatus.OK).body(response);
    }
}

// File storage service
@Service
public class FileStorageService {
    
    private final Path fileStorageLocation;
    
    @Autowired
    public FileStorageService(FileStorageProperties fileStorageProperties) {
        this.fileStorageLocation = Paths.get(fileStorageProperties.getUploadDir())
            .toAbsolutePath().normalize();
        
        try {
            Files.createDirectories(this.fileStorageLocation);
        } catch (Exception ex) {
            throw new FileStorageException("Could not create the directory", ex);
        }
    }
    
    public String storeFile(MultipartFile file) {
        // Generate unique filename
        String fileName = StringUtils.cleanPath(
            System.currentTimeMillis() + "_" + file.getOriginalFilename());
        
        try {
            // Copy file to the target location
            Path targetLocation = this.fileStorageLocation.resolve(fileName);
            Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);
            
            return fileName;
        } catch (IOException ex) {
            throw new FileStorageException("Could not store file " + fileName, ex);
        }
    }
}
```

## Database Best Practices
### Repository Pattern
```java
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    
    Optional<User> findByEmail(String email);
    
    @Query("SELECT u FROM User u WHERE u.role = :role")
    Page<User> findByRole(@Param("role") Role role, Pageable pageable);
    
    @Modifying
    @Query("UPDATE User u SET u.lastLogin = :lastLogin WHERE u.id = :userId")
    void updateLastLogin(@Param("userId") Long userId, @Param("lastLogin") LocalDateTime lastLogin);
}

// Service layer
@Service
@Transactional
public class UserService {
    
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    
    @Autowired
    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }
    
    public User createUser(UserDTO userDTO) {
        // Validate input
        if (userRepository.findByEmail(userDTO.getEmail()).isPresent()) {
            throw new UserAlreadyExistsException("Email already exists");
        }
        
        // Create user entity
        User user = new User();
        user.setName(userDTO.getName());
        user.setEmail(userDTO.getEmail());
        user.setPassword(passwordEncoder.encode(userDTO.getPassword()));
        user.setRole(Role.USER);
        
        // Save user
        return userRepository.save(user);
    }
    
    @Transactional(readOnly = true)
    public User getUserById(Long id) {
        return userRepository.findById(id)
            .orElseThrow(() -> new UserNotFoundException("User not found with id: " + id));
    }
}
```

### Query Optimization
```java
// Use projections for performance
public interface UserProjection {
    Long getId();
    String getName();
    String getEmail();
}

// Repository with projections
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    List<UserProjection> findByRole(Role role);
}

// Service using projections
@Service
public class UserService {
    
    public List<UserDTO> getActiveUsers() {
        return userRepository.findByRole(Role.USER).stream()
            .map(user -> new UserDTO(user.getId(), user.getName(), user.getEmail()))
            .collect(Collectors.toList());
    }
}

// Pagination and sorting
public Page<User> getUsers(Pageable pageable) {
    return userRepository.findAll(pageable);
}

// Batch processing
@Transactional
public void batchUpdateUsers(List<User> users) {
    userRepository.saveAll(users);
}
```

## Security Best Practices
### Input Validation
```java
// Controller with validation
@RestController
@RequestMapping("/api/users")
public class UserController {
    
    private final UserService userService;
    
    @Autowired
    public UserController(UserService userService) {
        this.userService = userService;
    }
    
    @PostMapping
    public ResponseEntity<User> createUser(@Valid @RequestBody UserDTO userDTO) {
        User createdUser = userService.createUser(userDTO);
        return new ResponseEntity<>(createdUser, HttpStatus.CREATED);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<User> getUser(@PathVariable Long id) {
        User user = userService.getUserById(id);
        return ResponseEntity.ok(user);
    }
}
```

### Authentication Security
```java
// JWT Authentication
@Component
public class JwtTokenProvider {
    
    @Value("${app.jwtSecret}")
    private String jwtSecret;
    
    @Value("${app.jwtExpirationInMs}")
    private int jwtExpirationInMs;
    
    public String generateToken(Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpirationInMs);
        
        return Jwts.builder()
            .setSubject(Long.toString(userPrincipal.getId()))
            .setIssuedAt(new Date())
            .setExpiration(expiryDate)
            .signWith(SignatureAlgorithm.HS512, jwtSecret)
            .compact();
    }
    
    public Long getUserIdFromJWT(String token) {
        Claims claims = Jwts.parser()
            .setSigningKey(jwtSecret)
            .parseClaimsJws(token)
            .getBody();
        
        return Long.parseLong(claims.getSubject());
    }
    
    public boolean validateToken(String authToken) {
        try {
            Jwts.parser().setSigningKey(jwtSecret).parseClaimsJws(authToken);
            return true;
        } catch (SignatureException ex) {
            logger.error("Invalid JWT signature");
        } catch (MalformedJwtException ex) {
            logger.error("Invalid JWT token");
        } catch (ExpiredJwtException ex) {
            logger.error("Expired JWT token");
        } catch (UnsupportedJwtException ex) {
            logger.error("Unsupported JWT token");
        } catch (IllegalArgumentException ex) {
            logger.error("JWT claims string is empty");
        }
        return false;
    }
}
```

## Performance Optimization
### Caching
```java
// Service with caching
@Service
public class ProductService {
    
    private final ProductRepository productRepository;
    
    @Cacheable(value = "products", key = "#id")
    public Product getProductById(Long id) {
        return productRepository.findById(id)
            .orElseThrow(() -> new ProductNotFoundException("Product not found"));
    }
    
    @CachePut(value = "products", key = "#product.id")
    public Product updateProduct(Product product) {
        return productRepository.save(product);
    }
    
    @CacheEvict(value = "products", key = "#id")
    public void deleteProduct(Long id) {
        productRepository.deleteById(id);
    }
}

// Cache configuration
@Configuration
@EnableCaching
public class CacheConfig {
    
    @Bean
    public CacheManager cacheManager() {
        SimpleCacheManager cacheManager = new SimpleCacheManager();
        cacheManager.setCaches(Arrays.asList(
            new ConcurrentMapCache("products"),
            new ConcurrentMapCache("users")
        ));
        return cacheManager;
    }
}
```

### Query Optimization
```java
// Use projections to reduce data transfer
public interface ProductProjection {
    Long getId();
    String getName();
    BigDecimal getPrice();
}

// Repository with projections
@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {
    List<ProductProjection> findByCategory(String category);
}

// Use batch operations
@Service
public class BatchProcessingService {
    
    private final ProductRepository productRepository;
    
    @Transactional
    public void processProductsInBatch(List<Product> products) {
        productRepository.saveAll(products);
    }
    
    public void updateProductPrices(BigDecimal percentage) {
        List<Product> products = productRepository.findAll();
        products.forEach(product -> {
            BigDecimal newPrice = product.getPrice().multiply(
                BigDecimal.ONE.add(percentage.divide(new BigDecimal("100"))));
            product.setPrice(newPrice);
        });
        productRepository.saveAll(products);
    }
}
```

## Error Handling
### Custom Exception Handling
```java
// Custom exceptions
public class UserNotFoundException extends RuntimeException {
    public UserNotFoundException(String message) {
        super(message);
    }
}

public class ProductNotFoundException extends RuntimeException {
    public ProductNotFoundException(String message) {
        super(message);
    }
}

// Global exception handler
@ControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleUserNotFound(UserNotFoundException ex) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.NOT_FOUND.value(),
            ex.getMessage(),
            System.currentTimeMillis());
        return new ResponseEntity<>(error, HttpStatus.NOT_FOUND);
    }
    
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationExceptions(
            MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach(error -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });
        
        ErrorResponse errorResponse = new ErrorResponse(
            HttpStatus.BAD_REQUEST.value(),
            "Validation failed",
            System.currentTimeMillis(),
            errors);
        
        return new ResponseEntity<>(errorResponse, HttpStatus.BAD_REQUEST);
    }
}
```

### Logging
```java
@Service
public class UserService {
    
    private static final Logger logger = LoggerFactory.getLogger(UserService.class);
    
    public User createUser(UserDTO userDTO) {
        logger.info("Creating user with email: {}", userDTO.getEmail());
        
        try {
            User user = userRepository.save(convertToEntity(userDTO));
            logger.info("User created successfully with ID: {}", user.getId());
            return user;
        } catch (Exception ex) {
            logger.error("Error creating user: {}", ex.getMessage(), ex);
            throw new UserCreationException("Failed to create user", ex);
        }
    }
}
```

## Testing Best Practices
### Unit Testing
```java
// Service test
@SpringBootTest
class UserServiceTest {
    
    @Mock
    private UserRepository userRepository;
    
    @InjectMocks
    private UserService userService;
    
    @Test
    void testCreateUser() {
        // Given
        UserDTO userDTO = new UserDTO("John Doe", "john@example.com", "password");
        User savedUser = new User(1L, "John Doe", "john@example.com", "encodedPassword", Role.USER);
        
        when(userRepository.findByEmail(userDTO.getEmail())).thenReturn(Optional.empty());
        when(userRepository.save(any(User.class))).thenReturn(savedUser);
        
        // When
        User result = userService.createUser(userDTO);
        
        // Then
        assertNotNull(result);
        assertEquals("John Doe", result.getName());
        verify(userRepository, times(1)).save(any(User.class));
    }
    
    @Test
    void testCreateUserWithExistingEmail() {
        // Given
        UserDTO userDTO = new UserDTO("John Doe", "john@example.com", "password");
        when(userRepository.findByEmail(userDTO.getEmail())).thenReturn(Optional.of(new User()));
        
        // When & Then
        assertThrows(UserAlreadyExistsException.class, () -> userService.createUser(userDTO));
    }
}
```

### Integration Testing
```java
// Controller test
@WebMvcTest(UserController.class)
class UserControllerIntegrationTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @MockBean
    private UserService userService;
    
    @Test
    void testGetUserById() throws Exception {
        // Given
        User user = new User(1L, "John Doe", "john@example.com", "password", Role.USER);
        when(userService.getUserById(1L)).thenReturn(user);
        
        // When & Then
        mockMvc.perform(get("/api/users/1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.name").value("John Doe"))
            .andExpect(jsonPath("$.email").value("john@example.com"));
    }
    
    @Test
    void testGetUserByIdNotFound() throws Exception {
        // Given
        when(userService.getUserById(1L)).thenThrow(new UserNotFoundException("User not found"));
        
        // When & Then
        mockMvc.perform(get("/api/users/1"))
            .andExpect(status().isNotFound());
    }
}
```

## API Development
### REST API with DTOs
```java
// DTO for user
public class UserDTO {
    private Long id;
    private String name;
    private String email;
    private Role role;
    
    // Getters and setters
}

// Controller
@RestController
@RequestMapping("/api/users")
public class UserController {
    
    private final UserService userService;
    
    @Autowired
    public UserController(UserService userService) {
        this.userService = userService;
    }
    
    @GetMapping
    public ResponseEntity<Page<UserDTO>> getUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        Page<User> users = userService.getUsers(PageRequest.of(page, size));
        Page<UserDTO> userDTOs = users.map(this::convertToDTO);
        
        return ResponseEntity.ok(userDTOs);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<UserDTO> getUser(@PathVariable Long id) {
        User user = userService.getUserById(id);
        UserDTO userDTO = convertToDTO(user);
        return ResponseEntity.ok(userDTO);
    }
    
    @PostMapping
    public ResponseEntity<UserDTO> createUser(@Valid @RequestBody UserDTO userDTO) {
        User createdUser = userService.createUser(userDTO);
        UserDTO createdUserDTO = convertToDTO(createdUser);
        return new ResponseEntity<>(createdUserDTO, HttpStatus.CREATED);
    }
    
    private UserDTO convertToDTO(User user) {
        UserDTO userDTO = new UserDTO();
        userDTO.setId(user.getId());
        userDTO.setName(user.getName());
        userDTO.setEmail(user.getEmail());
        userDTO.setRole(user.getRole());
        return userDTO;
    }
}
```

## Dependency Management
### Maven Configuration
```xml
<dependencies>
    <!-- Spring Boot Starter Web -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    
    <!-- Spring Boot Starter Data JPA -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    
    <!-- Spring Boot Starter Security -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
    
    <!-- Spring Boot Starter Validation -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    
    <!-- PostgreSQL Driver -->
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
        <scope>runtime</scope>
    </dependency>
    
    <!-- Lombok -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
    
    <!-- Test Dependencies -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
    
    <dependency>
        <groupId>org.mockito</groupId>
        <artifactId>mockito-core</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

### Gradle Configuration
```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-security'
    implementation 'org.springframework.boot:spring-boot-starter-validation'
    
    runtimeOnly 'org.postgresql:postgresql'
    
    compileOnly 'org.projectlombok:lombok'
    annotationProcessor 'org.projectlombok:lombok'
    
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'org.mockito:mockito-core'
}
```

## Deployment Best Practices
### Application Configuration
```properties
# Application properties
spring.application.name=java-app
server.port=8080

# Database configuration
spring.datasource.url=jdbc:postgresql://localhost:5432/app_db
spring.datasource.username=app_user
spring.datasource.password=secret
spring.datasource.driver-class-name=org.postgresql.Driver

# JPA configuration
spring.jpa.show-sql=true
spring.jpa.hibernate.ddl-auto=update
spring.jpa.properties.hibernate.format_sql=true

# Security configuration
spring.security.jwt.secret=your-secret-key-here
spring.security.jwt.expiration-in-ms=86400000

# Logging configuration
logging.level.org.springframework.security=DEBUG
logging.level.com.example.app=INFO
```

### Docker Configuration
```dockerfile
# Dockerfile
FROM openjdk:17-jdk-slim

WORKDIR /app

COPY target/java-app.jar java-app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "java-app.jar"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/app_db
      - SPRING_DATASOURCE_USERNAME=app_user
      - SPRING_DATASOURCE_PASSWORD=secret
    depends_on:
      - db

  db:
    image: postgres:14
    environment:
      - POSTGRES_DB=app_db
      - POSTGRES_USER=app_user
      - POSTGRES_PASSWORD=secret
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:
```

## Monitoring and Maintenance
### Health Checks
```java
@RestController
public class HealthController {
    
    @GetMapping("/health")
    public ResponseEntity<HealthResponse> health() {
        HealthResponse health = new HealthResponse(
            "healthy",
            LocalDateTime.now(),
            checkDatabaseConnection(),
            checkMemoryUsage(),
            checkDiskSpace());
        
        return ResponseEntity.ok(health);
    }
    
    private boolean checkDatabaseConnection() {
        try {
            return userRepository.count() >= 0;
        } catch (Exception e) {
            return false;
        }
    }
    
    private Map<String, Object> checkMemoryUsage() {
        Runtime runtime = Runtime.getRuntime();
        long usedMemory = runtime.totalMemory() - runtime.freeMemory();
        long maxMemory = runtime.maxMemory();
        
        return Map.of(
            "usedMemory", usedMemory,
            "maxMemory", maxMemory,
            "freeMemory", runtime.freeMemory(),
            "usedPercentage", (usedMemory * 100) / maxMemory
        );
    }
}
```

### Actuator for Monitoring
```java
@SpringBootApplication
@EnableActuator
public class App {

    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }
}

# Application properties
management.endpoints.web.exposure.include=health,info,metrics,env
management.endpoint.health.show-details=always
management.endpoint.metrics.enabled=true
```
