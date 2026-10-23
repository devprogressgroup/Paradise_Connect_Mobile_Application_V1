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

    // Picker nomor telepon bawaan Android: hasilnya URI satu nomor dengan izin baca sementara,
    // jadi tidak butuh READ_CONTACTS (kebijakan Contacts Permission Google Play).
    private var pendingContactResult: MethodChannel.Result? = null
    private val pickPhoneLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { activityResult ->
        val result = pendingContactResult ?: return@registerForActivityResult
        pendingContactResult = null
        val uri = activityResult.data?.data
        if (activityResult.resultCode != RESULT_OK || uri == null) {
            result.success(null)
            return@registerForActivityResult
        }
        try {
            val projection = arrayOf(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME, ContactsContract.CommonDataKinds.Phone.NUMBER)
            val picked = contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) mapOf("name" to cursor.getString(0), "phone" to cursor.getString(1)) else null
            }
            result.success(picked)
        } catch (e: Exception) {
            result.error("READ_FAILED", e.message, null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.progress_group/contact_picker")
            .setMethodCallHandler { call, result ->
                if (call.method != "pickPhone") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pendingContactResult != null) {
                    result.error("ALREADY_ACTIVE", "Contact picker sudah terbuka", null)
                    return@setMethodCallHandler
                }
                pendingContactResult = result
                try {
                    pickPhoneLauncher.launch(Intent(Intent.ACTION_PICK, ContactsContract.CommonDataKinds.Phone.CONTENT_URI))
                } catch (e: Exception) {
                    pendingContactResult = null
                    result.error("PICKER_UNAVAILABLE", e.message, null)
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
