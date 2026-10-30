package app.parkr.alpr.capacitor

import android.graphics.Color
import app.parkr.alpr.AlprAccelerator
import app.parkr.alpr.AlprConfig
import app.parkr.alpr.AlprOverlayStyle
import app.parkr.alpr.AlprPlate
import app.parkr.alpr.BoundingBox
import com.getcapacitor.JSObject
import org.json.JSONObject

internal fun plateObject(plate: AlprPlate): JSObject = JSObject()
  .put("plate", plate.plate)
  .put("ocrConfidence", plate.ocrConfidence.toDouble())
  .put("detectionConfidence", plate.detectionConfidence.toDouble())
  .put(
    "bbox",
    JSObject()
      .put("x", plate.bbox.x.toDouble())
      .put("y", plate.bbox.y.toDouble())
      .put("width", plate.bbox.width.toDouble())
      .put("height", plate.bbox.height.toDouble()),
  )
  .put("country", plate.country)
  .put("countryCode", plate.countryCode ?: JSONObject.NULL)
  .put("countryConfidence", plate.countryConfidence.toDouble())

private fun JSONObject.float(key: String): Float? = if (has(key) && !isNull(key)) getDouble(key).toFloat() else null

internal fun boundingBox(json: JSONObject) =
  BoundingBox(json.float("x") ?: 0f, json.float("y") ?: 0f, json.float("width") ?: 0f, json.float("height") ?: 0f)

internal fun configFrom(json: JSONObject?): AlprConfig {
  if (json == null) return AlprConfig()
  return AlprConfig(
    detectionThreshold = json.float("detectionThreshold"),
    ocrThreshold = json.float("ocrThreshold"),
    region = json.optJSONObject("region")?.let(::boundingBox),
    accelerator = AlprAccelerator.from(json.optString("accelerator", "gpu")),
  )
}

/** Parses `#RRGGBB` or `#RRGGBBAA` into an ARGB color int. */
internal fun color(value: String?): Int? {
  if (value == null || !value.startsWith("#")) return null
  val hex = value.substring(1)
  return when (hex.length) {
    6 -> Color.parseColor(value)
    8 -> hex.toLongOrNull(16)?.let { rgba -> ((rgba and 0xFF) shl 24 or (rgba ushr 8)).toInt() }
    else -> null
  }
}

internal fun overlayStyle(json: JSONObject): AlprOverlayStyle {
  val defaults = AlprOverlayStyle()
  fun bool(key: String) = if (json.has(key) && !json.isNull(key)) json.getBoolean(key) else null
  fun string(key: String) = if (json.has(key) && !json.isNull(key)) json.getString(key) else null
  return AlprOverlayStyle(
    boxColor = color(string("boxColor")),
    boxBorderWidth = json.float("boxBorderWidth") ?: defaults.boxBorderWidth,
    boxCornerRadius = json.float("boxCornerRadius") ?: defaults.boxCornerRadius,
    labelBackgroundColor = color(string("labelBackgroundColor")),
    labelTextColor = color(string("labelTextColor")) ?: defaults.labelTextColor,
    labelFontSize = json.float("labelFontSize") ?: defaults.labelFontSize,
    showLabel = bool("showLabel") ?: defaults.showLabel,
    showPlate = bool("showPlate") ?: defaults.showPlate,
    showCountry = bool("showCountry") ?: defaults.showCountry,
    showConfidence = bool("showConfidence") ?: defaults.showConfidence,
  )
}
