import type { Request, Response } from 'express';
import { z } from 'zod';
import * as authService from '../services/auth.service';
import { env } from '../config/env';
import { notFound, unauthorized } from '../utils/errors';

export const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  first_name: z.string().min(1).max(200).optional(),
  timezone: z.string().min(1).max(64).optional(),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export const refreshSchema = z.object({
  refresh_token: z.string().min(1),
});

export const devLoginSchema = z.object({
  email: z.string().email().default('dev@anchor.test'),
  password: z.string().min(8).default('anchor-dev-password'),
});

export async function register(req: Request, res: Response): Promise<void> {
  const session = await authService.register(req.body);
  res.status(201).json(session);
}

export async function login(req: Request, res: Response): Promise<void> {
  const session = await authService.login(req.body.email, req.body.password);
  res.json(session);
}

export async function refresh(req: Request, res: Response): Promise<void> {
  const session = await authService.refresh(req.body.refresh_token);
  res.json(session);
}

// DEV ONLY: 404 outside development. Returns a session for a pre-confirmed user.
export async function devLogin(req: Request, res: Response): Promise<void> {
  if (env.nodeEnv !== 'development') throw notFound('Route not found');
  const session = await authService.devLogin(req.body.email, req.body.password);
  res.json(session);
}

export async function logout(req: Request, res: Response): Promise<void> {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) throw unauthorized('Missing Authorization header');
  await authService.logout(header.slice('Bearer '.length));
  res.status(204).send();
}
