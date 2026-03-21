---
name: kmp-baseline-skill-blueprint
description: Provides the foundational architecture, best practices, and workarounds for a Kotlin Multiplatform (Android & iOS) project. Use when setting up or extending a KMP project using Compose, Room, Navigation 3, and native integrations.
---

# KMP Baseline

Detailed instructions and best practices for configuring and developing within this KMP architecture.

## When to use this skill

- Use this when initializing a new KMP project that requires Room, Compose Navigation 3, or specific Ktor/Koin configurations.
- This is helpful for resolving tricky Gradle dependencies, debugging "MissingResourceException", or diagnosing KMP database migration issues.
- Use this when working with native UI components in Compose (like `AndroidView` or `UIKitView`) or dealing with native video playback/trimming cross-platform.

## How to use it

Follow the step-by-step guidance, conventions, and patterns below when extending the codebase.

## 1. UI & Responsiveness (Compose Multiplatform)

### Handling Different Screen Sizes
*   **Problem**: Mobile apps are portrait/narrow, while larger screens (tablets) are landscape/wide. A simple `fillMaxSize()` layout often looks stretched or huge.
*   **Solution**:
    *   Wrap your main screen content in a `Box` with `contentAlignment = Alignment.Center`.
    *   Apply `widthIn(max = 600.dp)` (or appropriate size) to the content container.
    *   This ensures the app looks like a mobile app centered on the screen, preventing layout distortion.
    ```kotlin
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(modifier = Modifier.widthIn(max = 600.dp)) { ... }
    }
    ```

### Fonts & Icons
*   **Problem**: Text-based Emojis (e.g., 💣, 🚩) rely on system fonts which may not render consistently.
*   **Solution**:
    *   **Preferred**: Use `Canvas` drawing for simple shapes (Circles, Flags). It guarantees consistent rendering across all platforms.
    *   **Alternative**: Use `compose-material-icons-extended` dependency for standard icons (`Icons.Filled.*`).
    *   **Avoid**: Relying solely on Text Emojis for critical UI elements.

### Keyboard Management (iOS & Android)
*   **Problem**: Multi-line text inputs (like `OutlinedTextField`) keep the software keyboard open when clicking outside of them, which can block vital UI buttons (e.g., Save, Next) at the bottom of the screen. This is particularly noticeable on iOS.
*   **Solution**: Wrap your screen content in a layout (like a `Box`) and use `LocalFocusManager.current` combined with a pointer input tap detector to clear focus when the user taps outside the text field.
    ```kotlin
    val focusManager = LocalFocusManager.current
    Box(
        modifier = Modifier
            .fillMaxSize()
            .pointerInput(Unit) {
                detectTapGestures(onTap = {
                    focusManager.clearFocus()
                })
            }
    ) { ... }
    ```

## 2. Architecture & Dependencies

### Shared Logic
*   **ViewModels in KMP**:
    *   **Avoid**: Do NOT use `expect/actual` classes or `ViewModelFactory` boilerplate.
    *   **Use**: Official KMP Support (`androidx.lifecycle:lifecycle-viewmodel-compose`).
    *   **Implementation**:
        1.  Define ViewModel: `class MyVM : ViewModel()`.
        2.  Call in Compose: `val vm = viewModel { MyVM() }`.
