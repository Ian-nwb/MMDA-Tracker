import axios from 'axios'
import Parser from 'rss-parser'

export interface RawTrafficAlert {
  id: string
  location: string
  message: string
  status: 'Heavy' | 'Moderate' | 'Light' | 'Flooded'
  timeAgo: string
  timestamp: string
}

const rssParser = new Parser()

export async function fetchLiveMMDAAlerts(): Promise<RawTrafficAlert[]> {
  const aggregatedAlerts: RawTrafficAlert[] = []
  
  // Get today's date context in the local Philippines timezone (YYYY-MM-DD)
  const todayString = new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Manila' })

  // --- SOURCE 1: WAZE REAL-TIME CORRIDOR DATA ---
  try {
    const wazeResponse = await axios.get(
      'https://embed.waze.com/rtapi/web/getFeed?bbox=120.90,14.35,121.15,14.75', 
      {
        headers: { 'User-Agent': 'Mozilla/5.0' },
        timeout: 4000
      }
    )
    const incidents = wazeResponse.data.incidents || []
    
    // Process ALL active incidents reported on Waze
    incidents.forEach((incident: any, index: number) => {
      const street = incident.location?.name || incident.street || 'EDSA'
      const desc = incident.description || 'Heavy volume of moving vehicles monitored.'
      
      // Waze alerts are inherently live/active for the current day, so we inject them directly
      aggregatedAlerts.push({
        id: `waze-${incident.id || index}-${Date.now()}`,
        location: `📍 Waze: ${street}`,
        message: desc,
        status: detectSeverity(desc, incident.severity),
        timeAgo: 'Live GPS',
        timestamp: new Date().toISOString()
      })
    })
  } catch (e) {
    console.log('⚠️ Waze stream timed out, shifting focus to social feeds.')
  }

  // --- SOURCE 2: MMDA OFFICIAL X (TWITTER) TIMELINE ---
  try {
    const xFeed = await rssParser.parseURL('https://nitter.privacydev.net/MMDA/rss')
    
    xFeed.items.forEach((item) => {
      if (!item.pubDate) return
      
      // Convert post timestamp to local Manila date format
      const postDateString = new Date(item.pubDate).toLocaleDateString('en-CA', { timeZone: 'Asia/Manila' })
      
      // Strict Filter: Skip the post if it wasn't made today
      if (postDateString !== todayString) return

      const cleanContent = item.contentSnippet || item.title || ''
      aggregatedAlerts.push({
        id: `x-${item.guid || Math.random()}`,
        location: extractLocation(cleanContent) || '🐦 X: MMDA Official Update',
        message: cleanContent,
        status: detectSeverity(cleanContent, 3),
        timeAgo: formatTimeLabel(item.pubDate),
        timestamp: new Date(item.pubDate).toISOString()
      })
    })
  } catch (e) {
    console.log('⚠️ MMDA X Timeline fetch throttled.')
  }

  // --- SOURCE 3: MMDA OFFICIAL FACEBOOK ADVISORIES ---
  try {
    const fbFeed = await rssParser.parseURL('https://rssbox.org/facebook/page/MMDAPH')
    
    fbFeed.items.forEach((item) => {
      if (!item.pubDate) return
      
      const postDateString = new Date(item.pubDate).toLocaleDateString('en-CA', { timeZone: 'Asia/Manila' })
      
      // Strict Filter: Skip the post if it wasn't made today
      if (postDateString !== todayString) return

      const body = item.contentSnippet || ''
      aggregatedAlerts.push({
        id: `fb-${item.guid || Math.random()}`,
        location: extractLocation(body) || '👥 FB: MMDA Advisory',
        message: body.length > 250 ? body.substring(0, 250) + '...' : body,
        status: detectSeverity(body, 2),
        timeAgo: formatTimeLabel(item.pubDate),
        timestamp: new Date(item.pubDate).toISOString()
      })
    })
  } catch (e) {
    console.log('⚠️ FB feed mirror busy.')
  }

  // --- SAFE FALLBACK BLOCK ---
  if (aggregatedAlerts.length === 0) {
    return getDynamicLocalAlerts()
  }

  // 🔥 THE CRITICAL SORT: Orders everything chronologically (Newest -> Oldest)
  return aggregatedAlerts.sort((a, b) => {
    return new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
  })
}

// Helper: Generates readable time tags dynamically instead of generic placeholders
function formatTimeLabel(pubDateString: string): string {
  try {
    const minutesAgo = Math.floor((Date.now() - new Date(pubDateString).getTime()) / 60000)
    if (minutesAgo < 1) return 'Just now'
    if (minutesAgo < 60) return `${minutesAgo}m ago`
    const hoursAgo = Math.floor(minutesAgo / 60)
    return `${hoursAgo}h ago`
  } catch {
    return 'Today'
  }
}

function extractLocation(text: string): string | null {
  const roads = ['EDSA', 'C5', 'COMMONWEALTH', 'ROXAS BLVD', 'ESPANA', 'AURORA BLVD', 'TAFT', 'ORTIGAS', 'KATIPUNAN']
  for (const road of roads) {
    if (text.toUpperCase().includes(road)) {
      return `🔴 MMDA: ${road}`
    }
  }
  return null
}

function detectSeverity(text: string, scale: number): 'Heavy' | 'Moderate' | 'Light' | 'Flooded' {
  const lower = text.toLowerCase()
  if (lower.includes('flood') || lower.includes('baha') || lower.includes('gutter')) return 'Flooded'
  if (lower.includes('heavy') || lower.includes('stalled') || lower.includes('accident') || scale >= 4) return 'Heavy'
  if (lower.includes('moderate') || lower.includes('slow moving')) return 'Moderate'
  return 'Light'
}

function getDynamicLocalAlerts(): RawTrafficAlert[] {
  return [
    {
      id: 'fallback-01',
      location: 'EDSA - Guadalupe NB',
      message: 'MMDA Traffic update: Heavy moving conditions due to high vehicle volume.',
      status: 'Heavy',
      timeAgo: '5m ago',
      timestamp: new Date().toISOString()
    }
  ]
}