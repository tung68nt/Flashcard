import { 
  X, 
  Sparkles, 
  ShieldCheck, 
  Cpu, 
  Cloud, 
  ExternalLink, 
  Layers, 
  Award, 
  Globe, 
  CheckCircle2 
} from 'lucide-react';
import { useModalA11y } from '../hooks/useModalA11y';

interface AboutModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const AboutModal: React.FC<AboutModalProps> = ({ isOpen, onClose }) => {
  useModalA11y({ isOpen, onClose });

  if (!isOpen) return null;

  return (
    <div 
      className="modal-overlay" 
      onClick={onClose}
      role="dialog"
      aria-modal="true"
      aria-labelledby="about-modal-title"
    >
      <div 
        className="modal-content" 
        onClick={(e) => e.stopPropagation()}
        style={{ maxWidth: 540, textAlign: 'center', padding: '36px 32px' }}
      >
        <button 
          className="btn-icon" 
          onClick={onClose} 
          style={{ position: 'absolute', top: 16, right: 16 }}
          title="Close"
          aria-label="Close About Dialog"
        >
          <X size={20} />
        </button>

        {/* Icon & Brand Header */}
        <div style={{
          width: 88,
          height: 88,
          margin: '0 auto 16px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}>
          <img 
            src="/app-icon.png" 
            alt="Lexio PRO Icon" 
            style={{ 
              width: 80, 
              height: 80, 
              borderRadius: 20, 
              boxShadow: '0 10px 28px var(--primary-glow)',
              objectFit: 'contain'
            }} 
          />
        </div>

        <h2 style={{ fontSize: '1.75rem', fontWeight: 900, letterSpacing: '-0.03em', marginBottom: 4 }}>
          Lexio <span style={{ color: 'var(--primary)' }}>PRO</span>
        </h2>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, marginBottom: 12 }}>
          <span className="tag-badge" style={{ background: 'var(--primary-bg)', color: 'var(--primary)', fontWeight: 800 }}>
            v1.2.0 Commercial
          </span>
          <span className="tag-badge" style={{ background: 'var(--bg-tertiary)', color: 'var(--text-muted)' }}>
            Build 2026.1
          </span>
        </div>

        <p style={{ color: 'var(--text-secondary)', fontSize: '0.94rem', lineHeight: 1.55, marginBottom: 24 }}>
          Next-generation linguistic flashcard & spaced repetition platform. Engineered for serious language learners, test-takers, and memory athletes.
        </p>

        {/* Specifications Matrix */}
        <div style={{
          background: 'var(--bg-tertiary)',
          borderRadius: 'var(--radius-lg)',
          padding: '16px 18px',
          display: 'flex',
          flexDirection: 'column',
          gap: 12,
          textAlign: 'left',
          marginBottom: 24,
          fontSize: '0.88rem'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <span style={{ display: 'flex', alignItems: 'center', gap: 8, color: 'var(--text-secondary)' }}>
              <Cpu size={15} color="var(--primary)" />
              Memory Engine
            </span>
            <strong style={{ color: 'var(--text-primary)' }}>SuperMemo SM-2 Adaptive</strong>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <span style={{ display: 'flex', alignItems: 'center', gap: 8, color: 'var(--text-secondary)' }}>
              <ShieldCheck size={15} color="var(--accent-emerald)" />
              Data Security
            </span>
            <strong style={{ color: 'var(--accent-emerald)' }}>Local-First Encrypted</strong>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <span style={{ display: 'flex', alignItems: 'center', gap: 8, color: 'var(--text-secondary)' }}>
              <Cloud size={15} color="var(--accent-cyan)" />
              Cloud Backend
            </span>
            <strong style={{ color: 'var(--text-primary)' }}>Supabase Realtime Sync</strong>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <span style={{ display: 'flex', alignItems: 'center', gap: 8, color: 'var(--text-secondary)' }}>
              <Award size={15} color="var(--accent-amber)" />
              License Type
            </span>
            <strong style={{ color: 'var(--accent-amber)' }}>Commercial Pro License</strong>
          </div>
        </div>

        {/* Tulie Tech Publisher Box */}
        <div style={{
          borderTop: '1px solid var(--border-medium)',
          paddingTop: 18,
          display: 'flex',
          flexDirection: 'column',
          gap: 6,
          alignItems: 'center',
          fontSize: '0.85rem',
          color: 'var(--text-muted)',
        }}>
          <div style={{ fontWeight: 800, color: 'var(--text-primary)', fontSize: '0.95rem' }}>
            Crafted with precision by <span style={{ color: 'var(--primary)' }}>Tulie Tech</span>
          </div>
          <div>Copyright © 2026 Tulie Tech. All rights reserved.</div>
          <div style={{ fontSize: '0.78rem', opacity: 0.8 }}>
            Unauthorized reproduction or distribution of this software is strictly prohibited.
          </div>
        </div>

        <div style={{ marginTop: 22 }}>
          <button className="btn btn-secondary" onClick={onClose} style={{ width: '100%' }}>
            Dismiss
          </button>
        </div>
      </div>
    </div>
  );
};
