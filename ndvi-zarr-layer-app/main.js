import maplibregl from 'maplibre-gl'
import { ZarrLayer } from '@carbonplan/zarr-layer'
import { IcechunkStore } from '@carbonplan/icechunk-js'

// ---------------------------------------------------------------------------
// Config
// Replace ICECHUNK_URL with your R2 public URL once the bucket is public,
// e.g. https://pub-<hash>.r2.dev/ndvi-cdr-pyramid
// or   https://<accountId>.r2.cloudflarestorage.com/osc-pub/ndvi-cdr-pyramid
// ---------------------------------------------------------------------------
const ICECHUNK_URL = import.meta.env.VITE_ICECHUNK_URL

const DATES = [
  '2000-01-01',
  '2000-01-02',
  '2000-01-03',
  '2000-01-04',
  '2000-01-05',
]

// ---------------------------------------------------------------------------
// Map
// ---------------------------------------------------------------------------
const map = new maplibregl.Map({
  container: 'map',
  style: 'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json',
  center: [0, 20],
  zoom: 1.5,
  projection: 'mercator',
})

map.addControl(new maplibregl.NavigationControl(), 'top-left')

// ---------------------------------------------------------------------------
// Status helper
// ---------------------------------------------------------------------------
const statusEl = document.getElementById('status')
function setStatus(msg, cls = '') {
  statusEl.textContent = msg
  statusEl.className = cls
}

// ---------------------------------------------------------------------------
// Open IceChunk store (lazy singleton)
// ---------------------------------------------------------------------------
let _storePromise = null
function getStore() {
  return (_storePromise ??= IcechunkStore.open(ICECHUNK_URL, {
    branch: 'main',
    formatVersion: 'v1',
  }).catch((err) => {
    _storePromise = null
    throw err
  }))
}

// ---------------------------------------------------------------------------
// Layer state
// ---------------------------------------------------------------------------
let layer = null
let state = {
  time: 0,
  colormap: 'ylgn',
  clim: [-0.1, 1.0],
  opacity: 0.85,
}

async function addLayer() {
  setStatus('loading store…')

  let store
  try {
    store = await getStore()
  } catch (err) {
    setStatus('store error — check VITE_ICECHUNK_URL', 'error')
    console.error('IcechunkStore.open failed:', err)
    return
  }

  layer = new ZarrLayer({
    id: 'ndvi',
    source: ICECHUNK_URL,
    store,
    variable: 'NDVI',
    clim: state.clim,
    colormap: state.colormap,
    opacity: state.opacity,
    zarrVersion: 3,
    selector: { time: { selected: state.time, type: 'index' } },
    // lat/lon dimension names as written by topozarr
    spatialDimensions: { lat: 'latitude', lon: 'longitude' },
    latIsAscending: false,   // topozarr writes latitude 90→-90
    onLoadingStateChange: (loading) => {
      if (!loading) setStatus('ready', 'ready')
    },
  })

  map.addLayer(layer)
  setStatus('rendering…')
}

map.on('load', addLayer)

// ---------------------------------------------------------------------------
// Controls
// ---------------------------------------------------------------------------
const timeSlider = document.getElementById('time-slider')
const timeLabel  = document.getElementById('time-label')
timeSlider.addEventListener('input', () => {
  state.time = Number(timeSlider.value)
  timeLabel.textContent = DATES[state.time]
  layer?.setSelector({ time: { selected: state.time, type: 'index' } })
})

const colormapSelect = document.getElementById('colormap-select')
colormapSelect.addEventListener('change', () => {
  state.colormap = colormapSelect.value
  layer?.setColormap(state.colormap)
})

const climMin = document.getElementById('clim-min')
const climMax = document.getElementById('clim-max')
function updateClim() {
  state.clim = [Number(climMin.value), Number(climMax.value)]
  layer?.setClim(state.clim)
}
climMin.addEventListener('change', updateClim)
climMax.addEventListener('change', updateClim)

const opacitySlider = document.getElementById('opacity-slider')
const opacityLabel  = document.getElementById('opacity-label')
opacitySlider.addEventListener('input', () => {
  state.opacity = Number(opacitySlider.value)
  opacityLabel.textContent = state.opacity.toFixed(2)
  layer?.setOpacity(state.opacity)
})
