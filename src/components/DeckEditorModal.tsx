import React, { useState, useEffect } from 'react';
import { 
  X, 
  Plus, 
  Trash2, 
  Save, 
  Volume2, 
  Languages, 
  Palette, 
  Copy, 
  Subtitles, 
  Pin, 
  Lightbulb, 
  BookOpen,
  Layers,
  CornerDownLeft
} from 'lucide-react';
import { Deck, Flashcard } from '../types/flashcard';
import { speechService } from '../utils/speech';
import { useModalA11y } from '../hooks/useModalA11y';
import { useToast } from '../context/ToastContext';

interface DeckEditorModalProps {
  isOpen: boolean;
  onClose: () => void;
  deckToEdit?: Deck | null;
  onSave: (deck: Deck) => void;
}

export const DeckEditorModal: React.FC<DeckEditorModalProps> = ({
  isOpen,
  onClose,
  deckToEdit,
  onSave,
}) => {
  useModalA11y({ isOpen, onClose });
  const { showToast } = useToast();

  if (!isOpen) return null;

  const [title, setTitle] = useState(deckToEdit?.title || '');
  const [description, setDescription] = useState(deckToEdit?.description || '');
  const [language, setLanguage] = useState(deckToEdit?.language || 'en-US');
  const [category, setCategory] = useState(deckToEdit?.category || 'General');
  const [color, setColor] = useState(deckToEdit?.color || '#ff2a6d');
  const [cards, setCards] = useState<Flashcard[]>(
    deckToEdit?.cards || [
      {
        id: `card-${Date.now()}-1`,
        term: '',
        phonetic: '',
        partOfSpeech: '',
        definition: '',
        example: '',
        exampleTranslation: '',
        grammarPattern: '',
        notes: '',
        tags: [],
        starred: false,
        repetition: 0,
        interval: 1,
        easeFactor: 2.5,
        dueDate: new Date().toISOString(),
        reviewCount: 0,
        lapses: 0,
      },
    ]
  );

  const handleAddEmptyCard = () => {
    const newCard: Flashcard = {
      id: `card-${Date.now()}-${cards.length + 1}`,
      term: '',
      phonetic: '',
      partOfSpeech: '',
      definition: '',
      example: '',
      exampleTranslation: '',
      grammarPattern: '',
      notes: '',
      tags: [],
      starred: false,
      repetition: 0,
      interval: 1,
      easeFactor: 2.5,
      dueDate: new Date().toISOString(),
      reviewCount: 0,
      lapses: 0,
    };
    setCards((prev) => [...prev, newCard]);
  };

  const handleDuplicateCard = (index: number) => {
    const target = cards[index];
    const duplicated: Flashcard = {
      ...target,
      id: `card-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
    };
    const next = [...cards];
    next.splice(index + 1, 0, duplicated);
    setCards(next);
  };

  const handleRemoveCard = (index: number) => {
    if (cards.length <= 1) return;
    setCards(cards.filter((_, i) => i !== index));
  };

  const handleCardChange = (index: number, field: keyof Flashcard, value: any) => {
    const updated = [...cards];
    updated[index] = { ...updated[index], [field]: value };
    setCards(updated);
  };

  // Shortcut Cmd+Enter to add new card
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
        e.preventDefault();
        handleAddEmptyCard();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [cards.length]);

  const handleSaveDeck = () => {
    if (!title.trim()) {
      showToast('Please enter a deck title.', 'warning');
      return;
    }

    const validCards = cards.filter((c) => c.term.trim() || c.definition.trim());
    if (validCards.length === 0) {
      showToast('Please enter at least one card with a term or definition.', 'warning');
      return;
    }

    const savedDeck: Deck = {
      id: deckToEdit?.id || `deck-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
      title: title.trim(),
      description: description.trim(),
      language,
      targetLanguage: 'vi-VN',
      category: category.trim(),
      tags: deckToEdit?.tags || ['Custom'],
      color,
      createdAt: deckToEdit?.createdAt || new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      cards: validCards,
    };

    onSave(savedDeck);
    showToast(`Deck "${savedDeck.title}" saved successfully!`, 'success');
    onClose();
  };

  return (
    <div 
      className="modal-overlay" 
      onClick={onClose}
      role="dialog"
      aria-modal="true"
      aria-labelledby="studio-header-title"
    >
      <div className="modal-content studio-modal-content" onClick={(e) => e.stopPropagation()}>
        {/* Studio Top Header */}
        <div className="studio-modal-header">
          <h2 id="studio-header-title">
            <Layers size={22} color="var(--primary)" />
            <span>{deckToEdit ? 'Deck Studio — Edit Deck' : 'Deck Studio — Create New Deck'}</span>
          </h2>
          <button className="btn-icon" onClick={onClose} title="Close Studio" aria-label="Close Studio">
            <X size={20} />
          </button>
        </div>

        {/* Studio Scrollable Workspace */}
        <div className="studio-modal-body">
          {/* Deck Metadata Overview */}
          <div className="studio-meta-box">
            <div className="studio-meta-top-grid">
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">
                  <BookOpen size={14} style={{ display: 'inline', marginRight: 6 }} />
                  Deck Title *
                </label>
                <input 
                  className="form-input" 
                  placeholder="e.g. Oxford 3000 C1-C2 Vocabulary..." 
                  value={title} 
                  onChange={(e) => setTitle(e.target.value)} 
                />
              </div>

              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">
                  <Languages size={14} style={{ display: 'inline', marginRight: 6 }} />
                  Target Language
                </label>
                <select 
                  className="form-select" 
                  value={language} 
                  onChange={(e) => setLanguage(e.target.value)}
                >
                  <option value="en-US">English (US)</option>
                  <option value="en-GB">English (UK)</option>
                  <option value="ja-JP">Japanese</option>
                  <option value="zh-CN">Chinese (Mandarin)</option>
                  <option value="ko-KR">Korean</option>
                  <option value="fr-FR">French</option>
                  <option value="de-DE">German</option>
                  <option value="es-ES">Spanish</option>
                </select>
              </div>

              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">
                  <Palette size={14} style={{ display: 'inline', marginRight: 6 }} />
                  Color Accent
                </label>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginTop: 4 }}>
                  {['#ff2a6d', '#ff5733', '#8b5cf6', '#06b6d4', '#10b981', '#f59e0b'].map((c) => (
                    <button
                      key={c}
                      type="button"
                      style={{
                        width: 28,
                        height: 28,
                        borderRadius: '50%',
                        background: c,
                        border: color === c ? '3px solid white' : 'none',
                        boxShadow: color === c ? `0 0 0 2px ${c}` : 'none',
                        cursor: 'pointer',
                      }}
                      onClick={() => setColor(c)}
                    />
                  ))}
                </div>
              </div>
            </div>

            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Learning Goals & Description</label>
              <textarea 
                className="form-textarea" 
                rows={2} 
                placeholder="Notes on learning objectives, CEFR level, or topics..." 
                value={description}
                onChange={(e) => setDescription(e.target.value)}
              />
            </div>
          </div>

          {/* Cards Studio Toolbar */}
          <div className="studio-cards-toolbar">
            <div className="studio-cards-count">
              <span>Vocabulary Cards</span>
              <span className="badge-correct" style={{ fontSize: '0.85rem' }}>
                {cards.length} cards
              </span>
            </div>

            <button className="btn btn-secondary btn-sm" onClick={handleAddEmptyCard}>
              <Plus size={16} />
              <span>Add Card</span>
            </button>
          </div>

          {/* Card Items List */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            {cards.map((card, idx) => (
              <div key={card.id} className="studio-card-item">
                <div className="studio-card-item-header">
                  <span className="studio-card-badge">
                    Card #{idx + 1}
                  </span>

                  <div style={{ display: 'flex', gap: 8 }}>
                    {card.term && (
                      <button 
                        type="button"
                        className="btn-icon btn-sm" 
                        onClick={() => speechService.speak(card.term, { lang: language })}
                        title="Listen to pronunciation"
                      >
                        <Volume2 size={15} />
                      </button>
                    )}
                    <button 
                      type="button"
                      className="btn-icon btn-sm" 
                      onClick={() => handleDuplicateCard(idx)}
                      title="Duplicate this card"
                    >
                      <Copy size={15} />
                    </button>
                    {cards.length > 1 && (
                      <button 
                        type="button"
                        className="btn-icon btn-sm" 
                        style={{ color: 'var(--accent-rose)' }}
                        onClick={() => handleRemoveCard(idx)}
                        title="Delete card"
                      >
                        <Trash2 size={15} />
                      </button>
                    )}
                  </div>
                </div>

                {/* Primary Card Fields: Term, Phonetic, POS */}
                <div className="studio-card-main-grid">
                  <div className="studio-field-group">
                    <label className="studio-field-label">Term / Word *</label>
                    <input 
                      className="form-input" 
                      placeholder="e.g. Serendipity, Ubiquitous..." 
                      style={{ fontWeight: 700 }}
                      value={card.term} 
                      onChange={(e) => handleCardChange(idx, 'term', e.target.value)} 
                    />
                  </div>

                  <div className="studio-field-group">
                    <label className="studio-field-label">Phonetic IPA</label>
                    <input 
                      className="form-input" 
                      placeholder="e.g. /ˈpɪv.ə.t̬əl/" 
                      style={{ fontFamily: 'var(--font-phonetic)', letterSpacing: '0.02em' }}
                      value={card.phonetic || ''} 
                      onChange={(e) => handleCardChange(idx, 'phonetic', e.target.value)} 
                    />
                  </div>

                  <div className="studio-field-group">
                    <label className="studio-field-label">Part of Speech</label>
                    <select 
                      className="form-select" 
                      value={card.partOfSpeech || ''} 
                      onChange={(e) => handleCardChange(idx, 'partOfSpeech', e.target.value)}
                    >
                      <option value="">Select Part of Speech...</option>
                      <option value="noun">noun</option>
                      <option value="verb">verb</option>
                      <option value="adjective">adjective</option>
                      <option value="adverb">adverb</option>
                      <option value="idiom">idiom</option>
                      <option value="phrasal verb">phrasal verb</option>
                      <option value="grammar structure">grammar structure</option>
                    </select>
                  </div>
                </div>

                {/* Definition Field */}
                <div className="studio-field-group">
                  <label className="studio-field-label">Definition / Meaning *</label>
                  <input 
                    className="form-input" 
                    placeholder="Clear definition or Vietnamese meaning..." 
                    value={card.definition} 
                    onChange={(e) => handleCardChange(idx, 'definition', e.target.value)} 
                  />
                </div>

                {/* Example Sentence & Translation */}
                <div className="studio-card-sub-grid">
                  <div className="studio-field-group">
                    <label className="studio-field-label">
                      <Subtitles size={13} />
                      Context Example Sentence
                    </label>
                    <input 
                      className="form-input" 
                      placeholder="Realistic sentence demonstrating usage..." 
                      value={card.example || ''} 
                      onChange={(e) => handleCardChange(idx, 'example', e.target.value)} 
                    />
                  </div>

                  <div className="studio-field-group">
                    <label className="studio-field-label">
                      <Subtitles size={13} />
                      Example Translation
                    </label>
                    <input 
                      className="form-input" 
                      placeholder="Translation of the example sentence..." 
                      value={card.exampleTranslation || ''} 
                      onChange={(e) => handleCardChange(idx, 'exampleTranslation', e.target.value)} 
                    />
                  </div>
                </div>

                {/* Grammar Pattern & Notes */}
                <div className="studio-card-sub-grid">
                  <div className="studio-field-group">
                    <label className="studio-field-label">
                      <Pin size={13} />
                      Grammar Pattern / Collocation
                    </label>
                    <input 
                      className="form-input" 
                      placeholder="e.g. play a pivotal role in sth..." 
                      value={card.grammarPattern || ''} 
                      onChange={(e) => handleCardChange(idx, 'grammarPattern', e.target.value)} 
                    />
                  </div>

                  <div className="studio-field-group">
                    <label className="studio-field-label">
                      <Lightbulb size={13} />
                      Memory Notes / Synonyms
                    </label>
                    <input 
                      className="form-input" 
                      placeholder="Helpful mnemonic, antonyms, or notes..." 
                      value={card.notes || ''} 
                      onChange={(e) => handleCardChange(idx, 'notes', e.target.value)} 
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>

          <button 
            type="button"
            className="studio-add-card-btn" 
            onClick={handleAddEmptyCard} 
          >
            <Plus size={18} />
            <span>Add Next Card</span>
            <span className="studio-add-card-kbd">⌘ Enter</span>
          </button>
        </div>

        {/* Studio Sticky Footer Bar */}
        <div className="studio-modal-footer">
          <div className="studio-footer-hint">
            <CornerDownLeft size={14} />
            <span>Pro tip: Press <strong>Cmd + Enter</strong> to add a new card instantly</span>
          </div>

          <div className="studio-footer-actions">
            <button className="btn btn-secondary" onClick={onClose}>Cancel</button>
            <button className="btn btn-primary" onClick={handleSaveDeck}>
              <Save size={18} />
              <span>Save All {cards.length} Cards</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
