import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import swaggerUi from 'swagger-ui-express';
import routes from './routes';
import { openapiSpec } from './openapi';
import { errorHandler } from './middleware/errorHandler';

export function createApp(): express.Express {
  const app = express();

  // helmet's default CSP blocks Swagger UI's inline assets; disable it just for
  // the docs. Everything else keeps the full helmet defaults.
  app.use(helmet({ contentSecurityPolicy: false }));
  app.use(cors());
  app.use(express.json({ limit: '1mb' }));

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', service: 'anchor-backend' });
  });

  // Interactive API docs. Open http://localhost:3000/docs in a browser.
  app.get('/openapi.json', (_req, res) => res.json(openapiSpec));
  app.use('/docs', swaggerUi.serve, swaggerUi.setup(openapiSpec, {
    customSiteTitle: 'Anchor API',
    swaggerOptions: { persistAuthorization: true },
  }));

  // Routes at root, matching ANCHOR-BUILD-SPEC.md §7.
  app.use('/', routes);

  app.use((_req, res) => {
    res.status(404).json({ error: 'Route not found' });
  });

  app.use(errorHandler);
  return app;
}
