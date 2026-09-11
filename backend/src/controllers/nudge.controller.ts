import type { Request, Response } from 'express';
import { z } from 'zod';
import * as nudgeService from '../services/nudge.service';

export const scheduleSchema = z.object({
  commitment_id: z.string().uuid().optional(),
  fire_at: z.string().datetime({ offset: true }).optional(),
  channel: z.enum(['push', 'watch']).optional(),
  title: z.string().max(200).optional(),
  body: z.string().min(1).max(2000),
});

export const respondSchema = z.object({
  action: z.enum(['on_it', 'snooze']),
  snooze_minutes: z.number().int().min(5).max(24 * 60).optional(),
});

// POST /nudges — schedule.
export async function schedule(req: Request, res: Response): Promise<void> {
  res.status(201).json({ nudge: await nudgeService.scheduleNudge(req.user!.id, req.body) });
}

// GET /nudges — scheduled (or ?all=true for sent/acted/snoozed too).
export async function list(req: Request, res: Response): Promise<void> {
  const includeSent = req.query.all === 'true';
  res.json({ nudges: await nudgeService.listNudges(req.user!.id, includeSent) });
}

// PUT /nudges/:id/respond — On it / Snooze.
export async function respond(req: Request, res: Response): Promise<void> {
  const { action, snooze_minutes } = req.body;
  res.json({ nudge: await nudgeService.respondToNudge(req.user!.id, req.params.id, action, snooze_minutes) });
}
