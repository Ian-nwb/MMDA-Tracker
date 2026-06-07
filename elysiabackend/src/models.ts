import { t } from 'elysia'

// 1. Define the TypeBox Schema for strict runtime validation
export const TrafficAlertSchema = t.Object({
  id: t.String(),
  location: t.String(),
  message: t.String(),
  status: t.Union([
    t.Literal('Heavy'),
    t.Literal('Moderate'),
    t.Literal('Light'),
    t.Literal('Flooded')
  ]),
  timeAgo: t.String(),
  timestamp: t.String()
})

// 2. Export a clean TypeScript type generated directly from the TypeBox Schema
// This is super useful if you want to use this type across other backend functions
export type TrafficAlert = typeof TrafficAlertSchema.static