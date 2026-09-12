import type { Request, Response } from 'express';
import * as realtime from '../services/realtime.service';

// POST /realtime/session — ephemeral OpenAI Realtime credential for live voice.
export async function session(req: Request, res: Response): Promise<void> {
  res.json(await realtime.createSession(req.user!.id));
}
