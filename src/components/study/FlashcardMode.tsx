import React, { useState, useEffect, useCallback } from 'react';
import { 
  ArrowLeft, 
  ArrowRight, 
  Volume2, 
  Star, 
  Shuffle, 
  Repeat, 
  Layers,
  Pin,
  Subtitles,
  Lightbulb
} from 'lucide-react';
import confetti from 'canvas-confetti';
import { Flashcard, Deck } from '../../types/flashcard';
import { speechService } from '../../utils/speech';
import { PosChip } from '../../utils/posHelper';
import { StudyHeader } from './StudyHeader';

interface FlashcardModeProps {
  deck: Deck;
  onBackToDeck: () => void;
  onUpdateCard: (card: Flashcard) => void;
}

export const FlashcardMode: React.FC<FlashcardModeProps> = ({
  deck,
  onBackToDeck,
  onUpdateCard,
}) => {
  const [cards, setCards] = useState<Flashcard[]>(deck.cards);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isFlipped, setIsFlipped] = useState(false);
  const [showDefinitionFirst, setShowDefinitionFirst] = useState(false);
  const [isAutoPlayAudio, setIsAutoPlayAudio] = useState(true);

  const currentCard = cards[currentIndex];

  const handleFlip = useCallback(() => {
    setIsFlipped((prev) => !prev);
  }, []);

  const handleNext = useCallback(() => {
    setIsFlipped(false);
    if (currentIndex < cards.length - 1) {
      setCurrentIndex((prev) => prev + 1);
    } else {
      confetti({ particleCount: 80, spread: 70, origin: { y: 0.6 } });
    }
  }, [currentIndex, cards.length]);

  const handlePrev = useCallback(() => {
    setIsFlipped(false);
    if (currentIndex > 0) {
      setCurrentIndex((prev) => prev - 1);
    }
  }, [currentIndex]);

  const handleShuffle = () => {
    const shuffled = [...cards].sort(() => Math.random() - 0.5);
    setCards(shuffled);
    setCurrentIndex(0);
    setIsFlipped(false);
  };

  const handleToggleStar = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (!currentCard) return;
    const updated = { ...currentCard, starred: !currentCard.starred };
    const newCards = [...cards];
    newCards[currentIndex] = updated;
    setCards(newCards);
    onUpdateCard(updated);
  };

  const handlePlayAudio = (e?: React.MouseEvent, text?: string) => {
    if (e) e.stopPropagation();
    const textToSpeak = text || currentCard?.term;
    if (textToSpeak) {
      speechService.speak(textToSpeak, { lang: deck.language || 'en-US' });
    }
  };

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;

      if (e.code === 'Space') {
        e.preventDefault();
        handleFlip();
      } else if (e.code === 'ArrowRight' || e.code === 'KeyD') {
        e.preventDefault();
        handleNext();
      } else if (e.code === 'ArrowLeft' || e.code === 'KeyA') {
        e.preventDefault();
        handlePrev();
      } else if (e.code === 'KeyR') {
        e.preventDefault();
        handlePlayAudio();
      } else if (e.code === 'KeyS') {
        e.preventDefault();
        if (currentCard) {
          const updated = { ...currentCard, starred: !currentCard.starred };
          const newCards = [...cards];
          newCards[currentIndex] = updated;
          setCards(newCards);
          onUpdateCard(updated);
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [handleFlip, handleNext, handlePrev, currentCard, cards, currentIndex, onUpdateCard]);

  useEffect(() => {
    if (isAutoPlayAudio && currentCard && !showDefinitionFirst) {
      handlePlayAudio(undefined, currentCard.term);
    }
  }, [currentIndex, isAutoPlayAudio, showDefinitionFirst]);

  if (!currentCard) {
    return (
      <div className="study-container">
        <div className="write-quiz-card" style={{ textAlign: 'center' }}>
          <h2>This deck contains no flashcards yet.</h2>
          <button className="btn btn-primary" onClick={onBackToDeck} style={{ marginTop: 16 }}>
            Back to Deck
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="study-container">
      {/* Unified Study Header */}
      <StudyHeader
        deckTitle={deck.title}
        modeName="Flashcard Player"
        modeIcon={Layers}
        currentIndex={currentIndex}
        totalCards={cards.length}
        onExit={onBackToDeck}
        accentColor="var(--primary)"
      />

      {/* Auxiliary Study Quick Controls Bar */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 8, marginTop: -10 }}>
        <button 
          className={`btn btn-sm ${isAutoPlayAudio ? 'btn-primary' : 'btn-secondary'}`}
          onClick={() => setIsAutoPlayAudio(!isAutoPlayAudio)}
          title={isAutoPlayAudio ? 'Autoplay audio: ON' : 'Autoplay audio: OFF'}
        >
          <Volume2 size={15} />
          <span>Autoplay</span>
        </button>
        <button 
          className="btn btn-secondary btn-sm"
          onClick={() => setShowDefinitionFirst(!showDefinitionFirst)}
          title={showDefinitionFirst ? 'Showing Definition first' : 'Showing Term first'}
        >
          <Repeat size={15} />
          <span>{showDefinitionFirst ? 'Term First' : 'Def First'}</span>
        </button>
        <button className="btn btn-secondary btn-sm" onClick={handleShuffle} title="Shuffle deck cards">
          <Shuffle size={15} />
          <span>Shuffle</span>
        </button>
      </div>

      {/* 3D Flip Flashcard */}
      <div className="flashcard-stage" onClick={handleFlip}>
        <div className={`flashcard-inner ${isFlipped ? 'is-flipped' : ''}`}>
          
          {/* Card Face: FRONT */}
          <div className="card-face card-face-front">
            <div className="card-face-header">
              <div>
                <PosChip pos={currentCard.partOfSpeech || 'General'} />
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <button 
                  className="btn-icon" 
                  onClick={(e) => handlePlayAudio(e, currentCard.term)} 
                  title="Listen pronunciation"
                >
                  <Volume2 size={18} color="var(--primary)" />
                </button>
                <button 
                  className="btn-icon" 
                  onClick={handleToggleStar}
                  title="Star this card"
                >
                  <Star 
                    size={18} 
                    fill={currentCard.starred ? 'var(--accent-amber)' : 'none'} 
                    color={currentCard.starred ? 'var(--accent-amber)' : 'var(--text-muted)'} 
                  />
                </button>
              </div>
            </div>

            <div className="card-face-center">
              {!showDefinitionFirst ? (
                <>
                  <div className="card-main-term">{currentCard.term}</div>
                  {currentCard.phonetic && (
                    <div className="card-phonetic-pill">
                      <span className="card-phonetic-lg">
                        {currentCard.phonetic.startsWith('/') ? currentCard.phonetic : `/${currentCard.phonetic}/`}
                      </span>
                    </div>
                  )}
                  {currentCard.grammarPattern && (
                    <div className="card-grammar-box" style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                      <Pin size={13} color="var(--accent-cyan)" />
                      <span>{currentCard.grammarPattern}</span>
                    </div>
                  )}
                </>
              ) : (
                <div className="card-definition-lg">{currentCard.definition}</div>
              )}
            </div>

            <div className="card-face-footer">
              <span>Click or press <kbd className="kbd-badge">Space</kbd> to flip</span>
              <span>{deck.title}</span>
            </div>
          </div>

          {/* Card Face: BACK */}
          <div className="card-face card-face-back">
            <div className="card-face-header">
              <span className="tag-badge" style={{ background: 'var(--primary-bg)', color: 'var(--primary)' }}>
                {showDefinitionFirst ? 'Term & Phonetics' : 'Definition'}
              </span>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <button 
                  className="btn-icon" 
                  onClick={(e) => handlePlayAudio(e, currentCard.term)} 
                  title="Listen pronunciation"
                >
                  <Volume2 size={18} color="var(--primary)" />
                </button>
                <button 
                  className="btn-icon" 
                  onClick={handleToggleStar}
                  title="Star this card"
                >
                  <Star 
                    size={18} 
                    fill={currentCard.starred ? 'var(--accent-amber)' : 'none'} 
                    color={currentCard.starred ? 'var(--accent-amber)' : 'var(--text-muted)'} 
                  />
                </button>
              </div>
            </div>

            <div className="card-face-center">
              {showDefinitionFirst ? (
                <>
                  <div className="card-main-term">{currentCard.term}</div>
                  {currentCard.phonetic && (
                    <div className="card-phonetic-pill">
                      <span className="card-phonetic-lg">
                        {currentCard.phonetic.startsWith('/') ? currentCard.phonetic : `/${currentCard.phonetic}/`}
                      </span>
                    </div>
                  )}
                </>
              ) : (
                <div className="card-definition-lg">{currentCard.definition}</div>
              )}

              {/* Example & Example Translation */}
              {currentCard.example && (
                <div className="card-example-box" onClick={(e) => e.stopPropagation()}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <div className="card-example-text">{currentCard.example}</div>
                    <button 
                      className="btn-icon" 
                      style={{ width: 26, height: 26 }} 
                      onClick={() => handlePlayAudio(undefined, currentCard.example)}
                      title="Listen full example sentence"
                    >
                      <Volume2 size={14} />
                    </button>
                  </div>
                  {currentCard.exampleTranslation && (
                    <div className="card-example-trans" style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <Subtitles size={13} color="var(--primary)" />
                      <span>{currentCard.exampleTranslation}</span>
                    </div>
                  )}
                </div>
              )}

              {currentCard.notes && (
                <div className="card-notes-box" style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <Lightbulb size={13} color="var(--accent-amber)" />
                  <span>{currentCard.notes}</span>
                </div>
              )}
            </div>

            <div className="card-face-footer">
              <span>Click or press <kbd className="kbd-badge">Space</kbd> to flip back</span>
              <span>SRS Ease: {currentCard.easeFactor}x</span>
            </div>
          </div>

        </div>
      </div>

      {/* Navigation Controls & Keyboard legend */}
      <div className="flashcard-controls">
        <button 
          className="btn btn-secondary" 
          onClick={handlePrev} 
          disabled={currentIndex === 0}
          style={{ minWidth: 120 }}
        >
          <ArrowLeft size={18} />
          <span>Previous</span>
        </button>

        <div className="keyboard-hints">
          <span>Shortcuts:</span>
          <span><kbd className="kbd-badge">Space</kbd> Flip</span>
          <span><kbd className="kbd-badge">←</kbd> <kbd className="kbd-badge">→</kbd> Navigate</span>
          <span><kbd className="kbd-badge">R</kbd> Audio</span>
          <span><kbd className="kbd-badge">S</kbd> Star</span>
        </div>

        <button 
          className="btn btn-primary" 
          onClick={handleNext}
          disabled={currentIndex === cards.length - 1}
          style={{ minWidth: 120 }}
        >
          <span>Next</span>
          <ArrowRight size={18} />
        </button>
      </div>
    </div>
  );
};
