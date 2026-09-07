import { getSupabaseClient } from './supabaseClient';
import { Deck, Flashcard } from '../types/flashcard';
import { loadDecksFromStorage, saveDecksToStorage } from './storage';

export type SyncStatus = 'idle' | 'syncing' | 'synced' | 'offline' | 'error';

class SyncService {
  private status: SyncStatus = 'idle';
  private listeners: ((status: SyncStatus, message?: string) => void)[] = [];

  public getStatus(): SyncStatus {
    return this.status;
  }

  public subscribe(listener: (status: SyncStatus, message?: string) => void): () => void {
    this.listeners.push(listener);
    return () => {
      this.listeners = this.listeners.filter((l) => l !== listener);
    };
  }

  private notify(status: SyncStatus, message?: string) {
    this.status = status;
    this.listeners.forEach((l) => l(status, message));
  }

  /**
   * Đồng bộ 2 chiều toàn diện giữa LocalStorage và Supabase Database
   */
  public async syncAll(userId: string): Promise<{ success: boolean; decks: Deck[]; message: string }> {
    const supabase = getSupabaseClient();
    if (!supabase) {
      this.notify('offline', 'Supabase is not configured. Running in Local mode.');
      return { success: false, decks: loadDecksFromStorage(), message: 'Supabase not configured' };
    }

    this.notify('syncing', 'Syncing data with Supabase...');

    try {
      // 1. Tải toàn bộ Decks của User từ Supabase
      const { data: remoteDecks, error: decksErr } = await supabase
        .from('decks')
        .select('*')
        .eq('user_id', userId);

      if (decksErr) throw decksErr;

      // 2. Tải toàn bộ Cards của User từ Supabase
      const { data: remoteCards, error: cardsErr } = await supabase
        .from('cards')
        .select('*')
        .eq('user_id', userId);

      if (cardsErr) throw cardsErr;

      // Nhóm cards theo deck_id
      const remoteCardsByDeck: Record<string, Flashcard[]> = {};
      (remoteCards || []).forEach((rc: any) => {
        const card: Flashcard = {
          id: rc.id,
          term: rc.term,
          phonetic: rc.phonetic,
          partOfSpeech: rc.part_of_speech,
          definition: rc.definition,
          example: rc.example,
          exampleTranslation: rc.example_translation,
          grammarPattern: rc.grammar_pattern,
          notes: rc.notes,
          tags: rc.tags || [],
          starred: rc.starred || false,
          repetition: rc.repetition || 0,
          interval: rc.interval || 1,
          easeFactor: rc.ease_factor || 2.5,
          dueDate: rc.due_date || new Date().toISOString(),
          lastReviewed: rc.last_reviewed,
          reviewCount: rc.review_count || 0,
          lapses: rc.lapses || 0,
        };

        if (!remoteCardsByDeck[rc.deck_id]) {
          remoteCardsByDeck[rc.deck_id] = [];
        }
        remoteCardsByDeck[rc.deck_id].push(card);
      });

      // 3. Hợp nhất giữa Local Decks và Remote Decks
      const localDecks = loadDecksFromStorage();
      const localDecksMap = new Map<string, Deck>(localDecks.map((d) => [d.id, d]));
      const finalDecks: Deck[] = [];

      // Xử lý các decks từ remote
      for (const rd of remoteDecks || []) {
        const local = localDecksMap.get(rd.id);
        const remoteCards = remoteCardsByDeck[rd.id] || [];

        if (!local) {
          // Chỉ có trên remote -> đưa vào local
          finalDecks.push({
            id: rd.id,
            title: rd.title,
            description: rd.description || '',
            language: rd.language || 'en-US',
            targetLanguage: rd.target_language || 'en-US',
            category: rd.category || 'General',
            tags: rd.tags || [],
            color: rd.color || '#6366f1',
            createdAt: rd.created_at || new Date().toISOString(),
            updatedAt: rd.updated_at || new Date().toISOString(),
            cards: remoteCards,
          });
        } else {
          // Có cả 2 nơi -> so sánh updated_at
          const localTime = new Date(local.updatedAt || 0).getTime();
          const remoteTime = new Date(rd.updated_at || 0).getTime();

          if (remoteTime > localTime) {
            // Remote mới hơn
            finalDecks.push({
              ...local,
              title: rd.title,
              description: rd.description || '',
              language: rd.language || local.language,
              targetLanguage: rd.target_language || local.targetLanguage,
              category: rd.category || local.category,
              tags: rd.tags || local.tags,
              color: rd.color || local.color,
              updatedAt: rd.updated_at,
              cards: remoteCards,
            });
          } else {
            // Local mới hơn hoặc bằng -> giữ local và đẩy ngược lại remote
            finalDecks.push(local);
            await this.pushDeckToSupabase(userId, local);
          }
          localDecksMap.delete(rd.id);
        }
      }

      // Decks chỉ có ở Local -> đẩy lên Remote
      for (const [, localDeck] of localDecksMap) {
        finalDecks.push(localDeck);
        await this.pushDeckToSupabase(userId, localDeck);
      }

      // Lưu kết quả hợp nhất vào LocalStorage
      saveDecksToStorage(finalDecks);

      this.notify('synced', `Synced ${finalDecks.length} decks with Supabase.`);
      return { success: true, decks: finalDecks, message: 'Sync successful' };
    } catch (err: any) {
      console.error('Error syncing with Supabase:', err);
      this.notify('error', `Sync error: ${err.message || err}`);
      return { success: false, decks: loadDecksFromStorage(), message: err.message };
    }
  }

