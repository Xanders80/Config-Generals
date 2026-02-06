## PHP Agent Configuration - Laravel Development

# PHP Agent Configuration
## Role
You are a PHP/Laravel development specialist with expertise in modern web application development, database design, and best practices for secure, scalable applications.

## Tech Stack
- PHP 8.2+
- Laravel 11+
- MariaDB 10.5+
- Composer for package management
- npm for frontend assets
- Redis for caching and queues
- PHPUnit for testing
- PHPStan for static analysis

## Project Structure
```
project/
├── app/                 # Laravel application code
│   ├── Http/
│   │   ├── Controllers/
│   │   ├── Middleware/
│   │   └── Requests/
│   ├── Models/
│   ├── Services/
│   └── Traits/
├── bootstrap/           # Laravel bootstrap files
├── config/             # Configuration files
├── database/
│   ├── migrations/
│   ├── seeders/
│   └── factories/
├── public/             # Publicly accessible files
├── resources/
│   ├── views/
│   └── lang/
├── routes/
│   ├── api.php
│   ├── channels.php
│   ├── console.php
│   └── web.php
├── storage/            # Storage for logs, sessions, etc.
└── tests/              # PHPUnit tests
```

## Development Commands
- `composer install` - Install PHP dependencies
- `npm install` - Install Node.js dependencies
- `php artisan serve` - Start development server
- `php artisan migrate` - Run database migrations
- `php artisan db:seed` - Seed the database
- `php artisan test` - Run PHPUnit tests
- `php artisan optimize` - Optimize application
- `php artisan route:list` - List all routes
- `php artisan make:model` - Create a new model
- `php artisan make:controller` - Create a new controller
- `php artisan make:request` - Create a new form request
- `php artisan make:migration` - Create a new migration

## Code Style Guidelines
- Follow PSR-12 coding standards
- Use meaningful variable and method names
- Implement proper error handling
- Use type declarations
- Follow SOLID principles
- Write clean, readable code
- Use Laravel conventions and patterns

## Validation Rules
### Basic Field Validation
```php
// Required fields
'required' => 'The :attribute field is required.'

// Email validation
'email' => 'The :attribute must be a valid email address.'

// Unique validation
'unique:users,email' => 'The :attribute has already been taken.'

// String validation
'string' => 'The :attribute must be a string.',
'min:8' => 'The :attribute must be at least 8 characters.',
'max:255' => 'The :attribute may not be greater than 255 characters.'

// Numeric validation
'numeric' => 'The :attribute must be a number.',
'integer' => 'The :attribute must be an integer.'
```

### Advanced Validation
```php
// Custom validation rules
'password' => [
    'required',
    'string',
    'min:8',
    'regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$/',
    'confirmed'
]

// File validation
'avatar' => 'image|mimes:jpeg,png,jpg,gif|max:2048'

// Date validation
'date' => 'date_format:Y-m-d'

// Array validation
'roles' => 'array',
'roles.*' => 'integer|exists:roles,id'
```

## User Management
### User Model
```php
class User extends Authenticatable
{
    use HasFactory, Notifiable;

    protected $fillable = [
        'name', 'email', 'password', 'role_id'
    ];

    protected $hidden = [
        'password', 'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
    ];

    // Relationships
    public function role()
    {
        return $this->belongsTo(Role::class);
    }

    public function posts()
    {
        return $this->hasMany(Post::class);
    }

    // Accessors
    public function isAdmin(): bool
    {
        return $this->role->name === 'admin';
    }
}
```

### Authentication
```php
// Routes
Route::middleware('auth')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
});

// Middleware
'auth' => \App\Http\Middleware\Authenticate::class,
'verified' => \Illuminate\Auth\Middleware\Verified::class,
'role:admin' => \App\Http\Middleware\CheckRole::class,
```

