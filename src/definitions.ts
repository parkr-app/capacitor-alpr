import type { PermissionState, PluginListenerHandle } from '@capacitor/core';

export interface BoundingBox {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface DetectedPlate {
  plate: string;
  ocrConfidence: number;
  detectionConfidence: number;
  /** Normalized (0 to 1) box in the camera frame or photo. */
  bbox: BoundingBox;
  country: string;
  countryCode: string | null;
  countryConfidence: number;
}

export interface FrameInfo {
  frameWidth: number;
  frameHeight: number;
}

export type Accelerator = 'gpu' | 'cpu';

export interface AlprConfig {
  detectionThreshold?: number;
  ocrThreshold?: number;
  region?: BoundingBox;
  accelerator?: Accelerator;
}

export interface PlateOverlayStyle {
  /** CSS hex color, `#RRGGBB` or `#RRGGBBAA`. */
  boxColor?: string;
  boxBorderWidth?: number;
  boxCornerRadius?: number;
  labelBackgroundColor?: string;
  labelTextColor?: string;
  labelFontSize?: number;
  showLabel?: boolean;
  showPlate?: boolean;
  showCountry?: boolean;
  showConfidence?: boolean;
}

export interface CameraOptions {
  isActive?: boolean;
  /** Minimum time between `plates` events, in milliseconds. */
  throttle?: number;
  showFps?: boolean;
  showOverlay?: boolean;
  /** Image to scan instead of the camera, for simulators: a file path, or a path in the web assets such as `assets/plate.png`. */
  mockImage?: string;
  torch?: boolean;
  zoom?: number;
  scanRegion?: BoundingBox;
  showScanRegion?: boolean;
  overlayStyle?: PlateOverlayStyle;
  detectionThreshold?: number;
  ocrThreshold?: number;
  accelerator?: Accelerator;
}

/** Where the camera view goes, in CSS pixels of the web view, for example from `element.getBoundingClientRect()`. */
export interface CameraFrame {
  x: number;
  y: number;
  width: number;
  height: number;
}

export type AlprErrorCode = 'ERR_LICENSE_REQUIRED' | 'ERR_LICENSE_INVALID' | 'ERR_MODEL_LOAD' | 'ERR_CAMERA' | 'ERR_FILE';

export interface AlprError {
  code: AlprErrorCode;
  message: string;
}

export interface PermissionStatus {
  camera: PermissionState;
}

export type PlatesEvent = { plates: DetectedPlate[] } & FrameInfo;

export interface AlprPlugin {
  /** Loads the models ahead of time, so the first frame or photo is read without a delay. */
  loadModels(options?: { accelerator?: Accelerator }): Promise<void>;

  /** Reads the plates in a photo (file path or URI). PRO: needs a license key in release builds. */
  scanImage(options: { path: string; config?: AlprConfig }): Promise<{ plates: DetectedPlate[] }>;

  /**
   * Shows the native camera view at `frame` and starts scanning. The camera sits behind the web view, which is made
   * transparent, so the page can draw on top of it; keep the page background transparent where the camera shows.
   */
  startCamera(options: CameraOptions & { frame: CameraFrame }): Promise<void>;

  /** Changes options or the frame of the running camera view. */
  updateCamera(options: CameraOptions & { frame?: CameraFrame }): Promise<void>;

  stopCamera(): Promise<void>;

  setTelemetryEnabled(options: { enabled: boolean }): Promise<void>;

  checkPermissions(): Promise<PermissionStatus>;
  requestPermissions(): Promise<PermissionStatus>;

  /** Every plate read in the current frame, unsmoothed. */
  addListener(eventName: 'platesRaw', listener: (event: PlatesEvent) => void): Promise<PluginListenerHandle>;
  /** Confirmed plates in view, with consensus text and smoothed boxes. */
  addListener(eventName: 'plates', listener: (event: PlatesEvent) => void): Promise<PluginListenerHandle>;
  /** Each plate once, when several frames agree. For continuous scanning. PRO. */
  addListener(eventName: 'plate', listener: (event: { plate: DetectedPlate }) => void): Promise<PluginListenerHandle>;
  /** One plate per activation, once the reads are certain. For scanning a single plate. PRO. */
  addListener(eventName: 'scan', listener: (event: { plate: DetectedPlate }) => void): Promise<PluginListenerHandle>;
  addListener(eventName: 'error', listener: (event: AlprError) => void): Promise<PluginListenerHandle>;
  removeAllListeners(): Promise<void>;
}
