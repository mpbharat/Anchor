import type { NextFunction, Request, Response } from 'express';
import { supabase } from '../config/supabase';
import { unauthorized } from '../utils/errors';
import { asyncHandler } from '../utils/asyncHandler';

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: { id: string; email: string };
    }
  }
}

// Auth via Supabase: the mobile app sends the Supabase-issued access token as
// `Authorization: Bearer <token>`. We verify it with Supabase and attach the user.
export const requireAuth = asyncHandler(async (req: Request, _res: Response, next: NextFunction) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    throw unauthorized('Missing Authorization header');
  }
  const token = header.slice('Bearer '.length);
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) {
    throw unauthorized('Invalid or expired token');
  }
  req.user = { id: data.user.id, email: data.user.email ?? '' };
  next();
});
