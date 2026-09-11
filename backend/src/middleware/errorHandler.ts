import type { NextFunction, Request, Response } from 'express';
import { ApiError } from '../utils/errors';
import { env } from '../config/env';

export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
  if (err instanceof ApiError) {
    res.status(err.statusCode).json({ error: err.message });
    return;
  }
  console.error('Unhandled error:', err);
  res.status(500).json({
    error: env.nodeEnv === 'development' && err instanceof Error ? err.message : 'Internal server error',
  });
}
