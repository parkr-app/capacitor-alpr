import { WebPlugin } from '@capacitor/core';

import type { AlprPlugin, DetectedPlate, PermissionStatus } from './definitions';

export class AlprWeb extends WebPlugin implements AlprPlugin {
  private unsupported(): never {
    throw this.unavailable('capacitor-alpr runs on iOS and Android only.');
  }

  async loadModels(): Promise<void> {
    this.unsupported();
  }

  async scanImage(): Promise<{ plates: DetectedPlate[] }> {
    this.unsupported();
  }

  async startCamera(): Promise<void> {
    this.unsupported();
  }

  async updateCamera(): Promise<void> {
    this.unsupported();
  }

  async stopCamera(): Promise<void> {
    this.unsupported();
  }

  async setTelemetryEnabled(): Promise<void> {
    this.unsupported();
  }

  async checkPermissions(): Promise<PermissionStatus> {
    this.unsupported();
  }

  async requestPermissions(): Promise<PermissionStatus> {
    this.unsupported();
  }
}
