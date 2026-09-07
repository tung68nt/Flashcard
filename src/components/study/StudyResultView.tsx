import React from 'react';
import { 
  ArrowLeft, 
  RotateCcw, 
  CheckCircle2, 
  XCircle, 
  Award, 
  Volume2, 
  Target,
  FileText
} from 'lucide-react';
import { speechService } from '../../utils/speech';

export interface ResultStatItem {
  label: string;
  value: string | number;
  icon: React.ComponentType<{ size?: number; className?: string }>;
  color?: string;
}

export interface ReviewCardItem {
  id: string;
  term: string;
  phonetic?: string;
  definition: string;
  userAnswer?: string;
  correctAnswer?: string;
  isCorrect: boolean;
  notes?: string;
  example?: string;
}

interface StudyResultViewProps {
  title: string;
  subtitle?: string;
  score: number;
  total: number;
  percentage: number;
  stats?: ResultStatItem[];
  reviewItems?: ReviewCardItem[];
  language?: string;
  restartLabel?: string;
  onRestart: () => void;
  onExit: () => void;
}

export const StudyResultView: React.FC<StudyResultViewProps> = ({
  title,
  subtitle,
  score,
  total,
  percentage,
  stats,
  reviewItems,
  language = 'en-US',
  restartLabel = 'Practice Again',
  onRestart,
  onExit,
}) => {
  const incorrectCount = Math.max(0, total - score);

  const grade = 
    percentage >= 90 ? { label: 'Mastery', color: 'var(--emerald-fresh)' } :
    percentage >= 75 ? { label: 'Proficient', color: 'var(--cyan-neon)' } :
    percentage >= 50 ? { label: 'Passing', color: 'var(--amber-sunny)' } :
    { label: 'Needs Review', color: 'var(--pink-electric)' };

  return (
    <div className="study-container study-result-container">
      <div className="test-summary-card">
        {/* Score Circle */}
        <div className="result-meter-wrapper">
          <div className="score-circle" style={{ '--percent': percentage } as any}>
            <div className="score-circle-inner">
              <span className="score-percentage-text">{percentage}%</span>
              <span className="score-grade-badge" style={{ color: grade.color }}>
                {grade.label}
              </span>
            </div>
          </div>
        </div>

        <h2 className="result-main-title">{title}</h2>
        <p className="result-sub-text">
          {subtitle || `You correctly answered ${score} out of ${total} cards.`}
        </p>

        {/* 4-Stat Metric Cards */}
        <div className="result-stats-grid">
          <div className="result-stat-tile">
            <div className="result-stat-icon-wrap" style={{ color: 'var(--emerald-fresh)', background: 'var(--accent-emerald-bg)' }}>
              <CheckCircle2 size={18} />
            </div>
            <div className="result-stat-meta">
              <span className="result-stat-num" style={{ color: 'var(--emerald-fresh)' }}>{score}</span>
              <span className="result-stat-label">Correct</span>
            </div>
          </div>

          <div className="result-stat-tile">
            <div className="result-stat-icon-wrap" style={{ color: 'var(--pink-electric)', background: 'var(--primary-bg)' }}>
              <XCircle size={18} />
            </div>
            <div className="result-stat-meta">
              <span className="result-stat-num" style={{ color: 'var(--pink-electric)' }}>{incorrectCount}</span>
              <span className="result-stat-label">Incorrect</span>
            </div>
          </div>

          <div className="result-stat-tile">
            <div className="result-stat-icon-wrap" style={{ color: 'var(--cyan-neon)', background: 'var(--accent-cyan-bg)' }}>
              <Target size={18} />
            </div>
            <div className="result-stat-meta">
              <span className="result-stat-num">{total}</span>
              <span className="result-stat-label">Total Cards</span>
            </div>
          </div>

          <div className="result-stat-tile">
            <div className="result-stat-icon-wrap" style={{ color: 'var(--purple-vivid)', background: 'rgba(139, 92, 246, 0.12)' }}>
              <Award size={18} />
            </div>
            <div className="result-stat-meta">
              <span className="result-stat-num">{percentage}%</span>
              <span className="result-stat-label">Accuracy</span>
            </div>
          </div>
        </div>

        {/* Action Controls */}
        <div className="result-actions-row">
          <button className="btn btn-secondary" onClick={onExit}>
            <ArrowLeft size={16} />
            <span>Back to Deck</span>
          </button>
          <button className="btn btn-primary" onClick={onRestart}>
            <RotateCcw size={16} />
            <span>{restartLabel}</span>
          </button>
        </div>

        {/* Detailed Question / Answer Review */}
        {reviewItems && reviewItems.length > 0 && (
          <div className="result-review-section">
            <div className="result-review-header">
              <FileText size={18} color="var(--primary)" />
              <h3>Question Breakdown & Answers ({reviewItems.length})</h3>
            </div>

            <div className="result-review-list">
              {reviewItems.map((item, idx) => (
                <div 
                  key={item.id || idx} 
                  className={`result-review-item ${item.isCorrect ? 'is-correct' : 'is-incorrect'}`}
                >
                  <div className="review-item-top">
                    <div className="review-item-term-group">
                      <span className="review-item-number">#{idx + 1}</span>
                      <span className="review-item-term">{item.term}</span>
                      {item.phonetic && (
                        <span className="review-item-phonetic">{item.phonetic}</span>
                      )}
                      <button 
                        className="btn-icon btn-sm"
                        onClick={() => speechService.speak(item.term, { lang: language })}
                        title="Listen"
                      >
                        <Volume2 size={14} />
                      </button>
                    </div>

                    <div className="review-item-status-badge">
                      {item.isCorrect ? (
                        <span className="badge-correct">
                          <CheckCircle2 size={14} />
                          <span>Correct</span>
                        </span>
                      ) : (
                        <span className="badge-incorrect">
                          <XCircle size={14} />
                          <span>Incorrect</span>
                        </span>
                      )}
                    </div>
                  </div>

                  <div className="review-item-content">
                    <div className="review-item-definition">
                      <strong>Correct Definition:</strong> {item.definition}
                    </div>

                    {item.userAnswer && item.userAnswer !== item.correctAnswer && (
                      <div className="review-item-user-answer">
                        <strong>Your Answer:</strong> <span className="incorrect-answer-text">{item.userAnswer}</span>
                      </div>
                    )}

                    {item.example && (
                      <div className="review-item-example">
                        <strong>Example:</strong> {item.example}
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