*   **Navigation**:
    *   **Rule**: Use **Navigation 3** (`org.jetbrains.androidx.navigation3:navigation3-ui`) and related components. Do NOT use older `navigation-compose` artifacts as they cause linkage errors on iOS.
    *   **Dependency Group IDs vs Import Packages (CRITICAL for Multiplatform)**:
        *   **Problem**: Getting "Unresolved reference" errors when trying to import `androidx.navigation3...` or when trying to declare dependencies like `navigation3-core`.
        *   **Reason**: JetBrains maintains specific forks/versions of the Navigation 3 libraries for Compose Multiplatform. The *dependency group ID* in your `libs.versions.toml` must be `org.jetbrains.androidx.navigation3` or `org.jetbrains.androidx.lifecycle`. However, the *actual Kotlin imports* in your code remain the standard AndroidX ones (e.g., `androidx.navigation3.ui.NavDisplay`).
        *   **Required Dependencies**: You typically only need `navigation3-ui` and `lifecycle-viewmodel-navigation3`. You generally do *not* need to explicitly declare `navigation3-core`, `navigation3-runtime`, or `savedstate-compose-serialization` in your TOML if you are following standard JetBrains KMP setups, as they are bundled or handled internally.
        *   **Gradle Repositories**: The JetBrains compose dev repository `maven("https://maven.pkg.jetbrains.space/public/p/compose/dev")` MUST be added to `settings.gradle.kts` (under both `pluginManagement` and `dependencyResolutionManagement`). Do NOT add it to the module-level `build.gradle.kts` as it can break resolution for standard AndroidX dependencies.
    *   **API Usage (NavDisplay & Back Stack)**:
        *   **Avoid**: Do NOT use `NavHost` or `NavController` with Navigation 3.
        *   **Use**: `NavDisplay` as the main navigation composable.
        *   **State Management**: Manage the backstack explicitly using `rememberSerializable(serializer = SnapshotStateListSerializer()) { mutableStateListOf<Route>(InitialRoute) }`.
        *   **Route Definition**: Use a `sealed interface` or `sealed class` implementing `NavKey` with `@Serializable` data objects/classes.
        *   **Example (in `App.kt` or similar entry point):**
            ```kotlin
            import androidx.compose.runtime.mutableStateListOf
            import androidx.compose.runtime.saveable.rememberSerializable
            import androidx.lifecycle.viewmodel.navigation3.rememberViewModelStoreNavEntryDecorator
            import androidx.navigation3.runtime.entryProvider
            import androidx.navigation3.runtime.rememberSaveableStateHolderNavEntryDecorator
            import androidx.navigation3.ui.NavDisplay
            import androidx.savedstate.compose.serialization.serializers.SnapshotStateListSerializer
            import kotlinx.serialization.Serializable
            import androidx.navigation3.runtime.NavKey

            @Serializable
            sealed class Screen : NavKey {
                @Serializable data object Home : Screen()
                @Serializable data class Detail(val id: String) : Screen()
            }

            @Composable
            fun App() {
                val backStack = rememberSerializable(serializer = SnapshotStateListSerializer()) {
                    mutableStateListOf<Screen>(Screen.Home)
                }
                val onBack = { if (backStack.size > 1) backStack.removeLast() }

                NavDisplay(
                    backStack = backStack,
                    onBack = onBack,
                    entryProvider = entryProvider {
                        entry<Screen.Home> {
                            HomeScreen(onNavigate = { backStack.add(Screen.Detail("123")) })
                        }
                        entry<Screen.Detail> { destination ->
                            DetailScreen(id = destination.id, onBack = onBack)
                        }
                    },
                    entryDecorators = listOf(
                        rememberSaveableStateHolderNavEntryDecorator(),
                        rememberViewModelStoreNavEntryDecorator(),
                    ),
                )
            }
            ```
    *   **If That Fails Use**: Simple state-based navigation (`var screen by remember { mutableStateOf(...) }`).
*   **Permissions**:
    *   **Rule**: Use `com.mohamedrejeb.calf:calf-permissions` (Calf) for handling permissions in KMP. It is much more reliable and integrates better with Koin and standard Compose Multiplatform than older libraries like Moko.
    *   **Android**: Add `<uses-permission android:name="..." />` to `androidApp/src/main/AndroidManifest.xml` (and `<uses-feature>` tags for hardware like cameras).
    *   **iOS**: Add usage descriptions to `iosApp/iosApp/Info.plist` (e.g., `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`).
*   **Date and Time Handling**:
    *   **Rule**: When working with `Instant` (e.g., for database timestamps), use `kotlin.time.Clock.System.now()` to obtain the current time.
    *   **Reason**: In `kotlinx-datetime` versions 0.7.0 and newer, `kotlinx.datetime.Clock.now()` and `kotlinx.datetime.Instant.now()` were removed. `kotlin.time.Clock.System.now()` from the Kotlin standard library is the correct replacement for getting the current `Instant` in modern Kotlin Multiplatform projects.
    *   **Usage**: Ensure you have `import kotlin.time.Clock` and explicitly `import kotlin.time.Instant` in data classes. Use `@OptIn(ExperimentalTime::class)` where needed.
    *   **Note on `Instant` Deprecation Warning**: If `kotlinx.datetime.Instant` must be used (e.g., in Room `TypeConverters` because it provides necessary `.fromEpochMilliseconds()` methods while `kotlin.time` versions are still stabilizing in KMP), suppress the resulting typealias deprecation warning with `@Suppress("DEPRECATION")` directly on the `Converters` class.

