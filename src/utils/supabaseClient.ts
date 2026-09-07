import { createClient, SupabaseClient, User, Session } from '@supabase/supabase-js';

const STORAGE_URL_KEY = 'lexio_supabase_url';
const STORAGE_ANON_KEY = 'lexio_supabase_anon_key';

export interface SupabaseConfig {
  url: string;
  anonKey: string;
}

export function getSavedSupabaseConfig(): SupabaseConfig {
  const env = (import.meta as any)?.env || {};
  const url = localStorage.getItem(STORAGE_URL_KEY) || env.VITE_SUPABASE_URL || env.NEXT_PUBLIC_SUPABASE_URL || '';
  const anonKey = localStorage.getItem(STORAGE_ANON_KEY) || env.VITE_SUPABASE_ANON_KEY || env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY || env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';
  return { url, anonKey };
}

export function saveSupabaseConfig(url: string, anonKey: string): void {
  localStorage.setItem(STORAGE_URL_KEY, url.trim());
  localStorage.setItem(STORAGE_ANON_KEY, anonKey.trim());
  // Reset singleton so next access creates new client
  activeClient = null;
}

let activeClient: SupabaseClient | null = null;

export function getSupabaseClient(): SupabaseClient | null {
  if (activeClient) return activeClient;

  const { url, anonKey } = getSavedSupabaseConfig();
  if (!url || !anonKey) {
    return null;
  }

  try {
    activeClient = createClient(url, anonKey, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        storageKey: 'lexio_auth_token',
      },
    });
    return activeClient;
  } catch (err) {
    console.error('Lỗi khi khởi tạo Supabase client:', err);
    return null;
  }
}

/**
 * Kiểm tra kết nối tới Supabase
 */
export async function testSupabaseConnection(url: string, anonKey: string): Promise<{ success: boolean; message: string }> {
  try {
    const testClient = createClient(url, anonKey);
    const { data, error } = await testClient.auth.getSession();
    if (error) throw error;
    return { success: true, message: 'Kết nối tới Supabase thành công!' };
  } catch (err: any) {
    return { success: false, message: err.message || 'Không thể kết nối tới Supabase' };
  }
}
