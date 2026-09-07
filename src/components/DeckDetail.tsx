import React, { useState } from 'react';
import { 
  ArrowLeft, 
  Play, 
  Brain, 
  PenTool, 
  Zap, 
  FileCheck, 
  FileSpreadsheet, 
  Download, 
  Edit3, 
  Trash2, 
  Volume2, 
  Star, 
  Search, 
  Plus, 
  BookOpen,
  Calendar,
  Languages,
  Subtitles,
  Pin,
  Lightbulb
} from 'lucide-react';
import { Deck, Flashcard, StudyMode } from '../types/flashcard';
import { speechService } from '../utils/speech';
import { getDueCards } from '../utils/srs';
import { PosChip } from '../utils/posHelper';
import { ConfirmModal } from './common/ConfirmModal';
import { useToast } from '../context/ToastContext';

interface DeckDetailProps {
  deck: Deck;
  onBack: () => void;
  onStartStudy: (mode: StudyMode) => void;
  onOpenEditDeck: (deck: Deck) => void;
  onOpenImportToDeck: (deckId: string) => void;
  onOpenExportDeck: (deck: Deck) => void;
  onDeleteDeck: (deckId: string) => void;
  onUpdateCard: (card: Flashcard) => void;
  onDeleteCard: (cardId: string) => void;
}

