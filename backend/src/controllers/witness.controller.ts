import type { Request, Response } from 'express';
import { z } from 'zod';
import * as witnessService from '../services/witness.service';

export const addWitnessSchema = z.object({
  name: z.string().min(1).max(200),
  contact: z.string().max(200).optional(),
  channel: z.enum(['email', 'whatsapp']).optional(),
});

export async function list(req: Request, res: Response): Promise<void> {
  res.json({ witnesses: await witnessService.listWitnesses(req.user!.id) });
}

export async function add(req: Request, res: Response): Promise<void> {
  res.status(201).json({ witness: await witnessService.addWitness(req.user!.id, req.body) });
}

export async function remove(req: Request, res: Response): Promise<void> {
  await witnessService.removeWitness(req.user!.id, req.params.id);
  res.status(204).send();
}