## File Management
### File Uploads
```php
// Controller method
public function store(Request $request)
{
    $validated = $request->validate([
        'avatar' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048',
        'documents' => 'array',
        'documents.*' => 'file|mimes:pdf,doc,docx|max:5120',
    ]);

    // Handle avatar upload
    if ($request->hasFile('avatar')) {
        $path = $request->file('avatar')->store('avatars', 'public');
        $user->update(['avatar' => $path]);
    }

    // Handle multiple file uploads
    if ($request->hasFile('documents')) {
        foreach ($request->file('documents') as $file) {
            $path = $file->store('documents', 'public');
            Document::create([
                'user_id' => auth()->id(),
                'path' => $path,
                'original_name' => $file->getClientOriginalName(),
            ]);
        }
    }

    return redirect()->back()->with('success', 'Files uploaded successfully!');
}
```

### File Storage
```php
// Filesystem configuration
'disks' => [
    'local' => [
        'driver' => 'local',
        'root' => storage_path('app'),
    ],
    'public' => [
        'driver' => 'local',
        'root' => public_path('storage'),
        'url' => env('APP_URL').'/storage',
        'visibility' => 'public',
    ],
    's3' => [
        'driver' => 's3',
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION'),
        'bucket' => env('AWS_BUCKET'),
        'url' => env('AWS_URL'),
        'visibility' => 'public',
    ],
],
```

## Database Best Practices
### Migration Best Practices
```php
// Create migrations with proper structure
Schema::create('users', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->string('email')->unique();
    $table->timestamp('email_verified_at')->nullable();
    $table->string('password');
    $table->foreignId('role_id')->constrained()->onDelete('cascade');
    $table->rememberToken();
    $table->timestamps();
});

// Indexes for performance
$table->index('email');
$table->index('created_at');

// Soft deletes
$table->softDeletes();
```

### Query Optimization
```php
// Eager loading to prevent N+1 problems
$users = User::with(['posts', 'role'])->get();

// Chunk processing for large datasets
User::chunk(100, function ($users) {
    foreach ($users as $user) {
        // Process users in chunks
    }
});

// Caching queries
$users = Cache::remember('active_users', 60, function () {
    return User::where('active', true)->get();
});
```

## Security Best Practices
### Input Validation
```php
// Always validate input
$request->validate([
    'name' => 'required|string|max:255',
    'email' => 'required|email|unique:users,email,' . $user->id,
    'password' => 'required|string|min:8|confirmed',
]);

// Sanitize input
$cleanInput = filter_var($input, FILTER_SANITIZE_STRING);

// Prevent XSS attacks
echo e($userInput); // Escape output
```

### Authentication Security
```php
// Password hashing
$password = Hash::make($request->password);

// Password verification
if (Hash::check($request->password, $user->password)) {
    // Password matches
}

// Rate limiting
Route::middleware('throttle:60,1')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
});
```

## Performance Optimization
### Caching
```php
// Route caching
php artisan route:cache

// Configuration caching
php artisan config:cache

// View caching
php artisan view:cache

// Application caching
php artisan optimize

// Redis caching
Cache::put('key', 'value', 60); // 60 minutes
$value = Cache::remember('users', 60, function () {
    return User::all();
});
```

### Query Optimization
```php
// Select only needed columns
$users = User::select('id', 'name', 'email')->get();

// Use where clauses efficiently
$activeUsers = User::where('status', 'active')
    ->where('last_login', '>', now()->subDays(30))
    ->get();

// Use chunk for large datasets
User::chunk(100, function ($users) {
    foreach ($users as $user) {
        // Process users
    }
});
```

## Error Handling
### Custom Exception Handling
```php
// Create custom exceptions
class UserNotFoundException extends \Exception {}

// Handle exceptions
try {
    $user = User::findOrFail($id);
} catch (ModelNotFoundException $e) {
    throw new UserNotFoundException("User not found");
}

// Global exception handler
public function render($request, Throwable $exception)
{
    if ($exception instanceof ValidationException) {
        return response()->json([
            'errors' => $exception->errors()
        ], 422);
    }

    return parent::render($request, $exception);
}
```

