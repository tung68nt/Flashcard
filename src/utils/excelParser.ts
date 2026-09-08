import * as XLSX from 'xlsx';
import Papa from 'papaparse';
import { ColumnMapping, Flashcard } from '../types/flashcard';

/**
 * Tự động phân tích và dự đoán tên cột mapping phù hợp
 */
export function detectColumnMapping(headers: string[]): ColumnMapping {
  const mapping: ColumnMapping = {
    term: '',
    phonetic: '',
    partOfSpeech: '',
    definition: '',
    example: '',
    exampleTranslation: '',
    grammarPattern: '',
    notes: '',
    tags: '',
  };

  const removeAccents = (str: string) =>
    str.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D');

  const normalize = (str: string) =>
    removeAccents(str).toLowerCase().replace(/[^a-z0-9]/g, '');

  headers.forEach((header) => {
    const norm = normalize(header);

    if (!mapping.term && (norm.includes('term') || norm.includes('word') || norm.includes('vocab') || norm.includes('tuvung') || norm === 'tu' || norm.startsWith('tu_') || norm.includes('thuatngu'))) {
      mapping.term = header;
    } else if (!mapping.phonetic && (norm.includes('phonetic') || norm.includes('ipa') || norm.includes('phienam') || norm.includes('pronun') || norm.includes('phatam'))) {
      mapping.phonetic = header;
    } else if (!mapping.partOfSpeech && (norm.includes('partofspeech') || norm.includes('pos') || norm.includes('loaitu') || norm.includes('type') || norm.includes('tucloai') || norm.includes('tuloai'))) {
      mapping.partOfSpeech = header;
    } else if (!mapping.exampleTranslation && (((norm.includes('example') || norm.includes('vidu')) && (norm.includes('trans') || norm.includes('dich') || norm.includes('nghia'))) || norm.includes('dichcau') || norm.includes('dichvidu') || norm === 'exampletranslation')) {
      mapping.exampleTranslation = header;
    } else if (!mapping.example && (norm.includes('example') || norm.includes('vidu') || norm.includes('sentence') || norm.includes('cauvidu'))) {
      mapping.example = header;
    } else if (!mapping.definition && (norm.includes('meaning') || norm.includes('definition') || norm.includes('nghia') || norm.includes('dich') || norm.includes('dinhnghia') || norm.includes('vietnamese') || norm.includes('giainghia'))) {
      mapping.definition = header;
    } else if (!mapping.grammarPattern && (norm.includes('grammar') || norm.includes('pattern') || norm.includes('formula') || norm.includes('nguphap') || norm.includes('cautruc') || norm.includes('structure') || norm.includes('struc'))) {
      mapping.grammarPattern = header;
    } else if (!mapping.notes && (norm.includes('note') || norm.includes('mnemonic') || norm.includes('ghichu') || norm.includes('meonho') || norm.includes('luuy'))) {
      mapping.notes = header;
    } else if (!mapping.tags && (norm.includes('tag') || norm.includes('topic') || norm.includes('chude') || norm.includes('level') || norm.includes('nhan'))) {
      mapping.tags = header;
    }
  });

  // Nếu chưa nhận diện được Term và Definition, lấy mặc định 2 cột đầu tiên nếu có
  if (!mapping.term && headers.length > 0) mapping.term = headers[0];
  if (!mapping.definition && headers.length > 1) mapping.definition = headers[1];

  return mapping;
}

export interface ParsedFileData {
  headers: string[];
  rows: Record<string, any>[];
  fileName: string;
}

/**
 * Đọc file Excel (.xlsx, .xls)
 */
export async function parseExcelFile(file: File): Promise<ParsedFileData> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const data = new Uint8Array(e.target?.result as ArrayBuffer);
        const workbook = XLSX.read(data, { type: 'array' });
        const firstSheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[firstSheetName];
        
        const jsonData = XLSX.utils.sheet_to_json<Record<string, any>>(worksheet, { defval: '' });
        if (jsonData.length === 0) {
          resolve({ headers: [], rows: [], fileName: file.name });
          return;
        }

        const headers = Object.keys(jsonData[0]);
        resolve({ headers, rows: jsonData, fileName: file.name });
      } catch (err) {
        reject(new Error('Không thể đọc file Excel. Vui lòng kiểm tra định dạng file.'));
      }
    };
    reader.onerror = () => reject(new Error('Lỗi khi đọc file.'));
    reader.readAsArrayBuffer(file);
  });
}

/**
 * Đọc file CSV
 */
