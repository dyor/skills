// shared/src/commonMain/kotlin/org/example/project/domain/VideoPathResolver.kt
package org.example.project.domain

/**
 * Resolves a video path to handle platform-specific storage changes (e.g. iOS UUID changes on rebuild).
 */
expect fun resolveVideoPath(path: String): String

// shared/src/androidMain/kotlin/org/example/project/domain/VideoPathResolver.android.kt
/*
package org.example.project.domain

actual fun resolveVideoPath(path: String): String {
    // On Android, absolute file paths within the app directory remain stable across rebuilds.
    return path
}
*/

// shared/src/iosMain/kotlin/org/example/project/domain/VideoPathResolver.ios.kt
/*
package org.example.project.domain

import platform.Foundation.NSDocumentDirectory
import platform.Foundation.NSFileManager
import platform.Foundation.NSSearchPathForDirectoriesInDomains
import platform.Foundation.NSTemporaryDirectory
import platform.Foundation.NSUserDomainMask

actual fun resolveVideoPath(path: String): String {
    val fileManager = NSFileManager.defaultManager
    if (fileManager.fileExistsAtPath(path)) return path
    
    val fileName = path.substringAfterLast("/")
    
    val isTmp = path.contains("/tmp/")
    
    if (isTmp) {
        val tempDir = NSTemporaryDirectory()
        val tempPath = "$tempDir$fileName"
        return tempPath
    } else {
        val documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)
        val currentDocsDir = documentPaths.firstOrNull() as? String
        if (currentDocsDir != null) {
            val docsPath = "$currentDocsDir/$fileName"
            return docsPath
        }
    }
    
    return path
}
*/