### Database Testing (Room KMP)
*   **Best Practice**: Separate common test logic from platform-specific setup to avoid `kotlin.test` lifecycle issues with `lateinit` properties.
*   **Common Test Class (`shared/src/commonTest/kotlin/.../YourDaoTest.kt`):**
    *   Create an `open class` (e.g., `open class ScriptDaoTest`).
    *   **NO `@Test` annotations** on the methods.
    *   Test methods should accept dependencies as parameters: `open fun testInsertion(database: AppDatabase, dao: ScriptDao)`.
    *   Declare `expect fun getInMemoryDatabase(): AppDatabase`.
*   **Android Tests (`shared/src/androidTest/kotlin/.../AndroidYourDaoTest.kt`):**
    *   **CRITICAL**: Use **Android Instrumented Tests** (`androidTest`), *not* Robolectric (`androidHostTest`). The `BundledSQLiteDriver` requires native libraries (`sqliteJni`) that Robolectric cannot load on the desktop JVM, leading to `UnsatisfiedLinkError`.
    *   Create a class extending the common base: `class AndroidScriptDaoTest : ScriptDaoTest()`.
    *   Declare local `private lateinit var database: AppDatabase` and `private lateinit var dao: ScriptDao`.
    *   Use `@Before` and `@After` (from `org.junit`) to manage the database lifecycle using `Room.inMemoryDatabaseBuilder(ApplicationProvider.getApplicationContext(), AppDatabase::class.java)`.
    *   Override test methods, add `@Test` annotation, and call `super`: `@Test override fun testInsertion() = super.testInsertion(database, dao)`.
    *   Ensure `androidApp/build.gradle.kts` defines `testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"`.
    *   **Run**: `:androidApp:connectedDebugAndroidTest`.
*   **iOS Tests (`shared/src/iosTest/kotlin/.../IosYourDaoTest.kt`):**
    *   **CRITICAL**: To create an in-memory database on iOS, you MUST use `Room.inMemoryDatabaseBuilder(factory = { AppDatabaseConstructor.initialize() })`. Using `Room.databaseBuilder(name = ":memory:", ...)` will throw an `IllegalArgumentException`.
    *   Create a class extending the common base: `class IosScriptDaoTest : ScriptDaoTest()`.
    *   Declare local `private lateinit var database: AppDatabase` and `private lateinit var dao: ScriptDao`.
    *   Use `@BeforeTest` and `@AfterTest` (from `kotlin.test`) to manage the database lifecycle using your `actual fun getInMemoryDatabase()`.
    *   Override test methods, add `@Test` annotation, and call `super`: `@Test override fun testInsertion() = super.testInsertion(database, dao)`.
    *   **Run**: `:shared:iosSimulatorArm64Test`.

### Resources & Compose Multiplatform
*   **MissingResourceException / Resource Packaging**:
    *   **Problem**: Encountering `MissingResourceException: Missing resource with path: composeResources/...` at runtime.
    *   **Reason**: Often resources aren't packed correctly into the final APK or App bundle, or the path changed in newer Compose Multiplatform versions. For instance, in 1.7.0+, Compose Multiplatform generates resource paths that include the project/namespace (e.g., `composeResources/kotlinproject.shared.generated.resources/drawable/image.png`).
    *   **Solution / Troubleshooting**:
        1. Ensure you use the generated `Res` class to reference resources rather than hardcoded string paths.
        2. Verify your Gradle setup doesn't accidentally exclude resources or override `sourceSets`.
        3. A clean build (`./gradlew clean :androidApp:assembleDebug`) is often necessary after adding new files.
        4. If you used `withHostTest { isIncludeAndroidResources = true }` in your KMP android block, verify it's not interfering with Compose Resource packaging.
*   **Configuration (DO NOT CHANGE DEFAULT)**:
    *   **Rule**: Do NOT configure `compose.resources { packageOfResClass = ... }` manually in `shared/build.gradle.kts`.
    *   **Reason**: Manually setting the package name often leads to build/runtime mismatches and `MissingResourceException`. The default generated package is derived from the project structure (e.g., `kotlinproject.shared.generated.resources`).
    *   **Action**: Remove any `packageOfResClass` configuration and let the plugin generate the default package.
    *   **Usage**: Import with `import [rootProject].[subProject].generated.resources.Res` (e.g., `import kotlinproject.shared.generated.resources.Res`).

