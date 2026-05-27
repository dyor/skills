---
name: implement-native-firebase-kmp
description: Guides the implementation of Firebase in a KMP project using native platform SDKs (Android/iOS) via Interface Injection, avoiding third-party KMP wrappers.
version: 1.0.0-experimental
---

# Skill: Implement Native Firebase in KMP

## Overview
Currently, there is no official Firebase Kotlin Multiplatform SDK. While community wrappers like GitLive exist, teams often prefer using the official, up-to-date Android and iOS native SDKs directly. 

This skill guides the AI Agent and User through implementing Firebase (e.g., Analytics/Crashlytics) using the **Interface Injection** pattern. This pattern keeps the Kotlin shared code clean, utilizes standard Gradle dependencies for Android, and leverages Swift Package Manager (SPM) natively in Xcode for iOS, entirely avoiding the complexities of Kotlin CocoaPods / cinterop.

## Execution Protocol

When the user asks to "Add Firebase using native implementations", "Implement Firebase Analytics", or similar, follow these steps sequentially:

### Step 1: Define the Shared Interface (`commonMain`)
Create a contract in the shared module that the UI and business logic can use, oblivious to the underlying platform SDK.

- **Agent Action**: Create `FirebaseAnalyticsService.kt` in `shared/src/commonMain/kotlin/.../domain/`.
```kotlin
package org.example.project.domain

interface FirebaseAnalyticsService {
    fun logEvent(eventName: String, parameters: Map<String, String> = emptyMap())
    fun setUserId(userId: String)
}
```

### Step 2: Android Native Implementation (`androidMain` & `androidApp`)
Use the standard Android Firebase SDKs. 

- **Agent Action**: Add the Firebase BoM and Analytics dependencies to `androidApp/build.gradle.kts` (or `shared/build.gradle.kts` in the `androidMain` source set).
```kotlin
dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    // Add Analytics
    implementation("com.google.firebase:firebase-analytics")
}
```
- **Agent Action**: Create the Android implementation in `shared/src/androidMain/kotlin/.../data/AndroidFirebaseAnalyticsService.kt`.
```kotlin
package org.example.project.data

import android.content.Context
import android.os.Bundle
import com.google.firebase.analytics.FirebaseAnalytics
import org.example.project.domain.FirebaseAnalyticsService

class AndroidFirebaseAnalyticsService(context: Context) : FirebaseAnalyticsService {
    private val firebaseAnalytics = FirebaseAnalytics.getInstance(context)

    override fun logEvent(eventName: String, parameters: Map<String, String>) {
        val bundle = Bundle().apply {
            parameters.forEach { (key, value) -> putString(key, value) }
        }
        firebaseAnalytics.logEvent(eventName, bundle)
    }

    override fun setUserId(userId: String) {
        firebaseAnalytics.setUserId(userId)
    }
}
```
- **User Action**: Prompt the user to add the `google-services.json` file downloaded from the Firebase Console to the `androidApp/` directory and add the `com.google.gms.google-services` plugin to the root and app `build.gradle.kts`.

### Step 3: iOS Native Implementation (Swift)
Instead of fighting Kotlin cinterop, we implement the interface entirely in Swift and pass it to the Kotlin `AppContainer` or Compose entry point.

- **User Action**: Instruct the user to open Xcode (`iosApp.xcodeproj`) and use Swift Package Manager (File > Add Package Dependencies...) to add `https://github.com/firebase/firebase-ios-sdk`. Instruct them to add `GoogleService-Info.plist` to the Xcode project.
- **Agent Action**: Write the Swift implementation instructions/template to a temporary file (or just print it to the user) so they can copy it into `iOSApp.swift`.

```swift
import SwiftUI
import FirebaseCore
import FirebaseAnalytics
import Shared // Your KMP shared framework

// 1. Implement the Kotlin Interface in Swift
class IOSFirebaseAnalyticsService: FirebaseAnalyticsService {
    func logEvent(eventName: String, parameters: [String : String]) {
        Analytics.logEvent(eventName, parameters: parameters)
    }
    
    func setUserId(userId: String) {
        Analytics.setUserID(userId)
    }
}

@main
struct iOSApp: App {
    init() {
        // 2. Initialize Firebase
        FirebaseApp.configure()
        
        // 3. Inject the Swift implementation into Kotlin's DI container
        let analyticsService = IOSFirebaseAnalyticsService()
        AppContainerIOS.shared.initialize(analyticsService: analyticsService)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Step 4: Wire the Dependency Injection
- **Agent Action**: Update the `AppContainer` (or Koin modules) in `commonMain` to accept the `FirebaseAnalyticsService`.
```kotlin
// commonMain
object AppContainer {
    lateinit var analyticsService: FirebaseAnalyticsService
        private set

    fun init(analytics: FirebaseAnalyticsService) {
        analyticsService = analytics
    }
}
```
- **Agent Action**: Ensure `FactoryApp.kt` (Android) injects `AndroidFirebaseAnalyticsService`, and `AppContainerIOS.kt` (iOS) accepts the Swift implementation.

### Step 5: Wrap Up & Validate
- **Agent Action**: Update the main Composable to trigger a test event using the shared interface (e.g., `AppContainer.analyticsService.logEvent("app_open")`).
- **User Action**: Ask the user to run the app on both platforms and verify the event appears in the Firebase Console (Realtime Analytics).