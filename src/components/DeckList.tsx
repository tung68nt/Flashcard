import React, { useState } from 'react';
import { 
  Plus, 
  FileSpreadsheet, 
  Search, 
  BookOpen, 
  Calendar, 
  Sparkles, 
  Brain, 
  CheckCircle2, 
  ArrowRight,
  Download
} from 'lucide-react';
import { Deck } from '../types/flashcard';
import { getDueCards } from '../utils/srs';

interface DeckListProps {
  decks: Deck[];
  onSelectDeck: (deckId: string) => void;
  onOpenNewDeck: () => void;
  onOpenImport: () => void;
  onOpenExportDeck: (deck: Deck) => void;
}

export const DeckList: React.FC<DeckListProps> = ({
  decks,
  onSelectDeck,
  onOpenNewDeck,
  onOpenImport,
  onOpenExportDeck,
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');

  const categories = Array.from(new Set(decks.map((d) => d.category || 'General')));

  const filteredDecks = decks.filter((d) => {
    const matchSearch =
      d.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      d.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
      d.tags.some((t) => t.toLowerCase().includes(searchQuery.toLowerCase())) ||
      d.cards.some((c) => c.term.toLowerCase().includes(searchQuery.toLowerCase()));

    const matchCategory = selectedCategory === 'all' || d.category === selectedCategory;

    return matchSearch && matchCategory;
  });

  const totalCardsAllDecks = decks.reduce((acc, d) => acc + d.cards.length, 0);
  const totalDueToday = decks.reduce((acc, d) => acc + getDueCards(d.cards).length, 0);

  return (
    <div>
      {/* Hero Banner */}
      <div className="hero-banner">
        <div className="hero-text">
          <h1>Intelligent Flashcards & Spaced Repetition Engine</h1>
          <p>
            The premier alternative to Quizlet: High-performance <strong>Excel (.xlsx) & CSV bulk import</strong>, 
            scientifically proven <strong>SuperMemo SM-2 Spaced Repetition</strong>, local-first privacy, and seamless <strong>Supabase Cloud Sync</strong>.
          </p>
          <div className="hero-features">
            <span className="hero-chip"><FileSpreadsheet size={15} color="var(--primary)" /> High-Speed Excel/CSV Engine</span>
            <span className="hero-chip"><Brain size={15} color="var(--accent-cyan)" /> SuperMemo SM-2 Adaptive Algorithm</span>
            <span className="hero-chip"><Sparkles size={15} color="var(--accent-emerald)" /> Supabase Cloud Realtime Sync</span>
            <span className="hero-chip"><CheckCircle2 size={15} color="var(--accent-amber)" /> 5 Active Mastery Modes</span>
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, minWidth: 200 }}>
          <button 
            className="btn btn-primary" 
            onClick={onOpenImport}
            style={{ padding: '14px 20px', fontSize: '1rem' }}
          >
            <FileSpreadsheet size={20} />
            <span>Import Excel / CSV</span>
          </button>
          <button 
            className="btn btn-secondary" 
            onClick={onOpenNewDeck}
            style={{ padding: '12px 20px', fontSize: '0.95rem' }}
          >
            <Plus size={18} />
            <span>Create New Deck</span>
          </button>
        </div>
      </div>

      {/* Filter & Search Bar */}
      <div className="filter-bar">
        <div className="search-box">
          <Search size={18} />
          <input 
            className="form-input" 
            placeholder="Search decks, vocabulary, tags, or definitions..." 
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        <div className="filter-pills">
          <button 
            className={`filter-pill ${selectedCategory === 'all' ? 'active' : ''}`}
            onClick={() => setSelectedCategory('all')}
          >
            All Decks ({decks.length})
          </button>
          {categories.map((cat) => (
            <button 
              key={cat}
              className={`filter-pill ${selectedCategory === cat ? 'active' : ''}`}
              onClick={() => setSelectedCategory(cat)}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      {/* Overview Stats Bar */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        gap: 20,
        marginBottom: 24,
        fontSize: '0.9rem',
        color: 'var(--text-secondary)'
      }}>
        <span>Total Library: <strong>{decks.length}</strong> decks (<strong>{totalCardsAllDecks}</strong> cards)</span>
        {totalDueToday > 0 && (
          <span className="stat-due">
            <Calendar size={14} style={{ display: 'inline', marginRight: 4, verticalAlign: 'middle' }} />
            {totalDueToday} cards due for review today
          </span>
        )}
      </div>

      {/* Decks Grid */}
      <div className="deck-grid">
        {filteredDecks.map((deck) => {
          const dueInDeck = getDueCards(deck.cards).length;
          return (
            <div 
              key={deck.id} 
              className="deck-card"
              onClick={() => onSelectDeck(deck.id)}
            >
              <div className="deck-card-header">
                <span className="tag-badge" style={{ background: 'var(--primary-bg)', color: 'var(--primary)' }}>
                  {deck.category || 'General'}
                </span>
                <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                  {deck.language}
                </span>
              </div>

              <h2 className="deck-card-title">{deck.title}</h2>
              <p className="deck-card-desc">{deck.description || 'No description provided.'}</p>

              {deck.tags && deck.tags.length > 0 && (
                <div className="deck-card-tags">
                  {deck.tags.slice(0, 4).map((tag) => (
                    <span key={tag} className="tag-badge">#{tag}</span>
                  ))}
                </div>
              )}

              <div className="deck-card-footer">
                <div className="deck-card-stats">
                  <span className="stat-item">
                    <BookOpen size={15} />
                    <span>{deck.cards.length} cards</span>
                  </span>
                  {dueInDeck > 0 && (
                    <span className="stat-item stat-due">
                      <Calendar size={14} />
                      <span>{dueInDeck} due</span>
                    </span>
                  )}
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <button 
                    className="btn-icon" 
                    style={{ width: 30, height: 30 }}
                    onClick={(e) => {
                      e.stopPropagation();
                      onOpenExportDeck(deck);
                    }}
                    title="Export to Excel / CSV"
                  >
                    <Download size={14} />
                  </button>
                  <button 
                    className="btn btn-primary" 
                    style={{ padding: '6px 12px', fontSize: '0.82rem' }}
                    onClick={(e) => {
                      e.stopPropagation();
                      onSelectDeck(deck.id);
                    }}
                  >
                    <span>Study Now</span>
                    <ArrowRight size={14} />
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