*   **Resource Naming Convention (CRITICAL)**:
    *   **Rule**: Always use **snake_case** for resource files (e.g., `compose_logo.xml`).
    *   **Reason**: Android tools (AAPT) fail with hyphens (`-`).
*   **File Extensions**:
    *   **Rule**: Ensure file extensions match the actual file content (e.g., do not name a JPEG file `.png`). This can cause runtime decoding errors.

### Gradle & Build Logic
#### Running Gradle Tasks (CRITICAL AI INSTRUCTION)
*   **Rule**: **NEVER** use the raw shell command `run_shell_command("./gradlew ...")` to execute Gradle builds, tests, or syncs unless strictly necessary for a very specific low-level reason. It often hangs, loses buffer output, and causes daemon lockups. 
*   **Solution**: **ALWAYS** use the dedicated IDE `gradle_build` tool (e.g. `gradle_build(commandLine = "assembleDebug")`) or `gradle_sync` tool. This integrates directly with the IDE's build system and provides clean, structured output and error reporting.
*   **KMP Android Instrumented Test Task**: The typical Gradle task for running Android Instrumented Tests in a KMP application module is `:androidApp:connectedDebugAndroidTest`. Avoid `:androidApp:androidTestDebug` as it may not be found.
*   **KMP iOS Simulator Test Task**: The typical Gradle task for running iOS Simulator Tests in a KMP shared module is `:shared:iosSimulatorArm64Test`.
*   **KMP Android Instrumented Test Task**: The typical Gradle task for running Android Instrumented Tests in a KMP application module is `:androidApp:connectedDebugAndroidTest`. Avoid `:androidApp:androidTestDebug` as it may not be found.
*   **KMP iOS Simulator Test Task**: The typical Gradle task for running iOS Simulator Tests in a KMP shared module is `:shared:iosSimulatorArm64Test`.
*   **KMP Android Instrumented Test Task**: The typical Gradle task for running Android Instrumented Tests in a KMP application module is `:androidApp:connectedDebugAndroidTest`. Avoid `:androidApp:androidTestDebug` as it may not be found.
*   **KMP iOS Simulator Test Task**: The typical Gradle task for running iOS Simulator Tests in a KMP shared module is `:shared:iosSimulatorArm64Test`.

#### Avoid Version Roulette (CRITICAL AI INSTRUCTION)
*   **Rule**: Before randomly changing version numbers or regressing to previous library versions, **ALWAYS** follow these steps:
    1.  **Check Existing Documentation**: Consult `.skills/project-skill/SKILL.md` and `AGENTS.md` for any forbidden or recommended versions.
    2.  **Web Search & Official Docs**: Use `web_search` and `search_android_docs` to find official migration guides, known issues, or compatibility tables for the library in question.
    3.  **Prioritize Code Updates**: The error is most likely due to API changes in a newer library version. Focus on updating your code to match the new version's API, rather than downgrading the library.
    4.  **Diagnose Transitive Conflicts**: Use Gradle's `dependencyInsight` command to identify potential transitive dependency mismatches. For example, to diagnose Ktor issues for the iOS ARM64 compilation classpath:
        ```bash
        ./gradlew :shared:dependencyInsight --dependency io.ktor --configuration iosArm64CompileKlibraries
        ```
    5.  **Clear Caches**: If dependency issues persist, try clearing Gradle caches (`./gradlew clean --refresh-dependencies`) and IDE caches (File -> Invalidate Caches...).
    6.  **Upgrade Strategically**: If a newer version of a library resolves a known issue or improves compatibility, consider upgrading *all* related libraries to their latest stable versions together, after thorough research.
*   **AGP (Android Gradle Plugin)**: `9.0.0`
*   **Kotlin**: `2.3.10`
*   **KSP**: `2.3.2` (This is the stable/preview version of `com.google.devtools.ksp:symbol-processing-api` that we verified works well. Use this and do not try to search for or query other versions.)
*   **Compose Multiplatform**: `1.10.0`
*   **Room KMP**: `2.7.0-alpha13`
*   **AndroidX Lifecycle (for ViewModel)**: `2.10.0-alpha06`
*   **Navigation 3**: `1.0.0-alpha06`
*   **Coil**: `3.3.0`
*   **Koin**: `4.1.1`