  /**
   * Đẩy 1 bộ thẻ và tất cả cards của nó lên Supabase
   */
  public async pushDeckToSupabase(userId: string, deck: Deck): Promise<void> {
    const supabase = getSupabaseClient();
    if (!supabase) return;

    try {
      // Upsert Deck
      await supabase.from('decks').upsert({
        id: deck.id,
        user_id: userId,
        title: deck.title,
        description: deck.description,
        language: deck.language,
        target_language: deck.targetLanguage,
        category: deck.category || 'General',
        tags: deck.tags || [],
        color: deck.color || '#6366f1',
        updated_at: deck.updatedAt || new Date().toISOString(),
      });

      // Upsert Cards nếu có
      if (deck.cards && deck.cards.length > 0) {
        const rows = deck.cards.map((c) => ({
          id: c.id,
          deck_id: deck.id,
          user_id: userId,
          term: c.term,
          phonetic: c.phonetic || null,
          part_of_speech: c.partOfSpeech || null,
          definition: c.definition,
          example: c.example || null,
          example_translation: c.exampleTranslation || null,
          grammar_pattern: c.grammarPattern || null,
          notes: c.notes || null,
          tags: c.tags || [],
          starred: c.starred || false,
          repetition: c.repetition || 0,
          interval: c.interval || 1,
          ease_factor: c.easeFactor || 2.5,
          due_date: c.dueDate || new Date().toISOString(),
          last_reviewed: c.lastReviewed || null,
          review_count: c.reviewCount || 0,
          lapses: c.lapses || 0,
          updated_at: new Date().toISOString(),
        }));

        await supabase.from('cards').upsert(rows);
      }
    } catch (err) {
      console.error('Lỗi khi đẩy bộ thẻ lên Supabase:', err);
    }
  }

  /**
   * Xóa 1 bộ thẻ trên Supabase
   */
  public async deleteDeckFromSupabase(userId: string, deckId: string): Promise<void> {
    const supabase = getSupabaseClient();
    if (!supabase) return;

    try {
      await supabase.from('decks').delete().eq('id', deckId).eq('user_id', userId);
    } catch (err) {
      console.error('Lỗi khi xóa bộ thẻ trên Supabase:', err);
    }
  }

  /**
   * Xóa 1 thẻ trên Supabase
   */
  public async deleteCardFromSupabase(userId: string, cardId: string): Promise<void> {
    const supabase = getSupabaseClient();
    if (!supabase) return;

    try {
      await supabase.from('cards').delete().eq('id', cardId).eq('user_id', userId);
    } catch (err) {
      console.error('Lỗi khi xóa thẻ trên Supabase:', err);
    }
  }
}

export const syncService = new SyncService();
