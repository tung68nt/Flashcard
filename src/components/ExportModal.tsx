import React from 'react';
import { X, FileSpreadsheet, FileText, Download, Database } from 'lucide-react';
import { Deck } from '../types/flashcard';
import { exportDeckToExcel, exportDeckToCSV } from '../utils/excelParser';
import { exportAllDataJSON } from '../utils/storage';
import { useModalA11y } from '../hooks/useModalA11y';

interface ExportModalProps {
  isOpen: boolean;
  onClose: () => void;
  deck: Deck;
}

export const ExportModal: React.FC<ExportModalProps> = ({ isOpen, onClose, deck }) => {
  useModalA11y({ isOpen, onClose });

  if (!isOpen) return null;

  return (
    <div 
      className="modal-overlay" 
      onClick={onClose}
      role="dialog"
      aria-modal="true"
      aria-labelledby="export-modal-title"
    >
      <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 540 }}>
        <div className="modal-header">
          <h2 id="export-modal-title">Export Deck: {deck.title}</h2>
          <button className="btn-icon" onClick={onClose} aria-label="Close Export Dialog"><X size={20} /></button>
        </div>

        <div className="modal-body">
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.92rem', marginBottom: 20 }}>
            Choose your export format for {deck.cards.length} flashcards:
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <div 
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                padding: 16,
                borderRadius: 'var(--radius-lg)',
                border: '1px solid var(--border-subtle)',
                background: 'var(--bg-tertiary)',
                cursor: 'pointer',
              }}
              onClick={() => {
                exportDeckToExcel(deck.title, deck.cards);
                onClose();
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                <div style={{
                  width: 44,
                  height: 44,
                  borderRadius: 'var(--radius-md)',
                  background: 'var(--accent-emerald-bg)',
                  color: 'var(--accent-emerald)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}>
                  <FileSpreadsheet size={24} />
                </div>
                <div>
                  <h4 style={{ fontSize: '1rem', marginBottom: 2 }}>Excel Spreadsheet (.xlsx)</h4>
                  <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
                    Formatted Excel workbook with auto-aligned columns and 12 data fields.
                  </p>
                </div>
              </div>
              <Download size={20} color="var(--primary)" />
            </div>

            <div 
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                padding: 16,
                borderRadius: 'var(--radius-lg)',
                border: '1px solid var(--border-subtle)',
                background: 'var(--bg-tertiary)',
                cursor: 'pointer',
              }}
              onClick={() => {
                exportDeckToCSV(deck.title, deck.cards);
                onClose();
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                <div style={{
                  width: 44,
                  height: 44,
                  borderRadius: 'var(--radius-md)',
                  background: 'var(--accent-cyan-bg)',
                  color: 'var(--accent-cyan)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}>
                  <FileText size={24} />
                </div>
                <div>
                  <h4 style={{ fontSize: '1rem', marginBottom: 2 }}>Comma-Separated Values (.csv)</h4>
                  <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
                    Standard UTF-8 CSV compatible with Anki, Quizlet, and Google Sheets.
                  </p>
                </div>
              </div>
              <Download size={20} color="var(--primary)" />
            </div>

            <div 
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                padding: 16,
                borderRadius: 'var(--radius-lg)',
                border: '1px solid var(--border-subtle)',
                background: 'var(--bg-tertiary)',
                cursor: 'pointer',
              }}
              onClick={() => {
                exportAllDataJSON();
                onClose();
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                <div style={{
                  width: 44,
                  height: 44,
                  borderRadius: 'var(--radius-md)',
                  background: 'var(--primary-bg)',
                  color: 'var(--primary)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}>
                  <Database size={24} />
                </div>
                <div>
                  <h4 style={{ fontSize: '1rem', marginBottom: 2 }}>Complete JSON Backup (.json)</h4>
                  <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
                    Preserves all learning history, SM-2 SRS parameters, ease factors, and due dates.
                  </p>
                </div>
              </div>
              <Download size={20} color="var(--primary)" />
            </div>
          </div>
        </div>

        <div className="modal-footer">
          <button className="btn btn-secondary" onClick={onClose}>Close</button>
        </div>
      </div>
    </div>
  );
};
