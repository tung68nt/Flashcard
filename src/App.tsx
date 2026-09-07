import React, { useState, useEffect, useRef } from 'react';
import { Navbar } from './components/Navbar';
import { DeckList } from './components/DeckList';
import { DeckDetail } from './components/DeckDetail';
import { BulkImportModal } from './components/BulkImportModal';
import { DeckEditorModal } from './components/DeckEditorModal';
import { ExportModal } from './components/ExportModal';
import { AuthModal } from './components/AuthModal';
import { AboutModal } from './components/AboutModal';

import { FlashcardMode } from './components/study/FlashcardMode';
import { SRSLearnMode } from './components/study/SRSLearnMode';
import { WriteQuizMode } from './components/study/WriteQuizMode';
import { MatchGameMode } from './components/study/MatchGameMode';
import { TestMode } from './components/study/TestMode';

import { Deck, Flashcard, StudyMode } from './types/flashcard';
import { 
  loadDecksFromStorage, 
  saveSingleDeck, 
  deleteDeckFromStorage, 
  getSavedTheme, 
  saveTheme, 
  restoreDataFromJSON,
  initializeDecks
} from './utils/storage';
import { getSupabaseClient } from './utils/supabaseClient';
import { syncService } from './utils/syncService';
import { useToast } from './context/ToastContext';

