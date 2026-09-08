import Foundation

public struct CSVService {
    /// Khử Formula Injection (CWE-1236) khi xuất file
    public static func sanitizeCell(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("=") || trimmed.hasPrefix("+") || trimmed.hasPrefix("-") || trimmed.hasPrefix("@") || trimmed.hasPrefix("\t") {
            return "'\(trimmed)"
        }
        return text
    }
    
    /// Xuất danh sách thẻ ra chuỗi CSV an toàn
    public static func exportDeckToCSV(deck: Deck) -> String {
        var csv = "\u{FEFF}" // UTF-8 BOM cho Excel hiển thị đúng tiếng Việt
        csv += "Term,Phonetic,PartOfSpeech,Definition,Example,ExampleTranslation,GrammarPattern,Notes,Tags\n"
        
        for card in deck.cards {
            let term = escapeCSV(sanitizeCell(card.term))
            let phonetic = escapeCSV(sanitizeCell(card.phonetic ?? ""))
            let pos = escapeCSV(sanitizeCell(card.partOfSpeech ?? ""))
            let definition = escapeCSV(sanitizeCell(card.definition))
            let example = escapeCSV(sanitizeCell(card.example ?? ""))
            let translation = escapeCSV(sanitizeCell(card.exampleTranslation ?? ""))
            let grammar = escapeCSV(sanitizeCell(card.grammarPattern ?? ""))
            let notes = escapeCSV(sanitizeCell(card.notes ?? ""))
            let tags = escapeCSV(sanitizeCell(card.tags.joined(separator: "; ")))
            
            csv += "\(term),\(phonetic),\(pos),\(definition),\(example),\(translation),\(grammar),\(notes),\(tags)\n"
        }
        
        return csv
    }
    
    /// Xuất danh sách thẻ ra chuỗi CSV thuần (không BOM, không thêm nháy đơn khử formula) để hiển thị trong trình soạn thảo CSV trực tiếp
    public static func cardsToCSVString(cards: [Flashcard]) -> String {
        var csv = "Term,Phonetic,PartOfSpeech,Definition,Example,ExampleTranslation,GrammarPattern,Notes,Tags\n"
        for card in cards {
            let term = escapeCSV(card.term)
            let phonetic = escapeCSV(card.phonetic ?? "")
            let pos = escapeCSV(card.partOfSpeech ?? "")
            let definition = escapeCSV(card.definition)
            let example = escapeCSV(card.example ?? "")
            let translation = escapeCSV(card.exampleTranslation ?? "")
            let grammar = escapeCSV(card.grammarPattern ?? "")
            let notes = escapeCSV(card.notes ?? "")
            let tags = escapeCSV(card.tags.joined(separator: "; "))
            
            csv += "\(term),\(phonetic),\(pos),\(definition),\(example),\(translation),\(grammar),\(notes),\(tags)\n"
        }
        return csv
    }
    
    /// Dòng thẻ mẫu chuẩn cho nút Chèn Dòng Mẫu
    public static func sampleCardCSVRow() -> String {
        return "Eloquent,/ˈel.ə.kwənt/,adjective,\"Có tài hùng biện, diễn đạt lưu loát và thuyết phục\",\"She gave an eloquent speech that moved the entire audience.\",\"Cô ấy đã có bài phát biểu hùng hồn làm lay động cả khán phòng.\",\"an eloquent speech / speaker\",\"Gốc Latin: loqui (nói) -> người nói giỏi\",\"C1; Academic; Communication\""
    }
    
