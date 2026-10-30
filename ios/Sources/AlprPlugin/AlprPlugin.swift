import AlprKit
import AVFoundation
import Capacitor
import UIKit

@objc(AlprPlugin)
public class AlprPlugin: CAPPlugin, CAPBridgedPlugin, AlprCameraViewDelegate {
  public let identifier = "AlprPlugin"
  public let jsName = "Alpr"
  public let pluginMethods: [CAPPluginMethod] = [
    CAPPluginMethod(name: "loadModels", returnType: CAPPluginReturnPromise),
    CAPPluginMethod(name: "scanImage", returnType: CAPPluginReturnPromise),
    CAPPluginMethod(name: "startCamera", returnType: CAPPluginReturnPromise),
    CAPPluginMethod(name: "updateCamera", returnType: CAPPluginReturnPromise),
    CAPPluginMethod(name: "stopCamera", returnType: CAPPluginReturnPromise),
    CAPPluginMethod(name: "setTelemetryEnabled", returnType: CAPPluginReturnPromise),
    CAPPluginMethod(name: "checkPermissions", returnType: CAPPluginReturnPromise),
    CAPPluginMethod(name: "requestPermissions", returnType: CAPPluginReturnPromise),
  ]

  private let queue = DispatchQueue(label: "app.parkr.alpr.capacitor", qos: .userInitiated)
  private var camera: AlprCameraView?

  override public func load() {
    Alpr.framework = "capacitor"
  }

  @objc func loadModels(_ call: CAPPluginCall) {
    let accelerator = AlprAccelerator(rawValue: call.getString("accelerator") ?? "") ?? .gpu
    background(call) {
      try AlprEngine.shared.loadModels(accelerator: accelerator)
      call.resolve()
    }
  }

  @objc func scanImage(_ call: CAPPluginCall) {
    guard let path = call.getString("path"), let url = path.hasPrefix("/") ? URL(fileURLWithPath: path) : URL(string: path) else {
      return call.reject("Missing or invalid path", AlprError.Code.file.rawValue)
    }
    let config = alprConfig(call.getObject("config"))
    background(call) {
      let plates = try AlprEngine.shared.scanImage(contentsOf: url, config: config)
      call.resolve(["plates": plates.map(plateObject)])
    }
  }

  @objc func startCamera(_ call: CAPPluginCall) {
    DispatchQueue.main.async {
      guard let webView = self.bridge?.webView, let container = webView.superview else {
        return call.reject("No web view to attach the camera to", AlprError.Code.camera.rawValue)
      }
      let camera = self.camera ?? AlprCameraView(frame: .zero)
      camera.delegate = self
      camera.clipsToBounds = true
      if camera.superview == nil {
        // Behind a transparent web view, so the page can draw on top of the camera.
        container.insertSubview(camera, belowSubview: webView)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
      }
      self.camera = camera
      self.apply(call)
      call.resolve()
    }
  }

  @objc func updateCamera(_ call: CAPPluginCall) {
    DispatchQueue.main.async {
      guard self.camera != nil else { return call.reject("The camera is not started", AlprError.Code.camera.rawValue) }
      self.apply(call)
      call.resolve()
    }
  }

  @objc func stopCamera(_ call: CAPPluginCall) {
    DispatchQueue.main.async {
      self.camera?.isActive = false
      self.camera?.removeFromSuperview()
      self.camera = nil
      call.resolve()
    }
  }

  @objc func setTelemetryEnabled(_ call: CAPPluginCall) {
    Alpr.setTelemetryEnabled(call.getBool("enabled") ?? true)
    call.resolve()
  }

  @objc override public func checkPermissions(_ call: CAPPluginCall) {
    call.resolve(["camera": permissionState()])
  }

  @objc override public func requestPermissions(_ call: CAPPluginCall) {
    AVCaptureDevice.requestAccess(for: .video) { _ in
      call.resolve(["camera": self.permissionState()])
    }
  }

  private func permissionState() -> String {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized: return "granted"
    case .notDetermined: return "prompt"
    default: return "denied"
    }
  }

  private func background(_ call: CAPPluginCall, _ body: @escaping () throws -> Void) {
    queue.async {
      do {
        try body()
      } catch let error as AlprError {
        call.reject(error.message, error.code.rawValue)
      } catch {
        call.reject(error.localizedDescription, AlprError.Code.file.rawValue)
      }
    }
  }

  private func apply(_ call: CAPPluginCall) {
    guard let camera, let webView = bridge?.webView else { return }
    if let frame = call.getObject("frame") {
      camera.frame = webView.convert(rect(frame), to: camera.superview)
    }
    let options = call.options ?? [:]
    func has(_ key: String) -> Bool { options[key] != nil }
    if has("throttle") { camera.throttle = call.getDouble("throttle") ?? 200 }
    if has("showFps") { camera.showFps = call.getBool("showFps") ?? false }
    if has("showOverlay") { camera.showOverlay = call.getBool("showOverlay") ?? true }
    if has("mockImage") { camera.mockImage = call.getString("mockImage").map(resolveAsset) }
    if has("torch") { camera.torch = call.getBool("torch") ?? false }
    if has("zoom") { camera.zoom = call.getDouble("zoom") ?? 1 }
    if has("scanRegion") { camera.scanRegion = call.getObject("scanRegion").map(rect) }
    if has("showScanRegion") { camera.showScanRegion = call.getBool("showScanRegion") ?? true }
    if has("overlayStyle") { camera.overlayStyle = call.getObject("overlayStyle").map(overlayStyle) }
    if has("detectionThreshold") { camera.detectionThreshold = call.getFloat("detectionThreshold") }
    if has("ocrThreshold") { camera.ocrThreshold = call.getFloat("ocrThreshold") }
    if has("accelerator") { camera.accelerator = AlprAccelerator(rawValue: call.getString("accelerator") ?? "") ?? .gpu }
    camera.recognizesPlates = hasListeners("plate")
    camera.scansPlates = hasListeners("scan")
    if has("isActive") {
      camera.isActive = call.getBool("isActive") ?? true
    } else if call.methodName == "startCamera" {
      camera.isActive = true
    }
  }

  /// Paths that are not absolute or URLs point into the app's web assets.
  private func resolveAsset(_ path: String) -> String {
    if path.hasPrefix("/") || path.contains("://") { return path }
    guard let root = bridge?.config.appLocation else { return path }
    return root.appendingPathComponent(path).path
  }

  private func platesEvent(_ plates: [AlprPlate], _ frameSize: CGSize) -> [String: Any] {
    ["plates": plates.map(plateObject), "frameWidth": Double(frameSize.width), "frameHeight": Double(frameSize.height)]
  }

  public func alprCameraView(_ view: AlprCameraView, didDetectRaw plates: [AlprPlate], frameSize: CGSize) {
    notifyListeners("platesRaw", data: platesEvent(plates, frameSize))
  }

  public func alprCameraView(_ view: AlprCameraView, didDetect plates: [AlprPlate], frameSize: CGSize) {
    notifyListeners("plates", data: platesEvent(plates, frameSize))
  }

  public func alprCameraView(_ view: AlprCameraView, didRecognize plate: AlprPlate) {
    notifyListeners("plate", data: ["plate": plateObject(plate)])
  }

  public func alprCameraView(_ view: AlprCameraView, didScan plate: AlprPlate) {
    notifyListeners("scan", data: ["plate": plateObject(plate)])
  }

  public func alprCameraView(_ view: AlprCameraView, didFailWith error: AlprError) {
    notifyListeners("error", data: ["code": error.code.rawValue, "message": error.message])
  }
}
