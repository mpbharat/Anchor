import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import routes from './routes';
import { errorHandler } from './middleware/errorHandler';

export function createApp(): express.Express {
  const app = express();

  app.use(helmet());
  app.use(cors());
  app.use(express.json({ limit: '1mb' }));

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', service: 'anchor-backend' });
  });

  // Routes at root, matching ANCHOR-BUILD-SPEC.md §7.
  app.use('/', routes);

  app.use((_req, res) => {
    res.status(404).json({ error: 'Route not found' });
  });

  app.use(errorHandler);
  return app;
}
