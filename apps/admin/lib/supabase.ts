import { createClient, type SupabaseClient } from '@supabase/supabase-js';

export const localSupabaseConfig = {
  url: process.env.NEXT_PUBLIC_SUPABASE_URL ?? '',
  anonKey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? '',
};

export function isLocalSupabaseConfigured(): boolean {
  return localSupabaseConfig.url.length > 0 && localSupabaseConfig.anonKey.length > 0;
}

let client: SupabaseClient | null = null;

export function getSupabaseClient(): SupabaseClient {
  if (!isLocalSupabaseConfigured()) {
    throw new Error(
      'Local Supabase is not configured. Set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY before starting Admin Web.',
    );
  }
  client ??= createClient(localSupabaseConfig.url, localSupabaseConfig.anonKey, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: false,
    },
  });
  return client;
}
