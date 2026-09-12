import type { Request, Response } from 'express';
import { z } from 'zod';
import * as companion from '../services/companion.service';

// POST /companion/web-search — the companion's grounding tool (Exa, a sponsor API).
// The AI brain calls this when a commitment or question needs real-world evidence.
export const webSearchSchema = z.object({
  query: z.string().min(1).max(500),
  numResults: z.number().int().min(1).max(10).optional(),
});

export async function webSearch(req: Request, res: Response): Promise<void> {
  const { query, numResults } = req.body;
  res.json({ results: await companion.webSearch(query, numResults) });
}