export async function parseCSVFile(file: File): Promise<ParsedFileData> {
  return new Promise((resolve, reject) => {
    Papa.parse<Record<string, any>>(file, {
      header: true,
      skipEmptyLines: true,
      complete: (results) => {
        if (!results.data || results.data.length === 0) {
          resolve({ headers: [], rows: [], fileName: file.name });
          return;
        }
        const headers = results.meta.fields || Object.keys(results.data[0]);
        resolve({ headers, rows: results.data, fileName: file.name });
      },
      error: (error) => {
        reject(new Error(`Lỗi phân tích CSV: ${error.message}`));
      },
    });
  });
}

/**
 * Chuyển đổi dữ liệu đã parse thành mảng Flashcard theo mapping đã chọn
 */
export function convertRowsToCards(rows: Record<string, any>[], mapping: ColumnMapping): Flashcard[] {
  const now = new Date().toISOString();

  return rows
    .map((row, index) => {
      const term = String(row[mapping.term] || '').trim();
      const definition = String(row[mapping.definition] || '').trim();

      if (!term && !definition) return null;

      const rawTags = mapping.tags ? String(row[mapping.tags] || '').trim() : '';
      const tags = rawTags
        ? rawTags.split(/[,;|]/).map((t) => t.trim()).filter(Boolean)
        : [];

      const card: Flashcard = {
        id: `card-${Date.now()}-${index}-${Math.random().toString(36).substring(2, 7)}`,
        term: term || '(Chưa có từ vựng)',
        definition: definition || '(Chưa có nghĩa)',
        phonetic: mapping.phonetic ? String(row[mapping.phonetic] || '').trim() : undefined,
        partOfSpeech: mapping.partOfSpeech ? String(row[mapping.partOfSpeech] || '').trim() : undefined,
        example: mapping.example ? String(row[mapping.example] || '').trim() : undefined,
        exampleTranslation: mapping.exampleTranslation ? String(row[mapping.exampleTranslation] || '').trim() : undefined,
        grammarPattern: mapping.grammarPattern ? String(row[mapping.grammarPattern] || '').trim() : undefined,
        notes: mapping.notes ? String(row[mapping.notes] || '').trim() : undefined,
        tags,
        starred: false,
        repetition: 0,
        interval: 1,
        easeFactor: 2.5,
        dueDate: now,
        reviewCount: 0,
        lapses: 0,
      };

      return card;
    })
    .filter((card): card is Flashcard => card !== null);
}

/**
 * Tạo và tải xuống file Excel mẫu chuẩn
 */
export function downloadSampleExcel() {
  const sampleData = [
    {
      'Từ vựng (Term)': 'Pivotal',
      'Phiên âm (IPA)': '/ˈpɪv.ə.t̬əl/',
      'Từ loại': 'adjective',
      'Định nghĩa (Meaning)': 'Then chốt, có tính chất quyết định',
      'Ví dụ (Example)': 'The upcoming summit will play a pivotal role in negotiating the peace accord.',
      'Dịch ví dụ': 'Hội nghị thượng đỉnh sắp tới sẽ đóng vai trò then chốt trong đàm phán hiệp định hòa bình.',
      'Cấu trúc ngữ pháp': 'play a pivotal role in (doing) sth',
      'Ghi chú / Mẹo nhớ': 'Gốc từ "pivot" (trục quay) -> điểm trục cốt lõi, không thể thiếu',
      'Nhãn (Tags)': 'C1, C2, Academic, Formal',
    },
    {
      'Từ vựng (Term)': 'Exacerbate',
      'Phiên âm (IPA)': '/ɪɡˈzæs.ɚ.beɪt/',
      'Từ loại': 'verb',
      'Định nghĩa (Meaning)': 'Làm trầm trọng thêm, làm xấu đi tình hình',
      'Ví dụ (Example)': 'The economic crisis was exacerbated by a sudden surge in inflation.',
      'Dịch ví dụ': 'Khủng hoảng kinh tế càng bị trầm trọng thêm bởi sự gia tăng đột ngột của lạm phát.',
      'Cấu trúc ngữ pháp': 'exacerbate a problem/condition',
      'Ghi chú / Mẹo nhớ': 'Đồng nghĩa: worsen, aggravate',
      'Nhãn (Tags)': 'C1, C2, IELTS Writing Task 2',
    },
    {
      'Từ vựng (Term)': 'Ubiquitous',
      'Phiên âm (IPA)': '/juːˈbɪk.wə.t̬əs/',
      'Từ loại': 'adjective',
      'Định nghĩa (Meaning)': 'Có mặt ở khắp nơi, phổ biến rộng rãi',
      'Ví dụ (Example)': 'Smartphones have become ubiquitous in modern everyday life.',
      'Dịch ví dụ': 'Điện thoại thông minh đã trở nên hiện diện ở khắp mọi nơi trong đời sống hiện đại.',
      'Cấu trúc ngữ pháp': 'become / remain ubiquitous',
      'Ghi chú / Mẹo nhớ': 'Đồng nghĩa: omnipresent, pervasive',
      'Nhãn (Tags)': 'C1, Academic, Technology',
    },
    {
      'Từ vựng (Term)': 'Take something with a pinch of salt',
      'Phiên âm (IPA)': '/teɪk ˈsʌm.θɪŋ wɪð ə pɪntʃ əv sɑːlt/',
      'Từ loại': 'idiom',
      'Định nghĩa (Meaning)': 'Tin có chừng mực, hoài nghi một phần',
      'Ví dụ (Example)': 'You should take the rumors on social media with a pinch of salt.',
      'Dịch ví dụ': 'Bạn nên tiếp nhận những tin đồn trên mạng xã hội với sự dè dặt, tỉnh táo.',
      'Cấu trúc ngữ pháp': 'take sth with a grain/pinch of salt',
      'Ghi chú / Mẹo nhớ': 'Thêm chút muối để đồ ăn bớt kỳ lạ -> nghe gì cũng nêm thêm sự tỉnh táo',
      'Nhãn (Tags)': 'Idiom, C1, Daily English',
    },
  ];

  const worksheet = XLSX.utils.json_to_sheet(sampleData);
  // Cài đặt độ rộng cột cho đẹp
  worksheet['!cols'] = [
    { wch: 25 }, // Term
    { wch: 22 }, // IPA
    { wch: 15 }, // POS
    { wch: 35 }, // Meaning
    { wch: 50 }, // Example
    { wch: 50 }, // Example translation
    { wch: 30 }, // Grammar
    { wch: 35 }, // Notes
    { wch: 25 }, // Tags
  ];

  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, worksheet, 'Flashcards_Template');
  XLSX.writeFile(workbook, 'Lexio_Flashcard_Template.xlsx');
}

