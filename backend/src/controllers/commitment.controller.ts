import type { Request, Response } from 'express';
import { z } from 'zod';
import * as commitmentService from '../services/commitment.service';

export const createCommitmentSchema = z.object({
  title: z.string().min(1).max(200),
  kind: z.enum(['oneoff', 'recurring', 'budget']).optional(),
  metric: z.enum(['boolean', 'count', 'amount']).optional(),
  target_value: z.number().min(0).optional(),
  unit: z.string().max(30).optional(),
  period: z.enum(['week', 'month']).optional(),
  wish: z.string().max(500).optional(),
  obstacle: z.string().max(500).optional(),
  if_trigger: z.string().max(500).optional(),
  then_action: z.string().max(500).optional(),
});

export const updateCommitmentSchema = createCommitmentSchema.partial().strict();

export const checkinSchema = z.object({
  kind: z.enum(['progress', 'done', 'miss']),
  value: z.number().optional(),
  note: z.string().max(500).optional(),
});

export const swapSchema = z.object({ replacement: createCommitmentSchema });

export async function create(req: Request, res: Response): Promise<void> {
  const result = await commitmentService.createCommitment(req.user!.id, req.body);
  if (result.decision === 'no') {
    res.status(409).json({
      decision: 'no',
      message: `You're at ${result.loaded} of ${result.cap}. If it goes in, one comes out — which?`,
      loaded: result.loaded,
      cap: result.cap,
      commitments: result.commitments,
    });
    return;
  }
  res.status(201).json({ decision: 'added', commitment: result.commitment });
}

export async function get(req: Request, res: Response): Promise<void> {
  res.json({ commitment: await commitmentService.getCommitment(req.user!.id, req.params.id) });
}

export async function update(req: Request, res: Response): Promise<void> {
  res.json({ commitment: await commitmentService.updateCommitment(req.user!.id, req.params.id, req.body) });
}

export async function checkin(req: Request, res: Response): Promise<void> {
  res.json({ commitment: await commitmentService.checkin(req.user!.id, req.params.id, req.body) });
}

export async function drop(req: Request, res: Response): Promise<void> {
  res.json({ commitment: await commitmentService.dropCommitment(req.user!.id, req.params.id) });
}

export async function swap(req: Request, res: Response): Promise<void> {
  res.status(201).json(await commitmentService.swapCommitment(req.user!.id, req.params.id, req.body.replacement));
}
