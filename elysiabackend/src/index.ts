import { Elysia, t } from 'elysia'
import { cors } from '@elysiajs/cors'
import { TrafficAlertSchema } from './models'
import { fetchLiveMMDAAlerts, startAlertsScraper } from './scraper'

// Start the live background scraper polling every 5 seconds
startAlertsScraper(5000)

const app = new Elysia()
  // 🔓 Upgraded CORS configuration specifically for browser/web clients
  .use(cors({
    origin: true, // Auto-reflects the request origin back to the browser
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'X-Requested-With'],
    credentials: true
  }))
  
  .get('/', () => ({ status: 'MMDA Live Scraper Engine Active 🔥' }))

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
  
  .listen({
    port: 3000,
    hostname: '0.0.0.0'
  })

console.log(`🚀 Live backend cooking at http://${app.server?.hostname}:${app.server?.port}`)