import { describe, it, expect } from 'vitest';
import { calculateSRS, isCardDue, getDueCards } from './srs';
import { Flashcard } from '../types/flashcard';

describe('Spaced Repetition (SuperMemo SM-2) Engine', () => {
  const baseCard: Flashcard = {
    id: 'test-card-1',
    term: 'Empirical',
    definition: 'Based on observation or experience rather than theory',
    repetition: 0,
    interval: 1,
    easeFactor: 2.5,
    dueDate: new Date(Date.now() - 3600000).toISOString(), // Due 1 hour ago
    reviewCount: 0,
    lapses: 0,
  };

  it('correctly handles Rating 1 (Again - Forgot word)', () => {
    const updated = calculateSRS({ ...baseCard, repetition: 3, interval: 10, lapses: 0 }, 1);
    expect(updated.repetition).toBe(0);
    expect(updated.interval).toBe(1);
    expect(updated.lapses).toBe(1);
    expect(updated.reviewCount).toBe(1);
    // Ease Factor should decrease
    expect(updated.easeFactor).toBeLessThan(2.5);
  });

  it('correctly handles Rating 3 (Good - Remembered well)', () => {
    const updated = calculateSRS(baseCard, 3);
    expect(updated.repetition).toBe(1);
    expect(updated.interval).toBe(1);
    expect(updated.lapses).toBe(0);
    expect(updated.reviewCount).toBe(1);
  });

  it('correctly handles consecutive good ratings with ease factor multiplier', () => {
    // Card with repetition 2
    const learnedCard: Flashcard = {
      ...baseCard,
      repetition: 2,
      interval: 6,
      easeFactor: 2.5,
    };
    const updated = calculateSRS(learnedCard, 3);
    expect(updated.repetition).toBe(3);
    expect(updated.interval).toBe(Math.round(6 * 2.5)); // 15 days
  });

  it('gives interval bonus for Rating 4 (Easy)', () => {
    const learnedCard: Flashcard = {
      ...baseCard,
      repetition: 2,
      interval: 6,
      easeFactor: 2.5,
    };
    const updated = calculateSRS(learnedCard, 4);
    expect(updated.repetition).toBe(3);
    // Easy rating adds a 1.3x multiplier
    expect(updated.interval).toBeGreaterThan(Math.round(6 * 2.5));
    expect(updated.easeFactor).toBeGreaterThan(2.5);
  });

  it('enforces minimum Ease Factor floor of 1.3', () => {
    // Card with ease factor already near minimum
    const strugglingCard: Flashcard = {
      ...baseCard,
      easeFactor: 1.35,
      repetition: 0,
    };
    const updated = calculateSRS(strugglingCard, 1);
    expect(updated.easeFactor).toBeGreaterThanOrEqual(1.3);
  });

  it('correctly identifies due and non-due cards', () => {
    const pastCard: Flashcard = {
      ...baseCard,
      dueDate: new Date(Date.now() - 86400000).toISOString(), // Yesterday
    };
    const futureCard: Flashcard = {
      ...baseCard,
      dueDate: new Date(Date.now() + 86400000).toISOString(), // Tomorrow
    };

    expect(isCardDue(pastCard)).toBe(true);
    expect(isCardDue(futureCard)).toBe(false);

    const dueList = getDueCards([pastCard, futureCard]);
    expect(dueList.length).toBe(1);
    expect(dueList[0].term).toBe('Empirical');
  });
});
