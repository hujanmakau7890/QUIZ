-- ============================================================
-- SKEMA DATABASE QUIZ & PAPAN PARTISIPASI (SUPABASE)
-- ============================================================

-- 1. Tabel Sesi Pelatihan / Kelas
CREATE TABLE IF NOT EXISTS public.quiz_sessions (
    code TEXT PRIMARY KEY,                       -- Contoh: 'KELAS-7K2M'
    title TEXT NOT NULL DEFAULT 'Pelatihan Baru',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. Tabel Peserta (Hasil scan QR & isi form)
CREATE TABLE IF NOT EXISTS public.quiz_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_code TEXT NOT NULL REFERENCES public.quiz_sessions(code) ON DELETE CASCADE,
    name TEXT NOT NULL,
    division TEXT DEFAULT '',
    total_points INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_session_participant UNIQUE (session_code, name)
);

-- 3. Tabel Log / Riwayat Poin (Termasuk Poin Interaktif & Kuis)
CREATE TABLE IF NOT EXISTS public.quiz_point_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_code TEXT NOT NULL REFERENCES public.quiz_sessions(code) ON DELETE CASCADE,
    participant_id UUID NOT NULL REFERENCES public.quiz_participants(id) ON DELETE CASCADE,
    category TEXT NOT NULL,                      -- 'quiz', 'ask', 'crit', 'ans', 'minus'
    points INT NOT NULL,                         -- Nilai perubahan (+10, +5, -2, dsb)
    description TEXT DEFAULT '',                 -- Catatan / Judul Soal
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 4. Tabel Bank Soal Kuis
CREATE TABLE IF NOT EXISTS public.quiz_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_code TEXT REFERENCES public.quiz_sessions(code) ON DELETE CASCADE,
    question TEXT NOT NULL,
    options JSONB NOT NULL,                      -- ["Pilihan A", "Pilihan B", "Pilihan C", "Pilihan D"]
    correct_index INT NOT NULL,                  -- Index jawaban benar (0, 1, 2, atau 3)
    points INT NOT NULL DEFAULT 10,              -- Poin jika benar
    explanation TEXT DEFAULT '',                 -- Pembahasan / learning points
    order_num INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 5. Tabel Jawaban Peserta
CREATE TABLE IF NOT EXISTS public.quiz_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_code TEXT NOT NULL REFERENCES public.quiz_sessions(code) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES public.quiz_questions(id) ON DELETE CASCADE,
    participant_id UUID NOT NULL REFERENCES public.quiz_participants(id) ON DELETE CASCADE,
    selected_index INT NOT NULL,
    is_correct BOOLEAN NOT NULL,
    points_awarded INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_participant_question UNIQUE (participant_id, question_id)
);

-- ============================================================
-- KEAMANAN: ROW LEVEL SECURITY (RLS) UNTUK ANON KEY
-- ============================================================
ALTER TABLE public.quiz_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_point_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_submissions ENABLE ROW LEVEL SECURITY;

-- Beri izin akses baca & tulis penuh untuk anon key di web app
CREATE POLICY "Allow public all on quiz_sessions" ON public.quiz_sessions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public all on quiz_participants" ON public.quiz_participants FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public all on quiz_point_logs" ON public.quiz_point_logs FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public all on quiz_questions" ON public.quiz_questions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public all on quiz_submissions" ON public.quiz_submissions FOR ALL USING (true) WITH CHECK (true);

-- ============================================================
-- AKTIFKAN SUPABASE REALTIME
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.quiz_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.quiz_participants;
ALTER PUBLICATION supabase_realtime ADD TABLE public.quiz_point_logs;
ALTER PUBLICATION supabase_realtime ADD TABLE public.quiz_questions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.quiz_submissions;
