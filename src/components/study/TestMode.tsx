import React, { useState, useMemo } from 'react';
import { Award, CheckCircle2, HelpCircle } from 'lucide-react';
import confetti from 'canvas-confetti';
import { Deck, Flashcard } from '../../types/flashcard';
import { StudyHeader } from './StudyHeader';
import { StudyResultView, ReviewCardItem } from './StudyResultView';

interface Question {
  id: string;
  card: Flashcard;
  type: 'multiple-choice' | 'true-false';
  prompt: string;
  options: string[];
  correctAnswer: string;
  isStatementTrue?: boolean;
}

interface TestModeProps {
  deck: Deck;
  onBackToDeck: () => void;
}

export const TestMode: React.FC<TestModeProps> = ({ deck, onBackToDeck }) => {
  // Generate multiple choice questions from deck cards
  const questions: Question[] = useMemo(() => {
    const pool = [...deck.cards];
    return pool.map((card, idx) => {
      const isTrueFalse = idx % 3 === 2; // Every 3rd question is True/False

      if (isTrueFalse) {
        const makeItTrue = Math.random() > 0.5;
        let displayedDef = card.definition;
        if (!makeItTrue && pool.length > 1) {
          const wrongCard = pool.find((c) => c.id !== card.id) || pool[0];
          displayedDef = wrongCard.definition;
        }

        return {
          id: `q-${card.id}`,
          card,
          type: 'true-false',
          prompt: `Does "${card.term}" mean: "${displayedDef}"?`,
          options: ['True', 'False'],
          correctAnswer: makeItTrue ? 'True' : 'False',
          isStatementTrue: makeItTrue,
        };
      } else {
        // Multiple choice 4 options
        const otherCards = pool.filter((c) => c.id !== card.id);
        const wrongChoices = otherCards
          .sort(() => Math.random() - 0.5)
          .slice(0, 3)
          .map((c) => c.definition);

        // Ensure 4 options even for small decks
        while (wrongChoices.length < 3) {
          wrongChoices.push(`Option ${wrongChoices.length + 1}`);
        }

        const allOptions = [card.definition, ...wrongChoices].sort(() => Math.random() - 0.5);

        return {
          id: `q-${card.id}`,
          card,
          type: 'multiple-choice',
          prompt: `Select the correct definition for: "${card.term}"`,
          options: allOptions,
          correctAnswer: card.definition,
        };
      }
    });
  }, [deck.cards]);

  const [currentIndex, setCurrentIndex] = useState(0);
  const [userAnswers, setUserAnswers] = useState<Record<string, string>>({});
  const [isSubmitted, setIsSubmitted] = useState(false);

  const currentQ = questions[currentIndex];

  const handleSelectOption = (option: string) => {
    if (isSubmitted || !currentQ) return;
    setUserAnswers((prev) => ({ ...prev, [currentQ.id]: option }));
  };

  const handleNext = () => {
    if (currentIndex + 1 < questions.length) {
      setCurrentIndex((prev) => prev + 1);
    }
  };

  const handlePrev = () => {
    if (currentIndex > 0) {
      setCurrentIndex((prev) => prev - 1);
    }
  };

  const handleSubmit = () => {
    setIsSubmitted(true);
    confetti({ particleCount: 100, spread: 80, origin: { y: 0.6 } });
  };

  if (!currentQ && questions.length === 0) {
    return (
      <div className="study-container">
        <div className="write-quiz-card" style={{ textAlign: 'center' }}>
          <h2>No cards available for examination.</h2>
          <button className="btn btn-primary" onClick={onBackToDeck} style={{ marginTop: 16 }}>
            Back to Deck
          </button>
        </div>
      </div>
    );
  }

  if (isSubmitted) {
    let correct = 0;
    questions.forEach((q) => {
      if (userAnswers[q.id] === q.correctAnswer) {
        correct += 1;
      }
    });
    const total = questions.length;
    const percentage = total > 0 ? Math.round((correct / total) * 100) : 0;

    // Map questions to unified review items
    const reviewItems: ReviewCardItem[] = questions.map((q) => {
      const userChoice = userAnswers[q.id];
      const isRight = userChoice === q.correctAnswer;
      return {
        id: q.id,
        term: q.card.term,
        phonetic: q.card.phonetic,
        definition: q.correctAnswer,
        userAnswer: userChoice || '(Not answered)',
        correctAnswer: q.correctAnswer,
        isCorrect: isRight,
        example: q.card.example,
      };
    });

    return (
      <StudyResultView
        title="Comprehensive Test Results"
        subtitle={`You completed the examination with ${correct} correct answers out of ${total} questions.`}
        score={correct}
        total={total}
        percentage={percentage}
        reviewItems={reviewItems}
        language={deck.language}
        restartLabel="Retake Test"
        onRestart={() => {
          setUserAnswers({});
          setCurrentIndex(0);
          setIsSubmitted(false);
        }}
        onExit={onBackToDeck}
      />
    );
  }

  if (!currentQ) return null;

  const currentSelection = userAnswers[currentQ.id];

  return (
    <div className="study-container">
      {/* Unified Study Header */}
      <StudyHeader
        deckTitle={deck.title}
        modeName="Comprehensive Test"
        modeIcon={Award}
        currentIndex={currentIndex}
        totalCards={questions.length}
        onExit={onBackToDeck}
        accentColor="var(--primary)"
      />

      {/* Question Card */}
      <div className="write-quiz-card">
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
            <span className="tag-badge" style={{ background: 'var(--primary-bg)', color: 'var(--primary)' }}>
              {currentQ.type === 'multiple-choice' ? 'Multiple Choice (4 Options)' : 'True / False'}
            </span>
          </div>
          <h2 style={{ fontSize: '1.45rem', fontWeight: 800, lineHeight: 1.35 }}>
            {currentQ.prompt}
          </h2>
        </div>

        {/* Options */}
        <div className="test-options-grid">
          {currentQ.options.map((opt, optIdx) => {
            const isSelected = currentSelection === opt;
            const letter = String.fromCharCode(65 + optIdx);
            return (
              <button
                key={opt}
                className={`test-option-btn ${isSelected ? 'selected' : ''}`}
                onClick={() => handleSelectOption(opt)}
                style={{ display: 'flex', alignItems: 'center', gap: 12 }}
              >
                <span style={{
                  width: 28,
                  height: 28,
                  borderRadius: '50%',
                  background: isSelected ? 'rgba(255,255,255,0.25)' : 'var(--bg-card)',
                  color: isSelected ? 'white' : 'var(--primary)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: '0.85rem',
                  fontWeight: 900,
                  flexShrink: 0,
                }}>
                  {letter}
                </span>
                <span style={{ flex: 1 }}>{opt}</span>
              </button>
            );
          })}
        </div>

        {/* Navigation */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 24, paddingTop: 16, borderTop: '1px solid var(--border-medium)' }}>
          <button 
            className="btn btn-secondary" 
            onClick={handlePrev} 
            disabled={currentIndex === 0}
          >
            Previous
          </button>
          <button 
            className="btn btn-primary" 
            onClick={handleNext}
            disabled={!currentSelection}
          >
            {currentIndex + 1 === questions.length ? 'Submit Exam' : 'Next Question'}
          </button>
        </div>
      </div>
    </div>
  );
};
