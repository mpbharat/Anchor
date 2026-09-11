import type { Request, Response } from 'express';
import { z } from 'zod';
import * as judgeService from '../services/judge.service';

// POST /judge — returns {verdict, spoken, reasoning, weighed_against, suggested_action}.
// The AI (ai/judge.ts) produces verdict/spoken; the endpoint records + may schedule.
export const judgeSchema = z.object({
  source: z.enum(['voice', 'email', 'pattern', 'calendar']),
  request: z.string().max(2000).optional(),
  trigger: z.string().max(2000).optional(),
  week_id: z.string().uuid().optional(),
  verdict: z.enum(['nudge', 'stay_silent', 'declined', 'allowed', 'swapped']).optional(),
  spoken: z.string().max(2000).optional(),
  reasoning: z.string().max(2000).optional(),
  weighed_against: z.array(z.unknown()).optional(),
  suggested_action: z.string().max(500).optional(),
  commitment_id: z.string().uuid().optional(),
  amount: z.number().optional(),
});

export async function judge(req: Request, res: Response): Promise<void> {
  const r = await judgeService.judge(req.user!.id, req.body);
  res.status(201).json({
    verdict: r.verdict,
    spoken: r.spoken,
    reasoning: r.reasoning,
    weighed_against: r.weighed_against,
    suggested_action: r.suggested_action,
    nudge: r.nudge,
  });
}

export async function silenceLog(req: Request, res: Response): Promise<void> {
  res.json({ judgments: await judgeService.silenceLog(req.user!.id) });
}

export async function listJudgments(req: Request, res: Response): Promise<void> {
  res.json({ judgments: await judgeService.listJudgments(req.user!.id) });
}
