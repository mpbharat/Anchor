import type { Request, Response } from 'express';
import { z } from 'zod';
import * as companion from '../services/companion.service';
import * as memory from '../services/memory.service';

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

// POST /companion/chat — talk to Anchor (coach / counsellor / friend / accountability).
// Grounds facts via Exa when useful; persists the turn + Anchor's reply.
export const chatSchema = z.object({
  message: z.string().min(1).max(4000),
});

export async function chat(req: Request, res: Response): Promise<void> {
  res.status(201).json(await companion.chat(req.user!.id, req.body.message));
}

// POST /companion/reflect — debounced reflection: update durable memory
// (user_patterns) from the recent conversation. Called on session boundaries.
export async function reflect(req: Request, res: Response): Promise<void> {
  res.json(await memory.reflect(req.user!.id));
}