    /// Chuỗi CSV mẫu chuẩn kèm dữ liệu thực tế để người dùng tham khảo và nạp đúng cấu trúc
    public static func generateSampleCSV() -> String {
        var csv = "\u{FEFF}" // UTF-8 BOM cho Excel / Numbers / TextEdit hiển thị chuẩn tiếng Việt
        csv += "Term,Phonetic,PartOfSpeech,Definition,Example,ExampleTranslation,GrammarPattern,Notes,Tags\n"
        
        let sampleRows: [(term: String, phonetic: String, pos: String, def: String, ex: String, trans: String, grammar: String, notes: String, tags: String)] = [
            (
                "Pivotal",
                "/ˈpɪv.ə.t̬əl/",
                "adjective",
                "Then chốt, có tính chất quyết định",
                "The upcoming summit will play a pivotal role in negotiating the peace accord.",
                "Hội nghị thượng đỉnh sắp tới sẽ đóng vai trò then chốt trong đàm phán hiệp định hòa bình.",
                "play a pivotal role in (doing) sth",
                "Gốc từ \"pivot\" (trục quay) -> điểm trục cốt lõi, không thể thiếu",
                "C1; Academic; Formal"
            ),
            (
                "Exacerbate",
                "/ɪɡˈzæs.ɚ.beɪt/",
                "verb",
                "Làm trầm trọng thêm, làm xấu đi tình hình",
                "The economic crisis was exacerbated by a sudden surge in inflation.",
                "Khủng hoảng kinh tế càng bị trầm trọng thêm bởi sự gia tăng đột ngột của lạm phát.",
                "exacerbate a problem/condition",
                "Đồng nghĩa: worsen, aggravate",
                "C1; C2; IELTS Writing Task 2"
            ),
            (
                "Ubiquitous",
                "/juːˈbɪk.wə.t̬əs/",
                "adjective",
                "Có mặt ở khắp nơi, phổ biến rộng rãi",
                "Smartphones have become ubiquitous in modern everyday life.",
                "Điện thoại thông minh đã trở nên hiện diện ở khắp mọi nơi trong đời sống hiện đại.",
                "become / remain ubiquitous",
                "Đồng nghĩa: omnipresent, pervasive",
                "C1; Academic; Technology"
            ),
            (
                "Take something with a pinch of salt",
                "/teɪk ˈsʌm.θɪŋ wɪð ə pɪntʃ əv sɑːlt/",
                "idiom",
                "Tin có chừng mực, hoài nghi một phần",
                "You should take the rumors on social media with a pinch of salt.",
                "Bạn nên tiếp nhận những tin đồn trên mạng xã hội với sự dè dặt, tỉnh táo.",
                "take sth with a grain/pinch of salt",
                "Thêm chút muối để đồ ăn bớt kỳ lạ -> nghe gì cũng nêm thêm sự tỉnh táo",
                "Idiom; C1; Daily English"
            )
        ]
        
        for row in sampleRows {
            let term = escapeCSV(sanitizeCell(row.term))
            let phonetic = escapeCSV(sanitizeCell(row.phonetic))
            let pos = escapeCSV(sanitizeCell(row.pos))
            let definition = escapeCSV(sanitizeCell(row.def))
            let example = escapeCSV(sanitizeCell(row.ex))
            let translation = escapeCSV(sanitizeCell(row.trans))
            let grammar = escapeCSV(sanitizeCell(row.grammar))
            let notes = escapeCSV(sanitizeCell(row.notes))
            let tags = escapeCSV(sanitizeCell(row.tags))
            
            csv += "\(term),\(phonetic),\(pos),\(definition),\(example),\(translation),\(grammar),\(notes),\(tags)\n"
        }
        
        return csv
    }
    
