import { Elysia, t } from 'elysia'
import { cors } from '@elysiajs/cors'
import { TrafficAlertSchema } from './models'
import { fetchLiveMMDAAlerts } from './scraper'

const app = new Elysia()
  .use(cors({
    origin: '*',
    methods: ['GET']
  }))
  
  .get('/', () => ({ status: 'MMDA Live Scraper Engine Active 🔥' }))

  .group('/api', (subApp) => 
    subApp.get('/alerts', async () => {
      // Execute the live data fetch directly upon client request
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