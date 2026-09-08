import Foundation

public struct SampleData {
    public static func defaultDecks() -> [Deck] {
        let deck1 = Deck(
            id: "deck-c1-advanced",
            title: "Oxford 3000 & 5000 C1-C2 Academic Mastery",
            description: "Bộ từ vựng học thuật đỉnh cao phục vụ IELTS 8.0+, GRE, TOEFL iBT và đàm phán quốc tế.",
            language: "en-US",
            targetLanguage: "vi-VN",
            category: "Tiếng Anh Học Thuật",
            tags: ["C1", "C2", "IELTS", "Academic"],
            colorHex: "#FF2A6D",
            cards: [
                Flashcard(
                    id: "card-1",
                    term: "Pivotal",
                    phonetic: "/ˈpɪv.ə.t̬əl/",
                    partOfSpeech: "adjective",
                    definition: "Then chốt, có tính chất quyết định thay đổi toàn bộ cục diện",
                    example: "The upcoming summit will play a pivotal role in negotiating the peace accord.",
                    exampleTranslation: "Hội nghị thượng đỉnh sắp tới sẽ đóng vai trò then chốt trong việc đàm phán hiệp định hòa bình.",
                    grammarPattern: "play a pivotal role in (doing) sth",
                    notes: "Gốc từ 'pivot' (trục xoay) -> điểm trọng tâm không thể thiếu",
                    tags: ["C1", "IELTS Writing", "Formal"]
                ),
                Flashcard(
                    id: "card-2",
                    term: "Exacerbate",
                    phonetic: "/ɪɡˈzæs.ɚ.beɪt/",
                    partOfSpeech: "verb",
                    definition: "Làm trầm trọng thêm, làm xấu đi một tình huống tiêu cực vốn có",
                    example: "The economic crisis was exacerbated by a sudden surge in inflation.",
                    exampleTranslation: "Cuộc khủng hoảng kinh tế càng bị trầm trọng thêm bởi sự gia tăng đột ngột của lạm phát.",
                    grammarPattern: "exacerbate a problem/condition",
                    notes: "Đồng nghĩa: worsen, aggravate. Trái nghĩa: alleviate, mitigate",
                    tags: ["C1", "C2", "Writing Task 2"]
                ),
                Flashcard(
                    id: "card-3",
                    term: "Ubiquitous",
                    phonetic: "/juːˈbɪk.wə.t̬əs/",
                    partOfSpeech: "adjective",
                    definition: "Có mặt ở khắp mọi nơi, phổ biến tràn ngập trong đời sống",
                    example: "Smartphones and wireless internet have become ubiquitous in modern society.",
                    exampleTranslation: "Điện thoại thông minh và internet không dây đã trở nên hiện diện ở khắp mọi nơi trong xã hội hiện đại.",
                    grammarPattern: "become / remain ubiquitous",
                    notes: "Đồng nghĩa: omnipresent, pervasive, universal",
                    tags: ["C1", "Technology", "Reading"]
                ),
                Flashcard(
                    id: "card-4",
                    term: "Mitigate",
                    phonetic: "/ˈmɪt̬.ə.ɡeɪt/",
                    partOfSpeech: "verb",
                    definition: "Làm dịu bớt, giảm nhẹ mức độ nghiêm trọng hoặc thiệt hại",
                    example: "The government took emergency measures to mitigate the environmental impact.",
                    exampleTranslation: "Chính phủ đã áp dụng các biện pháp khẩn cấp nhằm giảm nhẹ tác động môi trường.",
                    grammarPattern: "mitigate risks / damage / effects",
                    notes: "Đồng nghĩa: lessen, alleviate, soften",
                    tags: ["C1", "Policy", "Environment"]
                ),
                Flashcard(
                    id: "card-5",
                    term: "Pragmatic",
                    phonetic: "/præɡˈmæt̬.ɪk/",
                    partOfSpeech: "adjective",
                    definition: "Thực tế, thực dụng, dựa trên tính khả thi thay vì lý thuyết suông",
                    example: "We need to adopt a pragmatic approach to resolve this complex challenge.",
                    exampleTranslation: "Chúng ta cần áp dụng một phương pháp tiếp cận thực tế để giải quyết thách thức phức tạp này.",
                    grammarPattern: "a pragmatic approach / solution to sth",
                    notes: "Đồng nghĩa: practical, realistic, down-to-earth",
                    tags: ["C1", "Business", "Speaking"]
                ),
                Flashcard(
                    id: "card-6",
                    term: "Take something with a pinch of salt",
                    phonetic: "/teɪk ˈsʌm.θɪŋ wɪð ə pɪntʃ əv sɑːlt/",
                    partOfSpeech: "idiom",
                    definition: "Tiếp nhận thông tin với sự thận trọng, dè dặt hoài nghi",
                    example: "You should take the anonymous rumors on social media with a pinch of salt.",
                    exampleTranslation: "Bạn nên tiếp nhận các tin đồn ẩn danh trên mạng xã hội với sự dè dặt, tỉnh táo.",
                    grammarPattern: "take sth with a grain / pinch of salt",
                    notes: "Thêm chút muối để món ăn dễ nuốt -> nghe gì cũng nêm thêm sự tỉnh táo",
                    tags: ["Idiom", "C1", "Colloquial"]
                )
            ]
        )
        
        let deck2 = Deck(
            id: "deck-tech-ai",
            title: "Artificial Intelligence & Software Engineering",
            description: "Thuật ngữ tiếng Anh chuyên ngành Trí Tuệ Nhân Tạo, Cloud Computing và Kiến trúc Hệ thống.",
            language: "en-US",
            targetLanguage: "vi-VN",
            category: "Công Nghệ Thông Tin",
            tags: ["AI", "Tech", "Software", "Cloud"],
            colorHex: "#06B6D4",
            cards: [
                Flashcard(
                    id: "card-tech-1",
                    term: "Idempotent",
                    phonetic: "/ˌaɪ.dɛmˈpoʊ.tənt/",
                    partOfSpeech: "adjective",
                    definition: "Bảo toàn kết quả: Thực hiện nhiều lần vẫn ra cùng một trạng thái như một lần duy nhất (REST API PUT/DELETE)",
                    example: "Making payment requests idempotent prevents users from being double-charged during network retry.",
                    exampleTranslation: "Thiết kế các yêu cầu thanh toán có tính idempotent giúp tránh trừ tiền 2 lần khi thử lại kết nối mạng.",
                    grammarPattern: "idempotent operation / endpoint",
                    notes: "Cốt lõi trong hệ thống phân tán và thanh toán trực tuyến",
                    tags: ["API", "Architecture", "Backend"]
                ),
                Flashcard(
                    id: "card-tech-2",
                    term: "Latency",
                    phonetic: "/ˈleɪ.tən.si/",
                    partOfSpeech: "noun",
                    definition: "Độ trễ thời gian giữa yêu cầu của client và phản hồi từ hệ thống",
                    example: "Edge computing significantly reduces latency for real-time video streaming.",
                    exampleTranslation: "Điện toán biên giúp giảm độ trễ đáng kể cho truyền tải video thời gian thực.",
                    grammarPattern: "ultra-low latency / reduce latency",
                    notes: "Đo bằng mili-giây (ms)",
                    tags: ["Network", "Cloud", "Performance"]
                ),
                Flashcard(
                    id: "card-tech-3",
                    term: "Vector Embeddings",
                    phonetic: "/ˈvɛk.tɚ ɛmˈbɛd.ɪŋz/",
                    partOfSpeech: "noun",
                    definition: "Biểu diễn ngữ nghĩa của văn bản hoặc hình ảnh dưới dạng các mảng số đa chiều trong mô hình AI/LLM",
                    example: "Semantic search relies on comparing vector embeddings in a high-dimensional space.",
                    exampleTranslation: "Tìm kiếm ngữ nghĩa dựa trên việc so sánh các vector embeddings trong không gian đa chiều.",
                    grammarPattern: "generate / query vector embeddings",
                    notes: "Nền tảng của RAG (Retrieval-Augmented Generation)",
                    tags: ["AI", "Machine Learning", "LLM"]
                )
            ]
        )
        
        return [deck1, deck2]
    }
}
