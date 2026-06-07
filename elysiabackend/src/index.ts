import { Elysia, t } from 'elysia'
import { cors } from '@elysiajs/cors'
import { TrafficAlertSchema } from './models'
import { fetchLiveMMDAAlerts, startAlertsScraper } from './scraper'

const app = new Elysia()
  // 🔓 Upgraded CORS configuration specifically for browser/web clients
  .use(cors({
    origin: true, // Auto-reflects the request origin back to the browser
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'X-Requested-With'],
    credentials: true
  }))
  
  .get('/', () => ({ status: 'MMDA Live Scraper Engine Active 🔥' }))

  // 🏥 Production-Grade Health Check Endpoint
  .get('/health', () => {
    return {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(), // Tracking runtime in seconds
      services: {
        scraperLoop: process.env.VERCEL ? 'disabled (serverless)' : 'active',
        apiEngine: 'online'
      }
    }
  })

  .group('/api', (subApp) => 
    subApp.get('/alerts', async () => {
      const liveAlerts = await fetchLiveMMDAAlerts()
      return {
        success: true,
        count: liveAlerts.length,
        data: liveAlerts
      }
    }, {
      response: t.Object({
        success: t.Boolean(),
        count: t.Number(),
        data: t.Array(TrafficAlertSchema)
      })
    })
  )

// Only start polling and listen to port if not running in Vercel's serverless environment
const isVercel = process.env.VERCEL === '1' || process.env.VERCEL === 'true'

if (!isVercel) {
  // Start the live background scraper polling every 5 seconds
  startAlertsScraper(5000)
  
  app.listen({
    port: 3000,
    hostname: '0.0.0.0'
  })
  console.log(`🚀 Live backend cooking at http://${app.server?.hostname}:${app.server?.port}`)
}

export default app;