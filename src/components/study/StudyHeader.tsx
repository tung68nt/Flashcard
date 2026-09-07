import React from 'react';
import { ArrowLeft, Flame, LucideIcon } from 'lucide-react';

interface StudyHeaderProps {
  deckTitle: string;
  modeName: string;
  modeIcon: LucideIcon;
  currentIndex: number;
  totalCards: number;
  streak?: number;
  onExit: () => void;
  accentColor?: string;
}

export const StudyHeader: React.FC<StudyHeaderProps> = ({
  deckTitle,
  modeName,
  modeIcon: ModeIcon,
  currentIndex,
  totalCards,
  streak = 0,
  onExit,
  accentColor,
}) => {
  const percent = totalCards > 0 ? Math.min(100, Math.round(((currentIndex + 1) / totalCards) * 100)) : 0;

  return (
    <div className="study-unified-header">
      <div className="study-unified-left">
        <button className="btn btn-secondary btn-sm" onClick={onExit} title="Exit session and return to deck">
          <ArrowLeft size={16} />
          <span>Exit</span>
        </button>

        <div className="study-deck-info">
          <div className="study-mode-badge" style={accentColor ? { color: accentColor } : undefined}>
            <ModeIcon size={14} />
            <span>{modeName}</span>
          </div>
          <span className="study-deck-title" title={deckTitle}>
            {deckTitle}
          </span>
        </div>
      </div>

      <div className="study-unified-center">
        <div className="study-unified-progress-bar">
          <div 
            className="study-unified-progress-fill" 
            style={{ width: `${percent}%` }} 
          />
        </div>
        <span className="study-progress-percent">{percent}%</span>
      </div>

      <div className="study-unified-right">
        {streak > 1 && (
          <div className="study-streak-badge" title={`Consecutive correct streak: ${streak}`}>
            <Flame size={16} />
            <span>Streak {streak}</span>
          </div>
        )}

        <div className="study-counter-chip">
          <span className="study-counter-current">{Math.min(currentIndex + 1, totalCards)}</span>
          <span className="study-counter-divider">/</span>
          <span className="study-counter-total">{totalCards}</span>
        </div>
      </div>
    </div>
  );
};
