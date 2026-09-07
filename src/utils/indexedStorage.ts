import { Deck } from '../types/flashcard';
import { SAMPLE_DECKS } from './sampleDecks';

const DB_NAME = 'LexioProDB';
const DB_VERSION = 1;
const STORE_DECKS = 'decks';
const LOCAL_STORAGE_KEY = 'flashmaster_pro_decks_v1';

let dbInstance: IDBDatabase | null = null;

/**
 * Khởi tạo hoặc lấy kết nối IndexedDB (Singleton)
 */
export function openDB(): Promise<IDBDatabase> {
  if (dbInstance) {
    return Promise.resolve(dbInstance);
  }

  return new Promise((resolve, reject) => {
    if (typeof window === 'undefined' || !window.indexedDB) {
      reject(new Error('IndexedDB is not supported in this environment.'));
      return;
    }

    const request = window.indexedDB.open(DB_NAME, DB_VERSION);

    request.onupgradeneeded = (event) => {
      const db = (event.target as IDBOpenDBRequest).result;
      if (!db.objectStoreNames.contains(STORE_DECKS)) {
        db.createObjectStore(STORE_DECKS, { keyPath: 'id' });
      }
    };

    request.onsuccess = (event) => {
      dbInstance = (event.target as IDBOpenDBRequest).result;
      resolve(dbInstance);
    };

    request.onerror = (event) => {
      reject((event.target as IDBOpenDBRequest).error || new Error('Failed to open IndexedDB.'));
    };
  });
}

/**
 * Lấy tất cả bộ thẻ từ IndexedDB
 */
export async function getAllDecksFromIDB(): Promise<Deck[]> {
  try {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_DECKS, 'readonly');
      const store = tx.objectStore(STORE_DECKS);
      const request = store.getAll();

      request.onsuccess = () => {
        const decks = request.result as Deck[];
        resolve(Array.isArray(decks) ? decks : []);
      };

      request.onerror = () => {
        reject(request.error || new Error('Failed to get decks from IndexedDB.'));
      };
    });
  } catch (err) {
    console.error('Error fetching from IndexedDB, falling back to localStorage:', err);
    return [];
  }
}

/**
 * Lưu hoặc cập nhật một bộ thẻ vào IndexedDB
 */
export async function saveDeckToIDB(deck: Deck): Promise<void> {
  const db = await openDB();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_DECKS, 'readwrite');
    const store = tx.objectStore(STORE_DECKS);
    const request = store.put(deck);

    request.onsuccess = () => resolve();
    request.onerror = () => reject(request.error);
  });
}

/**
 * Lưu hàng loạt bộ thẻ vào IndexedDB
 */
export async function saveAllDecksToIDB(decks: Deck[]): Promise<void> {
  const db = await openDB();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_DECKS, 'readwrite');
    const store = tx.objectStore(STORE_DECKS);
    store.clear();
    for (const deck of decks) {
      store.put(deck);
    }
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
  });
}

/**
 * Xóa một bộ thẻ khỏi IndexedDB
 */
export async function deleteDeckFromIDB(deckId: string): Promise<void> {
  const db = await openDB();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_DECKS, 'readwrite');
    const store = tx.objectStore(STORE_DECKS);
    const request = store.delete(deckId);

    request.onsuccess = () => resolve();
    request.onerror = () => reject(request.error);
  });
}

/**
 * Tự động chuyển đổi dữ liệu từ LocalStorage sang IndexedDB ngay lần khởi chạy đầu
 * Đảm bảo 100% dữ liệu cũ không bị mất
 */
export async function initAndMigrateStorage(): Promise<Deck[]> {
  try {
    const idbDecks = await getAllDecksFromIDB();
    if (idbDecks.length > 0) {
      return idbDecks;
    }

    // Nếu IDB rỗng, kiểm tra localStorage
    let migratedDecks: Deck[] = [];
    try {
      const raw = localStorage.getItem(LOCAL_STORAGE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed) && parsed.length > 0) {
          migratedDecks = parsed;
        }
      }
    } catch (e) {
      console.warn('Could not read legacy localStorage decks:', e);
    }

    // Nếu localStorage cũng rỗng, dùng SAMPLE_DECKS
    const finalDecks = migratedDecks.length > 0 ? migratedDecks : SAMPLE_DECKS;
    await saveAllDecksToIDB(finalDecks);
    return finalDecks;
  } catch (err) {
    console.error('Migration failed, using sample decks:', err);
    return SAMPLE_DECKS;
  }
}
