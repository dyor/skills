---
name: compose-migration-hints
description: A collection of architectural, UI, and workflow guidelines learned from migrating apps to Android using Jetpack Compose, Room, Koin, and Maps.
version: 1.0.1
author: dyor
---

# `compose-migration-hints` Skill

When migrating an application to Android using Jetpack Compose, or when developing a new complex Compose application, reference these guidelines. They represent hard-won lessons regarding UI performance, tooling quirks, and architectural best practices.

## 1. Agent Workflow & Tooling Patterns

### Batch I/O to Prevent IDE Interruptions
When generating long reports or resizing multiple images, **do not** use piecemeal shell commands (`echo`, `cat << EOF`, or running `sips`/`mogrify` in a loop). This triggers aggressive and constant IDE security permission prompts. 
*   **Solution:** Accumulate markdown strings or file contents purely in memory, then use the native `write_file` tool *once* at the very end. Execute bash scripts for batch image processing via a single script invocation.

### Image Paths in Markdown
Android Studio's Markdown renderer requires specific pathing to render local images properly.
*   **Solution:** Always use the `file://` scheme with an absolute path to the project directory: `![Alt Text](file://<absolute_project_path>/.journey_reports/.../image.png)`. Relative paths or missing `file://` schemes often result in broken image links.

### The "Before/After" TDD Reporting Workflow
When a Journey Test fails on a UI step, do not just fix the code and generate a passing report. 
*   **Solution:** Utilize the failed run's screenshots as the "Before" state. Fix the code, re-run the test, and capture the "After" state. Embed these side-by-side in a Markdown table to explicitly prove to the developer that the fix was successful and matches the expected design.

## 2. Jetpack Compose UI Patterns

### Safe Hex Color Parsing
Databases or external APIs often provide colors in formats that crash Android's parser (e.g., missing the `#` prefix, or unsupported lengths).
*   **Solution:** Always use a defensive parsing wrapper:
    ```kotlin
    val safeColor = if (rawColorString.startsWith("#")) rawColorString else "#$rawColorString"
    val composeColor = try { 
        Color(android.graphics.Color.parseColor(safeColor)) 
    } catch (e: Exception) { 
        Color.Gray // Safe fallback
    }
    ```

### Custom Canvas Drawing for Complex Lists
When building complex, connected lists (like a transit line timeline where stops are connected by vertical lines), standard `Row` and `Column` constraints can become convoluted and perform poorly.
*   **Solution:** Use `Modifier.drawBehind { }` on the container Box to draw the connecting lines and circular nodes dynamically based on the item's index (e.g., don't draw the top line for `isFirst`, don't draw the bottom line for `isLast`).

### Overlapping UI Elements
To float elements (like Map FABs, Bottom Sheets, or Toasts) securely over a base layer without clipping:
*   **Solution:** Use a `Box` and `Alignment`.
    ```kotlin
    Box(modifier = Modifier.fillMaxSize()) {
        GoogleMap(modifier = Modifier.fillMaxSize())
        
        FloatingActionButton(
            modifier = Modifier.align(Alignment.TopEnd).padding(16.dp)
        ) { /* ... */ }
        
        Card(
            modifier = Modifier.align(Alignment.BottomCenter)
        ) { /* Bottom Sheet Content */ }
    }
    ```

## 3. Map & Location Integration

### Mandatory Map Clustering
Rendering hundreds or thousands of individual `Marker` composables on a `GoogleMap` will cause severe frame drops and a visual "sea of pins".
*   **Solution:** You must use the `Clustering` API from the `maps-compose-utils` library.
    ```kotlin
    // Requires: implementation("com.google.maps.android:maps-compose-utils:x.x.x")
    val clusterItems = stations.map { StationClusterItem(it) }
    Clustering(
        items = clusterItems,
        onClusterItemClick = { item -> /* Handle Click */ true }
    )
    ```

### Secure API Key Management
Never check the Google Maps API key into source control (e.g., hardcoded in `AndroidManifest.xml`).
*   **Solution:** Place it in `local.properties`: `MAPS_API_KEY=AIzaSy...`
*   Read it in `build.gradle.kts`:
    ```kotlin
    val localProperties = Properties()
    localProperties.load(rootProject.file("local.properties").inputStream())
    val mapsApiKey = localProperties.getProperty("MAPS_API_KEY") ?: ""
    
    android {
        defaultConfig {
            manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
        }
    }
    ```
*   Inject it in `AndroidManifest.xml`:
    ```xml
    <meta-data android:name="com.google.android.geo.API_KEY" android:value="${MAPS_API_KEY}" />
    ```

## 4. Architecture & Data Management

### Dependency Injection with Koin
Avoid manual instantiation of ViewModels inside Compose navigation graphs.
*   **Solution:** Use `koinViewModel()`. For ViewModels requiring runtime parameters (like a specific `lineId` selected from a list), pass them cleanly:
    ```kotlin
    val viewModel: LineDetailViewModel = koinViewModel(parameters = { org.koin.core.parameter.parametersOf(lineId) })
    ```

### Room Database Pre-population
When migrating an app that relies on a large, static dataset (like transit network topology), do not force the app to download or parse this data on first launch.
*   **Solution:** Package the `.db` file in the `src/main/assets/` folder and use `createFromAsset()` when building the Room database.
    ```kotlin
    Room.databaseBuilder(context, TransitDatabase::class.java, "transit.db")
        .createFromAsset("transit.db")
        .build()
    ```