export const App: React.FC = () => {
  const { showToast } = useToast();
  const [decks, setDecks] = useState<Deck[]>(() => loadDecksFromStorage());
  const [activeDeckId, setActiveDeckId] = useState<string | null>(null);
  const [activeStudyMode, setActiveStudyMode] = useState<StudyMode | null>(null);
  const [currentTheme, setCurrentTheme] = useState<'dark' | 'light'>(() => getSavedTheme());

  // Modals state
  const [isImportModalOpen, setIsImportModalOpen] = useState(false);
  const [importTargetDeckId, setImportTargetDeckId] = useState<string | undefined>(undefined);

  const [isEditorModalOpen, setIsEditorModalOpen] = useState(false);
  const [deckToEdit, setDeckToEdit] = useState<Deck | null>(null);

  const [isExportModalOpen, setIsExportModalOpen] = useState(false);
  const [deckToExport, setDeckToExport] = useState<Deck | null>(null);

  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);
  const [isAboutModalOpen, setIsAboutModalOpen] = useState(false);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);

  const restoreFileInputRef = useRef<HTMLInputElement>(null);

  // Listen to native macOS Menu Bar events (New Deck, Import)
  useEffect(() => {
    const handleNativeNewDeck = () => {
      setDeckToEdit(null);
      setIsEditorModalOpen(true);
    };
    const handleNativeImport = () => {
      setImportTargetDeckId(undefined);
      setIsImportModalOpen(true);
    };

    window.addEventListener('lexio:open-new-deck', handleNativeNewDeck);
    window.addEventListener('lexio:open-import', handleNativeImport);

    return () => {
      window.removeEventListener('lexio:open-new-deck', handleNativeNewDeck);
      window.removeEventListener('lexio:open-import', handleNativeImport);
    };
  }, []);

  // Initialize IndexedDB storage & ensure migration from localStorage
  useEffect(() => {
    initializeDecks().then((loadedDecks) => {
      if (loadedDecks && loadedDecks.length > 0) {
        setDecks(loadedDecks);
      }
    }).catch(err => console.error('IndexedDB init error:', err));
  }, []);

  // Initialize theme
  useEffect(() => {
    saveTheme(currentTheme);
  }, [currentTheme]);

  // Check Supabase session on load and auto-sync
  useEffect(() => {
    const supabase = getSupabaseClient();
    if (supabase) {
      supabase.auth.getUser().then(({ data }) => {
        if (data.user) {
          setCurrentUserId(data.user.id);
          syncService.syncAll(data.user.id).then((res) => {
            if (res.success) setDecks(res.decks);
          });
        }
      });

      const { data: authListener } = supabase.auth.onAuthStateChange((_event, session) => {
        const uid = session?.user?.id || null;
        setCurrentUserId(uid);
        if (uid) {
          syncService.syncAll(uid).then((res) => {
            if (res.success) setDecks(res.decks);
          });
        }
      });

      return () => {
        authListener.subscription.unsubscribe();
      };
    }
  }, []);

  const handleToggleTheme = () => {
    const nextTheme = currentTheme === 'dark' ? 'light' : 'dark';
    setCurrentTheme(nextTheme);
    saveTheme(nextTheme);
  };

  const currentDeck = decks.find((d) => d.id === activeDeckId) || null;

  // Cập nhật 1 thẻ trong bộ thẻ đang mở
  const handleUpdateCard = (updatedCard: Flashcard) => {
    if (!currentDeck) return;
    const updatedCards = currentDeck.cards.map((c) =>
      c.id === updatedCard.id ? updatedCard : c
    );
    const updatedDeck: Deck = {
      ...currentDeck,
      cards: updatedCards,
      updatedAt: new Date().toISOString(),
    };
    const newDecks = saveSingleDeck(updatedDeck);
    setDecks(newDecks);

    if (currentUserId) {
      syncService.pushDeckToSupabase(currentUserId, updatedDeck);
    }
  };

  // Xóa 1 thẻ
  const handleDeleteCard = (cardId: string) => {
    if (!currentDeck) return;
    const updatedCards = currentDeck.cards.filter((c) => c.id !== cardId);
    const updatedDeck: Deck = {
      ...currentDeck,
      cards: updatedCards,
      updatedAt: new Date().toISOString(),
    };
    const newDecks = saveSingleDeck(updatedDeck);
    setDecks(newDecks);

    if (currentUserId) {
      syncService.deleteCardFromSupabase(currentUserId, cardId);
      syncService.pushDeckToSupabase(currentUserId, updatedDeck);
    }
  };

  // Xóa nguyên bộ thẻ
  const handleDeleteDeck = (deckId: string) => {
    const remaining = deleteDeckFromStorage(deckId);
    setDecks(remaining);
    setActiveDeckId(null);
    setActiveStudyMode(null);

    if (currentUserId) {
      syncService.deleteDeckFromSupabase(currentUserId, deckId);
    }
  };

  // Lưu tạo mới hoặc chỉnh sửa bộ thẻ
  const handleSaveDeck = (deck: Deck) => {
    const updatedDecks = saveSingleDeck(deck);
    setDecks(updatedDecks);
    setActiveDeckId(deck.id);

    if (currentUserId) {
      syncService.pushDeckToSupabase(currentUserId, deck);
    }
  };

  // Nạp thành công từ file Excel / CSV
  const handleImportSuccess = (newOrUpdatedDeck: Deck) => {
    const updatedDecks = saveSingleDeck(newOrUpdatedDeck);
    setDecks(updatedDecks);
    setActiveDeckId(newOrUpdatedDeck.id);

    if (currentUserId) {
      syncService.pushDeckToSupabase(currentUserId, newOrUpdatedDeck);
    }
  };

  // Khôi phục dữ liệu từ JSON
  const handleRestoreFileSelected = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      try {
        const restored = await restoreDataFromJSON(e.target.files[0]);
        setDecks(restored);
        showToast('All decks and study data restored successfully!', 'success');
        if (currentUserId) {
          for (const d of restored) {
            syncService.pushDeckToSupabase(currentUserId, d);
          }
        }
      } catch (err: any) {
        showToast(`Failed to restore backup file: ${err.message}`, 'error');
      }
    }
  };

  return (
    <div className="app-container">
      <Navbar 
        currentTheme={currentTheme}
        onToggleTheme={handleToggleTheme}
        onOpenNewDeck={() => {
          setDeckToEdit(null);
          setIsEditorModalOpen(true);
        }}
        onOpenImport={() => {
          setImportTargetDeckId(undefined);
          setIsImportModalOpen(true);
        }}
        onGoHome={() => {
          setActiveDeckId(null);
          setActiveStudyMode(null);
        }}
        onRestoreClick={() => restoreFileInputRef.current?.click()}
        onOpenAuth={() => setIsAuthModalOpen(true)}
        onOpenAbout={() => setIsAboutModalOpen(true)}
      />

      {/* Hidden file input for JSON restore */}
      <input 
        type="file" 
        ref={restoreFileInputRef} 
        style={{ display: 'none' }} 
        accept=".json" 
        onChange={handleRestoreFileSelected} 
      />

      <main className="main-content">
        {/* CASE 1: HOME VIEW (Danh sách các bộ thẻ) */}
        {!activeDeckId && (
          <DeckList 
            decks={decks}
            onSelectDeck={(deckId) => {
              setActiveDeckId(deckId);
              setActiveStudyMode(null);
            }}
            onOpenNewDeck={() => {
              setDeckToEdit(null);
              setIsEditorModalOpen(true);
            }}
            onOpenImport={() => {
              setImportTargetDeckId(undefined);
              setIsImportModalOpen(true);
            }}
            onOpenExportDeck={(deck) => {
              setDeckToExport(deck);
              setIsExportModalOpen(true);
            }}
          />
        )}

        {/* CASE 2: DECK DETAIL VIEW */}
        {activeDeckId && currentDeck && !activeStudyMode && (
          <DeckDetail 
            deck={currentDeck}
            onBack={() => setActiveDeckId(null)}
            onStartStudy={(mode) => setActiveStudyMode(mode)}
            onOpenEditDeck={(deck) => {
              setDeckToEdit(deck);
              setIsEditorModalOpen(true);
            }}
            onOpenImportToDeck={(deckId) => {
              setImportTargetDeckId(deckId);
              setIsImportModalOpen(true);
            }}
            onOpenExportDeck={(deck) => {
              setDeckToExport(deck);
              setIsExportModalOpen(true);
            }}
            onDeleteDeck={handleDeleteDeck}
            onUpdateCard={handleUpdateCard}
            onDeleteCard={handleDeleteCard}
          />
        )}

        {/* CASE 3: STUDY MODES */}
        {activeDeckId && currentDeck && activeStudyMode === 'flashcards' && (
          <FlashcardMode 
            deck={currentDeck}
            onBackToDeck={() => setActiveStudyMode(null)}
            onUpdateCard={handleUpdateCard}
          />
        )}

        {activeDeckId && currentDeck && activeStudyMode === 'srs' && (
          <SRSLearnMode 
            deck={currentDeck}
            onBackToDeck={() => setActiveStudyMode(null)}
            onUpdateCard={handleUpdateCard}
          />
        )}

        {activeDeckId && currentDeck && activeStudyMode === 'write' && (
          <WriteQuizMode 
            deck={currentDeck}
            onBackToDeck={() => setActiveStudyMode(null)}
            onUpdateCard={handleUpdateCard}
          />
        )}

        {activeDeckId && currentDeck && activeStudyMode === 'match' && (
          <MatchGameMode 
            deck={currentDeck}
            onBackToDeck={() => setActiveStudyMode(null)}
          />
        )}

        {activeDeckId && currentDeck && activeStudyMode === 'test' && (
          <TestMode 
            deck={currentDeck}
            onBackToDeck={() => setActiveStudyMode(null)}
          />
        )}
      </main>

      {/* Modals */}
      <BulkImportModal 
        isOpen={isImportModalOpen}
        onClose={() => setIsImportModalOpen(false)}
        existingDecks={decks}
        currentDeckId={importTargetDeckId}
        onImportSuccess={handleImportSuccess}
      />

      <DeckEditorModal 
        isOpen={isEditorModalOpen}
        onClose={() => setIsEditorModalOpen(false)}
        deckToEdit={deckToEdit}
        onSave={handleSaveDeck}
      />

      {deckToExport && (
        <ExportModal 
          isOpen={isExportModalOpen}
          onClose={() => setIsExportModalOpen(false)}
          deck={deckToExport}
        />
      )}

      <AuthModal 
        isOpen={isAuthModalOpen}
        onClose={() => setIsAuthModalOpen(false)}
        onSyncComplete={(syncedDecks) => setDecks(syncedDecks)}
      />

      <AboutModal 
        isOpen={isAboutModalOpen}
        onClose={() => setIsAboutModalOpen(false)}
      />
    </div>
  );
};
