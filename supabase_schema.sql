-- ==============================================================================
-- SCHEMA KHỞI TẠO CƠ SỞ DỮ LIỆU LEXIO PRO TRÊN SUPABASE (POSTGRESQL)
-- Chạy đoạn mã này trong: Supabase Dashboard -> SQL Editor -> New Query -> Run
-- ==============================================================================

-- 1. Tạo bảng lưu trữ Bộ Thẻ (Decks)
create table if not exists public.decks (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  description text default '',
  language text default 'en-US',
  target_language text default 'vi-VN',
  category text default 'Chung',
  tags text[] default '{}',
  color text default '#6366f1',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. Tạo bảng lưu trữ Thẻ Ghi Nhớ (Flashcards)
create table if not exists public.cards (
  id text primary key,
  deck_id text references public.decks(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  term text not null,
  phonetic text,
  part_of_speech text,
  definition text not null,
  example text,
  example_translation text,
  grammar_pattern text,
  notes text,
  tags text[] default '{}',
  starred boolean default false,
  -- Thuật toán Spaced Repetition SM-2
  repetition int default 0,
  interval int default 1,
  ease_factor numeric(4,2) default 2.50,
  due_date timestamptz default now(),
  last_reviewed timestamptz,
  review_count int default 0,
  lapses int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 3. Bật Row Level Security (RLS) để đảm bảo bảo mật tuyệt đối
alter table public.decks enable row level security;
alter table public.cards enable row level security;

-- 4. Chính sách phân quyền RLS: Mỗi user chỉ xem, sửa, xóa dữ liệu của chính mình
drop policy if exists "User decks isolation" on public.decks;
create policy "User decks isolation"
  on public.decks for all
  using (auth.uid() = user_id);

drop policy if exists "User cards isolation" on public.cards;
create policy "User cards isolation"
  on public.cards for all
  using (auth.uid() = user_id);

-- 5. Chỉ mục tăng tốc truy vấn (Indexes)
create index if not exists idx_decks_user_id on public.decks(user_id);
create index if not exists idx_cards_deck_id on public.cards(deck_id);
create index if not exists idx_cards_user_id on public.cards(user_id);
create index if not exists idx_cards_due_date on public.cards(due_date);
