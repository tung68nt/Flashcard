import React, { useState, useEffect } from 'react';
import { 
  Brain, 
  Volume2, 
  CheckCircle2, 
  Subtitles, 
  Pin, 
  Lightbulb, 
  RotateCcw 
} from 'lucide-react';
import confetti from 'canvas-confetti';
import { Flashcard, Deck, SRSRating } from '../../types/flashcard';
import { calculateSRS, getDueCards } from '../../utils/srs';
import { speechService } from '../../utils/speech';
import { PosChip } from '../../utils/posHelper';
import { StudyHeader } from './StudyHeader';
import { StudyResultView, ReviewCardItem } from './StudyResultView';

interface SRSLearnModeProps {
  deck: Deck;
  onBackToDeck: () => void;
  onUpdateCard: (card: Flashcard) => void;
}

export const SRSLearnMode: React.FC<SRSLearnModeProps> = ({
  deck,
  onBackToDeck,
  onUpdateCard,
}) => {
  const initialDueCards = getDueCards(deck.cards);
  const [queue, setQueue] = useState<Flashcard[]>(
    initialDueCards.length > 0 ? initialDueCards : deck.cards
  );
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isAnswerRevealed, setIsAnswerRevealed] = useState(false);
  const [reviewedCount, setReviewedCount] = useState(0);
  const [goodCount, setGoodCount] = useState(0);
  const [sessionCompleted, setSessionCompleted] = useState(false);

  const currentCard = queue[currentIndex];

  const handleRate = (rating: SRSRating) => {
    if (!currentCard) return;

    const srsUpdates = calculateSRS(currentCard, rating);
    const updatedCard: Flashcard = {
      ...currentCard,
      ...srsUpdates,
    };

    onUpdateCard(updatedCard);
    setReviewedCount((prev) => prev + 1);
    if (rating >= 3) {
      setGoodCount((prev) => prev + 1);
    }

    let newQueue = [...queue];
    if (rating === 1) {
      newQueue.push(updatedCard);
    }

    if (currentIndex + 1 < newQueue.length) {
      setQueue(newQueue);
      setCurrentIndex((prev) => prev + 1);
      setIsAnswerRevealed(false);
    } else {
      setSessionCompleted(true);
      confetti({ particleCount: 100, spread: 80, origin: { y: 0.6 } });
    }
  };

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;

      if (e.code === 'Space') {
        e.preventDefault();
        setIsAnswerRevealed((prev) => !prev);
      } else if (isAnswerRevealed) {
        if (e.key === '1') handleRate(1);
        else if (e.key === '2') handleRate(2);
        else if (e.key === '3') handleRate(3);
        else if (e.key === '4') handleRate(4);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isAnswerRevealed, currentCard, queue, currentIndex]);

  if (sessionCompleted) {
    const percent = reviewedCount > 0 ? Math.round((goodCount / reviewedCount) * 100) : 100;
    const reviewItems: ReviewCardItem[] = queue.slice(0, 15).map((c) => ({
      id: c.id,
      term: c.term,
      phonetic: c.phonetic,
      definition: c.definition,
      correctAnswer: c.definition,
      isCorrect: (c.repetition || 0) > 0,
      example: c.example,
    }));

    return (
      <StudyResultView
        title="SRS Review Session Completed"
        subtitle={`You completed a spaced repetition session reviewing ${reviewedCount} cards using the SM-2 algorithm.`}
        score={goodCount}
        total={reviewedCount}
        percentage={percent}
        reviewItems={reviewItems}
        language={deck.language}
        restartLabel="Review All Cards Again"
        onRestart={() => {
          setQueue(deck.cards);
          setCurrentIndex(0);
          setIsAnswerRevealed(false);
          setSessionCompleted(false);
          setReviewedCount(0);
          setGoodCount(0);
        }}
        onExit={onBackToDeck}
      />
    );
  }

  if (!currentCard) {
    return null;
  }

  const estAgain = '1 day';
  const estHard = `${Math.max(2, Math.round(currentCard.interval * 1.2))} days`;
  const estGood = `${Math.max(3, Math.round(currentCard.interval * currentCard.easeFactor))} days`;
  const estEasy = `${Math.max(5, Math.round(currentCard.interval * currentCard.easeFactor * 1.3))} days`;

  return (
    <div className="study-container">
      {/* Unified Study Header */}
      <StudyHeader
        deckTitle={deck.title}
        modeName="Spaced Repetition (SRS)"
        modeIcon={Brain}
        currentIndex={currentIndex}
        totalCards={queue.length}
        onExit={onBackToDeck}
        accentColor="var(--purple-vivid)"
      />

      {/* SRS Study Card */}
      <div className="write-quiz-card" style={{ minHeight: 400, justifyContent: 'space-between' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
            <PosChip pos={currentCard.partOfSpeech || 'General'} />
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
                Reviewed: {currentCard.reviewCount || 0} times
              </span>
              <button 
                className="btn-icon" 
                onClick={() => speechService.speak(currentCard.term, { lang: deck.language || 'en-US' })}
                title="Pronounce"
              >
                <Volume2 size={18} color="var(--primary)" />
              </button>
            </div>
          </div>

          <div style={{ textAlign: 'center', padding: '16px 0' }}>
            <h1 style={{ fontSize: '2.8rem', fontWeight: 800, marginBottom: 12, color: 'var(--text-primary)', letterSpacing: '-0.03em' }}>
              {currentCard.term}
            </h1>
            {currentCard.phonetic && (
              <div className="card-phonetic-pill">
                <span className="card-phonetic-lg">
                  {currentCard.phonetic.startsWith('/') ? currentCard.phonetic : `/${currentCard.phonetic}/`}
                </span>
              </div>
            )}
            {currentCard.grammarPattern && (
              <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, marginTop: 12, color: 'var(--accent-cyan)', fontWeight: 700 }}>
                <Pin size={14} />
                <span>{currentCard.grammarPattern}</span>
              </div>
            )}
          </div>
        </div>

        {/* Revealed Answer Section */}
        {isAnswerRevealed ? (
          <div style={{ animation: 'fadeIn 0.25s ease-out' }}>
            <div style={{
              background: 'var(--bg-tertiary)',
              borderRadius: 'var(--radius-lg)',
              padding: '20px 24px',
              border: '1px solid var(--border-medium)',
              marginBottom: 20,
            }}>
              <h3 style={{ fontSize: '1.45rem', color: 'var(--text-primary)', marginBottom: 10, fontWeight: 800 }}>
                {currentCard.definition}
              </h3>
              {currentCard.example && (
                <div style={{ marginTop: 8, fontSize: '0.95rem', color: 'var(--text-secondary)' }}>
                  <div style={{ fontStyle: 'italic' }}>"{currentCard.example}"</div>
                  {currentCard.exampleTranslation && (
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--text-muted)', marginTop: 6 }}>
                      <Subtitles size={14} color="var(--primary)" />
                      <span>{currentCard.exampleTranslation}</span>
                    </div>
                  )}
                </div>
              )}
              {currentCard.notes && (
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 10, fontSize: '0.88rem', color: 'var(--accent-amber)' }}>
                  <Lightbulb size={14} />
                  <span>{currentCard.notes}</span>
                </div>
              )}
            </div>

            {/* SRS 4 Evaluation Buttons */}
            <div className="srs-ratings-container">
              <button className="srs-btn srs-btn-again" onClick={() => handleRate(1)}>
                <span>[1] Again</span>
                <span className="srs-interval-hint">{estAgain}</span>
              </button>
              <button className="srs-btn srs-btn-hard" onClick={() => handleRate(2)}>
                <span>[2] Hard</span>
                <span className="srs-interval-hint">{estHard}</span>
              </button>
              <button className="srs-btn srs-btn-good" onClick={() => handleRate(3)}>
                <span>[3] Good</span>
                <span className="srs-interval-hint">{estGood}</span>
              </button>
              <button className="srs-btn srs-btn-easy" onClick={() => handleRate(4)}>
                <span>[4] Easy</span>
                <span className="srs-interval-hint">{estEasy}</span>
              </button>
            </div>
          </div>
        ) : (
          <div style={{ textAlign: 'center', marginTop: 30 }}>
            <button 
              className="btn btn-primary" 
              style={{ width: '100%', padding: '16px', fontSize: '1.1rem' }}
              onClick={() => setIsAnswerRevealed(true)}
            >
              Show Answer (Space)
            </button>
          </div>
        )}
      </div>
    </div>
  );
};