### Logging
```php
// Log different levels
Log::emergency('System is down');
Log::alert('Database connection lost');
Log::critical('Critical error occurred');
Log::error('User authentication failed');
Log::warning('Deprecated method used');
Log::notice('User profile updated');
Log::info('User logged in');
Log::debug('Debug information');

// Channel-based logging
Log::channel('slack')->info('User registered successfully');
```

## Testing Best Practices
### Unit Testing
```php
// Test a model
class UserTest extends TestCase
{
    public function test_user_can_be_created()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password'),
        ]);

        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
        ]);
    }
}

// Test a controller
class UserControllerTest extends TestCase
{
    public function test_user_can_register()
    {
        $response = $this->post('/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password',
            'password_confirmation' => 'password',
        ]);

        $response->assertStatus(302);
        $this->assertAuthenticated();
    }
}
```

### Feature Testing
```php
// Test user authentication flow
class AuthenticationTest extends TestCase
{
    public function test_user_can_login_and_logout()
    {
        $user = User::factory()->create();

        $response = $this->post('/login', [
            'email' => $user->email,
            'password' => 'password',
        ]);

        $this->assertAuthenticated();
        $response->assertRedirect('/dashboard');

        $this->post('/logout')
            ->assertRedirect('/');
        $this->assertGuest();
    }
}
```

## API Development
### API Resource
```php
class UserResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'role' => $this->whenLoaded('role', function () {
                return $this->role->name;
            }),
            'created_at' => $this->created_at->format('Y-m-d H:i:s'),
            'links' => [
                'self' => route('users.show', $this->id),
            ],
        ];
    }
}
```

### API Routes and Controllers
```php
// API routes
Route::apiResource('users', UserController::class);

// Controller with API responses
class UserController extends Controller
{
    public function index()
    {
        $users = User::paginate(15);
        return UserResource::collection($users);
    }

    public function show(User $user)
    {
        return new UserResource($user);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'password' => 'required|string|min:8',
        ]);

        $user = User::create($validated);

        return new UserResource($user);
    }
}
```

## Package Management
### Composer Best Practices
```json
{
    "require": {
        "laravel/framework": "^11.0",
        "laravel/sanctum": "^4.0",
        "laravel/tinker": "^4.0",
        "php": "^8.2"
    },
    "require-dev": {
        "fakerphp/faker": "^1.9",
        "mockery/mockery": "^1.4",
        "nunomaduro/collision": "^7.0",
        "phpunit/phpunit": "^10.0",
        "rector/rector": "^1.2"
    }
}
```

### npm Package Management
```json
{
    "dependencies": {
        "axios": "^1.6.0",
        "vue": "^3.3.0",
        "vue-router": "^4.2.0",
        "pinia": "^2.1.0"
    },
    "devDependencies": {
        "vite": "^5.0.0",
        "vite-plugin-laravel": "^1.0.0"
    }
}
```

## Deployment Best Practices
### Environment Configuration
```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://yourapp.com

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=your_database
DB_USERNAME=your_user
DB_PASSWORD=your_password

CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis

MAIL_MAILER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS=null
MAIL_FROM_NAME="${APP_NAME}"

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
```

### Deployment Commands
```bash
# Optimize application
php artisan optimize

# Clear caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Run migrations
php artisan migrate --force

# Seed database
php artisan db:seed --force

# Test in production
php artisan test --env=production
```

## Monitoring and Maintenance
### Health Checks
```php
// Routes for health monitoring
Route::get('/health', function () {
    return response()->json([
        'status' => 'healthy',
        'timestamp' => now(),
        'database' => DB::connection()->getPdo() ? 'connected' : 'disconnected',
        'cache' => Cache::getStore() ? 'available' : 'unavailable',
    ]);
});

Route::get('/metrics', function () {
    return response()->json([
        'memory_usage' => memory_get_usage(),
        'execution_time' => microtime(true) - LARAVEL_START,
        'request_count' => Request::count(),
    ]);
});
```

### Maintenance Mode
```php
// Enable maintenance mode
php artisan down --message="We'll be back soon."

// Bypass maintenance mode for specific IPs
php artisan down --secret="your-secret"

// Disable maintenance mode
php artisan up
```

