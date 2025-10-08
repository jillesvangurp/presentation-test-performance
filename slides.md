# Parallel Spring Boot Integration Tests

## From >5 minutes to < 30 seconds

<!-- .slide: class="title-slide" -->

<section>
  <div style="display: flex; justify-content: center; align-items: center; gap: 2em;">
    <img src="yellowmustang.webp" alt="Yellow Mustang" style="height:15vh; object-fit:cover;" />
    <img src="mustang-jilles.png" alt="Mustang Jilles" style="height:15vh; object-fit:cover;" />
  </div>
</section>

### Jilles van Gurp

---
### Whoami

- @jillesvangurp, www.jillesvangurp.com, tryformation.com
- CTO of FORMATION Gmbh
  > Maps for Factories & Logistics.
- Using Java between **1995-2017**, Kotlin **2018-now**:
- Yes, I'm a bit "senior"
  > If you are not using Spring with Kotlin, you are doing it wrong!


---

## Some OSS stuff I work on

<img src="jilles-github.jpg" alt="Jilles GitHub" style="width:100%; height:auto; display:block; margin:auto;" />
---
## Agenda

- ⚡ The need for speed
- 🧪 Unit vs. Integration Tests
- ⚡ Parallel tests HOWTO
  - ⚙️ JUnit Parallel Options
  - What can go wrong?
  - 🧼 Avoiding the Need for Cleanup
  - 🎲 Randomize Test Data
  - ⏱️ Poll, Don’t Sleep
- 🔁 Recap

---

## ⚡ The need for speed

> Life is too short for slow builds.


<section>
  <div style="display: flex; gap: 3em; justify-content: center; align-items: flex-start;">
    <ul>
      <li>Interrupted flow</li>
      <li>Procrastination</li>
      <li>Time is money</li>
      <li>Context switches</li>
    </ul>
    <ul>
      <li>Less frequent commits</li>
      <li>YOLO! Don't run tests before committing</li>
      <li>Long feedback cycles</li>
      <li>...</li>
    </ul>
  </div>
</section>



---

## Goal

- Tests run fast
  - 89 unit tests & 284 integration tests
  - **~23** seconds (excluding compilation)
- Use available CPU (Macbook Pro M4 Max, 48GB)
  - 14 CPU cores & threads

![Speedy Tests](speedy-tests.webp)
<!-- .element: style="display:block; margin: 1em auto; width:80%;" -->

---

## Unit Test

> A **unit test** verifies the behavior of a single, isolated piece of code—typically a function or class—under controlled conditions.
> It runs quickly, avoids external dependencies like databases or APIs, and ensures that logic works as expected in isolation.

