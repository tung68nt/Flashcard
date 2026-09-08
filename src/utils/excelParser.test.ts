import { describe, it, expect } from 'vitest';
import { detectColumnMapping, convertRowsToCards, sanitizeForSpreadsheet } from './excelParser';
import { ColumnMapping } from '../types/flashcard';

describe('Excel & CSV Parser and Formula Injection Sanitizer', () => {
  it('correctly detects column mapping from English and Vietnamese header synonyms', () => {
    const headers = [
      'Từ vựng (Word)',
      'Phiên âm IPA',
      'Loại từ',
      'Định nghĩa (Meaning)',
      'Ví dụ minh họa',
      'Dịch câu ví dụ',
      'Cấu trúc ngữ pháp',
      'Ghi chú',
      'Nhãn / Tags'
    ];

    const mapping = detectColumnMapping(headers);
    expect(mapping.term).toBe('Từ vựng (Word)');
    expect(mapping.phonetic).toBe('Phiên âm IPA');
    expect(mapping.partOfSpeech).toBe('Loại từ');
    expect(mapping.definition).toBe('Định nghĩa (Meaning)');
    expect(mapping.example).toBe('Ví dụ minh họa');
    expect(mapping.exampleTranslation).toBe('Dịch câu ví dụ');
    expect(mapping.grammarPattern).toBe('Cấu trúc ngữ pháp');
    expect(mapping.notes).toBe('Ghi chú');
    expect(mapping.tags).toBe('Nhãn / Tags');
  });

  it('prevents CSV Formula Injection (CWE-1236) by escaping leading formula triggers', () => {
    expect(sanitizeForSpreadsheet('=1+1')).toBe("'=1+1");
    expect(sanitizeForSpreadsheet('+cmd|/c calc')).toBe("'+cmd|/c calc");
    expect(sanitizeForSpreadsheet('-SUM(A1:A10)')).toBe("'-SUM(A1:A10)");
    expect(sanitizeForSpreadsheet('@attack.com')).toBe("'@attack.com");
    expect(sanitizeForSpreadsheet('\tTabMalware')).toBe("'\tTabMalware");
    
    // Normal text should not be escaped
    expect(sanitizeForSpreadsheet('Hello world')).toBe('Hello world');
    expect(sanitizeForSpreadsheet('Pragmatic')).toBe('Pragmatic');
    expect(sanitizeForSpreadsheet(123)).toBe(123);
  });

  it('converts raw spreadsheet rows into standard Flashcard objects', () => {
    const rows = [
      {
        'Term': 'Resilient',
        'Phonetic': '/rɪˈzɪl.jənt/',
        'POS': 'adjective',
        'Definition': 'Able to quickly recover from difficulties',
        'Example': 'Babies are surprisingly resilient.',
        'Tags': 'B2, Personality, IELTS'
      }
    ];

    const mapping: ColumnMapping = {
      term: 'Term',
      phonetic: 'Phonetic',
      partOfSpeech: 'POS',
      definition: 'Definition',
      example: 'Example',
      exampleTranslation: '',
      grammarPattern: '',
      notes: '',
      tags: 'Tags'
    };

    const cards = convertRowsToCards(rows, mapping);
    expect(cards.length).toBe(1);
    expect(cards[0].term).toBe('Resilient');
    expect(cards[0].phonetic).toBe('/rɪˈzɪl.jənt/');
    expect(cards[0].definition).toBe('Able to quickly recover from difficulties');
    expect(cards[0].tags).toEqual(['B2', 'Personality', 'IELTS']);
    expect(cards[0].easeFactor).toBe(2.5);
    expect(cards[0].repetition).toBe(0);
  });

  it('correctly detects standard 9-column CSV template headers', () => {
    const csvTemplateHeaders = [
      'Term',
      'Phonetic',
      'PartOfSpeech',
      'Definition',
      'Example',
      'ExampleTranslation',
      'GrammarPattern',
      'Notes',
      'Tags'
    ];

    const mapping = detectColumnMapping(csvTemplateHeaders);
    expect(mapping.term).toBe('Term');
    expect(mapping.phonetic).toBe('Phonetic');
    expect(mapping.partOfSpeech).toBe('PartOfSpeech');
    expect(mapping.definition).toBe('Definition');
    expect(mapping.example).toBe('Example');
    expect(mapping.exampleTranslation).toBe('ExampleTranslation');
    expect(mapping.grammarPattern).toBe('GrammarPattern');
    expect(mapping.notes).toBe('Notes');
    expect(mapping.tags).toBe('Tags');
  });

  it('correctly maps Structure and avoids false positive on Term', () => {
    const headers = [
      'Structure',
      'Word',
      'Meaning',
      'IPA',
      'Example'
    ];

    const mapping = detectColumnMapping(headers);
    expect(mapping.grammarPattern).toBe('Structure');
    expect(mapping.term).toBe('Word');
    expect(mapping.definition).toBe('Meaning');
    expect(mapping.phonetic).toBe('IPA');
    expect(mapping.example).toBe('Example');
  });
});
