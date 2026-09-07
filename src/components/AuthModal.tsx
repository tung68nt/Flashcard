import React, { useState, useEffect } from 'react';
import { 
  X, 
  Cloud, 
  LogIn, 
  UserPlus, 
  LogOut, 
  RefreshCw, 
  Settings, 
  CheckCircle2, 
  AlertCircle, 
  Key, 
  Database,
  Download,
  Copy,
  Check
} from 'lucide-react';
import { 
  getSupabaseClient, 
  getSavedSupabaseConfig, 
  saveSupabaseConfig, 
  testSupabaseConnection 
} from '../utils/supabaseClient';
import { syncService, SyncStatus } from '../utils/syncService';
import { Deck } from '../types/flashcard';
import { useModalA11y } from '../hooks/useModalA11y';

interface AuthModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSyncComplete: (decks: Deck[]) => void;
}

export const AuthModal: React.FC<AuthModalProps> = ({
  isOpen,
  onClose,
  onSyncComplete,
}) => {
  useModalA11y({ isOpen, onClose });

  if (!isOpen) return null;

  const [activeTab, setActiveTab] = useState<'auth' | 'config'>('auth');
  const [authMode, setAuthMode] = useState<'signin' | 'signup'>('signin');
  
  const [currentUser, setCurrentUser] = useState<any>(null);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  
  // Supabase Config State
  const initialConfig = getSavedSupabaseConfig();
  const [supabaseUrl, setSupabaseUrl] = useState(initialConfig.url);
  const [supabaseAnonKey, setSupabaseAnonKey] = useState(initialConfig.anonKey);
  const [testResult, setTestResult] = useState<{ success: boolean; message: string } | null>(null);

  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [copiedSql, setCopiedSql] = useState(false);

  // Sync state
  const [syncStatus, setSyncStatus] = useState<SyncStatus>(syncService.getStatus());

  useEffect(() => {
    const supabase = getSupabaseClient();
    if (supabase) {
      supabase.auth.getUser().then(({ data }) => {
        setCurrentUser(data.user || null);
      });
    }

    const unsubscribe = syncService.subscribe((status, msg) => {
      setSyncStatus(status);
      if (status === 'synced' && msg) setSuccessMsg(msg);
      if (status === 'error' && msg) setErrorMsg(msg);
    });

    return () => unsubscribe();
  }, [isOpen]);

  const handleTestConnection = async () => {
    setIsLoading(true);
    setTestResult(null);
    setErrorMsg(null);
    const result = await testSupabaseConnection(supabaseUrl, supabaseAnonKey);
    setTestResult(result);
    setIsLoading(false);
    if (result.success) {
      saveSupabaseConfig(supabaseUrl, supabaseAnonKey);
    }
  };

  const handleSaveConfig = () => {
    saveSupabaseConfig(supabaseUrl, supabaseAnonKey);
    setSuccessMsg('Supabase configuration saved successfully!');
    setTimeout(() => setSuccessMsg(null), 3000);
  };

  const handleAuthSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setSuccessMsg(null);

    const supabase = getSupabaseClient();
    if (!supabase) {
      setErrorMsg('Supabase URL and Anon Key are missing. Please configure them in the "Supabase Config" tab.');
      setActiveTab('config');
      return;
    }

    setIsLoading(true);
    try {
      if (authMode === 'signin') {
        const { data, error } = await supabase.auth.signInWithPassword({ email, password });
        if (error) throw error;
        setCurrentUser(data.user);
        setSuccessMsg('Signed in successfully!');
        
        // Trigger sync automatically
        if (data.user) {
          const syncRes = await syncService.syncAll(data.user.id);
          if (syncRes.success) {
            onSyncComplete(syncRes.decks);
          }
        }
      } else {
        const { data, error } = await supabase.auth.signUp({ email, password });
        if (error) throw error;
        setCurrentUser(data.user);
        setSuccessMsg('Account created successfully! You can start studying now.');
        if (data.user) {
          const syncRes = await syncService.syncAll(data.user.id);
          if (syncRes.success) {
            onSyncComplete(syncRes.decks);
          }
        }
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'Authentication error');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSignOut = async () => {
    const supabase = getSupabaseClient();
    if (supabase) {
      await supabase.auth.signOut();
      setCurrentUser(null);
      setSuccessMsg('Signed out successfully.');
    }
  };

  const handleManualSync = async () => {
    if (!currentUser) return;
    setIsLoading(true);
    const syncRes = await syncService.syncAll(currentUser.id);
    setIsLoading(false);
    if (syncRes.success) {
      onSyncComplete(syncRes.decks);
    }
  };

  const sqlSchema = `-- Bảng lưu trữ Decks & Cards cho Lexio
create table if not exists public.decks (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  description text default '',
  language text default 'en-US',
  target_language text default 'vi-VN',
  category text default 'Chung',
  tags text[] default '{}',
  color text default '#6366f1',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.cards (
  id text primary key,
  deck_id text references public.decks(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  term text not null,
  phonetic text,
  part_of_speech text,
  definition text not null,
  example text,
  example_translation text,
  grammar_pattern text,
  notes text,
  tags text[] default '{}',
  starred boolean default false,
  repetition int default 0,
  interval int default 1,
  ease_factor numeric(4,2) default 2.50,
  due_date timestamptz default now(),
  last_reviewed timestamptz,
  review_count int default 0,
  lapses int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.decks enable row level security;
alter table public.cards enable row level security;

create policy if not exists "User decks isolation" on public.decks for all using (auth.uid() = user_id);
create policy if not exists "User cards isolation" on public.cards for all using (auth.uid() = user_id);`;

  const copySqlToClipboard = () => {
    navigator.clipboard.writeText(sqlSchema);
    setCopiedSql(true);
    setTimeout(() => setCopiedSql(false), 2000);
  };

  return (
    <div 
      className="modal-overlay" 
      onClick={onClose}
      role="dialog"
      aria-modal="true"
      aria-labelledby="auth-modal-title"
    >
      <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 640 }}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <Cloud size={24} color="var(--primary)" />
            <h2 id="auth-modal-title">Cloud Sync & Account (Supabase)</h2>
          </div>
          <button className="btn-icon" onClick={onClose} aria-label="Close Cloud Sync Dialog"><X size={20} /></button>
        </div>

        {/* Tab Headers */}
        <div style={{
          display: 'flex',
          borderBottom: '1px solid var(--border-subtle)',
          background: 'var(--bg-tertiary)',
          padding: '0 24px',
        }}>
          <button
            type="button"
            style={{
              padding: '12px 16px',
              fontWeight: 600,
              fontSize: '0.92rem',
              color: activeTab === 'auth' ? 'var(--primary)' : 'var(--text-secondary)',
              borderBottom: activeTab === 'auth' ? '2px solid var(--primary)' : '2px solid transparent',
            }}
            onClick={() => setActiveTab('auth')}
          >
            Account & Sync
          </button>
          <button
            type="button"
            style={{
              padding: '12px 16px',
              fontWeight: 600,
              fontSize: '0.92rem',
              color: activeTab === 'config' ? 'var(--primary)' : 'var(--text-secondary)',
              borderBottom: activeTab === 'config' ? '2px solid var(--primary)' : '2px solid transparent',
              display: 'flex',
              alignItems: 'center',
              gap: 6
            }}
            onClick={() => setActiveTab('config')}
          >
            <Settings size={15} />
            <span>Supabase Config</span>
          </button>
        </div>

        <div className="modal-body">
          {errorMsg && (
            <div style={{
              background: 'var(--accent-rose-bg)',
              color: 'var(--accent-rose)',
              border: '1px solid var(--accent-rose)',
              borderRadius: 'var(--radius-md)',
              padding: '10px 14px',
              marginBottom: 16,
              display: 'flex',
              alignItems: 'center',
              gap: 8,
              fontSize: '0.88rem'
            }}>
              <AlertCircle size={16} />
              <span>{errorMsg}</span>
            </div>
          )}

          {successMsg && (
            <div style={{
              background: 'var(--accent-emerald-bg)',
              color: 'var(--accent-emerald)',
              border: '1px solid var(--accent-emerald)',
              borderRadius: 'var(--radius-md)',
              padding: '10px 14px',
              marginBottom: 16,
              display: 'flex',
              alignItems: 'center',
              gap: 8,
              fontSize: '0.88rem'
            }}>
              <CheckCircle2 size={16} />
              <span>{successMsg}</span>
            </div>
          )}

          {/* TAB 1: AUTH & SYNC */}
          {activeTab === 'auth' && (
            <div>
              {currentUser ? (
                /* User is Logged In */
                <div>
                  <div style={{
                    background: 'var(--bg-tertiary)',
                    padding: '20px',
                    borderRadius: 'var(--radius-lg)',
                    border: '1px solid var(--border-subtle)',
                    marginBottom: 20
                  }}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
                      <div>
                        <div style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>LOGGED IN AS</div>
                        <div style={{ fontSize: '1.2rem', fontWeight: 700, color: 'var(--text-primary)' }}>
                          {currentUser.email}
                        </div>
                      </div>
                      <span className="tag-badge" style={{ background: 'var(--accent-emerald-bg)', color: 'var(--accent-emerald)' }}>
                        Connected
                      </span>
                    </div>

                    <div style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
                      User ID: <code style={{ fontFamily: 'monospace' }}>{currentUser.id.slice(0, 12)}...</code>
                    </div>
                  </div>

                  <div style={{ display: 'flex', gap: 12 }}>
                    <button 
                      className="btn btn-primary" 
                      onClick={handleManualSync}
                      disabled={isLoading || syncStatus === 'syncing'}
                      style={{ flex: 1 }}
                    >
                      <RefreshCw size={18} className={syncStatus === 'syncing' ? 'spin' : ''} />
                      <span>{syncStatus === 'syncing' ? 'Syncing...' : 'Sync Now'}</span>
                    </button>

                    <button 
                      className="btn btn-secondary" 
                      onClick={handleSignOut}
                      style={{ color: 'var(--accent-rose)' }}
                    >
                      <LogOut size={18} />
                      <span>Sign Out</span>
                    </button>
                  </div>
                </div>
              ) : (
                /* User is NOT Logged In */
                <div>
                  <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem', marginBottom: 20 }}>
                    Sign in to sync your decks, starred cards, and SM-2 spaced repetition progress across Web and Native Desktop.
                  </p>

                  <div style={{ display: 'flex', gap: 10, marginBottom: 16 }}>
                    <button
                      type="button"
                      className={`filter-pill ${authMode === 'signin' ? 'active' : ''}`}
                      onClick={() => setAuthMode('signin')}
                    >
                      Sign In
                    </button>
                    <button
                      type="button"
                      className={`filter-pill ${authMode === 'signup' ? 'active' : ''}`}
                      onClick={() => setAuthMode('signup')}
                    >
                      Create Account
                    </button>
                  </div>

                  <form onSubmit={handleAuthSubmit}>
                    <div className="form-group">
                      <label className="form-label">Account Email</label>
                      <input 
                        type="email" 
                        required 
                        className="form-input" 
                        placeholder="user@example.com" 
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label">Password</label>
                      <input 
                        type="password" 
                        required 
                        minLength={6} 
                        className="form-input" 
                        placeholder="••••••••" 
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                      />
                    </div>

                    <button 
                      type="submit" 
                      className="btn btn-primary" 
                      style={{ width: '100%', padding: '12px' }}
                      disabled={isLoading}
                    >
                      {authMode === 'signin' ? <LogIn size={18} /> : <UserPlus size={18} />}
                      <span>{isLoading ? 'Processing...' : authMode === 'signin' ? 'Sign In & Sync' : 'Create Account'}</span>
                    </button>
                  </form>
                </div>
              )}
            </div>
          )}

          {/* TAB 2: SUPABASE CONFIGURATION */}
          {activeTab === 'config' && (
            <div>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.88rem', marginBottom: 16 }}>
                Connect your personal Supabase project by providing the URL and Public Anon Key:
              </p>

              <div className="form-group">
                <label className="form-label">Supabase Project URL</label>
                <input 
                  className="form-input" 
                  placeholder="https://xyzcompany.supabase.co" 
                  value={supabaseUrl}
                  onChange={(e) => setSupabaseUrl(e.target.value)}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Supabase Anon Public Key</label>
                <textarea 
                  className="form-textarea" 
                  rows={3} 
                  placeholder="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." 
                  value={supabaseAnonKey}
                  onChange={(e) => setSupabaseAnonKey(e.target.value)}
                />
              </div>

              <div style={{ display: 'flex', gap: 10, marginBottom: 20 }}>
                <button 
                  type="button" 
                  className="btn btn-secondary" 
                  onClick={handleTestConnection}
                  disabled={isLoading || !supabaseUrl || !supabaseAnonKey}
                >
                  <Key size={16} />
                  <span>{isLoading ? 'Verifying...' : 'Test Connection'}</span>
                </button>
                <button 
                  type="button" 
                  className="btn btn-primary" 
                  onClick={handleSaveConfig}
                >
                  Save Configuration
                </button>
              </div>

              {testResult && (
                <div style={{
                  padding: '10px 14px',
                  borderRadius: 'var(--radius-md)',
                  marginBottom: 16,
                  fontSize: '0.85rem',
                  background: testResult.success ? 'var(--accent-emerald-bg)' : 'var(--accent-rose-bg)',
                  color: testResult.success ? 'var(--accent-emerald)' : 'var(--accent-rose)',
                  border: `1px solid ${testResult.success ? 'var(--accent-emerald)' : 'var(--accent-rose)'}`
                }}>
                  {testResult.message}
                </div>
              )}

              {/* SQL Schema helper */}
              <div style={{
                background: 'var(--bg-tertiary)',
                padding: 16,
                borderRadius: 'var(--radius-lg)',
                border: '1px solid var(--border-subtle)',
              }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontWeight: 700, fontSize: '0.9rem' }}>
                    <Database size={16} color="var(--primary)" />
                    <span>Supabase Schema Setup SQL (Run once in SQL Editor)</span>
                  </div>
                  <button 
                    type="button" 
                    className="btn btn-secondary" 
                    style={{ padding: '4px 8px', fontSize: '0.78rem' }}
                    onClick={copySqlToClipboard}
                  >
                    {copiedSql ? <Check size={14} color="var(--accent-emerald)" /> : <Copy size={14} />}
                    <span>{copiedSql ? 'Copied' : 'Copy SQL'}</span>
                  </button>
                </div>
                <pre style={{
                  fontSize: '0.75rem',
                  background: 'var(--bg-secondary)',
                  padding: 10,
                  borderRadius: 'var(--radius-md)',
                  overflowX: 'auto',
                  maxHeight: 120,
                  color: 'var(--text-secondary)',
                }}>
                  {sqlSchema}
                </pre>
              </div>
            </div>
          )}
        </div>

        <div className="modal-footer">
          <button className="btn btn-secondary" onClick={onClose}>Close</button>
        </div>
      </div>
    </div>
  );
};