#### Gradle Config Rules
*   **`libs.versions.toml` formatting**: ALWAYS use hyphens (`-`) for library names instead of camelCase in the `[libraries]` and `[plugins]` block to remain consistent and avoid "Unresolved reference" errors during Gradle sync.
*   **Android Target Configuration in KMP**: When using the `com.android.kotlin.multiplatform.library` plugin (which is modern), do NOT use a standalone `android { ... }` block in `shared/build.gradle.kts`. Instead, configure the android specifics directly within the `androidLibrary { ... }` block inside the `kotlin { ... }` block. Ensure you set the `jvmTarget` inside `compilerOptions`.

*   **Target Hygiene (CRITICAL FIRST STEP)**: 
    *   **Rule**: If a project ONLY targets Android and iOS, you MUST immediately remove `jvm()`, `js {}`, and `wasmJs {}` blocks from `shared/build.gradle.kts`, delete their corresponding source sets (`jsMain`, `wasmJsMain`, `jvmMain`), and remove desktop/web apps from `settings.gradle.kts`. Failing to do this will cause dependency resolution to fail violently when adding mobile-only or mobile-specific KMP libraries.

*   **Version Catalog**: Update `gradle/libs.versions.toml` frequently but verify compatibility between Kotlin, Compose Multiplatform, and AndroidX libraries. Use `./gradlew :shared:assemble` to quickly check dependency resolution.

#### Room KMP Database Initialization (CRITICAL & CORRECTED)
*   **Problem**: Encountering `kotlin.IllegalStateException: Room cannot verify the data integrity. Looks like you've changed schema but forgot to update the version number.` or `Cannot create a RoomDatabase without providing a SQLiteDriver via setDriver()` on iOS.
*   **Solution**: For Room 2.7.0+ in KMP, you must rely on KSP to generate the constructor for non-Android platforms, but you configure the driver via standard factory functions. For *simple, additive* schema changes (like adding new columns with default values), `AutoMigration` is the preferred and simplest approach. For more complex migrations (e.g., column renames, type changes), manual `Migration` classes might still be necessary.
    *   **Rule**: When making any schema changes (adding/removing entities, fields, or changing types), you MUST increment the `version` number in the `@Database` annotation.
    *   **Manual Migrations (The KMP Way)**:
        *   **CRITICAL RULE**: Do NOT write manual migrations using the old Android `SupportSQLiteDatabase` in `androidMain`. This is incompatible with KMP's `BundledSQLiteDriver` and will crash the iOS build or fail at runtime.
        *   Proper manual KMP migrations must be written in `commonMain` using `androidx.sqlite.SQLiteConnection` (part of the new KMP SQLite driver APIs) so they execute on both Android and iOS.
    *   **Development Fallback (Destructive Migration)**:
        *   During active development when the schema changes rapidly and preserving data isn't necessary, the safest and easiest way to prevent `IllegalStateException` crashes is to use `.fallbackToDestructiveMigration(dropAllTables = true)`.
        *   **Implementation**: Add this line directly to the `RoomDatabase.Builder` inside your `getDatabaseBuilder()` functions in both `androidMain` and `iosMain`.
    *   **AutoMigration Process (For Production Additive Changes)**:
        1.  **Configure `AppDatabase.kt`**: Set `version = [NEW_VERSION]`, `exportSchema = true`, and add `autoMigrations = [AutoMigration(from = [OLD_VERSION], to = [NEW_VERSION])]`. Ensure `TypeConverters` are correctly applied.
        2.  **Configure `build.gradle.kts`**: Ensure the `room { schemaDirectory(...) }` block is present and that `ksp` arguments for `room.schemaLocation` are passed for *all* KSP targets (`kspAndroid`, `kspIosArm64`, `kspIosSimulatorArm64`). Example for `kspAndroid` (other KSP targets are similar):
            ```kotlin
            dependencies {
                add("kspAndroid", libs.room.compiler) {
                    arg("room.schemaLocation", "$projectDir/src/commonMain/room/schemas")
                }
                // ... other ksp targets
            }
            ```
        3.  **Generate `OLD_VERSION.json` Schema**: Temporarily set `version = [OLD_VERSION]` in `AppDatabase.kt` and remove the `autoMigrations` block. Run a clean build (`./gradlew clean :androidApp:assembleDebug`) to generate the schema file for the old version. Verify its existence.
        4.  **Re-apply `AutoMigration` and Increment Version**: Set `version = [NEW_VERSION]` in `AppDatabase.kt` and re-add `autoMigrations = [AutoMigration(from = [OLD_VERSION], to = [NEW_VERSION])]`. Run another clean build to validate `AutoMigration` and generate `NEW_VERSION.json`.
    *   **Platform Implementations**: **Do NOT write `actual object AppDatabaseConstructor`.** By suppressing the missing actual warning, we tell KSP to generate the platform-specific actual implementations automatically during the build step.
    *   **Platform Factories**: Provide standard factory functions (e.g., `fun getDatabase(context: Any? = null): AppDatabase` — notice NO `expect/actual` keyword here) in `androidMain` and `iosMain` that use `Room.databaseBuilder<AppDatabase>(...).setDriver(...).build()`. You should **remove any explicit `.addMigrations()` calls if `AutoMigration` is used for that specific version range, and remove `.fallbackToDestructiveMigration()` as it is no longer needed/recommended.**
        *   **iOS specific**: You must explicitly call `.setDriver(BundledSQLiteDriver())` on the builder.

