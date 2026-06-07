import { Elysia } from 'elysia';
import { cors } from '@elysiajs/cors';
import { fetchLiveMMDAAlerts } from '../src/scraper'; // Adjust path if needed

const app = new Elysia({ aot: false }) // Disable ahead-of-time compilation for serverless speeds
  .use(cors())
  .get('/api/alerts', async () => {
    const liveAlerts = await fetchLiveMMDAAlerts();
    return {
      success: true,
      count: liveAlerts.length,
      data: liveAlerts
    };
  });

// Important for Vercel execution context:
export const GET = app.handle;
export const POST = app.handle;
export const OPTIONS = app.handle;