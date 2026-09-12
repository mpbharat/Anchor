import path from 'path';
import dotenv from 'dotenv';

// Load backend/.env first, then fall back to the repo-root .env for shared keys.
dotenv.config();
dotenv.config({ path: path.resolve(process.cwd(), '../.env') });

function firstOf(names: string[]): string {
  for (const n of names) {
    const v = process.env[n];
    if (v) return v;
  }
  throw new Error(`Missing required environment variable: one of ${names.join(', ')}`);
}

export const env = {
  port: Number(process.env.PORT ?? 3000),
  nodeEnv: process.env.NODE_ENV ?? 'development',
  supabaseUrl: firstOf(['SUPABASE_URL']),
  // Full DB access, bypasses RLS. Server-side only.
  supabaseSecretKey: firstOf(['SUPABASE_SECRET_KEY', 'SUPABASE_SERVICE_ROLE_KEY']),
  // Used only for email/password auth flows.
  supabasePublishableKey: firstOf(['SUPABASE_PUBLISHABLE_KEY', 'SUPABASE_ANON_KEY']),
  // OpenAI — the AI model inside Anchor (judgment + companion). Base URL + model swappable.
  openaiApiKey: process.env.OPENAI_API_KEY ?? '',
  openaiBaseUrl: process.env.OPENAI_BASE_URL ?? 'https://api.openai.com/v1',
  openaiModel: process.env.OPENAI_MODEL ?? 'gpt-4o-mini',
  // Exa (sponsor) — companion web-search grounding. Optional: absent = feature off.
  exaApiKey: process.env.EXA_API_KEY ?? '',
  // OpenRouter — voice model (OpenAI-compatible gateway). Optional.
  openRouterApiKey: process.env.OPENROUTER_API_KEY ?? '',
  openRouterBaseUrl: process.env.OPENROUTER_BASE_URL ?? 'https://openrouter.ai/api/v1',
};
