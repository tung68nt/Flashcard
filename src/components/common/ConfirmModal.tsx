import React from 'react';
import { AlertTriangle, Trash2, X } from 'lucide-react';
import { useModalA11y } from '../../hooks/useModalA11y';

interface ConfirmModalProps {
  isOpen: boolean;
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  isDanger?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

export const ConfirmModal: React.FC<ConfirmModalProps> = ({
  isOpen,
  title,
  message,
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  isDanger = false,
  onConfirm,
  onCancel,
}) => {
  useModalA11y({ isOpen, onClose: onCancel });

  if (!isOpen) return null;

  return (
    <div 
      className="modal-overlay" 
      onClick={onCancel}
      role="dialog"
      aria-modal="true"
      aria-labelledby="confirm-modal-title"
      aria-describedby="confirm-modal-desc"
    >
      <div 
        className="modal-content" 
        onClick={(e) => e.stopPropagation()}
        style={{ maxWidth: 440, padding: 28 }}
      >
        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 16, marginBottom: 20 }}>
          <div style={{
            width: 44,
            height: 44,
            borderRadius: 'var(--radius-full)',
            background: isDanger ? 'var(--accent-rose-bg)' : 'var(--primary-bg)',
            color: isDanger ? 'var(--accent-rose)' : 'var(--primary)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
          }}>
            {isDanger ? <Trash2 size={22} /> : <AlertTriangle size={22} />}
          </div>
          <div>
            <h3 id="confirm-modal-title" style={{ fontSize: '1.2rem', fontWeight: 800, marginBottom: 6 }}>
              {title}
            </h3>
            <p id="confirm-modal-desc" style={{ color: 'var(--text-secondary)', fontSize: '0.92rem', lineHeight: 1.5 }}>
              {message}
            </p>
          </div>
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
          <button 
            type="button"
            className="btn btn-secondary" 
            onClick={onCancel}
            style={{ padding: '9px 18px' }}
          >
            {cancelText}
          </button>
          <button 
            type="button"
            className={`btn ${isDanger ? 'btn-danger' : 'btn-primary'}`} 
            onClick={() => {
              onConfirm();
              onCancel();
            }}
            style={{ 
              padding: '9px 18px',
              backgroundColor: isDanger ? 'var(--accent-rose)' : undefined,
              borderColor: isDanger ? 'var(--accent-rose)' : undefined,
              color: '#ffffff'
            }}
            autoFocus
          >
            {confirmText}
          </button>
        </div>
      </div>
    </div>
  );
};
