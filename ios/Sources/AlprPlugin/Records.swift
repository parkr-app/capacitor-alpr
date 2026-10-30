import AlprKit
import UIKit

func plateObject(_ plate: AlprPlate) -> [String: Any] {
  [
    "plate": plate.plate,
    "ocrConfidence": Double(plate.ocrConfidence),
    "detectionConfidence": Double(plate.detectionConfidence),
    "bbox": [
      "x": Double(plate.bbox.origin.x),
      "y": Double(plate.bbox.origin.y),
      "width": Double(plate.bbox.size.width),
      "height": Double(plate.bbox.size.height),
    ],
    "country": plate.country,
    "countryCode": plate.countryCode ?? NSNull(),
    "countryConfidence": Double(plate.countryConfidence),
  ]
}

private func number(_ value: Any?) -> Double? { (value as? NSNumber)?.doubleValue }

func rect(_ object: [String: Any]) -> CGRect {
  CGRect(x: number(object["x"]) ?? 0, y: number(object["y"]) ?? 0, width: number(object["width"]) ?? 0, height: number(object["height"]) ?? 0)
}

func alprConfig(_ object: [String: Any]?) -> AlprConfig {
  guard let object else { return AlprConfig() }
  return AlprConfig(
    detectionThreshold: number(object["detectionThreshold"]).map(Float.init),
    ocrThreshold: number(object["ocrThreshold"]).map(Float.init),
    region: (object["region"] as? [String: Any]).map(rect),
    accelerator: (object["accelerator"] as? String).flatMap(AlprAccelerator.init(rawValue:)) ?? .gpu
  )
}

/// Parses `#RRGGBB` or `#RRGGBBAA`.
func color(_ value: Any?) -> UIColor? {
  guard var hex = value as? String, hex.hasPrefix("#") else { return nil }
  hex.removeFirst()
  if hex.count == 6 { hex += "FF" }
  guard hex.count == 8, let rgba = UInt32(hex, radix: 16) else { return nil }
  return UIColor(
    red: CGFloat((rgba >> 24) & 0xFF) / 255,
    green: CGFloat((rgba >> 16) & 0xFF) / 255,
    blue: CGFloat((rgba >> 8) & 0xFF) / 255,
    alpha: CGFloat(rgba & 0xFF) / 255
  )
}

func overlayStyle(_ object: [String: Any]) -> AlprOverlayStyle {
  var style = AlprOverlayStyle()
  func size(_ key: String) -> CGFloat? { number(object[key]).map { CGFloat($0) } }
  style.boxColor = color(object["boxColor"])
  style.boxBorderWidth = size("boxBorderWidth") ?? style.boxBorderWidth
  style.boxCornerRadius = size("boxCornerRadius") ?? style.boxCornerRadius
  style.labelBackgroundColor = color(object["labelBackgroundColor"])
  style.labelTextColor = color(object["labelTextColor"]) ?? style.labelTextColor
  style.labelFontSize = size("labelFontSize") ?? style.labelFontSize
  style.showLabel = object["showLabel"] as? Bool ?? style.showLabel
  style.showPlate = object["showPlate"] as? Bool ?? style.showPlate
  style.showCountry = object["showCountry"] as? Bool ?? style.showCountry
  style.showConfidence = object["showConfidence"] as? Bool ?? style.showConfidence
  return style
}
