import { Elysia, t } from 'elysia'
import { cors } from '@elysiajs/cors'
import { TrafficAlertSchema } from '../src/models' // Double check path to models
import { fetchLiveMMDAAlerts } from '../src/scraper' // Double check path to scraper

const app = new Elysia({ aot: false })
  .use(cors({
    origin: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'X-Requested-With'],
    credentials: true
  }))
  
  .get('/', () => ({ status: 'MMDA Live Scraper Engine Active 🔥' }))

  .get('/health', () => {
    return {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
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

// Required for Vercel's serverless pipeline handler
export default app;