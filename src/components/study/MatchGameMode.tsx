import React, { useState, useEffect, useRef } from 'react';
import { ArrowLeft, Zap, Timer, Trophy, RotateCcw, Award, CheckCircle2 } from 'lucide-react';
import confetti from 'canvas-confetti';
import { Deck, Flashcard } from '../../types/flashcard';
import { StudyHeader } from './StudyHeader';
import { StudyResultView } from './StudyResultView';

interface MatchTile {
  id: string;
  cardId: string;
  type: 'term' | 'definition';
  text: string;
  matched: boolean;
}

interface MatchGameModeProps {
  deck: Deck;
  onBackToDeck: () => void;
}

export const MatchGameMode: React.FC<MatchGameModeProps> = ({ deck, onBackToDeck }) => {
  const [tiles, setTiles] = useState<MatchTile[]>([]);
  const [selectedTileId, setSelectedTileId] = useState<string | null>(null);
  const [wrongPairIds, setWrongPairIds] = useState<string[]>([]);
  const [elapsedTimeMs, setElapsedTimeMs] = useState(0);
  const [isGameRunning, setIsGameRunning] = useState(false);
  const [isGameOver, setIsGameOver] = useState(false);
  const [bestTimeMs, setBestTimeMs] = useState<number | null>(() => {
    const saved = localStorage.getItem(`lexio_best_match_${deck.id}`);
    return saved ? parseInt(saved, 10) : null;
  });

  const timerRef = useRef<number | null>(null);
  const startTimeRef = useRef<number>(0);

  const startNewGame = () => {
    const shuffledCards = [...deck.cards].sort(() => Math.random() - 0.5).slice(0, 6);
    const generatedTiles: MatchTile[] = [];

    shuffledCards.forEach((c) => {
      generatedTiles.push({
        id: `tile-term-${c.id}`,
        cardId: c.id,
        type: 'term',
        text: c.term,
        matched: false,
      });
      generatedTiles.push({
        id: `tile-def-${c.id}`,
        cardId: c.id,
        type: 'definition',
        text: c.definition,
        matched: false,
      });
    });

    const scrambled = generatedTiles.sort(() => Math.random() - 0.5);
    setTiles(scrambled);
    setSelectedTileId(null);
    setWrongPairIds([]);
    setElapsedTimeMs(0);
    setIsGameOver(false);
    setIsGameRunning(true);
    startTimeRef.current = Date.now();

    if (timerRef.current) clearInterval(timerRef.current);
    timerRef.current = window.setInterval(() => {
      setElapsedTimeMs(Date.now() - startTimeRef.current);
    }, 50);
  };

  useEffect(() => {
    startNewGame();
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [deck.id]);

  const handleTileClick = (tile: MatchTile) => {
    if (!isGameRunning || tile.matched || wrongPairIds.length > 0) return;

    if (!selectedTileId) {
      setSelectedTileId(tile.id);
      return;
    }

    if (selectedTileId === tile.id) {
      setSelectedTileId(null);
      return;
    }

    const firstTile = tiles.find((t) => t.id === selectedTileId);
    if (!firstTile) return;

    if (firstTile.cardId === tile.cardId && firstTile.type !== tile.type) {
      // Match found
      const updatedTiles = tiles.map((t) =>
        t.id === firstTile.id || t.id === tile.id ? { ...t, matched: true } : t
      );
      setTiles(updatedTiles);
      setSelectedTileId(null);

      const allMatched = updatedTiles.every((t) => t.matched);
      if (allMatched) {
        if (timerRef.current) clearInterval(timerRef.current);
        setIsGameRunning(false);
        setIsGameOver(true);

        const finalTime = Date.now() - startTimeRef.current;
        setElapsedTimeMs(finalTime);

        if (!bestTimeMs || finalTime < bestTimeMs) {
          setBestTimeMs(finalTime);
          localStorage.setItem(`lexio_best_match_${deck.id}`, finalTime.toString());
        }

        confetti({ particleCount: 120, spread: 80, origin: { y: 0.6 } });
      }
    } else {
      setWrongPairIds([firstTile.id, tile.id]);
      setTimeout(() => {
        setWrongPairIds([]);
        setSelectedTileId(null);
      }, 500);
    }
  };

  const formatSeconds = (ms: number) => {
    return (ms / 1000).toFixed(1) + 's';
  };

  const matchedCount = tiles.filter((t) => t.matched).length / 2;
  const totalPairs = tiles.length / 2;

  if (isGameOver) {
    return (
      <StudyResultView
        title="Excellent! Match Completed"
        subtitle={`You successfully matched ${totalPairs}/${totalPairs} pairs in ${formatSeconds(elapsedTimeMs)}.`}
        score={totalPairs}
        total={totalPairs}
        percentage={100}
        language={deck.language}
        restartLabel="Play Again"
        onRestart={startNewGame}
        onExit={onBackToDeck}
      />
    );
  }

  return (
    <div className="study-container" style={{ maxWidth: 920 }}>
      {/* Unified Study Header */}
      <StudyHeader
        deckTitle={deck.title}
        modeName="Speed Match"
        modeIcon={Zap}
        currentIndex={matchedCount - 1}
        totalCards={totalPairs}
        onExit={onBackToDeck}
        accentColor="var(--amber-sunny)"
      />

      {/* Timer & Best Record Row */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 4px', marginTop: -6 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: '0.9rem', color: 'var(--text-muted)' }}>
          {bestTimeMs && (
            <span style={{ display: 'flex', alignItems: 'center', gap: 4, color: 'var(--accent-amber)', fontWeight: 700 }}>
              <Trophy size={15} />
              Best: {formatSeconds(bestTimeMs)}
            </span>
          )}
        </div>

        <div className="match-timer" style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <Timer size={20} />
          <span>{formatSeconds(elapsedTimeMs)}</span>
        </div>
      </div>

      {/* Tiles Grid */}
      <div className="match-grid">
        {tiles.map((tile) => {
          const isSelected = selectedTileId === tile.id;
          const isWrong = wrongPairIds.includes(tile.id);
          return (
            <div
              key={tile.id}
              className={`match-tile ${tile.matched ? 'matched' : ''} ${isSelected ? 'selected' : ''} ${isWrong ? 'wrong' : ''}`}
              onClick={() => handleTileClick(tile)}
            >
              <div>
                <div style={{ fontSize: tile.type === 'term' ? '1.15rem' : '0.95rem', fontWeight: tile.type === 'term' ? 800 : 600 }}>
                  {tile.text}
                </div>
                <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: 4, display: 'block', fontWeight: 600 }}>
                  {tile.type === 'term' ? 'Term' : 'Definition'}
                </span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
