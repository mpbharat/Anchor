import { Router } from 'express';
import { requireAuth } from '../middleware/auth';
import { validateBody } from '../middleware/validate';
import { asyncHandler } from '../utils/asyncHandler';

import authRoutes from './auth.routes';
import * as users from '../controllers/user.controller';
import * as weeks from '../controllers/week.controller';
import * as commitments from '../controllers/commitment.controller';
import * as judge from '../controllers/judge.controller';
import * as nudges from '../controllers/nudge.controller';
import * as signals from '../controllers/signal.controller';
import * as integrations from '../controllers/integration.controller';
import * as witnesses from '../controllers/witness.controller';
import * as messages from '../controllers/message.controller';
import * as pushTokens from '../controllers/pushtoken.controller';
import * as companion from '../controllers/companion.controller';
import * as realtime from '../controllers/realtime.controller';

// Paths match ANCHOR-BUILD-SPEC.md §7 exactly (no /api prefix).
const router = Router();

// Auth (convenience proxies over Supabase Auth; the app may also use the SDK).
router.use('/auth', authRoutes);

// Everything below is scoped to the signed-in user.
router.use(requireAuth);

// Profile & settings
router.get('/me', asyncHandler(users.getMe));
router.patch('/me', validateBody(users.updateMeSchema), asyncHandler(users.updateMe));
router.get('/settings', asyncHandler(users.getSettings));
router.put('/settings', validateBody(users.updateSettingsSchema), asyncHandler(users.updateSettings));

// Import & load (Maria)
router.post('/users/:id/patterns', validateBody(users.importPatternsSchema), asyncHandler(users.importPatterns));
router.get('/users/:id/patterns', asyncHandler(users.getPatterns));
router.delete('/users/:id/patterns', asyncHandler(users.clearPatterns));
router.get('/users/:id/load', asyncHandler(users.getLoad));

// Onboarding & commitments
router.post('/weeks/current', asyncHandler(weeks.current));
router.get('/weeks/current/commitments', asyncHandler(weeks.currentLoad));
router.get('/weeks/:id/review', asyncHandler(weeks.review));
router.post('/weeks/:id/close', validateBody(weeks.closeSchema), asyncHandler(weeks.close));

router.post('/commitments', validateBody(commitments.createCommitmentSchema), asyncHandler(commitments.create));
router.get('/commitments/:id', asyncHandler(commitments.get));
router.patch('/commitments/:id', validateBody(commitments.updateCommitmentSchema), asyncHandler(commitments.update));
router.put('/commitments/:id/checkin', validateBody(commitments.checkinSchema), asyncHandler(commitments.checkin));
router.post('/commitments/:id/swap', validateBody(commitments.swapSchema), asyncHandler(commitments.swap));
router.delete('/commitments/:id', asyncHandler(commitments.drop));

// The AI seam
router.post('/judge', validateBody(judge.judgeSchema), asyncHandler(judge.judge));
router.get('/silence-log', asyncHandler(judge.silenceLog));
router.get('/judgments', asyncHandler(judge.listJudgments));
router.get('/messages', asyncHandler(messages.list));
router.post('/messages', validateBody(messages.addMessageSchema), asyncHandler(messages.add));
router.post('/companion/web-search', validateBody(companion.webSearchSchema), asyncHandler(companion.webSearch));
router.post('/companion/chat', validateBody(companion.chatSchema), asyncHandler(companion.chat));
router.post('/realtime/session', asyncHandler(realtime.session));

// Integrations & signals (Maria)
router.get('/integrations', asyncHandler(integrations.list));
router.post('/integrations/google', validateBody(integrations.connectGoogleSchema), asyncHandler(integrations.connectGoogle));
router.put('/integrations/status', validateBody(integrations.statusSchema), asyncHandler(integrations.setStatus));
router.post('/signals', validateBody(signals.ingestSchema), asyncHandler(signals.ingest));
router.get('/signals', asyncHandler(signals.list));

// Nudges & delivery
router.post('/nudges', validateBody(nudges.scheduleSchema), asyncHandler(nudges.schedule));
router.get('/nudges', asyncHandler(nudges.list));
router.put('/nudges/:id/respond', validateBody(nudges.respondSchema), asyncHandler(nudges.respond));
router.post('/push-tokens', validateBody(pushTokens.registerSchema), asyncHandler(pushTokens.register));
router.delete('/push-tokens', validateBody(pushTokens.removeSchema), asyncHandler(pushTokens.remove));

// Witness
router.get('/witnesses', asyncHandler(witnesses.list));
router.post('/witnesses', validateBody(witnesses.addWitnessSchema), asyncHandler(witnesses.add));
router.delete('/witnesses/:id', asyncHandler(witnesses.remove));

export default router;