    private static func escapeCSV(_ text: String) -> String {
        var escaped = text.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            escaped = "\"\(escaped)\""
        }
        return escaped
    }
    
    /// Khử tiền tố nháy đơn an toàn khi đọc lại các ô được xuất từ bảng tính
    private static func cleanCell(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("'") && trimmed.count > 1 {
            let second = trimmed[trimmed.index(after: trimmed.startIndex)]
            if second == "=" || second == "+" || second == "-" || second == "@" || second == "\t" {
                return String(trimmed.dropFirst())
            }
        }
        return trimmed
    }
    
    /// Nhập nội dung CSV thành danh sách Flashcard
    public static func parseCSV(content: String) -> [Flashcard] {
        let rows = parseCSVRows(content)
        guard rows.count > 1 else { return [] }
        
        // Header line
        let headers = rows[0].map { normalizeHeader($0) }
        
        var termIdx = -1
        var phoneticIdx = -1
        var posIdx = -1
        var defIdx = -1
        var exIdx = -1
        var transIdx = -1
        var grammarIdx = -1
        var notesIdx = -1
        var tagsIdx = -1
        
        for (i, h) in headers.enumerated() {
            if termIdx == -1 && (h == "term" || h == "word" || h.contains("tuvung") || h.contains("vocab") || h.contains("thuatngu") || h == "tu") {
                termIdx = i
            } else if phoneticIdx == -1 && (h.contains("phon") || h.contains("ipa") || h.contains("phienam") || h.contains("phatam") || h.contains("pronun")) {
                phoneticIdx = i
            } else if posIdx == -1 && (h.contains("partofspeech") || h == "pos" || h.contains("loaitu") || h.contains("tuloai") || h.contains("tucloai") || h == "type") {
                posIdx = i
            } else if transIdx == -1 && (((h.contains("trans") || h.contains("dich")) && (h.contains("ex") || h.contains("vidu") || h.contains("cau"))) || h.contains("dichcau") || h.contains("dichvidu") || h == "exampletranslation" || h == "translation") {
                transIdx = i
            } else if grammarIdx == -1 && (h.contains("gram") || h.contains("pattern") || h.contains("cautruc") || h.contains("nguphap") || h.contains("struc") || h.contains("formula")) {
                grammarIdx = i
            } else if exIdx == -1 && (h.contains("example") || h.contains("vidu") || h.contains("sentence") || h.contains("cauvidu") || h == "cau") {
                exIdx = i
            } else if defIdx == -1 && (h.contains("def") || h.contains("mean") || h.contains("nghia") || h.contains("dinhnghia") || h.contains("giainghia") || h.contains("vietnamese") || h == "dich") {
                defIdx = i
            } else if notesIdx == -1 && (h.contains("note") || h.contains("ghichu") || h.contains("meonho") || h.contains("luuy") || h.contains("mnemonic") || h == "ghi") {
                notesIdx = i
            } else if tagsIdx == -1 && (h.contains("tag") || h.contains("nhan") || h.contains("chude") || h.contains("topic") || h.contains("level")) {
                tagsIdx = i
            }
        }
        
        // Mặc định dự phòng nếu chưa nhận diện được Term hoặc Definition
        if termIdx == -1 && headers.count > 0 {
            termIdx = 0
        }
        if defIdx == -1 && headers.count > 1 {
            defIdx = (termIdx == 0) ? 1 : 0
        }
        
        var cards: [Flashcard] = []
        
        for lineIdx in 1..<rows.count {
            let row = rows[lineIdx]
            guard row.count > max(termIdx, defIdx) else { continue }
            
            let term = cleanCell(row[termIdx])
            let def = cleanCell(row[defIdx])
            guard !term.isEmpty && !def.isEmpty else { continue }
            
            let phonetic = (phoneticIdx >= 0 && phoneticIdx < row.count) ? cleanCell(row[phoneticIdx]) : nil
            let pos = (posIdx >= 0 && posIdx < row.count) ? cleanCell(row[posIdx]) : nil
            let ex = (exIdx >= 0 && exIdx < row.count) ? cleanCell(row[exIdx]) : nil
            let trans = (transIdx >= 0 && transIdx < row.count) ? cleanCell(row[transIdx]) : nil
            let grammar = (grammarIdx >= 0 && grammarIdx < row.count) ? cleanCell(row[grammarIdx]) : nil
            let notes = (notesIdx >= 0 && notesIdx < row.count) ? cleanCell(row[notesIdx]) : nil
            
            var tags: [String] = []
            if tagsIdx >= 0 && tagsIdx < row.count {
                let tagsStr = cleanCell(row[tagsIdx])
                tags = tagsStr.components(separatedBy: CharacterSet(charactersIn: ";,")).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            }
            
            let card = Flashcard(
                term: term,
                phonetic: phonetic?.isEmpty == false ? phonetic : nil,
                partOfSpeech: pos?.isEmpty == false ? pos : nil,
                definition: def,
                example: ex?.isEmpty == false ? ex : nil,
                exampleTranslation: trans?.isEmpty == false ? trans : nil,
                grammarPattern: grammar?.isEmpty == false ? grammar : nil,
                notes: notes?.isEmpty == false ? notes : nil,
                tags: tags
            )
            cards.append(card)
        }
        
        return cards
    }
    
    private static func normalizeHeader(_ h: String) -> String {
        return h.lowercased()
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "d")
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
    }
    
    /// Phân tích toàn bộ chuỗi CSV thành ma trận hàng và cột tuân thủ chuẩn RFC-4180
    public static func parseCSVRows(_ content: String) -> [[String]] {
        var cleanContent = content
        if cleanContent.hasPrefix("\u{FEFF}") {
            cleanContent.removeFirst()
        }
        
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false
        let chars = Array(cleanContent)
        var i = 0
        
        while i < chars.count {
            let char = chars[i]
            if char == "\"" {
                if inQuotes && i + 1 < chars.count && chars[i + 1] == "\"" {
                    // RFC-4180: "" -> "
                    currentField.append("\"")
                    i += 1
                } else {
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                currentRow.append(currentField)
                currentField = ""
            } else if (char == "\r" || char == "\n") && !inQuotes {
                if char == "\r" && i + 1 < chars.count && chars[i + 1] == "\n" {
                    i += 1
                }
                currentRow.append(currentField)
                currentField = ""
                if currentRow.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                    rows.append(currentRow)
                }
                currentRow = []
            } else {
                currentField.append(char)
            }
            i += 1
        }
        
        currentRow.append(currentField)
        if currentRow.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    public static func parseCSVLine(_ line: String) -> [String] {
        return parseCSVRows(line).first ?? []
    }
}
