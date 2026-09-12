import type { Request, Response } from 'express';
import { z } from 'zod';
import * as integrationService from '../services/integration.service';

// POST /integrations/google — store read-only Calendar + Gmail grant (Maria).
export const connectGoogleSchema = z.object({
  access_token: z.string().min(1),
  refresh_token: z.string().optional(),
  scope: z.string().max(2000).optional(),
  providers: z.array(z.enum(['google_calendar', 'gmail'])).optional(),
});

export const statusSchema = z.object({
  provider: z.enum(['google_calendar', 'gmail', 'notifications']),
  status: z.enum(['connected', 'revoked']),
});

export async function list(req: Request, res: Response): Promise<void> {
  res.json({ integrations: await integrationService.listIntegrations(req.user!.id) });
}

export async function connectGoogle(req: Request, res: Response): Promise<void> {
  res.status(201).json({ integrations: await integrationService.connectGoogle(req.user!.id, req.body) });
}

export async function setStatus(req: Request, res: Response): Promise<void> {
  const { provider, status } = req.body;
  res.json({ integration: await integrationService.setStatus(req.user!.id, provider, status) });
}
