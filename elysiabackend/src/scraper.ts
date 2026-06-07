import axios from 'axios'

export interface RawTrafficAlert {
  id: string
  location: string
  message: string
  status: 'Heavy' | 'Moderate' | 'Light' | 'Flooded'
  timeAgo: string
  timestamp: string
}

// Target the official high-availability livemap JSON feed directly
const WAZE_REAL_API = 'https://www.waze.com/livemap/api/georss'

// Bound boxes matching complete Metro Manila expansion limits
const WAZE_PARAMS = {
  bottom: '14.35',
  top: '14.75',
  left: '120.95',
  right: '121.15',
  env: 'row',
  types: 'alerts,jams'
}

// 🌐 Human Browser Fingerprint Spoofing Headers to bypass Datacenter Firewalls
const FIREWALL_BYPASS_HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  'Accept': 'application/json, text/plain, */*',
  'Accept-Language': 'en-US,en;q=0.9',
  'Referer': 'https://www.waze.com/live-map/',
  'Origin': 'https://www.waze.com',
  'Cache-Control': 'no-cache',
  'Pragma': 'no-cache',
  'Sec-Fetch-Dest': 'empty',
  'Sec-Fetch-Mode': 'cors',
  'Sec-Fetch-Site': 'same-origin',
  'Connection': 'keep-alive'
}

export async function fetchLiveMMDAAlerts(): Promise<RawTrafficAlert[]> {
  const aggregatedAlerts: RawTrafficAlert[] = []
  
  try {
    console.log('[API Pipeline] Fetching raw live data from Waze routing grids...')
    
    const response = await axios.get(WAZE_REAL_API, {
      params: WAZE_PARAMS,
      headers: FIREWALL_BYPASS_HEADERS,
      timeout: 8000 // Generous window to ensure serverless containers don't timeout
    })

    const alerts = response.data?.alerts || []
    const jams = response.data?.jams || []

    // 1. Process Live Incidents (Accidents, Hazards, Roadworks)
    alerts.forEach((alert: any) => {
      const street = alert.street || alert.city || 'Metro Manila Corridor'
      const description = alert.reportDescription || alert.subtype || 'Traffic incident monitored.'
      const timeMs = alert.pubMillis || Date.now()

      aggregatedAlerts.push({
        id: `waze-live-alert-${alert.uuid || Math.random()}`,
        location: `📍 Live Waze: ${street}`,
        message: description,
        status: detectSeverity(description, alert.severity || 0),
        timeAgo: calculateMinutesAgo(timeMs),
        timestamp: new Date(timeMs).toISOString()
      })
    })

    // 2. Process Live Jam Segments (Gridlocks, Slow Downs)
    jams.forEach((jam: any, index: number) => {
      const street = jam.street || 'Arterial Road'
      const speedKmh = jam.speedKMH ? `${Math.round(jam.speedKMH)} km/h` : 'slow moving'
      const delayMin = jam.delay ? `${Math.round(jam.delay / 60)} min delay` : ''
      const jamMsg = `Traffic congestion monitored moving at ${speedKmh}.${delayMin ? ` Expect an added ${delayMin}.` : ''}`

      aggregatedAlerts.push({
        id: `waze-live-jam-${index}-${Date.now()}`,
        location: `🔴 Traffic Jam: ${street}`,
        message: jamMsg,
        status: detectSeverity('', jam.level || 0),
        timeAgo: 'Live Now',
        timestamp: new Date().toISOString()
      })
    })

    console.log(`[API Pipeline] Stream successfully mapped! Total items: ${aggregatedAlerts.length}`)

  } catch (error: any) {
    console.error('[API Pipeline] Critical Connection Intercept Error:', error.message)
    // Throwing error directly to Express layer so we can view actual log faults in Vercel console
    throw new Error(`Data Stream Blocked: ${error.message}`)
  }

  // Chronological sort: freshest live metrics always on top
  return aggregatedAlerts.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
}

export function startAlertsScraper() {
  // Empty stub keeping entry index points completely intact
}

// Utilities
function calculateMinutesAgo(millis: number): string {
  const diff = Math.floor((Date.now() - millis) / 60000)
  if (diff < 1) return 'Just now'
  if (diff < 60) return `${diff}m ago`
  return `${Math.floor(diff / 60)}h ago`
}

function detectSeverity(text: string, scale: number): 'Heavy' | 'Moderate' | 'Light' | 'Flooded' {
  const lower = text.toLowerCase()
  if (lower.includes('flood') || lower.includes('baha') || lower.includes('gutter')) return 'Flooded'
  if (lower.includes('heavy') || lower.includes('stalled') || lower.includes('accident') || scale >= 4) return 'Heavy'
  if (lower.includes('moderate') || lower.includes('slow') || scale >= 2) return 'Moderate'
  return 'Light'
}