/**
 * Tạo và tải xuống file CSV mẫu chuẩn
 */
export function downloadSampleCSV() {
  const sampleData = [
    {
      'Từ vựng (Term)': 'Pivotal',
      'Phiên âm (IPA)': '/ˈpɪv.ə.t̬əl/',
      'Từ loại': 'adjective',
      'Định nghĩa (Meaning)': 'Then chốt, có tính chất quyết định',
      'Ví dụ (Example)': 'The upcoming summit will play a pivotal role in negotiating the peace accord.',
      'Dịch ví dụ': 'Hội nghị thượng đỉnh sắp tới sẽ đóng vai trò then chốt trong đàm phán hiệp định hòa bình.',
      'Cấu trúc ngữ pháp': 'play a pivotal role in (doing) sth',
      'Ghi chú / Mẹo nhớ': 'Gốc từ "pivot" (trục quay) -> điểm trục cốt lõi, không thể thiếu',
      'Nhãn (Tags)': 'C1, C2, Academic, Formal',
    },
    {
      'Từ vựng (Term)': 'Exacerbate',
      'Phiên âm (IPA)': '/ɪɡˈzæs.ɚ.beɪt/',
      'Từ loại': 'verb',
      'Định nghĩa (Meaning)': 'Làm trầm trọng thêm, làm xấu đi tình hình',
      'Ví dụ (Example)': 'The economic crisis was exacerbated by a sudden surge in inflation.',
      'Dịch ví dụ': 'Khủng hoảng kinh tế càng bị trầm trọng thêm bởi sự gia tăng đột ngột của lạm phát.',
      'Cấu trúc ngữ pháp': 'exacerbate a problem/condition',
      'Ghi chú / Mẹo nhớ': 'Đồng nghĩa: worsen, aggravate',
      'Nhãn (Tags)': 'C1, C2, IELTS Writing Task 2',
    },
    {
      'Từ vựng (Term)': 'Ubiquitous',
      'Phiên âm (IPA)': '/juːˈbɪk.wə.t̬əs/',
      'Từ loại': 'adjective',
      'Định nghĩa (Meaning)': 'Có mặt ở khắp nơi, phổ biến rộng rãi',
      'Ví dụ (Example)': 'Smartphones have become ubiquitous in modern everyday life.',
      'Dịch ví dụ': 'Điện thoại thông minh đã trở nên hiện diện ở khắp mọi nơi trong đời sống hiện đại.',
      'Cấu trúc ngữ pháp': 'become / remain ubiquitous',
      'Ghi chú / Mẹo nhớ': 'Đồng nghĩa: omnipresent, pervasive',
      'Nhãn (Tags)': 'C1, Academic, Technology',
    },
    {
      'Từ vựng (Term)': 'Take something with a pinch of salt',
      'Phiên âm (IPA)': '/teɪk ˈsʌm.θɪŋ wɪð ə pɪntʃ əv sɑːlt/',
      'Từ loại': 'idiom',
      'Định nghĩa (Meaning)': 'Tin có chừng mực, hoài nghi một phần',
      'Ví dụ (Example)': 'You should take the rumors on social media with a pinch of salt.',
      'Dịch ví dụ': 'Bạn nên tiếp nhận những tin đồn trên mạng xã hội với sự dè dặt, tỉnh táo.',
      'Cấu trúc ngữ pháp': 'take sth with a grain/pinch of salt',
      'Ghi chú / Mẹo nhớ': 'Thêm chút muối để đồ ăn bớt kỳ lạ -> nghe gì cũng nêm thêm sự tỉnh táo',
      'Nhãn (Tags)': 'Idiom, C1, Daily English',
    },
  ];

  const csvString = Papa.unparse(sampleData);
  const blob = new Blob(['\ufeff' + csvString], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.setAttribute('href', url);
  link.setAttribute('download', 'Lexio_Flashcard_Template.csv');
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

/**
 * Khử mã độc Formula Injection (CWE-1236) khi xuất file CSV/Excel
 * Ngăn chặn phần mềm bảng tính tự động thực thi khi ô bắt đầu bằng =, +, -, @, \t, \r
 */
export function sanitizeForSpreadsheet(val: any): any {
  if (typeof val !== 'string') return val;
  if (/^[=+\-@\t\r]/.test(val) || /^[=+\-@]/.test(val.trim())) {
    return `'${val}`;
  }
  return val;
}

/**
 * Xuất danh sách thẻ ra file Excel (.xlsx) an toàn
 */
export function exportDeckToExcel(deckTitle: string, cards: Flashcard[]) {
  const exportData = cards.map((card, idx) => ({
    'STT': idx + 1,
    'Từ vựng / Cụm từ': sanitizeForSpreadsheet(card.term),
    'Phiên âm (IPA)': sanitizeForSpreadsheet(card.phonetic || ''),
    'Từ loại': sanitizeForSpreadsheet(card.partOfSpeech || ''),
    'Nghĩa tiếng Việt': sanitizeForSpreadsheet(card.definition),
    'Câu ví dụ': sanitizeForSpreadsheet(card.example || ''),
    'Dịch ví dụ': sanitizeForSpreadsheet(card.exampleTranslation || ''),
    'Cấu trúc ngữ pháp': sanitizeForSpreadsheet(card.grammarPattern || ''),
    'Ghi chú / Mẹo nhớ': sanitizeForSpreadsheet(card.notes || ''),
    'Nhãn (Tags)': sanitizeForSpreadsheet((card.tags || []).join(', ')),
    'Số lần ôn tập': card.reviewCount || 0,
    'Hệ số dễ (Ease)': card.easeFactor || 2.5,
  }));

  const worksheet = XLSX.utils.json_to_sheet(exportData);
  worksheet['!cols'] = [
    { wch: 6 },
    { wch: 25 },
    { wch: 20 },
    { wch: 15 },
    { wch: 35 },
    { wch: 45 },
    { wch: 45 },
    { wch: 30 },
    { wch: 30 },
    { wch: 20 },
    { wch: 12 },
    { wch: 12 },
  ];

  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, worksheet, 'Flashcards');
  const safeTitle = deckTitle.replace(/[^a-zA-Z0-9_-]/g, '_');
  XLSX.writeFile(workbook, `${safeTitle}_Flashcards.xlsx`);
}

/**
 * Xuất danh sách thẻ ra file CSV an toàn
 */
export function exportDeckToCSV(deckTitle: string, cards: Flashcard[]) {
  const exportData = cards.map((card) => ({
    Term: sanitizeForSpreadsheet(card.term),
    IPA: sanitizeForSpreadsheet(card.phonetic || ''),
    PartOfSpeech: sanitizeForSpreadsheet(card.partOfSpeech || ''),
    Definition: sanitizeForSpreadsheet(card.definition),
    Example: sanitizeForSpreadsheet(card.example || ''),
    ExampleTranslation: sanitizeForSpreadsheet(card.exampleTranslation || ''),
    GrammarPattern: sanitizeForSpreadsheet(card.grammarPattern || ''),
    Notes: sanitizeForSpreadsheet(card.notes || ''),
    Tags: sanitizeForSpreadsheet((card.tags || []).join(',')),
  }));

  const csvString = Papa.unparse(exportData);
  const blob = new Blob(['\ufeff' + csvString], { type: 'text/csv;charset=utf-8;' }); // UTF-8 BOM
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.setAttribute('href', url);
  const safeTitle = deckTitle.replace(/[^a-zA-Z0-9_-]/g, '_');
  link.setAttribute('download', `${safeTitle}_Flashcards.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
