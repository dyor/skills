package org.example.project.permissions

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.mohamedrejeb.calf.permissions.ExperimentalPermissionsApi
import com.mohamedrejeb.calf.permissions.Permission
import com.mohamedrejeb.calf.permissions.PermissionState
import com.mohamedrejeb.calf.permissions.PermissionStatus
import com.mohamedrejeb.calf.permissions.rememberPermissionState


@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun AppPermissionsHandler(content: @Composable () -> Unit) {
    val cameraPermissionState = rememberPermissionState(Permission.Camera)
    val recordAudioPermissionState = rememberPermissionState(Permission.RecordAudio)

    // Logging for initial state and any changes
    LaunchedEffect(cameraPermissionState.status, recordAudioPermissionState.status) {
        println("AppPermissionsHandler: Camera status = ${cameraPermissionState.status}")
        println("AppPermissionsHandler: RecordAudio status = ${recordAudioPermissionState.status}")
    }

    val allPermissionsGranted = cameraPermissionState.status == PermissionStatus.Granted &&
            recordAudioPermissionState.status == PermissionStatus.Granted

    if (allPermissionsGranted) {
        content()
    } else {
        PermissionRequestScreen(cameraPermissionState, recordAudioPermissionState, content)
    }
}

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun PermissionRequestScreen(
    cameraPermissionState: PermissionState,
    recordAudioPermissionState: PermissionState,
    content: @Composable () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
    ) {
        when {
            cameraPermissionState.status != PermissionStatus.Granted -> {
                // Request Camera permission first
                Text("Camera permission required.")
                Spacer(modifier = Modifier.height(8.dp))
                Button(onClick = { cameraPermissionState.launchPermissionRequest() }) {
                    Text("Request Camera")
                }
            }
            recordAudioPermissionState.status != PermissionStatus.Granted -> {
                // Request Record Audio permission next
                Text("Microphone permission required.")
                Spacer(modifier = Modifier.height(8.dp))
                Button(onClick = { recordAudioPermissionState.launchPermissionRequest() }) {
                    Text("Request Microphone")
                }
            }
            else -> {
                // All permissions granted, show content
                content()
            }
        }
    }
}