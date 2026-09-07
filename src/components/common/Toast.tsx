import React from 'react';
import { CheckCircle2, AlertCircle, AlertTriangle, Info, X } from 'lucide-react';
import { useToast, ToastType } from '../../context/ToastContext';

export const ToastContainer: React.FC = () => {
  const { toasts, removeToast } = useToast();

  if (toasts.length === 0) return null;

  const getIcon = (type: ToastType) => {
    switch (type) {
      case 'success':
        return <CheckCircle2 size={18} color="var(--accent-emerald)" />;
      case 'error':
        return <AlertCircle size={18} color="var(--accent-rose)" />;
      case 'warning':
        return <AlertTriangle size={18} color="var(--accent-amber)" />;
      case 'info':
      default:
        return <Info size={18} color="var(--accent-cyan)" />;
    }
  };

  return (
    <div 
      className="toast-container" 
      role="region" 
      aria-label="Notifications"
      style={{
        position: 'fixed',
        bottom: 24,
        right: 24,
        zIndex: 9999,
        display: 'flex',
        flexDirection: 'column',
        gap: 10,
        pointerEvents: 'none',
      }}
    >
      {toasts.map((toast) => (
        <div
          key={toast.id}
          className={`toast-card toast-${toast.type}`}
          role="alert"
          aria-live="polite"
          style={{
            pointerEvents: 'auto',
            display: 'flex',
            alignItems: 'center',
            gap: 12,
            padding: '12px 18px',
            borderRadius: 'var(--radius-lg)',
            background: 'var(--bg-card)',
            color: 'var(--text-primary)',
            boxShadow: 'var(--shadow-card-hover)',
            border: '1px solid var(--border-medium)',
            backdropFilter: 'blur(12px)',
            maxWidth: 420,
            fontSize: '0.9rem',
            animation: 'toastSlideIn 0.3s cubic-bezier(0.16, 1, 0.3, 1)',
          }}
        >
          <div style={{ flexShrink: 0, display: 'flex', alignItems: 'center' }}>
            {getIcon(toast.type)}
          </div>
          <span style={{ flex: 1, lineHeight: 1.45 }}>{toast.message}</span>
          <button
            onClick={() => removeToast(toast.id)}
            style={{
              background: 'transparent',
              border: 'none',
              color: 'var(--text-muted)',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              padding: 2,
              borderRadius: 4,
            }}
            aria-label="Close notification"
          >
            <X size={15} />
          </button>
        </div>
      ))}
    </div>
  );
};
