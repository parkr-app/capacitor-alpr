package app.parkr.alpr.capacitor

import android.Manifest
import android.graphics.Color
import android.view.ViewGroup
import android.widget.FrameLayout
import app.parkr.alpr.Alpr
import app.parkr.alpr.AlprAccelerator
import app.parkr.alpr.AlprCameraView
import app.parkr.alpr.AlprCameraViewListener
import app.parkr.alpr.AlprEngine
import app.parkr.alpr.AlprError
import app.parkr.alpr.AlprPlate
import com.getcapacitor.JSArray
import com.getcapacitor.JSObject
import com.getcapacitor.PermissionState
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.getcapacitor.annotation.Permission
import com.getcapacitor.annotation.PermissionCallback
import java.io.File
import java.util.concurrent.Executors

@CapacitorPlugin(
  name = "Alpr",
  permissions = [Permission(alias = "camera", strings = [Manifest.permission.CAMERA])],
)
class AlprPlugin : Plugin(), AlprCameraViewListener {
  private val executor = Executors.newSingleThreadExecutor()
  private var camera: AlprCameraView? = null

  override fun load() {
    Alpr.framework = "capacitor"
    Alpr.init(context)
  }

  @PluginMethod
  fun loadModels(call: PluginCall) = background(call) {
    AlprEngine.loadModels(context, AlprAccelerator.from(call.getString("accelerator")))
    call.resolve()
  }

  @PluginMethod
  fun scanImage(call: PluginCall) {
    val path = call.getString("path") ?: return call.reject("Missing path", AlprError.Code.FILE.value)
    val config = configFrom(call.getObject("config"))
    background(call) {
      val plates = AlprEngine.scanImage(context, path, config)
      call.resolve(JSObject().put("plates", JSArray(plates.map(::plateObject))))
    }
  }

  @PluginMethod
  fun startCamera(call: PluginCall) {
    activity.runOnUiThread {
      val webView = bridge.webView
      val container = webView.parent as? ViewGroup ?: return@runOnUiThread call.reject("No web view to attach the camera to", AlprError.Code.CAMERA.value)
      val view = camera ?: AlprCameraView(context).also { it.listener = this }
      if (view.parent == null) {
        // Behind a transparent web view, so the page can draw on top of the camera.
        container.addView(view, container.indexOfChild(webView), FrameLayout.LayoutParams(0, 0))
        webView.setBackgroundColor(Color.TRANSPARENT)
      }
      camera = view
      apply(call, starting = true)
      call.resolve()
    }
  }

  @PluginMethod
  fun updateCamera(call: PluginCall) {
    activity.runOnUiThread {
      if (camera == null) return@runOnUiThread call.reject("The camera is not started", AlprError.Code.CAMERA.value)
      apply(call, starting = false)
      call.resolve()
    }
  }

  @PluginMethod
  fun stopCamera(call: PluginCall) {
    activity.runOnUiThread {
      camera?.let {
        it.isActive = false
        it.listener = null
        (it.parent as? ViewGroup)?.removeView(it)
      }
      camera = null
      call.resolve()
    }
  }

  @PluginMethod
  fun setTelemetryEnabled(call: PluginCall) {
    Alpr.setTelemetryEnabled(call.getBoolean("enabled", true) ?: true)
    call.resolve()
  }

  @PluginMethod
  override fun requestPermissions(call: PluginCall) {
    if (getPermissionState("camera") == PermissionState.GRANTED) return checkPermissions(call)
    requestPermissionForAlias("camera", call, "cameraPermissionCallback")
  }

  @PermissionCallback
  private fun cameraPermissionCallback(call: PluginCall) = checkPermissions(call)

  private fun background(call: PluginCall, block: () -> Unit) {
    executor.execute {
      try {
        block()
      } catch (error: AlprError) {
        call.reject(error.message, error.code.value)
      } catch (error: Exception) {
        call.reject(error.message, AlprError.Code.FILE.value)
      }
    }
  }

  private fun apply(call: PluginCall, starting: Boolean) {
    val view = camera ?: return
    val data = call.data
    call.getObject("frame")?.let { frame ->
      val density = context.resources.displayMetrics.density
      val webView = bridge.webView
      view.layoutParams = view.layoutParams.apply {
        width = (frame.getDouble("width") * density).toInt()
        height = (frame.getDouble("height") * density).toInt()
      }
      view.x = webView.x + (frame.getDouble("x") * density).toFloat()
      view.y = webView.y + (frame.getDouble("y") * density).toFloat()
    }
    if (data.has("throttle")) view.throttle = data.getLong("throttle")
    if (data.has("showFps")) view.showFps = data.getBoolean("showFps")
    if (data.has("showOverlay")) view.showOverlay = data.getBoolean("showOverlay")
    if (data.has("mockImage")) view.mockImage = call.getString("mockImage")?.let(::resolveAsset)
    if (data.has("torch")) view.torch = data.getBoolean("torch")
    if (data.has("zoom")) view.zoom = data.getDouble("zoom").toFloat()
    if (data.has("scanRegion")) view.scanRegion = call.getObject("scanRegion")?.let(::boundingBox)
    if (data.has("showScanRegion")) view.showScanRegion = data.getBoolean("showScanRegion")
    if (data.has("overlayStyle")) view.overlayStyle = call.getObject("overlayStyle")?.let(::overlayStyle)
    if (data.has("detectionThreshold")) view.detectionThreshold = call.getFloat("detectionThreshold")
    if (data.has("ocrThreshold")) view.ocrThreshold = call.getFloat("ocrThreshold")
    if (data.has("accelerator")) view.accelerator = AlprAccelerator.from(call.getString("accelerator"))
    view.recognizesPlates = hasListeners("plate")
    view.scansPlates = hasListeners("scan")
    if (data.has("isActive")) view.isActive = data.getBoolean("isActive") else if (starting) view.isActive = true
  }

  /** Paths that are not absolute or URLs point into the app's web assets; they are copied to the cache to be read as files. */
  private fun resolveAsset(path: String): String {
    if (path.startsWith("/") || path.contains("://")) return path
    val target = File(context.cacheDir, "alpr-assets/$path")
    if (!target.exists()) {
      target.parentFile?.mkdirs()
      context.assets.open("public/$path").use { input -> target.outputStream().use { input.copyTo(it) } }
    }
    return target.absolutePath
  }

  private fun platesEvent(plates: List<AlprPlate>, frameWidth: Int, frameHeight: Int) = JSObject()
    .put("plates", JSArray(plates.map(::plateObject)))
    .put("frameWidth", frameWidth)
    .put("frameHeight", frameHeight)

  override fun onPlatesRaw(view: AlprCameraView, plates: List<AlprPlate>, frameWidth: Int, frameHeight: Int) =
    notifyListeners("platesRaw", platesEvent(plates, frameWidth, frameHeight))

  override fun onPlates(view: AlprCameraView, plates: List<AlprPlate>, frameWidth: Int, frameHeight: Int) =
    notifyListeners("plates", platesEvent(plates, frameWidth, frameHeight))

  override fun onPlate(view: AlprCameraView, plate: AlprPlate) = notifyListeners("plate", JSObject().put("plate", plateObject(plate)))

  override fun onScan(view: AlprCameraView, plate: AlprPlate) = notifyListeners("scan", JSObject().put("plate", plateObject(plate)))

  override fun onError(view: AlprCameraView, error: AlprError) =
    notifyListeners("error", JSObject().put("code", error.code.value).put("message", error.message ?: ""))

  override fun handleOnDestroy() {
    camera?.isActive = false
    executor.shutdown()
  }
}
