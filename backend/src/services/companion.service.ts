import Exa from 'exa-js';
import { env } from '../config/env';
import { badRequest } from '../utils/errors';

// Anchor's companion grounds its coaching in real sources via Exa web search
// (a sponsor API). Used to reality-check commitments — e.g. "is a half marathon
// in 6 weeks realistic?" — so the push-back cites evidence instead of guessing.
// Server-side only: the Exa key never reaches the client.

export interface GroundedResult {
  title: string;
  url: string;
  highlight: string | null;
}

let client: Exa | null = null;
function exa(): Exa {
  if (!env.exaApiKey) {
    throw badRequest('Web search is unavailable: EXA_API_KEY is not configured.');
  }
  client ??= new Exa(env.exaApiKey);
  return client;
}

// The recommended Exa request: the query plus token-efficient highlights, nothing
// else. numResults is optional and defaults to Exa's server default (10).
export async function webSearch(query: string, numResults?: number): Promise<GroundedResult[]> {
  const res = await exa().search(query, {
    type: 'auto',
    contents: { highlights: true },
    ...(numResults ? { numResults } : {}),
  });
  return res.results.map((r) => ({
    title: r.title ?? r.url,
    url: r.url,
    highlight: r.highlights?.[0] ?? null,
  }));
}