- [Wikipedia – Unit testing](https://en.wikipedia.org/wiki/Unit_testing)
- [BrowserStack – Types of Testing](https://www.browserstack.com/guide/types-of-testing)
- [Martin Fowler – Unit Test](https://martinfowler.com/bliki/UnitTest.html)
---

## Integration Test

> An **integration test** verifies that multiple components of a system work together correctly.
> It exercises real dependencies such as databases, APIs, or messaging systems, and focuses on validating end-to-end behavior rather than isolated logic.

- [Wikipedia – Integration testing](https://en.wikipedia.org/wiki/Integration_testing)
- [Atlassian – Types of Software Testing](https://www.atlassian.com/continuous-delivery/software-testing/types-of-software-testing)
- [Software Testing Fundamentals – Integration Testing](https://softwaretestingfundamentals.com/integration-testing/)
---

## Unit vs. Integration Test (1/2)

| Aspect | Unit Test | Integration Test |
|---------|------------|------------------|
| **Scope** | Single function or class | Multiple components or systems |
| **Dependencies** | None (uses mocks/stubs) | Real systems (DB, APIs, queues, etc.) |
| **Speed** | Very fast (milliseconds) | Slower (seconds or more) |
| **Isolation** | Fully isolated | Interdependent |
| **Purpose** | Validate logic correctness | Validate system interaction and behavior |

---

## Unit vs. Integration Test (2/2)

| Aspect | Unit Test | Integration Test |
|---------|------------|------------------|
| **Reliability** | High consistency | Can vary with environment setup |
| **Maintenance** | Easy and low-cost | Harder and higher-cost |
| **Typical Tools** | JUnit, Mockito | Spring Boot Test, Testcontainers |
| **Execution Frequency** | Every build/commit | CI pipeline or nightly runs |
| **Failure Cause** | Logic or algorithm bug | Configuration, network, or integration issue |

---

## Test coverage vs. Realism

- Test either for **coverage** or for **realism**
- Unit testing is about test coverage
  - Unit is small enough that you can **test permutations** of input
- Integration testing is about realism
  - The permutations of possible inputs is **not computable**
  - Next best thing: **test things that users do**

---

## Scenario tests

- The **most realistic** form of integration testing
- End to end testing your system from the outside.
- As close to the **"real" system** as you can get away with
- Fake/mock as little as possible
- Touch as much of your system as you can.
- Don't waste a good scenario - add more to it.
- It's all about testing **side effects**, triggering **feature interactions**, and the **unexpected stuff** that happens in the real world.

---

## From Unit to Integration test

### Pure Unit test

Logic test, mock test,

### ~~Somewhere in between~~ Half-assed integration test

Whitebox test, database testing with sqlite, using fakes, ...

### 'Pure' Integration test

BDD, Blackbox test, Performance test, **Scenario Test**, Load test, Stress Test, Contract Test, Smoke Test, Chaos Test, Compliance Test, ...

---

## Half-assed tests

- All the downsides of integration testing without most of the upsides
- Coverage is an illusion (permutations of inputs is like integration test)
- Still slow and costly
- But maybe less costly than a full integration test
- A full integration test is what you want.

### If only we could integration test faster?! ....

---
<!-- .slide: class="title-slide" -->
## Parallizing your tests

- A M4 Max has 14 CPU cores
- Why use only 1 core when you run tests? You could be **14x** as fast.
- Integration tests are IO constrained and spend a lot of time idling/waiting.
- JUnit Parallel Options

### What could possibly go wrong?

---

## About our backend

<img src="arch.svg" alt="Enrichment flow" style="width:80%;margin:auto;">

---

## What does it do

- Users & Teams
- Map Marker CRUD
- Asset Tracking
- ...
- Async Search indexing pipeline
  - Search is a critical part of our stack

<img src="enrich.svg" alt="Enrichment flow" style="width:80%;margin:auto;">

---

## Our Test Setup

- **Spring Boot** test context with API server & some test beans
- **Docker Compose** for Elasticsearch, Valkey, and Postgres
  - Compose for gradle plugin
- Simple Kotlin tests
  - **junit 6**
  - kotest-assertions
    - Nice idomatic kotlin assertions
      - `(40 + 2) shouldBe 42`
    - Support for async stuff
      - `eventually {...}` Runs until it passes

---

## A typical scenario test

- **Given** a team and some users and some map objects
- **When** Do some REST calls
- **Wait** for things to happen in Redis/Elasticsearch
- **Assert** Stuff

```kotlin [3-7|8-24|26-32]
    @Test
    fun `should lookup by specific id`() = runTest {
        val team = createTeam()

        val adminClient = team.admin.client
        val externalId = randomExternalId()
        val macAddress = randomMacAddress()

        val objId = adminClient.updateOrCreateExternalObjects(
            groupId = team.groupId,
            updates =
                listOf(
                    ExternalObjectUpdate(
                        externalId = externalId,
                        updatePointLocation = UpdatePointLocation(position = randomLatLon()),
                        assetInformation = AssetInformation(
                            displayName = "My Tracked Object",
                            specificIds = listOf(
                                SpecificId("name", macAddress, IdType.MAC)
                            )
                        )
                    ),
                ),
        ).shouldBeSuccess().entries.first().value

        eventuallyWithTimeout {
            adminClient.lookupCode(team.groupId, macAddress) shouldBeSuccess {
                it.shouldBeInstanceOf<CodeLookupResult.GeoObject> { obj ->
                    obj.result.id shouldBe objId
                }
            }
        }
    }
```

---

## Let's make this go voom!

- We have 284 tess
- 5-20 REST requests per test
- Elasticsearch, Redis, DB
- Requests 10-100 ms
- + wait/poll time in tests
- How to get this running in **23 seconds**?

> Keep those cores busy!

---

## Junit configuration

### Parallel Test Execution in Gradle

```kotlin [49-55|57-67|69-73]
tasks.withType<Test> {
    this.jvmArgs("-XX:MaxMetaspaceSize=512m", "-Xms1024m", "-Xmx1024m")
//    logger.lifecycle("in CI: '$runningInCi' failFast is enabled")
    failFast = false
    // note, we start ES on port 9999 so we can avoid having it accidentally put garbage on port 9200
    // if you have another locally running elasticsearch.
    // run with -PdockerComposeTestsEnabled=true to let gradle start docker compose
    // or start it manually
    val excludeTagsProp = System.getProperty("excludeTags")?.takeIf { it.isNotBlank() }
    val excludeTagsList = excludeTagsProp?.split(',')?.map(String::trim) ?: emptyList()
    val skipCompose = "integration-test" in excludeTagsList

    if (!skipCompose) {
        val isUp = try {
            URI.create("http://localhost:9999").toURL().openConnection().connect()
            true
        } catch (e: Exception) {
            false
        }

        logger.lifecycle("test server isUp: $isUp")

        if (!isUp) {
            println("Docker comppose not up")
            // if it is not running, use docker compose
            dependsOn("composeUp")
            // this enables us to detect that we want to run es tests
            // deprecated, will be removed
            systemProperty("dockerComposeTestsEnabled", "true")

            // comment this out if you want to reuse ES between test runs when debugging
            // avoids the overhead of restarting docker compose
            finalizedBy("composeDown")
        } else {
            println("Docker compose is up already")

        }
    }
    // https://junit.org/junit5/docs/snapshot/user-guide/index.html
    // note tests run concurrently because of systemProperties["junit.jupiter.*"] below
    // this is a junit thing
    useJUnitPlatform {
        val include = System.getProperty("includeTags")?.takeIf { it.isNotBlank() }
        include?.split(',')?.map(String::trim)?.let { includeTags(*it.toTypedArray()) }
        if (excludeTagsList.isNotEmpty()) {
            excludeTags(*excludeTagsList.toTypedArray())
        }
    }

    systemProperties["junit.jupiter.execution.parallel.enabled"] = "true"
    // executes test classes concurrently
    systemProperties["junit.jupiter.execution.parallel.mode.default"] = "concurrent"
    // executes tests inside a class concurrently
    systemProperties["junit.jupiter.execution.parallel.mode.classes.default"] = "concurrent"
    systemProperties["junit.jupiter.execution.parallel.config.strategy"] = "fixed"

    val threads = max(3,
        Runtime.getRuntime().availableProcessors()-2 // make sure we don't starve es & db & server of cpu cores
    )
    // Why this works: our eventually blocks cause threads to spend a lot of time delaying
    println(
        "running tests with $threads threads on a machine with ${
            Runtime.getRuntime().availableProcessors()
        } CPUs and ${Runtime.getRuntime().maxMemory() / 1024 / 1024} MB memory",
    )
    systemProperties["junit.jupiter.execution.parallel.config.fixed.parallelism"] = threads
    systemProperties["junit.jupiter.execution.parallel.config.fixed.max-pool-size"] = threads

    systemProperties["junit.jupiter.testclass.order.default"] =
        "org.junit.jupiter.api.ClassOrderer\$ClassName"
    systemProperties["junit.jupiter.testclass.order.random.seed"] = "42"
    // works around an issue with the ktor client and redis client needing more than 64 threads in our tests.
    systemProperties["kotlinx.coroutines.io.parallelism"] = "200"

    // junit test runner in gradle ignores @ActiveProfile, go figure
    systemProperty("spring.profiles.active", "test")

    testLogging.exceptionFormat = TestExceptionFormat.FULL
    testLogging.events = setOf(
        TestLogEvent.FAILED,
        TestLogEvent.PASSED,
        TestLogEvent.SKIPPED,
        TestLogEvent.STANDARD_ERROR,
        TestLogEvent.STANDARD_OUT,
    )
    addTestListener(
        object : TestListener {
            val failures = mutableListOf<String>()
            override fun beforeSuite(desc: TestDescriptor) {
            }

            override fun afterSuite(desc: TestDescriptor, result: TestResult) {

            }

            override fun beforeTest(desc: TestDescriptor) {
            }

            override fun afterTest(desc: TestDescriptor, result: TestResult) {
                if (result.resultType == TestResult.ResultType.FAILURE) {
                    val report =
                        """
                    TESTFAILURE ${desc.className} - ${desc.name}
                    ${
                            result.exception?.let { e ->
                                """
                            ${e::class.simpleName} ${e.message}
                        """.trimIndent()
                            }
                        }
                    -----------------
                    """.trimIndent()
                    failures.add(report)
                }
            }
        },
    )
}

---
## Base class for tests

```kotlin [4-8]
@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.DEFINED_PORT)
// needed so we can have @BeforeAll on non static functions
@TestInstance(
    TestInstance.Lifecycle.PER_CLASS
)
@Execution(ExecutionMode.CONCURRENT)
@Tag("integration-test")
abstract class APITest : ClientCreator {
...
```

- Run Concurrent
- Every test class gets scheduled on its own thread
- Tag as integration test so we can run the unit tests really fast!

```bash
./gradlew  check -DexcludeTags=integration-test

```

---

## ⚠️ Potential Problems

> Parallel tests = speed 🏎️ + chaos 💥 if you’re not careful.

- 🧩 **Test interaction** — shared state or data collisions across tests
- 💾 **Resource contention** — DB, ports, temp files, or caches competing for access
- 🕸️ **Non-thread-safe code** — singletons, static mocks, or global config mutated in parallel
- 💤 **Race conditions & timing issues** — async jobs or delayed cleanup causing flakiness
- 👻 **Heisenbugs** — failures that vanish when debugged
- 🧭 **Order dependence** — tests assuming sequence or leftover state

---

## A simple guide to parallel testing

- 🎲 **Randomize test data** Unique IDs prevent collisions
- 🚫 **No Cleaning** Don’t clean between tests
- 🔄 **Poll, don’t sleep** Check until stuff passes, instead of sleeping.
- 🧩 **Embrace Flakiness** These are the bugs you want to find. Deflakification makes your system better.
- 💡**DRY Tests** Don't Repeat Yourself. Avoid copy paste. Invest time in writing shorter tests.

> This works on any kind of backend system.
---

## Randomizing Test data

- Kotlin's random
- A few simple functions like `randomLocation()`, `randomExternalId()`, etc.
- inbot-testfixtures
  - Really old library that I haven't touched in 7 years (still in Java :-( )
  - `val person = RandomNameGenerator(seed).`

> Bottom line: no hard coded strings == no test colissions

```kotlin
    suspend fun createTeam(
        numberOfMembers: Int = 1,
        teamName: String =
            randomNameGenerator.nextPerson().domainName.replace("[.][^.]+$".toRegex(), ""),
        addTrackerUser: Boolean = false,
        formationAdminTeam: Boolean = false,
        vararg groupFeatureFlags: GroupFeatureFlags,
    ) =
        teamAndClientCreator.createTeam(
            numberOfMembers,
            teamName,
            addTrackerUser,
            formationAdminTeam,
            groupFeatureFlags = groupFeatureFlags
        )

```

## No cleaning between tests

- **Why** There's always other tests running
- **Speed** Cleaning is slow. Not cleaning is faster.
- **Realism** Real users won't be using an empty database by themselves either
- **Easy** Just skip it. You don't have to do anything for that

> Clean at the beginning and reinitialize your db & schema.

---

## Polling with eventually

```kotlin [1-6|21-22|23-50|52-52]
eventuallyWithTimeout {
    adminClient.lookupCode(team.groupId, macAddress) shouldBeSuccess {
        it.shouldBeInstanceOf<CodeLookupResult.GeoObject> { obj ->
            obj.result.id shouldBe objId
        }
    }
}

...

suspend fun <T> eventuallyWithTimeout(
    wait: Duration = 1.minutes,
    message: String? = null,
    log: Boolean = false,
    block: suspend () -> T,
): T {
    eventuallyWaiting.incrementAndGet()
    try {
        var retryCounterLocal = 0
        return measureTimedValue {
                eventually(
                    eventuallyConfig {
                        this.duration = wait
                        if (eventuallyWaiting.get() > 5) {
                            this.initialDelay = 1.seconds
                        } else this.initialDelay = Duration.ZERO

                        // back off the longer it takes
                        this.intervalFn = DurationFn { count ->
                            eventuallyTotalRetryCount.incrementAndGet()
                            retryCounterLocal++

                            val d =
                                when {
                                    count < 2 -> 0.1.seconds
                                    count < 5 -> 0.3.seconds
                                    count < 15 -> 0.6.seconds
                                    // by this time, we are several seconds in so slow down until
                                    // enrichment catches up
                                    else -> 2.seconds
                                }

                            d.also {
                                if(log) {
                                    logger.info {
                                        "retry $count${message?.let { ". $it" } ?: ""}. next wait $it, total waiting: $eventuallyWaiting"
                                    }
                                }
                            }
                        }
                    },
                    block
                )
            }
            .let { tv ->
                eventuallyCompletedBlockCount.incrementAndGet()
                eventurallyTotalSleepMillis.addAndGet(tv.duration.inWholeMilliseconds)
                if(log) {
                    logger.info {
                        "eventually exited after ${tv.duration} and $retryCounterLocal retries. Cumulative sleep time ${eventurallyTotalSleepMillis.get().milliseconds}"
                    }
                }
                tv.value
            }
    } finally {
        eventuallyWaiting.decrementAndGet()
    }
}
```
---
## Stats


![Speedy Tests](stats.png)
<!-- .element: style="display:block; margin: 1em auto; width:100%;" -->

---
## DRY Principle

- Automate repetitive things
- Like code you copy for every test
- With integration tests, test setup is most of the work
  - Remove any excuses
- Make creating stuff easy
- Make asserting stuff easy
- Group things you call together in functions
- Use Kotlin DSLs

---

## Effective Testing is a mindset

- Don't accept slow tests, do something about it
- Remove excuses to test
- Fast tests is a great excuse to get a nice fast laptop

---

### Benefits

- ⚡ **Fast tests!** — massive time savings and faster feedback loops
- 🤝 **Realistic concurrency** — simulates real-world multi-user load
- 🔍 **Performance visibility** — bottlenecks and locking issues surface early
- 🧠 **Improved confidence** — fewer surprises in production
- 🧩 **Better code quality** — forces testable, thread-safe, stateless design
- 🔁 **Continuous integration friendly** — parallel runs scale well on CI agents
- 💰 **Lower CI costs** — faster runs = less compute time billed
- 🧪 **Improved coverage of edge cases** — concurrency often reveals hidden bugs
- 🧼 **No cleanup overhead** — randomized test data eliminates teardown logic
- 🧠 **Production parity** — mirrors how your real systems behave under load

---

## Questions?!

- 🧑‍💻 jillesvangurp on GitHub, X, etc.
- 🚫 we are **not yet** hiring
  - 💻 multiplatform Kotlin
  - ⚙️ Kotlin / Spring Boot
  - 🎨 Kotlin-JS / frontend
  - 📦 Kotlin multiplatform libraries
  - ❤️ ... we love Kotlin

---

## Thanks
