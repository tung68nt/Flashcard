import React, { useState, useRef, useEffect } from 'react';
import { 
  PenTool, 
  CheckCircle2, 
  XCircle, 
  Volume2, 
  ArrowRight, 
  RotateCcw,
  Subtitles,
  Pin,
  Sparkles
} from 'lucide-react';
import confetti from 'canvas-confetti';
import { Flashcard, Deck } from '../../types/flashcard';
import { speechService } from '../../utils/speech';
import { PosChip } from '../../utils/posHelper';
import { StudyHeader } from './StudyHeader';
import { StudyResultView, ReviewCardItem } from './StudyResultView';

interface WriteQuizModeProps {
  deck: Deck;
  onBackToDeck: () => void;
  onUpdateCard?: (card: Flashcard) => void;
}

export const WriteQuizMode: React.FC<WriteQuizModeProps> = ({
  deck,
  onBackToDeck,
}) => {
  const [cards] = useState<Flashcard[]>(() => [...deck.cards].sort(() => Math.random() - 0.5));
  const [currentIndex, setCurrentIndex] = useState(0);
  const [userInput, setUserInput] = useState('');
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [isCorrect, setIsCorrect] = useState(false);
  const [score, setScore] = useState(0);
  const [streak, setStreak] = useState(0);
  const [isFinished, setIsFinished] = useState(false);
  const [answersHistory, setAnswersHistory] = useState<Record<string, { userInput: string; isCorrect: boolean }>>({});

  const inputRef = useRef<HTMLInputElement>(null);
  const currentCard = cards[currentIndex];

  useEffect(() => {
    if (!isSubmitted && inputRef.current) {
      inputRef.current.focus();
    }
  }, [currentIndex, isSubmitted]);

  const checkAnswer = () => {
    if (!currentCard || !userInput.trim()) return;

    const cleanUser = userInput.trim().toLowerCase().replace(/[.,!?;:'"-]/g, '');
    const cleanTarget = currentCard.term.trim().toLowerCase().replace(/[.,!?;:'"-]/g, '');

    const match = cleanUser === cleanTarget;
    setIsCorrect(match);
    setIsSubmitted(true);

    setAnswersHistory((prev) => ({
      ...prev,
      [currentCard.id]: { userInput: userInput.trim(), isCorrect: match }
    }));

    if (match) {
      setScore((prev) => prev + 1);
      setStreak((prev) => prev + 1);
      speechService.speak(currentCard.term, { lang: deck.language || 'en-US' });
    } else {
      setStreak(0);
    }
  };

  const handleNext = () => {
    setUserInput('');
    setIsSubmitted(false);
    if (currentIndex + 1 < cards.length) {
      setCurrentIndex((prev) => prev + 1);
    } else {
      setIsFinished(true);
      confetti({ particleCount: 100, spread: 70, origin: { y: 0.6 } });
    }
  };

  if (isFinished) {
    const percent = cards.length > 0 ? Math.round((score / cards.length) * 100) : 0;

    const reviewItems: ReviewCardItem[] = cards.map((c) => {
      const hist = answersHistory[c.id];
      const isRight = hist ? hist.isCorrect : false;
      return {
        id: c.id,
        term: c.term,
        phonetic: c.phonetic,
        definition: c.definition,
        userAnswer: hist?.userInput || '(Not entered)',
        correctAnswer: c.term,
        isCorrect: isRight,
        example: c.example,
      };
    });

    return (
      <StudyResultView
        title="Spelling Practice Complete"
        subtitle={`You successfully spelled ${score} out of ${cards.length} vocabulary terms.`}
        score={score}
        total={cards.length}
        percentage={percent}
        reviewItems={reviewItems}
        language={deck.language}
        restartLabel="Practice Again"
        onRestart={() => {
          setCurrentIndex(0);
          setScore(0);
          setStreak(0);
          setIsSubmitted(false);
          setIsFinished(false);
          setAnswersHistory({});
        }}
        onExit={onBackToDeck}
      />
    );
  }

  if (!currentCard) return null;

  const maskedExample = currentCard.example
    ? currentCard.example.replace(new RegExp(currentCard.term, 'gi'), '__________')
    : null;

  return (
    <div className="study-container">
      {/* Unified Header */}
      <StudyHeader
        deckTitle={deck.title}
        modeName="Write & Spell"
        modeIcon={PenTool}
        currentIndex={currentIndex}
        totalCards={cards.length}
        streak={streak}
        onExit={onBackToDeck}
        accentColor="var(--accent-cyan)"
      />

      {/* Quiz Card */}
      <div className="write-quiz-card">
        <div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
            <PosChip pos={currentCard.partOfSpeech || 'Vocabulary'} />
            <span style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--text-muted)' }}>
              Score: {score}/{currentIndex + (isSubmitted ? 1 : 0)}
            </span>
          </div>

          <h2 className="quiz-prompt" style={{ marginBottom: 16 }}>
            {currentCard.definition}
          </h2>

          {maskedExample && (
            <div style={{
              background: 'var(--bg-tertiary)',
              padding: '16px 20px',
              borderRadius: 'var(--radius-lg)',
              borderLeft: '4px solid var(--primary)',
              marginBottom: 20,
              fontSize: '1rem',
              color: 'var(--text-secondary)',
            }}>
              <div>{maskedExample}</div>
              {currentCard.exampleTranslation && (
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontStyle: 'italic', fontSize: '0.88rem', marginTop: 6, color: 'var(--text-muted)' }}>
                  <Subtitles size={14} color="var(--primary)" />
                  <span>{currentCard.exampleTranslation}</span>
                </div>
              )}
            </div>
          )}

          {currentCard.grammarPattern && (
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: '0.9rem', color: 'var(--accent-cyan)', fontWeight: 700, marginBottom: 20 }}>
              <Pin size={14} />
              <span>Grammar hint: {currentCard.grammarPattern}</span>
            </div>
          )}
        </div>

        {/* Input and Submit Form */}
        {!isSubmitted ? (
          <form 
            onSubmit={(e) => {
              e.preventDefault();
              checkAnswer();
            }}
          >
            <div className="quiz-input-wrapper">
              <input 
                ref={inputRef}
                className="quiz-input"
                placeholder="Type the exact target word here..."
                value={userInput}
                onChange={(e) => setUserInput(e.target.value)}
                autoComplete="off"
                spellCheck={false}
              />
              <button 
                type="submit" 
                className="btn btn-primary" 
                disabled={!userInput.trim()}
                style={{ padding: '0 28px', fontSize: '1rem' }}
              >
                Check
              </button>
            </div>
          </form>
        ) : (
          <div className={`quiz-feedback-box ${isCorrect ? 'correct' : 'incorrect'}`}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                {isCorrect ? <CheckCircle2 size={24} /> : <XCircle size={24} />}
                <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>
                  {isCorrect ? 'Correct!' : 'Incorrect'}
                </h3>
              </div>
              <button 
                className="btn-icon" 
                onClick={() => speechService.speak(currentCard.term, { lang: deck.language || 'en-US' })}
                title="Listen to pronunciation"
              >
                <Volume2 size={20} />
              </button>
            </div>

            <div style={{ fontSize: '1.15rem', marginBottom: 6 }}>
              Target answer: <strong>{currentCard.term}</strong>
              {currentCard.phonetic && (
                <span className="phonetic-text" style={{ marginLeft: 12, fontSize: '1.05rem' }}>
                  {currentCard.phonetic.startsWith('/') ? currentCard.phonetic : `/${currentCard.phonetic}/`}
                </span>
              )}
            </div>

            {!isCorrect && (
              <div style={{ fontSize: '0.95rem', color: 'var(--text-secondary)', marginBottom: 16 }}>
                You typed: <span className="incorrect-answer-text">{userInput}</span>
              </div>
            )}

            <button 
              className="btn btn-primary" 
              onClick={handleNext}
              style={{ marginTop: 12, width: '100%', padding: '14px' }}
              autoFocus
            >
              <span>Continue (Enter)</span>
              <ArrowRight size={18} />
            </button>
          </div>
        )}
      </div>
    </div>
  );
};
