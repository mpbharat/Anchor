import type { NextFunction, Request, Response } from 'express';
import type { ZodSchema } from 'zod';
import { badRequest } from '../utils/errors';

export function validateBody(schema: ZodSchema) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      const detail = result.error.issues
        .map((i) => `${i.path.join('.') || 'body'}: ${i.message}`)
        .join('; ');
      throw badRequest(detail);
    }
    req.body = result.data;
    next();
  };
}