### Networking & Ktor
#### Gemini API Configuration
*   **Problem**: Encountering 400 Client Errors ("No candidates received") when using older Gemini models.
*   **Solution**: Ensure you are using the correct endpoint URL and payload structure for the specific model. The `v1beta` endpoint for `gemini-2.5-flash` requires a very specific `contents` array structure. You MUST use the `gemini-2.5-flash` model version as older ones may be deprecated or restricted.
    *   **Endpoint**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey`
    *   **JSON Structure**: 
        ```json
        { "contents": [ { "parts": [ { "text": "Your prompt here" } ] } ] }
        ```

*   **Problem**: Encountering `java.lang.ExceptionInInitializerError` or `java.lang.NoClassDefFoundError` when instantiating `HttpClient()` from `io.ktor.client.HttpClient` in `commonMain`.
*   **Reason**: Ktor's `HttpClient` requires a platform-specific "engine" (like OkHttp on Android, Darwin on iOS) to actually make the network calls. If the engine dependency isn't provided to the specific target source sets, the client fails to initialize at runtime.
*   **Solution**:
    1.  Add `implementation(libs.ktor.client.okhttp)` to the `androidMain.dependencies` block.
    2.  Add `implementation(libs.ktor.client.darwin)` to the `iosMain.dependencies` block.
*   **Problem**: Encountering `java.lang.SecurityException: Permission denied (missing INTERNET permission?)` on Android when making network calls.
*   **Reason**: Android applications require explicit permission declared in the manifest to access the internet, even if using Ktor in `commonMain`.
*   **Solution**: Ensure `<uses-permission android:name="android.permission.INTERNET" />` is added to your `androidApp/src/main/AndroidManifest.xml`.

#### Troubleshooting & IDE Caching
*   **Problem**: Not seeing all the code modules, or project files look broken.
*   **Solution**: **Ensure Android Studio project view is changed from "Android View" to "Project View"** using the dropdown in the top-left of the Project tool window. This is required to see all KMP directories like `shared` and `iosApp`.
*   **Problem**: Newly added resources (e.g., images in `composeResources`) are not found at runtime (causing `MissingResourceException`), or stubborn dependency/build issues persist despite correct configuration.
*   **Solution**: Android Studio and Gradle caches can get out of sync, especially in KMP projects. 
    1. Run a clean build (`./gradlew clean assembleDebug`).
    2. If that fails, go to **File -> Invalidate Caches... -> Check 'Clear file system cache and Local History' -> Invalidate and Restart**.

#### iOS Build & Xcode Troubleshooting (CRITICAL)
*   **Problem**: You get vague Kotlin iOS linkage or compilation errors (e.g., `linkDebugFrameworkIosSimulatorArm64` fails, `Cannot infer a bundle ID`, etc.) and running Gradle commands or grepping errors doesn't give a clear reason.
*   **Solution**: The issue is often native Xcode configuration, most commonly missing Provisioning Profiles or Team Signing. **Do not randomly execute gradle commands to diagnose iOS native errors.**
*   **Steps to Fix**:
    1.  Stop the agent execution and ask the User to open the project natively.
    2.  User Action: Right-click the `iosApp/iosApp` folder and select "Open in Finder" (or navigate via terminal).
    3.  User Action: Double-click `iosApp.xcodeproj` to open it in Xcode.
    4.  User Action: Select the `iosApp` target -> go to the **Signing & Capabilities** tab.
    5.  User Action: Configure the "Team" (select the Apple Developer team).
*   **Rule**: If iOS builds fail mysteriously, stop and explicitly ask the user to open Xcode to diagnose the real issue and fix signing.

#### iOS Deployment Troubleshooting
*   **Problem**: Deployment fails with the error `The developer disk image could not be mounted on this device.`
*   **Solution**: The run configuration is currently pointing to a physical iPhone that is either disconnected or locked. 
    *   **User Action**: Change the deployment target in Android Studio / Xcode to a running iOS Simulator, or ensure the physical device is plugged in and unlocked.

## 3. Useful Reference Documentation

As KMP and Compose Multiplatform are rapidly evolving, refer to these primary sources for the latest patterns, versions, and migrations:

*   **Compose Navigation 3 Official Docs**: [https://kotlinlang.org/docs/multiplatform/compose-navigation-3.html](https://kotlinlang.org/docs/multiplatform/compose-navigation-3.html) - Official concepts for `NavDisplay`, `NavKey`, and backstack management.
*   **KMP App Template Repository**: [https://github.com/Kotlin/KMP-App-Template](https://github.com/Kotlin/KMP-App-Template) - Maintained by JetBrains, this is the gold standard for current architecture and dependencies.
    *   *Navigation 3 Migration PR*: [https://github.com/Kotlin/KMP-App-Template/pull/62/changes](https://github.com/Kotlin/KMP-App-Template/pull/62/changes) - Excellent reference for exact dependency coordinates, imports, and polymorphic serialization setup used in our project.
*   **Compose Multiplatform Releases**: [https://github.com/JetBrains/compose-multiplatform/releases](https://github.com/JetBrains/compose-multiplatform/releases) - Check here for version compatibility between Kotlin and Compose.

## 4. Video Playback & Editing (KMP)
Working with Native Video (especially `VideoTrimmer` and `VideoPlayer`) requires strict adherence to native API limitations to avoid crashes.

*   **AndroidView & Recomposition Bug (CRITICAL)**:
    *   **Problem**: You get "Can't play this video" or continuous video reloading when modifying state elsewhere on the screen.
    *   **Solution**: `AndroidView`'s `update = { ... }` block runs on *every single recomposition*. Do NOT put `videoView.setVideoURI()` inside the `update` block, otherwise the player resets from scratch repeatedly. Instead, leave the `update` block empty and use `LaunchedEffect(url)` and `LaunchedEffect(seekRequest)` to control the VideoView asynchronously.
*   **iOS Sandbox UUID Mapping**:
    *   **Problem**: Video trimmer fails with "requested URL was not found on this server" after rebuilding the iOS app.
    *   **Solution**: The iOS App Sandbox UUID changes on every fresh build. If you store absolute file paths (e.g. to `Documents` or `tmp`), they become invalid. You MUST parse the filename and prepend the current `NSTemporaryDirectory()` or `NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, ...)` every time you resolve a path before playback or trimming.
*   **Android `MediaMuxer` Corrupt Output**:
    *   **Problem**: Trimming results in a corrupted MP4 file that throws "Can't play this video" in the Publishing Studio.
    *   **Solution**: Android's `MediaMuxer` requires *strictly monotonic* timestamps. When reading interleaved audio/video from `MediaExtractor`, timestamps can jitter backwards. Maintain a `val lastWrittenTimeUs = mutableMapOf<Int, Long>()` and only `writeSampleData` if `pts > lastPts`.
*   **iOS `AVAssetExportSession` Silent Failures**:
    *   **Problem**: Native iOS trimming completes instantly but returns `false` or fails.
    *   **Solution**: Do NOT use `AVAssetExportPresetHighestQuality` if stitching segmented slices, as slight encoding differences cause failures. Always use `AVAssetExportPresetPassthrough` to slice and copy frames without re-encoding.
*   **Async Seek Debouncing**:
    *   **Problem**: The UI jumps back and forth infinitely when seeking the video via state updates.
    *   **Solution**: `seekToTime` on iOS and `seekTo` on Android are asynchronous. The video's time observer loop will continue to fire old timestamps *after* you request a seek. Add a `delay(200)` inside the `LaunchedEffect(seekRequest)` right after the native seek command to debounce the old callbacks before you listen to `onTimeUpdate` again.