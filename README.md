# capacitor-alpr

On-device license plate recognition (ALPR/ANPR) for Capacitor and Ionic apps on iOS and Android. It wraps AlprKit, the native SDK behind [react-native-alpr](https://github.com/parkr-app/react-native-alpr); one license key works for both.

<p align="center">
  <img src="https://alpr.parkr.app/screenshots/ios-scan-bmw-i3.webp" width="200" alt="iPhone: live scan reading EL 40489">
  <img src="https://alpr.parkr.app/screenshots/ios-photo-tesla-model-s.webp" width="200" alt="iPhone: two Tesla plates read from a photo">
  <img src="https://alpr.parkr.app/screenshots/android-scan-nissan-e-nv200.webp" width="200" alt="Android: live scan reading EL 64433">
  <img src="https://alpr.parkr.app/screenshots/android-photo-nissan-leaf.webp" width="200" alt="Android: EL 15211 read from a photo">
</p>
<p align="center"><sub>Photos: Norsk Elbilforening and Mariordo, <a href="https://creativecommons.org/licenses/by/2.0/">CC BY 2.0</a>, via <a href="https://commons.wikimedia.org/wiki/Category:Electric_vehicle_license_plates_of_Norway">Wikimedia Commons</a>, cropped.</sub></p>

- Fully offline, runs on the device (Core ML on iOS, LiteRT from Google Play services on Android)
- Live camera scanning at 30 FPS with GPU or Neural Engine acceleration
- Plate text, country and bounding box, several plates per frame, [65 countries](#supported-countries)
- Stable results: reads from several frames are combined into one answer, and boxes move smoothly
- One-shot scanning that waits for a certain read instead of taking the first blurry frame
- Recognition in photos

**The basic scanner is free, also in production.** PRO features need a license key in release builds and work without one in development builds. See [Licensing](#licensing) and [alpr.parkr.app](https://alpr.parkr.app).

## Platforms

One license key covers your app on every platform.

| Platform | Package | Repository |
| --- | --- | --- |
| Expo and React Native | `react-native-alpr` on npm | [parkr-app/react-native-alpr](https://github.com/parkr-app/react-native-alpr) |
| iOS (Swift) | `AlprKit` through Swift Package Manager | [parkr-app/alpr-ios](https://github.com/parkr-app/alpr-ios) |
| Android (Kotlin) | `app.parkr:alpr` | [parkr-app/alpr-android](https://github.com/parkr-app/alpr-android) |
| Flutter | `flutter_alpr` on pub.dev | [parkr-app/flutter_alpr](https://github.com/parkr-app/flutter_alpr) |
| Capacitor | `capacitor-alpr` on npm | [parkr-app/capacitor-alpr](https://github.com/parkr-app/capacitor-alpr) |

## Supported countries

🇦🇱 Albania (`AL`), 🇦🇩 Andorra (`AD`), 🇦🇷 Argentina (`AR`), 🇦🇲 Armenia (`AM`), 🇦🇺 Australia (`AU`), 🇦🇹 Austria (`AT`), 🇦🇿 Azerbaijan (`AZ`), 🇧🇭 Bahrain (`BH`), 🇧🇾 Belarus (`BY`), 🇧🇪 Belgium (`BE`), 🇧🇦 Bosnia and Herzegovina (`BA`), 🇧🇷 Brazil (`BR`), 🇧🇬 Bulgaria (`BG`), 🇰🇭 Cambodia (`KH`), 🇨🇦 Canada (`CA`), 🇭🇷 Croatia (`HR`), 🇨🇾 Cyprus (`CY`), 🇨🇿 Czech Republic (`CZ`), 🇩🇰 Denmark (`DK`), 🇪🇪 Estonia (`EE`), 🇫🇮 Finland (`FI`), 🇫🇷 France (`FR`), 🇬🇪 Georgia (`GE`), 🇩🇪 Germany (`DE`), 🇬🇮 Gibraltar (`GI`), 🇬🇷 Greece (`GR`), 🇬🇬 Guernsey (`GG`), 🇭🇺 Hungary (`HU`), 🇮🇸 Iceland (`IS`), 🇮🇩 Indonesia (`ID`), 🇮🇪 Ireland (`IE`), 🇮🇱 Israel (`IL`), 🇮🇹 Italy (`IT`), 🇱🇻 Latvia (`LV`), 🇱🇮 Liechtenstein (`LI`), 🇱🇹 Lithuania (`LT`), 🇱🇺 Luxembourg (`LU`), 🇲🇾 Malaysia (`MY`), 🇲🇹 Malta (`MT`), 🇲🇽 Mexico (`MX`), 🇲🇩 Moldova (`MD`), 🇲🇨 Monaco (`MC`), 🇲🇪 Montenegro (`ME`), 🇳🇱 Netherlands (`NL`), 🇳🇿 New Zealand (`NZ`), 🇲🇰 North Macedonia (`MK`), 🇳🇴 Norway (`NO`), 🇵🇱 Poland (`PL`), 🇵🇹 Portugal (`PT`), 🇶🇦 Qatar (`QA`), 🇷🇴 Romania (`RO`), 🇸🇲 San Marino (`SM`), 🇷🇸 Serbia (`RS`), 🇸🇬 Singapore (`SG`), 🇸🇰 Slovakia (`SK`), 🇸🇮 Slovenia (`SI`), 🇪🇸 Spain (`ES`), 🇸🇪 Sweden (`SE`), 🇨🇭 Switzerland (`CH`), 🇹🇭 Thailand (`TH`), 🇹🇷 Turkey (`TR`), 🇺🇦 Ukraine (`UA`), 🇬🇧 United Kingdom (`GB`), 🇺🇸 United States (`US`), 🇻🇳 Vietnam (`VN`).

## Installation

```sh
npm install capacitor-alpr
npx cap sync
```

Requires Capacitor 8, iOS 15.1 and Android 7.0 (API 24).

**iOS:** add `NSCameraUsageDescription` to `ios/App/App/Info.plist`.

**Android:** the plugin adds the `CAMERA` permission and the `https://alpr.parkr.app/maven` repository for the `app.parkr:alpr` SDK.

## Usage

The camera is a native view behind the web view, which the plugin makes transparent. Give the element where the camera shows a transparent background, and draw your own UI on top of it in HTML.

```ts
import { Alpr } from 'capacitor-alpr';

await Alpr.addListener('plates', ({ plates }) => console.log(plates.map((p) => p.plate)));
await Alpr.addListener('scan', ({ plate }) => console.log('Scanned', plate.plate)); // PRO

const { camera } = await Alpr.requestPermissions();
if (camera === 'granted') {
  const { x, y, width, height } = document.querySelector('#camera')!.getBoundingClientRect();
  await Alpr.startCamera({ frame: { x, y, width, height } });
}

// Later
await Alpr.stopCamera();
```

Add the `plate` and `scan` listeners before `startCamera`; the camera only reports those events when someone listens.

Read plates in a photo (PRO):

```ts
const { plates } = await Alpr.scanImage({ path: '/path/to/photo.jpg' });
```

## Licensing

| | Development builds | Release builds without a key | Release builds with a key |
| --- | --- | --- | --- |
| Live scanning, `plates`, `platesRaw`, default overlay | ✓ | ✓ | ✓ |
| PRO features | ✓ | Off | ✓ |

Development builds are debug builds, simulators and emulators, TestFlight and ad-hoc builds. Without a key, release builds fall back quietly and never crash: the scanner runs on the CPU with default settings, `plate` and `scan` don't fire, torch and zoom stay off, and `scanImage` rejects with `ERR_LICENSE_REQUIRED`.

Get a key at [alpr.parkr.app](https://alpr.parkr.app). A key is bound to your app ids and works on every platform and framework. Add it as `AlprLicenseKey` (String) in `ios/App/App/Info.plist`, and in `android/app/src/main/AndroidManifest.xml` inside `<application>`:

```xml
<meta-data android:name="app.parkr.alpr.LICENSE_KEY" android:value="eyJ2Ijox..." />
```

## Telemetry

At most once a day per device, the SDK sends a small anonymous report to `alpr.parkr.app`: app id and version, platform, OS and SDK versions, build type, license state and the names of disabled PRO features. It never contains device or user identifiers, images or plate data. It is on by default without a license and off by default with one. Turn it off with `Alpr.setTelemetryEnabled({ enabled: false })`.

## API

| Method | |
| --- | --- |
| `startCamera({ frame, ...options })` | Shows the camera at `frame` (CSS pixels) and starts scanning |
| `updateCamera({ frame?, ...options })` | Changes the frame or options |
| `stopCamera()` | |
| `scanImage({ path, config? })` | `{ plates }` from a photo. PRO |
| `loadModels({ accelerator? })` | Loads the models ahead of time |
| `checkPermissions()`, `requestPermissions()` | `{ camera }` |
| `setTelemetryEnabled({ enabled })` | |

Camera options: `isActive`, `throttle` (ms, default 200), `showFps`, `showOverlay`, `torch`, `zoom`, `scanRegion`, `showScanRegion`, `overlayStyle` (colors as `#RRGGBB` or `#RRGGBBAA`), `detectionThreshold`, `ocrThreshold`, `accelerator` (`gpu` or `cpu`) and `mockImage` (an image to scan instead of the camera, for simulators: a file path, or a path in your web assets).

Events: `platesRaw` and `plates` with `{ plates, frameWidth, frameHeight }`, `plate` and `scan` with `{ plate }` (PRO), and `error` with `{ code, message }`. `toViewRect(bbox, frame, view)` maps a plate's normalized box to the camera view.

`DetectedPlate` has `plate`, `ocrConfidence`, `detectionConfidence`, `bbox`, `country`, `countryCode` and `countryConfidence`.

## Example app

[example-app](example-app) scans with the camera on a device and with a bundled photo on simulators and emulators:

```sh
cd example-app && npm install && npm run ios
```

## License

The TypeScript and platform code in this repository is MIT licensed. The bundled AlprKit native SDK is licensed under the [Parkr ALPR SDK License Agreement](SDK-LICENSE.md). Bundled models: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
