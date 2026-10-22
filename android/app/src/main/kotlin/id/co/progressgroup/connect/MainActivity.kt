package id.co.progressgroup.connect

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.provider.Settings
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {

    private var pendingPickPhone: MethodChannel.Result? = null

    // Picker nomor telepon sistem (ACTION_PICK + Phone.CONTENT_URI) memberi izin baca
    // sementara KHUSUS ke baris kontak yang dipilih user, jadi app tidak butuh READ_CONTACTS
    // (kebijakan Izin Kontak Google Play). Picker bawaan flutter_contacts tanpa izin cuma
    // bisa kasih nama, bukan nomor — makanya dibuat sendiri di sini.
    private val pickPhoneLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { res ->
            val result = pendingPickPhone ?: return@registerForActivityResult
            pendingPickPhone = null
            val uri = res.data?.data
            if (res.resultCode != RESULT_OK || uri == null) {
                result.success(null)
                return@registerForActivityResult
            }
            try {
                val picked = contentResolver.query(
                    uri,
                    arrayOf(
                        ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                        ContactsContract.CommonDataKinds.Phone.NUMBER,
                    ),
                    null,
                    null,
                    null,
                )?.use { c ->
                    if (c.moveToFirst()) mapOf("name" to c.getString(0), "phone" to c.getString(1)) else null
                }
                result.success(picked)
            } catch (e: Exception) {
                result.error("PICK_FAILED", e.message, null)
            }
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.progress_group/contact_picker")
            .setMethodCallHandler { call, result ->
                if (call.method == "pickPhone") {
                    if (pendingPickPhone != null) {
                        result.error("ALREADY_ACTIVE", "Picker kontak sedang terbuka", null)
                        return@setMethodCallHandler
                    }
                    try {
                        pendingPickPhone = result
                        pickPhoneLauncher.launch(
                            Intent(Intent.ACTION_PICK, ContactsContract.CommonDataKinds.Phone.CONTENT_URI)
                        )
                    } catch (e: Exception) {
                        pendingPickPhone = null
                        result.error("PICK_FAILED", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.progress_group/install_apk")
            .setMethodCallHandler { call, result ->
                if (call.method == "installApk") {
                    val filePath = call.argument<String>("filePath")
                    if (filePath == null) {
                        result.error("INVALID_ARG", "filePath is null", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val file = File(filePath)
                        val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
                        } else {
                            Uri.fromFile(file)
                        }
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INSTALL_FAILED", e.message, null)
                    }
                } else if (call.method == "isPackageInstalled") {
                    val packageName = call.argument<String>("packageName")
                    if (packageName == null) {
                        result.error("INVALID_ARG", "packageName is null", null)
                        return@setMethodCallHandler
                    }
                    val installed = try {
                        packageManager.getPackageInfo(packageName, 0)
                        true
                    } catch (e: PackageManager.NameNotFoundException) {
                        false
                    }
                    result.success(installed)
                } else if (call.method == "uninstallPackage") {
                    val packageName = call.argument<String>("packageName")
                    if (packageName == null) {
                        result.error("INVALID_ARG", "packageName is null", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        intent.data = Uri.fromParts("package", packageName, null)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNINSTALL_FAILED", e.message, null)
                    }
                } else if (call.method == "canInstallPackages") {
                    val canInstall = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        packageManager.canRequestPackageInstalls()
                    } else {
                        true
                    }
                    result.success(canInstall)
                } else if (call.method == "openInstallPermissionSettings") {
                    try {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Intent(
                                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:$packageName")
                            )
                        } else {
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.fromParts("package", packageName, null)
                            }
                        }
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTINGS_FAILED", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
