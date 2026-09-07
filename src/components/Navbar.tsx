import React, { useState, useEffect } from 'react';
import { 
  Sparkles, 
  Plus, 
  FileSpreadsheet, 
  Moon, 
  Sun, 
  Download, 
  Upload, 
  Cloud, 
  RefreshCw,
  Info
} from 'lucide-react';
import { exportAllDataJSON } from '../utils/storage';
import { getSupabaseClient } from '../utils/supabaseClient';
import { syncService, SyncStatus } from '../utils/syncService';

interface NavbarProps {
  currentTheme: 'dark' | 'light';
  onToggleTheme: () => void;
  onOpenNewDeck: () => void;
  onOpenImport: () => void;
  onGoHome: () => void;
  onRestoreClick: () => void;
  onOpenAuth: () => void;
  onOpenAbout: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  currentTheme,
  onToggleTheme,
  onOpenNewDeck,
  onOpenImport,
  onGoHome,
  onRestoreClick,
  onOpenAuth,
  onOpenAbout,
}) => {
  const [userEmail, setUserEmail] = useState<string | null>(null);
  const [syncStatus, setSyncStatus] = useState<SyncStatus>(syncService.getStatus());

  useEffect(() => {
    const supabase = getSupabaseClient();
    if (supabase) {
      supabase.auth.getUser().then(({ data }) => {
        if (data.user?.email) {
          setUserEmail(data.user.email);
        }
      });

      const { data: authListener } = supabase.auth.onAuthStateChange((_event, session) => {
        setUserEmail(session?.user?.email || null);
      });

      return () => {
        authListener.subscription.unsubscribe();
      };
    }
  }, []);

  useEffect(() => {
    return syncService.subscribe((status) => {
      setSyncStatus(status);
    });
  }, []);

  return (
    <nav className="navbar">
      <div className="nav-brand" onClick={onGoHome} role="button" tabIndex={0} title="Return to Dashboard">
        <img src="/app-icon.png" alt="Lexio PRO Logo" className="nav-logo-icon-img" />
        <div>
          <span className="nav-title">Lexio</span>
          <span className="nav-badge">PRO</span>
        </div>
      </div>

      <div className="nav-actions">
        {/* Supabase Cloud Sync / User Button */}
        <button 
          className={`btn ${userEmail ? 'btn-secondary' : 'btn-accent'}`}
          onClick={onOpenAuth}
          style={{ padding: '7px 14px', fontSize: '0.85rem' }}
          title={userEmail ? `Connected: ${userEmail}` : 'Connect Supabase Cloud'}
        >
          {syncStatus === 'syncing' ? (
            <RefreshCw size={16} className="spin" />
          ) : (
            <Cloud size={16} />
          )}
          <span>{userEmail ? userEmail.split('@')[0] : 'Cloud Sync'}</span>
        </button>

        <button 
          className="btn btn-primary"
          onClick={onOpenImport}
          title="Batch import vocabulary from Excel (.xlsx) or CSV"
        >
          <FileSpreadsheet size={18} />
          <span>Import Excel / CSV</span>
        </button>

        <button 
          className="btn btn-secondary"
          onClick={onOpenNewDeck}
          title="Create a new deck manually"
        >
          <Plus size={18} />
          <span>New Deck</span>
        </button>

        <button 
          className="btn-icon" 
          onClick={exportAllDataJSON}
          title="Download complete data backup (.json)"
          aria-label="Download complete data backup (.json)"
        >
          <Download size={18} />
        </button>

        <button 
          className="btn-icon" 
          onClick={onRestoreClick}
          title="Restore data from JSON backup"
          aria-label="Restore data from JSON backup"
        >
          <Upload size={18} />
        </button>

        <button 
          className="btn-icon" 
          onClick={onOpenAbout}
          title="About Lexio PRO & Tulie Tech"
          aria-label="About Lexio PRO & Tulie Tech"
        >
          <Info size={18} />
        </button>

        <button 
          className="btn-icon" 
          onClick={onToggleTheme}
          title={currentTheme === 'dark' ? 'Switch to Light Theme' : 'Switch to Dark Theme'}
          aria-label={currentTheme === 'dark' ? 'Switch to Light Theme' : 'Switch to Dark Theme'}
        >
          {currentTheme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
        </button>
      </div>
    </nav>
  );
};
