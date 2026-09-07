import React, { Component, ErrorInfo, ReactNode } from 'react';
import { AlertCircle, RefreshCw, Download, Home } from 'lucide-react';
import { exportAllDataJSON } from '../../utils/storage';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  public state: State = {
    hasError: false,
    error: null,
  };

  public static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Uncaught error in Lexio PRO:', error, errorInfo);
  }

  private handleReload = () => {
    window.location.reload();
  };

  private handleReset = () => {
    this.setState({ hasError: false, error: null });
    window.location.href = '/';
  };

  public render() {
    if (this.state.hasError) {
      return (
        <div style={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: 24,
          background: 'var(--bg-primary, #0b0a16)',
          color: 'var(--text-primary, #ffffff)',
          fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, sans-serif'
        }}>
          <div style={{
            maxWidth: 540,
            width: '100%',
            background: 'var(--bg-card, #16132f)',
            padding: 36,
            borderRadius: 24,
            boxShadow: '0 20px 50px rgba(0,0,0,0.5)',
            textAlign: 'center'
          }}>
            <div style={{
              width: 64,
              height: 64,
              borderRadius: 20,
              background: 'rgba(255, 42, 109, 0.15)',
              color: '#ff2a6d',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 20px',
            }}>
              <AlertCircle size={32} />
            </div>

            <h2 style={{ fontSize: '1.6rem', fontWeight: 800, marginBottom: 8 }}>
              Something went wrong
            </h2>

            <p style={{ color: 'var(--text-secondary, #94a3b8)', fontSize: '0.94rem', lineHeight: 1.6, marginBottom: 24 }}>
              An unexpected application error occurred. Your study data is safe in IndexedDB storage.
            </p>

            {this.state.error && (
              <div style={{
                background: 'var(--bg-tertiary, #1e1b38)',
                padding: 14,
                borderRadius: 12,
                fontSize: '0.82rem',
                fontFamily: 'monospace',
                color: '#ff7a59',
                textAlign: 'left',
                overflowX: 'auto',
                marginBottom: 24,
                maxHeight: 120
              }}>
                {this.state.error.message}
              </div>
            )}

            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <button 
                onClick={this.handleReload}
                className="btn btn-primary"
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 8,
                  padding: '12px 20px',
                  borderRadius: 12,
                  fontWeight: 700,
                  cursor: 'pointer',
                  background: 'var(--gradient-primary)',
                  color: '#fff',
                  border: 'none'
                }}
              >
                <RefreshCw size={16} />
                <span>Reload Application</span>
              </button>

              <button 
                onClick={exportAllDataJSON}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 8,
                  padding: '10px 20px',
                  borderRadius: 12,
                  cursor: 'pointer',
                  background: 'transparent',
                  color: 'var(--text-primary, #fff)',
                  border: '1px solid var(--border-medium, rgba(255,255,255,0.1))'
                }}
              >
                <Download size={16} />
                <span>Download Emergency Backup (.json)</span>
              </button>
            </div>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}
