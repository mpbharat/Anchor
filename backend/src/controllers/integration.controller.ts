import type { Request, Response } from 'express';
import { z } from 'zod';
import * as integrationService from '../services/integration.service';
import * as googleOAuth from '../services/google-oauth.service';

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

// GET /integrations/google/start — mint the consent URL for the app to open.
export async function startGoogle(req: Request, res: Response): Promise<void> {
  res.json({ url: googleOAuth.buildAuthUrl(req.user!.id) });
}

// This page is the last thing someone sees before switching back to Anchor, so
// it says plainly what was granted and stays quiet otherwise.
function resultPage(heading: string, detail: string): string {
  return `<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Anchor</title></head>
<body style="margin:0;display:flex;align-items:center;justify-content:center;height:100vh;
background:#F2E8D5;color:#111A2E;font-family:ui-monospace,Menlo,Consolas,monospace;text-align:center">
<div style="padding:28px;max-width:22rem">
<h1 style="font-size:18px;letter-spacing:1px;margin:0 0 10px">${heading}</h1>
<p style="font-size:13px;line-height:1.6;color:#6B6350;margin:0">${detail}</p>
</div></body></html>`;
}

// GET /integrations/google/callback — Google redirects the browser here. No
// Authorization header, so this route sits above requireAuth and identifies the
// user from the signed `state` instead.
export async function googleCallback(req: Request, res: Response): Promise<void> {
  const code = typeof req.query.code === 'string' ? req.query.code : '';
  const state = typeof req.query.state === 'string' ? req.query.state : '';
  const denied = typeof req.query.error === 'string' ? req.query.error : '';

  if (denied) {
    res.status(400).send(resultPage('Not connected', `Google reported: ${denied}`));
    return;
  }
  if (!code || !state) {
    res.status(400).send(resultPage('Not connected', 'Google did not return a code.'));
    return;
  }

  try {
    const { providers } = await googleOAuth.exchangeCode(code, state);
    const names = providers
      .map((p) => (p === 'google_calendar' ? 'Calendar' : 'Gmail'))
      .join(' and ');
    res.send(resultPage('Connected', `${names} linked, read-only. You can close this and go back to Anchor.`));
  } catch (err) {
    res.status(400).send(resultPage('Not connected', (err as Error).message));
  }
}
