---
name: java-spring
description: "Use when working on projects involving Java and Spring Boot code."
---

# Java + Spring Boot

## References

- [Spring Boot Reference](https://docs.spring.io/spring-boot/reference/)
- [Spring Framework Reference](https://docs.spring.io/spring-framework/reference/)
- [Spring WebFlux](https://docs.spring.io/spring-framework/reference/web/webflux.html)
- [Java Language Specification (JLS 21)](https://docs.oracle.com/javase/specs/jls/se21/html/index.html)
- [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)
- [OWASP Dependency-Check](https://jeremylong.github.io/DependencyCheck/)
- [Testcontainers](https://java.testcontainers.org/)
- [Gradle Wrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html)

## Code Quality Checks

Run these in order. ALWAYS use `./gradlew`, never bare `gradle`.

Check the project first for existing build configuration. For new projects, use Gradle with Groovy DSL, Java 21, and latest stable Spring Boot.

```bash
# 1. Format code
./gradlew spotlessApply

# 2. Check compilation
./gradlew compileJava

# 3. Static analysis (Checkstyle, SpotBugs, PMD run as tasks; Error Prone runs during compilation)
./gradlew checkstyleMain spotbugsMain pmdMain

# 4. Run all tests
./gradlew test

# 5. Vulnerability check
./gradlew dependencyCheckAnalyze
```

Check the project for existing tool configuration before adding new plugins. New projects use Spotless + Google Java Format for formatting and all four static analysis tools.

## Project Structure

Hexagonal / ports-and-adapters architecture:

```
project-root/
├── build.gradle
├── gradlew
├── gradlew.bat
├── settings.gradle
├── gradle/
│   └── wrapper/
├── src/
│   ├── main/
│   │   ├── java/com/example/app/
│   │   │   ├── Application.java
│   │   │   ├── domain/
│   │   │   │   ├── model/
│   │   │   │   ├── port/
│   │   │   │   │   ├── in/
│   │   │   │   │   └── out/
│   │   │   │   └── service/
│   │   │   ├── adapter/
│   │   │   │   ├── in/
│   │   │   │   │   └── web/
│   │   │   │   └── out/
│   │   │   │       └── persistence/
│   │   │   └── config/
│   │   └── resources/
│   │       ├── application.yml
│   │       └── application-local.yml
│   └── test/
│       └── java/com/example/app/
└── README.md
```

- `domain/model/` — Entities, value objects, enums
- `domain/port/in/` — Inbound port interfaces (use cases)
- `domain/port/out/` — Outbound port interfaces (driven)
- `domain/service/` — Domain service implementations
- `adapter/in/web/` — REST controllers, request/response DTOs
- `adapter/out/persistence/` — Repository implementations (R2DBC for WebFlux, JPA for MVC; avoid blocking persistence in reactive flows)
- `config/` — Spring @Configuration classes

## Testing

Check the project for existing test configuration. New projects use JUnit 5, Mockito, AssertJ, and Testcontainers.

```bash
./gradlew test
```

- Unit tests for domain services — mock outbound ports
- Integration tests for adapters — use Testcontainers
- Slice tests: `@WebFluxTest` for controllers, `@DataR2dbcTest` for reactive repositories (or `@DataJpaTest` for MVC projects)
- Test naming: `shouldDoX_whenConditionY()`
- Use `StepVerifier` for reactive stream assertions

### Testcontainers

```java
@Testcontainers
@SpringBootTest
class UserRepositoryIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres =
            new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }
}
```

### StepVerifier

```java
@Test
void shouldReturnUser_whenIdExists() {
    StepVerifier.create(userService.findById(1L))
            .assertNext(user -> assertThat(user.name()).isEqualTo("Alice"))
            .verifyComplete();
}
```

## Naming Conventions

| Item | Convention | Example |
|---|---|---|
| Packages | lowercase, dot-separated | `com.example.app.domain` |
| Classes | PascalCase | `UserService`, `OrderController` |
| Interfaces | PascalCase (no I prefix) | `UserRepository`, `PaymentGateway` |
| Methods | camelCase | `findById()`, `processOrder()` |
| Constants | SCREAMING_SNAKE | `MAX_RETRIES`, `DEFAULT_TIMEOUT` |
| Variables | camelCase | `itemCount`, `userName` |
| Enum values | SCREAMING_SNAKE | `ACTIVE`, `PENDING` |
| Test classes | ClassNameTest | `UserServiceTest` |
| Test methods | descriptive with underscores | `shouldReturnUser_whenIdExists()` |

## Idioms

- **Constructor injection exclusively.** Never `@Autowired` on fields. Use `final` fields with a single constructor (Spring auto-wires it).
- **`@ConfigurationProperties`** for type-safe configuration binding. Prefer over `@Value`.
- **`@ControllerAdvice`** for global exception handling — one per application or bounded context.
- **Records for DTOs and value objects.** Replace mutable POJOs with `record` types.
- **`Optional` only as return type.** Never as a field, method parameter, or collection element.
- **Composition over inheritance.** Inject collaborators, don't extend base classes.
- **`@Qualifier` and custom annotations** over string-based bean names for disambiguation.
- **Profile-based configuration.** Use `application-{profile}.yml` for environment-specific config.
- **Immutable objects wherever possible.** Final fields, no setters, Records.
- **SLF4J + Logback for logging.** Spring Boot's default. Use `LoggerFactory.getLogger()`, never `System.out`. Structured logging for production.
- **Spring Cloud Config Server required for new projects.** All configuration must be externalized — no hardcoded values in source. Secrets use environment placeholders (`${DB_PASSWORD}`) in config server properties; actual secret values are injected at runtime by external automation (control scripts, CI/CD pipelines). The application must never contain or log secret values.

```java
@Service
public class OrderService implements CreateOrderUseCase {

    private final OrderRepository orderRepository;
    private final PaymentGateway paymentGateway;

    public OrderService(OrderRepository orderRepository, PaymentGateway paymentGateway) {
        this.orderRepository = orderRepository;
        this.paymentGateway = paymentGateway;
    }
}
```

```java
@ConfigurationProperties(prefix = "app.payment")
public record PaymentProperties(String apiKey, Duration timeout, int maxRetries) {}
```

Config server properties use environment placeholders for secrets:

```yaml
# Served by Spring Cloud Config Server — NOT in application source
app:
  payment:
    api-key: ${PAYMENT_API_KEY}
    timeout: 30s
    max-retries: 3
  datasource:
    url: ${DATABASE_URL}
    username: ${DATABASE_USERNAME}
    password: ${DATABASE_PASSWORD}
```

```java
public record CreateOrderRequest(String customerId, List<LineItem> items) {}
public record OrderResponse(String orderId, BigDecimal total, OrderStatus status) {}
```

## Design Patterns

- **Hexagonal architecture** — Domain knows nothing about adapters. Ports define boundaries.
- **Strategy** — Inject different implementations via Spring bean injection and `@Qualifier`.
- **Template method** — Rare; only when integrating with a framework pattern that requires inheritance. Prefer composition.
- **Observer** — `ApplicationEventPublisher` for decoupled domain event handling.
- **Factory** — `@Bean` methods in `@Configuration` classes.
- **Decorator** — Spring AOP / proxies for cross-cutting concerns.
- **Repository** — Spring Data interfaces for data access.
- **CQRS** — Separate read/write models when query and command needs diverge.

## Anti-Patterns

**NEVER do these:**

- **Project Lombok — FORBIDDEN.** Never add Lombok to any project. Never use `@Data`, `@Value`, `@Builder`, `@Getter`, `@Setter`, `@AllArgsConstructor`, or any other Lombok annotation. Use Java Records, manual constructors, and IDE generation instead. If existing code uses Lombok, migrate it away.
- **Field injection** — `@Autowired` on fields hides dependencies and prevents immutability. Use constructor injection.
- **God classes** — Services with dozens of methods. Split by use case.
- **Catching `Exception` / `Throwable` broadly** — Catch specific exceptions only.
- **Business logic in controllers** — Controllers delegate to domain services only.
- **Exposing domain entities as API responses** — Use DTOs (Records) to decouple API from domain.
- **Circular dependencies** — Redesign with events or introduce a mediator.
- **N+1 queries** — Use `@EntityGraph`, join fetch, or batch fetching.
- **Hardcoded configuration** — All config must be externalized via Spring Cloud Config Server. Secrets must use environment placeholders (`${SECRET}`) injected by external automation, never committed to source.
- **Secrets in source or logs** — Never hardcode, log, or commit secrets. Environment placeholders only.
- **Mutable DTOs** — Use Records. No setters on data transfer objects.

## Error Handling

- `@ControllerAdvice` + `@ExceptionHandler` for centralized error handling
- Domain-specific exception hierarchy rooted in a base `DomainException`
- RFC 7807 Problem Details for HTTP error responses (`ProblemDetail` in Spring 6+)
- Never swallow exceptions — log and rethrow or transform
- Log at appropriate levels: `ERROR` for unrecoverable, `WARN` for recoverable, `DEBUG` for diagnostics
- Reactive: propagate errors with `Mono.error()` / `Flux.error()`

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ProblemDetail handleNotFound(ResourceNotFoundException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.NOT_FOUND, ex.getMessage());
        problem.setTitle("Resource Not Found");
        return problem;
    }
}
```

```java
public class ResourceNotFoundException extends DomainException {
    public ResourceNotFoundException(String resourceType, Object id) {
        super("%s not found with id: %s".formatted(resourceType, id));
    }
}
```

## Reactive Programming (WebFlux)

Check the project for existing web stack. New projects use Spring WebFlux.

- **Never block** inside reactive chains. No `.block()`, no blocking I/O.
- **`.flatMap()`** for async composition. `.map()` for synchronous transforms only.
- **Backpressure** — Use `.onBackpressureBuffer()`, `.onBackpressureDrop()` as needed.
- **`Schedulers.boundedElastic()`** — Wrap unavoidable blocking calls with `.subscribeOn()`.
- **`WebClient`** for HTTP calls. Never use `RestTemplate` in reactive code.
- **`StepVerifier`** for testing reactive streams.

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    private final FindUserUseCase findUserUseCase;

    public UserController(FindUserUseCase findUserUseCase) {
        this.findUserUseCase = findUserUseCase;
    }

    @GetMapping("/{id}")
    public Mono<UserResponse> getUser(@PathVariable Long id) {
        return findUserUseCase.findById(id)
                .map(UserResponse::from)
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("User", id)));
    }

    @GetMapping
    public Flux<UserResponse> getAllUsers() {
        return findUserUseCase.findAll()
                .map(UserResponse::from);
    }
}
```

```java
public Mono<OrderResponse> createOrder(CreateOrderRequest request) {
    return validateOrder(request)
            .flatMap(this::processPayment)
            .flatMap(this::saveOrder)
            .map(OrderResponse::from);
}
```

Wrapping blocking calls:

```java
Mono.fromCallable(() -> blockingLegacyService.call(param))
        .subscribeOn(Schedulers.boundedElastic());
```

## Documentation

- All public classes and methods must have Javadoc
- Javadoc on interfaces, not implementations (unless implementation adds behavior)
- `@param`, `@return`, `@throws` tags for all non-trivial methods
- Package-level documentation in `package-info.java`
- API documentation via SpringDoc OpenAPI

## Dependencies

- Check `build.gradle` before adding any dependency
- Use Spring Boot dependency management BOM — do not specify versions for managed dependencies
- Pin versions for non-managed dependencies
- Run `./gradlew dependencyCheckAnalyze` after adding new dependencies
- Prefer Spring ecosystem libraries (Spring Data, Spring Security, Spring Cloud)
- Evaluate transitive dependencies before adding new libraries

## Performance Considerations

- Use connection pooling (HikariCP is Spring Boot default)
- Configure thread pools appropriately for WebFlux (`reactor.netty` defaults)
- Use caching (`@Cacheable`) for frequently accessed, rarely changing data
- Pagination for collection endpoints (`Pageable` / reactive equivalents)
- Use projections and DTOs in queries — never fetch full entities when partial data suffices
- Database indexing aligned with query patterns
- Lazy loading awareness with JPA (prefer explicit fetch strategies)

## Troubleshooting

For detailed legacy migration guidance, see `reference/legacy-migration.md`.

### Remote Debugging

```bash
# Attach debugger on port 5005 (suspend=y to wait for debugger before startup)
java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005 -jar app.jar

# Via Gradle
./gradlew bootRun --args='--debug' -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005"
```

### Thread & Heap Dumps

```bash
jps -l                                    # Find PID
jcmd <pid> Thread.print > threads.txt     # Thread dump (deadlock detection)
jcmd <pid> GC.heap_dump heap.hprof        # Heap dump (memory leaks)
jcmd <pid> GC.class_histogram | head -20  # Quick memory by class
```

Take 3 thread dumps 5 seconds apart — if thread states are identical across dumps, that thread is stuck.

### Actuator Diagnostics

```properties
management.endpoints.web.exposure.include=env,health,beans,conditions,mappings
management.endpoint.health.show-details=always
```

| Endpoint | Use |
|---|---|
| `/actuator/env` | Property sources and precedence — find config issues |
| `/actuator/conditions` | Why an auto-config bean was/wasn't created |
| `/actuator/beans` | All registered beans — find missing/duplicate beans |
| `/actuator/health` | DB connectivity, disk, custom health checks |
| `/actuator/mappings` | All request mappings — find routing issues |

### Common Startup Failures

| Error | Root Cause | Fix |
|---|---|---|
| `BeanCreationException` | Constructor/init method failed | Check `Caused by:` — usually NPE, missing config, or DB down |
| `NoSuchBeanDefinitionException` | Missing `@Component`/`@Service` or package not scanned | Verify annotations and `@ComponentScan` base packages |
| `UnsatisfiedDependencyException` | Bean exists but can't be wired | Check type matches, `@Qualifier`, conditional annotations |
| `BeanCurrentlyInCreationException` | Circular dependency | Refactor with events/mediator, or use `ObjectProvider<T>` for lazy resolution |
| `NoUniqueBeanDefinitionException` | Multiple beans of same type | Add `@Primary` or `@Qualifier` |
| `ConfigurationPropertiesBindException` | Type mismatch or missing required property | Check `Origin:` line in error for exact file and line |
| `PortInUseException` | Port already bound | `lsof -i :<port>` to find and kill the other process |

### Legacy Version Detection

When debugging existing projects, identify versions first:

```bash
./gradlew dependencies | grep spring-boot     # Spring Boot version
java -version                                   # Java version
./gradlew dependencies | grep javax             # javax presence = pre-3.x
./gradlew dependencies | grep jakarta           # jakarta presence = 3.x+
```

If `javax.*` imports are present alongside Spring Boot 3.x, the project has an incomplete migration — see `reference/legacy-migration.md`.

## Design Principles

- **SOLID** — Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **DRY** — Don't Repeat Yourself. Extract shared logic, but not prematurely.
- **KISS** — Keep It Simple. Prefer straightforward solutions over clever abstractions.
- **YAGNI** — You Aren't Going to Need It. Don't build for hypothetical future requirements.
- **Composition over inheritance** — Inject collaborators via constructor.
- **Program to interfaces** — Depend on port interfaces, not concrete implementations.
- **Separation of concerns** — Domain logic in domain layer, infrastructure in adapters.
- **Fail fast** — Validate inputs early. Throw domain exceptions at the boundary.

## Checklist Before Completion

- [ ] Code compiles: `./gradlew compileJava`
- [ ] Code is formatted: `./gradlew spotlessApply`
- [ ] Static analysis passes: `./gradlew checkstyleMain spotbugsMain pmdMain`
- [ ] All tests pass: `./gradlew test`
- [ ] Vulnerability check: `./gradlew dependencyCheckAnalyze`
- [ ] No Lombok usage anywhere
- [ ] Constructor injection used exclusively
- [ ] All public classes and methods have Javadoc
- [ ] Domain logic lives in `domain/service/`, not adapters
- [ ] DTOs use Records, not mutable classes
- [ ] Exceptions are domain-specific, not generic
- [ ] Reactive chains do not block
- [ ] No business logic in controllers
- [ ] Configuration externalized via Spring Cloud Config Server (new projects)
- [ ] Secrets use environment placeholders — no hardcoded values in source
- [ ] No secrets logged or exposed in error responses
