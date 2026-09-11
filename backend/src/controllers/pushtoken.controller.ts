import type { Request, Response } from 'express';
import { z } from 'zod';
import * as pushTokenService from '../services/pushtoken.service';

export const registerSchema = z.object({
  token: z.string().min(1),
  platform: z.enum(['ios', 'android', 'wearos']),
  device_info: z.string().max(500).optional(),
});

export const removeSchema = z.object({ token: z.string().min(1) });

export async function register(req: Request, res: Response): Promise<void> {
  res.status(201).json({ push_token: await pushTokenService.registerPushToken(req.user!.id, req.body) });
}

export async function remove(req: Request, res: Response): Promise<void> {
  await pushTokenService.removePushToken(req.user!.id, req.body.token);
  res.status(204).send();
}
