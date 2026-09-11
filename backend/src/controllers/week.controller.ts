import type { Request, Response } from 'express';
import { z } from 'zod';
import * as weekService from '../services/week.service';

export const closeSchema = z.object({
  mode: z.enum(['same', 'fresh']).default('fresh'),
  carry_commitment_ids: z.array(z.string().uuid()).optional(),
});

export async function current(req: Request, res: Response): Promise<void> {
  const week = await weekService.getOrCreateCurrentWeek(req.user!.id);
  res.json({ week });
}

export async function currentLoad(req: Request, res: Response): Promise<void> {
  res.json(await weekService.getCurrentLoad(req.user!.id));
}

export async function review(req: Request, res: Response): Promise<void> {
  res.json(await weekService.getReview(req.user!.id, req.params.id));
}

export async function close(req: Request, res: Response): Promise<void> {
  const { mode, carry_commitment_ids } = req.body;
  res.status(201).json(await weekService.closeWeek(req.user!.id, req.params.id, mode, carry_commitment_ids));
}
