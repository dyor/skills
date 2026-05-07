// shared/src/commonMain/kotlin/org/example/project/domain/VideoPublisher.kt
/*
package org.example.project.domain

expect class VideoPublisher {
    suspend fun saveToGallery(videoPath: String): Boolean
    fun openYouTube()
}

@Composable
expect fun rememberVideoPublisher(): VideoPublisher
*/

// shared/src/androidMain/kotlin/org/example/project/domain/VideoPublisher.android.kt
/*
package org.example.project.domain

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import java.io.File
import java.io.FileInputStream
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

actual class VideoPublisher(private val context: Context) {
    actual suspend fun saveToGallery(videoPath: String): Boolean = withContext(Dispatchers.IO) {
        try {
            val videoFile = File(videoPath)
            if (!videoFile.exists()) return@withContext false

            val values = ContentValues().apply {
                put(MediaStore.Video.Media.TITLE, videoFile.name)
                put(MediaStore.Video.Media.DISPLAY_NAME, videoFile.name)
                put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                put(MediaStore.Video.Media.DATE_ADDED, System.currentTimeMillis() / 1000)
                put(MediaStore.Video.Media.DATE_TAKEN, System.currentTimeMillis())
                put(MediaStore.Video.Media.RELATIVE_PATH, Environment.DIRECTORY_MOVIES + "/MyApp")
            }

            val resolver = context.contentResolver
            val uri = resolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values)
            
            if (uri != null) {
                resolver.openOutputStream(uri)?.use { outputStream ->
                    FileInputStream(videoFile).use { inputStream ->
                        inputStream.copyTo(outputStream)
                    }
                }
                return@withContext true
            }
            false
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
    
    actual fun openYouTube() {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.youtube.com"))
        intent.setPackage("com.google.android.youtube")
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        
        try {
            context.startActivity(intent)
        } catch (e: Exception) {
            val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.youtube.com"))
            browserIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(browserIntent)
        }
    }
}

@Composable
actual fun rememberVideoPublisher(): VideoPublisher {
    val context = LocalContext.current
    return remember(context) { VideoPublisher(context) }
}
*/

// shared/src/iosMain/kotlin/org/example/project/domain/VideoPublisher.ios.kt
/*
package org.example.project.domain

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import platform.Foundation.NSURL
import platform.Photos.PHPhotoLibrary
import platform.UIKit.UIApplication
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.withContext

actual class VideoPublisher {
    actual suspend fun saveToGallery(videoPath: String): Boolean = withContext(Dispatchers.IO) {
        suspendCoroutine { continuation ->
            val resolvedPath = resolveVideoPath(videoPath)
            val url = if (resolvedPath.startsWith("/")) NSURL.fileURLWithPath(resolvedPath) else NSURL.URLWithString(resolvedPath)
            
            if (url == null) {
                continuation.resume(false)
                return@suspendCoroutine
            }

            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                platform.Photos.PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(url)
            }, completionHandler = { success, error ->
                if (error != null) {
                    error.localizedDescription?.let { println("Error saving video: $it") }
                }
                continuation.resume(success)
            })
        }
    }
    
    actual fun openYouTube() {
        val appUrl = NSURL.URLWithString("youtube://")
        val webUrl = NSURL.URLWithString("https://www.youtube.com")
        
        val app = UIApplication.sharedApplication
        if (appUrl != null && app.canOpenURL(appUrl)) {
            app.openURL(appUrl, emptyMap<Any?, Any>(), null)
        } else if (webUrl != null) {
            app.openURL(webUrl, emptyMap<Any?, Any>(), null)
        }
    }
}

@Composable
actual fun rememberVideoPublisher(): VideoPublisher {
    return remember { VideoPublisher() }
}
*/