import { Alpr } from 'capacitor-alpr';

const results = document.getElementById('results');
const recognized = [];
let plates = [];
let error = '';
let usingPhoto = false;

function render() {
  const lines = [
    error,
    plates.length ? plates.map((p) => `${p.plate}  ${p.countryCode ?? p.country}`).join('\n') : 'Point the camera at a license plate.',
    recognized.length ? `Recognized: ${recognized.slice(0, 5).join(', ')}` : '',
  ];
  results.textContent = lines.filter(Boolean).join('\n');
}

function frame() {
  const { x, y, width, height } = document.getElementById('camera').getBoundingClientRect();
  return { x, y, width, height };
}

async function start() {
  Alpr.loadModels();
  await Alpr.addListener('plates', (event) => {
    plates = event.plates;
    render();
  });
  await Alpr.addListener('plate', ({ plate }) => {
    recognized.unshift(plate.plate);
    render();
  });
  await Alpr.addListener('error', async (event) => {
    // Simulators and emulators have no camera, so scan the bundled photo instead.
    if (event.code === 'ERR_CAMERA' && !usingPhoto) {
      usingPhoto = true;
      await Alpr.updateCamera({ mockImage: 'plate-1.png' });
      return;
    }
    error = event.message;
    render();
  });
  const { camera } = await Alpr.requestPermissions();
  if (camera !== 'granted') {
    results.textContent = 'Allow camera access in Settings.';
    return;
  }
  await Alpr.startCamera({ frame: frame(), showFps: true });
  window.addEventListener('resize', () => Alpr.updateCamera({ frame: frame() }));
}

start().catch((e) => {
  results.textContent = String(e?.message ?? e);
});