export const DeckDetail: React.FC<DeckDetailProps> = ({
  deck,
  onBack,
  onStartStudy,
  onOpenEditDeck,
  onOpenImportToDeck,
  onOpenExportDeck,
  onDeleteDeck,
  onUpdateCard,
  onDeleteCard,
}) => {
  const { showToast } = useToast();
  const [searchQuery, setSearchQuery] = useState('');
  const [onlyStarred, setOnlyStarred] = useState(false);
  const [selectedTag, setSelectedTag] = useState<string>('all');
  const [showDeleteDeckConfirm, setShowDeleteDeckConfirm] = useState(false);
  const [cardToDelete, setCardToDelete] = useState<Flashcard | null>(null);

  const dueCards = getDueCards(deck.cards);
  const allTags = Array.from(new Set(deck.cards.flatMap((c) => c.tags || [])));

  const filteredCards = deck.cards.filter((card) => {
    const matchSearch =
      card.term.toLowerCase().includes(searchQuery.toLowerCase()) ||
      card.definition.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (card.example && card.example.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (card.notes && card.notes.toLowerCase().includes(searchQuery.toLowerCase()));

    const matchStarred = !onlyStarred || card.starred;
    const matchTag = selectedTag === 'all' || (card.tags && card.tags.includes(selectedTag));

    return matchSearch && matchStarred && matchTag;
  });

  const handleToggleStar = (card: Flashcard) => {
    onUpdateCard({ ...card, starred: !card.starred });
  };

  const handlePlayAudio = (term: string) => {
    speechService.speak(term, { lang: deck.language || 'en-US' });
  };

  return (
    <div>
      {/* Top Back & Quick Action Bar */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
        <button className="btn btn-secondary" onClick={onBack}>
          <ArrowLeft size={16} />
          <span>All Decks</span>
        </button>

        <div style={{ display: 'flex', gap: 8 }}>
          <button 
            className="btn btn-secondary"
            onClick={() => onOpenImportToDeck(deck.id)}
            title="Import Excel or CSV cards into this deck"
          >
            <FileSpreadsheet size={16} />
            <span>Import Excel/CSV</span>
          </button>

          <button 
            className="btn btn-secondary"
            onClick={() => onOpenExportDeck(deck)}
            title="Export deck to Excel (.xlsx) or CSV"
          >
            <Download size={16} />
            <span>Export</span>
          </button>

          <button 
            className="btn btn-secondary"
            onClick={() => onOpenEditDeck(deck)}
            title="Edit deck metadata and cards in Studio"
          >
            <Edit3 size={16} />
            <span>Edit Deck</span>
          </button>

          <button 
            className="btn-icon"
            style={{ color: 'var(--accent-rose)' }}
            onClick={() => setShowDeleteDeckConfirm(true)}
            title="Delete deck"
            aria-label={`Delete deck ${deck.title}`}
          >
            <Trash2 size={16} />
          </button>
        </div>
      </div>

      {/* Deck Overview Header */}
      <div className="deck-detail-header">
        <div className="deck-detail-top">
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
              <span className="tag-badge" style={{ background: 'var(--primary-bg)', color: 'var(--primary)' }}>
                {deck.category || 'General'}
              </span>
              <span className="tag-badge" style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                <Languages size={13} />
                <span>{deck.language === 'en-US' ? 'English (US)' : deck.language === 'en-GB' ? 'English (UK)' : deck.language}</span>
              </span>
            </div>
            <h1 className="deck-detail-title">{deck.title}</h1>
            <p className="deck-detail-desc">{deck.description || 'No description provided.'}</p>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 8 }}>
            <div style={{ fontSize: '1.8rem', fontWeight: 800, color: 'var(--primary)' }}>
              {deck.cards.length} <span style={{ fontSize: '1rem', fontWeight: 500, color: 'var(--text-muted)' }}>cards</span>
            </div>
            {dueCards.length > 0 && (
              <span className="stat-due" style={{ fontSize: '0.85rem' }}>
                <Calendar size={14} style={{ display: 'inline', marginRight: 4, verticalAlign: 'middle' }} />
                {dueCards.length} cards due for review today
              </span>
            )}
          </div>
        </div>

        {/* 5 Study Modes Banner */}
        <h3 style={{ fontSize: '1.05rem', margin: '24px 0 12px' }}>
          Select Active Study Mode
        </h3>
        <div className="study-modes-grid">
          <div className="study-mode-card" onClick={() => onStartStudy('flashcards')}>
            <div className="study-mode-icon" style={{ background: 'linear-gradient(135deg, #6366f1 0%, #4338ca 100%)' }}>
              <Play size={20} />
            </div>
            <div>
              <div className="study-mode-name">3D Flip Flashcards</div>
              <div className="study-mode-desc">Tactile 3D card flips with native pronunciation audio and phonetic transcription.</div>
            </div>
          </div>

          <div className="study-mode-card" onClick={() => onStartStudy('srs')}>
            <div className="study-mode-icon" style={{ background: 'linear-gradient(135deg, #06b6d4 0%, #0284c7 100%)' }}>
              <Brain size={20} />
            </div>
            <div>
              <div className="study-mode-name">Spaced Repetition (SM-2)</div>
              <div className="study-mode-desc">SuperMemo SM-2 algorithm predicting optimal review intervals for long-term retention.</div>
            </div>
          </div>

          <div className="study-mode-card" onClick={() => onStartStudy('write')}>
            <div className="study-mode-icon" style={{ background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)' }}>
              <PenTool size={20} />
            </div>
            <div>
              <div className="study-mode-name">Write & Spelling Quiz</div>
              <div className="study-mode-desc">Fill in words from contextual examples and train typing recall precision.</div>
            </div>
          </div>

          <div className="study-mode-card" onClick={() => onStartStudy('match')}>
            <div className="study-mode-icon" style={{ background: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)' }}>
              <Zap size={20} />
            </div>
            <div>
              <div className="study-mode-name">Speed Match Game</div>
              <div className="study-mode-desc">High-speed tile matching against the clock to connect terms and definitions.</div>
            </div>
          </div>

          <div className="study-mode-card" onClick={() => onStartStudy('test')}>
            <div className="study-mode-icon" style={{ background: 'linear-gradient(135deg, #ec4899 0%, #be185d 100%)' }}>
              <FileCheck size={20} />
            </div>
            <div>
              <div className="study-mode-name">Comprehensive Test</div>
              <div className="study-mode-desc">Multiple-choice & True/False exam simulations with instant grading.</div>
            </div>
          </div>
        </div>
      </div>

      {/* Cards List Section */}
      <div className="cards-list-section">
        <div className="cards-list-header">
          <h2 style={{ fontSize: '1.3rem' }}>
            Vocabulary & Cards ({filteredCards.length}/{deck.cards.length})
          </h2>

          <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
            <div className="search-box" style={{ minWidth: 220, maxWidth: 300 }}>
              <Search size={16} />
              <input 
                className="form-input" 
                placeholder="Search terms, definitions, examples..." 
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>

            <button 
              className={`btn btn-secondary ${onlyStarred ? 'btn-primary' : ''}`}
              onClick={() => setOnlyStarred(!onlyStarred)}
              style={{ fontSize: '0.85rem', padding: '8px 12px' }}
            >
              <Star size={16} fill={onlyStarred ? 'currentColor' : 'none'} />
              <span>Starred Only</span>
            </button>
          </div>
        </div>

        {/* Tags filter if any */}
        {allTags.length > 0 && (
          <div className="filter-pills" style={{ marginBottom: 16 }}>
            <button 
              className={`filter-pill ${selectedTag === 'all' ? 'active' : ''}`}
              onClick={() => setSelectedTag('all')}
            >
              All Tags ({deck.cards.length})
            </button>
            {allTags.map((tag) => (
              <button 
                key={tag}
                className={`filter-pill ${selectedTag === tag ? 'active' : ''}`}
                onClick={() => setSelectedTag(tag)}
              >
                #{tag}
              </button>
            ))}
          </div>
        )}

        {/* Cards Table */}
        <div className="cards-table">
          {filteredCards.map((card) => (
            <div key={card.id} className="card-item-row">
              {/* Front Col */}
              <div className="card-item-front">
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <span className="card-item-term">{card.term}</span>
                  <button 
                    className="btn-icon" 
                    style={{ width: 28, height: 28 }}
                    onClick={() => handlePlayAudio(card.term)}
                    title="Play pronunciation"
                  >
                    <Volume2 size={16} color="var(--primary)" />
                  </button>
                </div>
                {card.phonetic && (
                  <span className="phonetic-text" style={{ fontSize: '0.98rem' }}>
                    {card.phonetic.startsWith('/') ? card.phonetic : `/${card.phonetic}/`}
                  </span>
                )}
                {card.partOfSpeech && (
                  <div>
                    <PosChip pos={card.partOfSpeech} />
                  </div>
                )}
              </div>

              {/* Back Col */}
              <div className="card-item-back">
                <div className="card-item-def">{card.definition}</div>
                {card.example && (
                  <div className="card-item-example">
                    <div>"{card.example}"</div>
                    {card.exampleTranslation && (
                      <div className="card-item-example-trans" style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                        <Subtitles size={12} color="var(--primary)" />
                        <span>{card.exampleTranslation}</span>
                      </div>
                    )}
                  </div>
                )}
                {card.grammarPattern && (
                  <div className="card-item-grammar" style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                    <Pin size={12} color="var(--accent-cyan)" />
                    <span>{card.grammarPattern}</span>
                  </div>
                )}
                {card.notes && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: '0.82rem', color: 'var(--accent-amber)' }}>
                    <Lightbulb size={12} />
                    <span>{card.notes}</span>
                  </div>
                )}
              </div>

              {/* Actions */}
              <div className="card-item-actions">
                <button 
                  className="btn-icon" 
                  onClick={() => handleToggleStar(card)}
                  title="Toggle star"
                >
                  <Star 
                    size={18} 
                    fill={card.starred ? 'var(--accent-amber)' : 'none'} 
                    color={card.starred ? 'var(--accent-amber)' : 'var(--text-muted)'} 
                  />
                </button>
                <button 
                  className="btn-icon"
                  style={{ color: 'var(--accent-rose)' }}
                  onClick={() => setCardToDelete(card)}
                  title="Delete card"
                  aria-label={`Delete card ${card.term}`}
                >
                  <Trash2 size={16} />
                </button>
              </div>
            </div>
          ))}

          {filteredCards.length === 0 && (
            <div style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--text-secondary)' }}>
              <BookOpen size={36} style={{ margin: '0 auto 12px', opacity: 0.5 }} />
              <p>No flashcards found matching your search filter.</p>
            </div>
          )}
        </div>
      </div>

      {/* Confirm Modals */}
      <ConfirmModal 
        isOpen={showDeleteDeckConfirm}
        title="Delete Deck"
        message={`Are you sure you want to delete "${deck.title}" and all its ${deck.cards.length} cards? This action cannot be undone.`}
        confirmText="Delete Deck"
        cancelText="Keep Deck"
        isDanger={true}
        onConfirm={() => {
          onDeleteDeck(deck.id);
          showToast(`Deleted deck "${deck.title}"`, 'info');
        }}
        onCancel={() => setShowDeleteDeckConfirm(false)}
      />

      {cardToDelete && (
        <ConfirmModal 
          isOpen={!!cardToDelete}
          title="Delete Flashcard"
          message={`Delete card "${cardToDelete.term}"?`}
          confirmText="Delete"
          cancelText="Cancel"
          isDanger={true}
          onConfirm={() => {
            onDeleteCard(cardToDelete.id);
            showToast(`Deleted card "${cardToDelete.term}"`, 'info');
            setCardToDelete(null);
          }}
          onCancel={() => setCardToDelete(null)}
        />
      )}
    </div>
  );
};
