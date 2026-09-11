import type { Request, Response } from 'express';
import { z } from 'zod';
import * as signalService from '../services/signal.service';

// POST /signals — parsed purchase / event / incoming ask (Maria).
export const ingestSchema = z.object({
  source: z.enum(['calendar', 'gmail']),
  kind: z.enum(['event', 'ask', 'purchase']),
  title: z.string().max(500).optional(),
  merchant: z.string().max(200).optional(),
  amount: z.number().optional(),
  category: z.string().max(100).optional(),
  occurred_at: z.string().datetime({ offset: true }).optional(),
});

export async function ingest(req: Request, res: Response): Promise<void> {
  res.status(201).json({ signal: await signalService.ingestSignal(req.user!.id, req.body) });
}

export async function list(req: Request, res: Response): Promise<void> {
  res.json({ signals: await signalService.listSignals(req.user!.id) });
}
