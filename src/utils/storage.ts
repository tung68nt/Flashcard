import { Deck, Flashcard } from '../types/flashcard';
import { SAMPLE_DECKS } from './sampleDecks';
import { 
  saveDeckToIDB, 
  saveAllDecksToIDB, 
  deleteDeckFromIDB, 
  initAndMigrateStorage,
  getAllDecksFromIDB 
} from './indexedStorage';

const STORAGE_KEY = 'flashmaster_pro_decks_v1';
const THEME_KEY = 'flashmaster_pro_theme';

export async function initializeDecks(): Promise<Deck[]> {
  return await initAndMigrateStorage();
}

export function loadDecksFromStorage(): Deck[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) {
      saveDecksToStorage(SAMPLE_DECKS);
      return SAMPLE_DECKS;
    }
    const parsed = JSON.parse(raw) as Deck[];
    return Array.isArray(parsed) && parsed.length > 0 ? parsed : SAMPLE_DECKS;
  } catch (err) {
    console.error('Error loading decks from storage:', err);
    return SAMPLE_DECKS;
  }
}

export function saveDecksToStorage(decks: Deck[]): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(decks));
  } catch (err) {
    console.warn('LocalStorage save warning (may exceed quota, persisting to IndexedDB):', err);
  }
  // Đồng bộ sang IndexedDB bất đồng bộ
  saveAllDecksToIDB(decks).catch((err) => console.error('Failed to sync decks to IndexedDB:', err));
}

export function saveSingleDeck(updatedDeck: Deck): Deck[] {
  const decks = loadDecksFromStorage();
  const index = decks.findIndex((d) => d.id === updatedDeck.id);
  let newDecks: Deck[];
  if (index >= 0) {
    newDecks = [...decks];
    newDecks[index] = { ...updatedDeck, updatedAt: new Date().toISOString() };
  } else {
    newDecks = [updatedDeck, ...decks];
  }
  saveDecksToStorage(newDecks);
  saveDeckToIDB(updatedDeck).catch((err) => console.error('Failed to save deck to IndexedDB:', err));
  return newDecks;
}

export function updateCardInDeck(deckId: string, updatedCard: Flashcard): Deck | null {
  const decks = loadDecksFromStorage();
  const deck = decks.find((d) => d.id === deckId);
  if (!deck) return null;

  const cardIndex = deck.cards.findIndex((c) => c.id === updatedCard.id);
  let newCards = [...deck.cards];
  if (cardIndex >= 0) {
    newCards[cardIndex] = updatedCard;
  } else {
    newCards.push(updatedCard);
  }

  const updatedDeck: Deck = {
    ...deck,
    cards: newCards,
    updatedAt: new Date().toISOString(),
  };

  saveSingleDeck(updatedDeck);
  return updatedDeck;
}

export function deleteDeckFromStorage(deckId: string): Deck[] {
  const decks = loadDecksFromStorage().filter((d) => d.id !== deckId);
  saveDecksToStorage(decks);
  deleteDeckFromIDB(deckId).catch((err) => console.error('Failed to delete deck from IndexedDB:', err));
  return decks;
}

// Theme storage
export function getSavedTheme(): 'dark' | 'light' {
  const saved = localStorage.getItem(THEME_KEY);
  if (saved === 'dark' || saved === 'light') return saved;
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

export function saveTheme(theme: 'dark' | 'light'): void {
  localStorage.setItem(THEME_KEY, theme);
  document.documentElement.setAttribute('data-theme', theme);
}

// Backup & Restore
export function exportAllDataJSON(): void {
  const decks = loadDecksFromStorage();
  const dataStr = 'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(decks, null, 2));
  const downloadAnchor = document.createElement('a');
  downloadAnchor.setAttribute('href', dataStr);
  downloadAnchor.setAttribute('download', `flashmaster_backup_${new Date().toISOString().slice(0, 10)}.json`);
  document.body.appendChild(downloadAnchor);
  downloadAnchor.click();
  downloadAnchor.remove();
}

export function restoreDataFromJSON(file: File): Promise<Deck[]> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = async (e) => {
      try {
        const text = e.target?.result as string;
        const decks = JSON.parse(text) as Deck[];
        if (!Array.isArray(decks)) throw new Error('Dữ liệu không đúng định dạng mảng bộ thẻ');
        saveDecksToStorage(decks);
        await saveAllDecksToIDB(decks);
        resolve(decks);
      } catch (err) {
        reject(err);
      }
    };
    reader.onerror = () => reject(new Error('Lỗi khi đọc file backup'));
    reader.readAsText(file);
  });
}
