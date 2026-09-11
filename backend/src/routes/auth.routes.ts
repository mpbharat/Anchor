import { Router } from 'express';
import * as auth from '../controllers/auth.controller';
import { validateBody } from '../middleware/validate';
import { asyncHandler } from '../utils/asyncHandler';

const router = Router();

router.post('/register', validateBody(auth.registerSchema), asyncHandler(auth.register));
router.post('/login', validateBody(auth.loginSchema), asyncHandler(auth.login));
router.post('/refresh', validateBody(auth.refreshSchema), asyncHandler(auth.refresh));
router.post('/logout', asyncHandler(auth.logout));

// DEV ONLY (404 in production): pre-confirmed user + session, no email step.
router.post('/dev-login', validateBody(auth.devLoginSchema), asyncHandler(auth.devLogin));

export default router;
