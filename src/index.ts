import { registerPlugin } from '@capacitor/core';

import type { AlprPlugin, BoundingBox, FrameInfo } from './definitions';

const Alpr = registerPlugin<AlprPlugin>('Alpr', {
  web: () => import('./web').then((m) => new m.AlprWeb()),
});

/** Maps a plate's normalized box to a rect in a view of `view` size that shows the frame scaled to fill. */
export function toViewRect(bbox: BoundingBox, frame: FrameInfo, view: { width: number; height: number }): BoundingBox {
  const scale = Math.max(view.width / frame.frameWidth, view.height / frame.frameHeight);
  const displayedWidth = frame.frameWidth * scale;
  const displayedHeight = frame.frameHeight * scale;
  const offsetX = (view.width - displayedWidth) / 2;
  const offsetY = (view.height - displayedHeight) / 2;
  return {
    x: offsetX + bbox.x * displayedWidth,
    y: offsetY + bbox.y * displayedHeight,
    width: bbox.width * displayedWidth,
    height: bbox.height * displayedHeight,
  };
}

export * from './definitions';
export { Alpr };
