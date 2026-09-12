import type { Request, Response } from 'express';
import { z } from 'zod';
import * as userService from '../services/user.service';
import * as patternService from '../services/pattern.service';
import * as signalService from '../services/signal.service';
import * as extractService from '../services/extract.service';
import { forbidden } from '../utils/errors';

const time = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/, 'Expected HH:MM');

export const updateMeSchema = z
  .object({
    first_name: z.string().min(1).max(200).optional(),
    timezone: z
      .string()
      .min(1)
      .max(64)
      .refine((tz) => {
        try {
          new Intl.DateTimeFormat('en-US', { timeZone: tz });
          return true;
        } catch {
          return false;
        }
      }, 'Unknown IANA timezone')
      .optional(),
    comm_style: z.string().max(200).optional(),
    onboarding_status: z.string().max(50).optional(),
    is_fresh_start: z.boolean().optional(),
  })
  .strict();

export const updateSettingsSchema = z
  .object({
    review_day: z.enum(['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']).optional(),
    review_time: time.optional(),
    nudge_style: z.enum(['only_matters', 'quiet', 'off']).optional(),
    quiet_hours: z.record(z.unknown()).optional(),
    cap: z.number().int().min(1).max(8).optional(),
  })
  .strict();

// POST /users/:id/patterns — exact keys per spec §7.
export const importPatternsSchema = z.object({
  personality: z.record(z.unknown()).optional(),
  pitfalls: z.array(z.unknown()).optional(),
  working_style: z.string().max(4000).optional(),
  current_projects: z.array(z.unknown()).optional(),
  baseline_load: z.string().max(4000).optional(),
  priorities: z.array(z.unknown()).optional(),
  habits: z.array(z.unknown()).optional(),
  source: z.enum(['chatgpt', 'claude', 'upload', 'fresh']),
  raw_import: z.string().max(200_000).optional(),
});

function resolveUserId(req: Request): string {
  const paramId = req.params.id;
  if (paramId && paramId !== 'me' && paramId !== req.user!.id) {
    throw forbidden('Cannot access another user');
  }
  return req.user!.id;
}

export async function getMe(req: Request, res: Response): Promise<void> {
  const [user, settings] = await Promise.all([
    userService.getUser(req.user!.id, req.user!.email),
    userService.getSettings(req.user!.id),
  ]);
  res.json({ user, settings });
}

export async function updateMe(req: Request, res: Response): Promise<void> {
  const user = await userService.updateUser(req.user!.id, req.body);
  res.json({ user });
}

export async function getSettings(req: Request, res: Response): Promise<void> {
  const settings = await userService.getSettings(req.user!.id);
  res.json({ settings });
}

export async function updateSettings(req: Request, res: Response): Promise<void> {
  const settings = await userService.updateSettings(req.user!.id, req.body);
  res.json({ settings });
}

export async function importPatterns(req: Request, res: Response): Promise<void> {
  const userId = resolveUserId(req);
  const patterns = await patternService.upsertUserPatterns(userId, req.body);
  res.status(201).json({ patterns });
}

// POST /users/:id/patterns/extract — the Import screen's "Extract" button.
// Takes the raw paste from ChatGPT/Claude and structures it into user_patterns.
export const extractPatternsSchema = z.object({
  source: z.enum(['chatgpt', 'claude', 'upload', 'fresh']).default('chatgpt'),
  raw_text: z.string().min(1).max(200_000),
});

export async function extractPatterns(req: Request, res: Response): Promise<void> {
  const userId = resolveUserId(req);
  const { source, raw_text } = req.body;
  const patterns = await extractService.extractAndStore(userId, { source, raw_text });
  res.status(201).json({ patterns });
}

export async function getPatterns(req: Request, res: Response): Promise<void> {
  const patterns = await patternService.getUserPatterns(resolveUserId(req));
  res.json({ patterns });
}

export async function clearPatterns(req: Request, res: Response): Promise<void> {
  await patternService.clearUserPatterns(resolveUserId(req));
  res.status(204).send();
}

// GET /users/:id/load — current load + spend totals.
export async function getLoad(req: Request, res: Response): Promise<void> {
  const summary = await signalService.getLoadSummary(resolveUserId(req));
  res.json(summary);
}
