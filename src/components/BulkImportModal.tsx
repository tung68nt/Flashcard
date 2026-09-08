import React, { useState, useRef } from 'react';
import { 
  UploadCloud, 
  FileSpreadsheet, 
  FileText, 
  X, 
  CheckCircle2, 
  Download, 
  ArrowRight, 
  AlertCircle 
} from 'lucide-react';
import { 
  ParsedFileData, 
  parseExcelFile, 
  parseCSVFile, 
  detectColumnMapping, 
  convertRowsToCards, 
  downloadSampleExcel,
  downloadSampleCSV 
} from '../utils/excelParser';
import { ColumnMapping, Deck, Flashcard } from '../types/flashcard';
import { useModalA11y } from '../hooks/useModalA11y';
import { useToast } from '../context/ToastContext';

interface BulkImportModalProps {
  isOpen: boolean;
  onClose: () => void;
  existingDecks: Deck[];
  currentDeckId?: string;
  onImportSuccess: (newDeckOrUpdated: Deck, isNewDeck: boolean) => void;
}

export const BulkImportModal: React.FC<BulkImportModalProps> = ({
  isOpen,
  onClose,
  existingDecks,
  currentDeckId,
  onImportSuccess,
}) => {
  useModalA11y({ isOpen, onClose });
  const { showToast } = useToast();
  const [isDragging, setIsDragging] = useState(false);
  const [fileData, setFileData] = useState<ParsedFileData | null>(null);
  const [mapping, setMapping] = useState<ColumnMapping>({
    term: '',
    phonetic: '',
    partOfSpeech: '',
    definition: '',
    example: '',
    exampleTranslation: '',
    grammarPattern: '',
    notes: '',
    tags: '',
  });

  const [targetMode, setTargetMode] = useState<'new' | 'existing'>(
    currentDeckId ? 'existing' : 'new'
  );
  const [selectedDeckId, setSelectedDeckId] = useState<string>(
    currentDeckId || (existingDecks[0]?.id || '')
  );
  const [existingStrategy, setExistingStrategy] = useState<'replace' | 'append'>('replace');
  const [newDeckTitle, setNewDeckTitle] = useState('');
  const [newDeckDesc, setNewDeckDesc] = useState('');
  const [newDeckLang, setNewDeckLang] = useState('en-US');
  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const fileInputRef = useRef<HTMLInputElement>(null);

  if (!isOpen) return null;

  const handleFileProcess = async (file: File) => {
    setErrorMsg(null);
    setIsLoading(true);
    try {
      let parsed: ParsedFileData;
      const fileName = file.name.toLowerCase();
      if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
        parsed = await parseExcelFile(file);
      } else if (fileName.endsWith('.csv')) {
        parsed = await parseCSVFile(file);
      } else {
        throw new Error('Please select an Excel (.xlsx, .xls) or CSV (.csv) file');
      }

      if (parsed.headers.length === 0 || parsed.rows.length === 0) {
        throw new Error('File is empty or table structure could not be parsed.');
      }

      setFileData(parsed);
      const autoMapping = detectColumnMapping(parsed.headers);
      setMapping(autoMapping);

      // Suggest deck title from file name
      if (!newDeckTitle) {
        const cleanName = file.name
          .replace(/\.[^/.]+$/, '')
          .replace(/[-_]/g, ' ')
          .trim();
        setNewDeckTitle(cleanName.charAt(0).toUpperCase() + cleanName.slice(1));
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'Error parsing file');
      setFileData(null);
    } finally {
      setIsLoading(false);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      handleFileProcess(e.dataTransfer.files[0]);
    }
  };

  const handleExecuteImport = () => {
    if (!fileData) return;
    if (!mapping.term || !mapping.definition) {
      setErrorMsg('Please map at least the "Term" and "Definition" columns.');
      return;
    }

    const cards = convertRowsToCards(fileData.rows, mapping);
    if (cards.length === 0) {
      setErrorMsg('No valid flashcard rows found to import.');
      return;
    }

    if (targetMode === 'new') {
      const title = newDeckTitle.trim() || `New Deck (${new Date().toLocaleDateString('en-US')})`;
      const newDeck: Deck = {
        id: `deck-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
        title,
        description: newDeckDesc.trim() || `Imported from ${fileData.fileName} (${cards.length} cards)`,
        language: newDeckLang,
        targetLanguage: 'en-US',
        tags: ['Imported', 'Excel/CSV'],
        color: '#4f46e5',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        cards,
      };
      onImportSuccess(newDeck, true);
      showToast(`Imported ${cards.length} cards into new deck "${title}"!`, 'success');
    } else {
      const targetDeck = existingDecks.find((d) => d.id === selectedDeckId);
      if (!targetDeck) {
        setErrorMsg('Please select a valid destination deck.');
        return;
      }
      const finalCards = existingStrategy === 'replace' ? cards : [...targetDeck.cards, ...cards];
      const updatedDeck: Deck = {
        ...targetDeck,
        cards: finalCards,
        updatedAt: new Date().toISOString(),
      };
      onImportSuccess(updatedDeck, false);
      showToast(
        existingStrategy === 'replace'
          ? `Đã ghi đè ${cards.length} thẻ vào bộ "${targetDeck.title}"!`
          : `Đã thêm nối tiếp ${cards.length} thẻ vào bộ "${targetDeck.title}"!`,
        'success'
      );
    }

    onClose();
  };

  return (
    <div 
      className="modal-overlay" 
      onClick={onClose}
      role="dialog"
      aria-modal="true"
      aria-labelledby="bulk-import-title"
    >
      <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 880 }}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <FileSpreadsheet size={24} color="var(--primary)" />
            <h2 id="bulk-import-title">Batch Flashcard Import (Excel / CSV)</h2>
          </div>
          <button className="btn-icon" onClick={onClose} aria-label="Close Import Dialog"><X size={20} /></button>
        </div>

        <div className="modal-body">
          {errorMsg && (
            <div style={{
              background: 'var(--accent-rose-bg)',
              color: 'var(--accent-rose)',
              border: '1px solid var(--accent-rose)',
              borderRadius: 'var(--radius-md)',
              padding: '12px 16px',
              marginBottom: 16,
              display: 'flex',
              alignItems: 'center',
              gap: 8,
              fontSize: '0.9rem'
            }}>
              <AlertCircle size={18} />
              <span>{errorMsg}</span>
            </div>
          )}

          {!fileData ? (
            <div>
              {/* Dropzone */}
              <div 
                className={`dropzone-box ${isDragging ? 'drag-active' : ''}`}
                onDragOver={(e) => { e.preventDefault(); setIsDragging(true); }}
                onDragLeave={() => setIsDragging(false)}
                onDrop={handleDrop}
                onClick={() => fileInputRef.current?.click()}
              >
                <input 
                  type="file" 
                  ref={fileInputRef} 
                  style={{ display: 'none' }} 
                  accept=".xlsx, .xls, .csv" 
                  onChange={(e) => {
                    if (e.target.files && e.target.files.length > 0) {
                      handleFileProcess(e.target.files[0]);
                    }
                  }}
                />
                <div className="dropzone-icon">
                  <UploadCloud size={30} />
                </div>
                <h3 style={{ marginBottom: 6, fontSize: '1.2rem' }}>
                  Drag & drop Excel (.xlsx) or CSV file here
                </h3>
                <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem', marginBottom: 16 }}>
                  Or click to browse from your computer
                </p>
                <div style={{ display: 'inline-flex', gap: 8 }}>
                  <span className="tag-badge">.xlsx</span>
                  <span className="tag-badge">.xls</span>
                  <span className="tag-badge">.csv (UTF-8)</span>
                </div>
              </div>

              {/* Template Download Banner */}
              <div style={{
                marginTop: 20,
                padding: 16,
                background: 'var(--bg-tertiary)',
                borderRadius: 'var(--radius-lg)',
                border: '1px solid var(--border-subtle)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                flexWrap: 'wrap',
                gap: 12
              }}>
                <div>
                  <h4 style={{ fontSize: '0.95rem', marginBottom: 2 }}>Need a standard template?</h4>
                  <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
                    Download our ready-to-use template with 9 standard columns (Term, Phonetics, POS, Definition, Example, Translation, Grammar, Notes, Tags).
                  </p>
                </div>
                <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
                  <button 
                    type="button"
                    className="btn btn-secondary" 
                    onClick={downloadSampleCSV}
                    style={{ fontSize: '0.85rem' }}
                    id="download-csv-template-btn"
                  >
                    <Download size={16} />
                    <span>Download CSV Template (.csv)</span>
                  </button>
                  <button 
                    type="button"
                    className="btn btn-secondary" 
                    onClick={downloadSampleExcel}
                    style={{ fontSize: '0.85rem' }}
                    id="download-excel-template-btn"
                  >
                    <Download size={16} />
                    <span>Download Excel Template (.xlsx)</span>
                  </button>
                </div>
              </div>
            </div>
          ) : (
            <div>
              {/* File Info Bar */}
              <div style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                background: 'var(--primary-bg)',
                padding: '12px 18px',
                borderRadius: 'var(--radius-md)',
                marginBottom: 20
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <CheckCircle2 size={20} color="var(--primary)" />
                  <div>
                    <strong>{fileData.fileName}</strong>
                    <span style={{ marginLeft: 8, fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
                      ({fileData.rows.length} rows, {fileData.headers.length} columns)
                    </span>
                  </div>
                </div>
                <button 
                  className="btn btn-secondary" 
                  style={{ padding: '4px 10px', fontSize: '0.8rem' }}
                  onClick={() => setFileData(null)}
                >
                  Change File
                </button>
              </div>

              {/* Step 1: Mapping Columns */}
              <h3 style={{ fontSize: '1.05rem', marginBottom: 12 }}>
                1. Column Mapping
              </h3>
              <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginBottom: 16 }}>
                Columns have been automatically matched based on headers. You can adjust if needed.
              </p>

              <div className="mapping-grid">
                <div className="form-group">
                  <label className="form-label">
                    Term / Word <span style={{ color: 'var(--accent-rose)' }}>*</span>
                  </label>
                  <select 
                    className="form-select" 
                    value={mapping.term}
                    onChange={(e) => setMapping({ ...mapping, term: e.target.value })}
                  >
                    <option value="">-- Select Column --</option>
                    {fileData.headers.map((h) => <option key={h} value={h}>{h}</option>)}
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">
                    Definition / Meaning <span style={{ color: 'var(--accent-rose)' }}>*</span>
                  </label>
                  <select 
                    className="form-select" 
                    value={mapping.definition}
                    onChange={(e) => setMapping({ ...mapping, definition: e.target.value })}
                  >
                    <option value="">-- Select Column --</option>
                    {fileData.headers.map((h) => <option key={h} value={h}>{h}</option>)}
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">IPA Phonetics</label>
                  <select 
                    className="form-select" 
                    value={mapping.phonetic}
                    onChange={(e) => setMapping({ ...mapping, phonetic: e.target.value })}
                  >
                    <option value="">-- Do Not Import --</option>
                    {fileData.headers.map((h) => <option key={h} value={h}>{h}</option>)}
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Part of Speech</label>
                  <select 
                    className="form-select" 
                    value={mapping.partOfSpeech}
                    onChange={(e) => setMapping({ ...mapping, partOfSpeech: e.target.value })}
                  >
                    <option value="">-- Do Not Import --</option>
                    {fileData.headers.map((h) => <option key={h} value={h}>{h}</option>)}
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Example Sentence</label>
                  <select 
                    className="form-select" 
                    value={mapping.example}
                    onChange={(e) => setMapping({ ...mapping, example: e.target.value })}
                  >
                    <option value="">-- Do Not Import --</option>
                    {fileData.headers.map((h) => <option key={h} value={h}>{h}</option>)}
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Example Translation</label>
                  <select 
                    className="form-select" 
                    value={mapping.exampleTranslation}
                    onChange={(e) => setMapping({ ...mapping, exampleTranslation: e.target.value })}
                  >
                    <option value="">-- Do Not Import --</option>
                    {fileData.headers.map((h) => <option key={h} value={h}>{h}</option>)}
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Grammar Pattern</label>
                  <select 
                    className="form-select" 
                    value={mapping.grammarPattern}
                    onChange={(e) => setMapping({ ...mapping, grammarPattern: e.target.value })}
                  >
                    <option value="">-- Do Not Import --</option>
                    {fileData.headers.map((h) => <option key={h} value={h}>{h}</option>)}
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Notes & Mnemonics</label>
                  <select 
                    className="form-select" 
                    value={mapping.notes}
                    onChange={(e) => setMapping({ ...mapping, notes: e.target.value })}
                  >
                    <option value="">-- Do Not Import --</option>
                    {fileData.headers.map((h) => <option key={h} value={h}>{h}</option>)}
                  </select>
                </div>
              </div>

              {/* Step 2: Target Deck */}
              <h3 style={{ fontSize: '1.05rem', margin: '24px 0 12px' }}>
                2. Destination Deck
              </h3>
              <div style={{ display: 'flex', gap: 16, marginBottom: 14 }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', fontSize: '0.92rem' }}>
                  <input 
                    type="radio" 
                    name="targetMode" 
                    checked={targetMode === 'new'} 
                    onChange={() => setTargetMode('new')} 
                  />
                  <span>Create a new deck</span>
                </label>
                {existingDecks.length > 0 && (
                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', fontSize: '0.92rem' }}>
                    <input 
                      type="radio" 
                      name="targetMode" 
                      checked={targetMode === 'existing'} 
                      onChange={() => setTargetMode('existing')} 
                    />
                    <span>Append to existing deck ({existingDecks.length} decks)</span>
                  </label>
                )}
              </div>

              {targetMode === 'new' ? (
                <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: 14 }}>
                  <div className="form-group">
                    <label className="form-label">New Deck Title</label>
                    <input 
                      className="form-input" 
                      placeholder="e.g. C1-C2 Advanced Vocabulary..." 
                      value={newDeckTitle}
                      onChange={(e) => setNewDeckTitle(e.target.value)}
                    />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Pronunciation Audio Language</label>
                    <select 
                      className="form-select" 
                      value={newDeckLang}
                      onChange={(e) => setNewDeckLang(e.target.value)}
                    >
                      <option value="en-US">English (US - en-US)</option>
                      <option value="en-GB">English (UK - en-GB)</option>
                      <option value="ja-JP">Japanese (ja-JP)</option>
                      <option value="zh-CN">Chinese (zh-CN)</option>
                      <option value="ko-KR">Korean (ko-KR)</option>
                      <option value="fr-FR">French (fr-FR)</option>
                      <option value="de-DE">German (de-DE)</option>
                    </select>
                  </div>
                </div>
              ) : (
                <div className="form-group">
                  <label className="form-label">Select Destination Deck</label>
                  <select 
                    className="form-select" 
                    value={selectedDeckId}
                    onChange={(e) => setSelectedDeckId(e.target.value)}
                  >
                    {existingDecks.map((d) => (
                      <option key={d.id} value={d.id}>
                        {d.title} ({d.cards.length} cards)
                      </option>
                    ))}
                  </select>

                  <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 6, background: 'var(--bg-tertiary)', padding: '10px 14px', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-subtle)' }}>
                    <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', fontSize: '0.85rem' }}>
                      <input 
                        type="radio" 
                        name="existingStrategy" 
                        checked={existingStrategy === 'replace'} 
                        onChange={() => setExistingStrategy('replace')} 
                      />
                      <span><strong>Ghi đè toàn bộ (Overwrite)</strong>: Thay thế toàn bộ thẻ hiện có bằng danh sách trong file CSV/Excel này (phù hợp khi tải về sửa rồi nạp lại).</span>
                    </label>
                    <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', fontSize: '0.85rem' }}>
                      <input 
                        type="radio" 
                        name="existingStrategy" 
                        checked={existingStrategy === 'append'} 
                        onChange={() => setExistingStrategy('append')} 
                      />
                      <span><strong>Thêm nối tiếp (Append)</strong>: Giữ nguyên thẻ cũ và thêm các thẻ mới trong file vào cuối bộ thẻ.</span>
                    </label>
                  </div>
                </div>
              )}

              {/* Step 3: Data Preview */}
              <h3 style={{ fontSize: '1.05rem', margin: '20px 0 10px' }}>
                3. Data Preview (First 5 rows)
              </h3>
              <div className="preview-table-container">
                <table className="preview-table">
                  <thead>
                    <tr>
                      <th>#</th>
                      <th>Term</th>
                      <th>Definition</th>
                      <th>Phonetic</th>
                      <th>Example</th>
                    </tr>
                  </thead>
                  <tbody>
                    {fileData.rows.slice(0, 5).map((row, idx) => (
                      <tr key={idx}>
                        <td>{idx + 1}</td>
                        <td style={{ fontWeight: 600 }}>{row[mapping.term] || '-'}</td>
                        <td>{row[mapping.definition] || '-'}</td>
                        <td style={{ fontFamily: 'monospace', color: 'var(--primary)' }}>
                          {mapping.phonetic ? row[mapping.phonetic] || '-' : '-'}
                        </td>
                        <td style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
                          {mapping.example ? row[mapping.example] || '-' : '-'}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>

        <div className="modal-footer">
          <button className="btn btn-secondary" onClick={onClose}>Cancel</button>
          {fileData && (
            <button 
              className="btn btn-primary" 
              onClick={handleExecuteImport}
              disabled={isLoading}
            >
              <CheckCircle2 size={18} />
              <span>Import {fileData.rows.length} Flashcards</span>
            </button>
          )}
        </div>
      </div>
    </div>
  );
};
