-- ============================================================
-- SKEMA DATABASE PAPAN PARTISIPASI & Q&A APPROVAL (SUPABASE)
-- ============================================================

-- 1. Tabel Sesi Pelatihan / Kelas
CREATE TABLE IF NOT EXISTS public.quiz_sessions (
    code TEXT PRIMARY KEY,                       -- Contoh: 'KELAS-7K2M'
    title TEXT NOT NULL DEFAULT 'Pelatihan Baru',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. Tabel Peserta (Hasil scan QR & isi form nama di HP)
CREATE TABLE IF NOT EXISTS public.quiz_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_code TEXT NOT NULL REFERENCES public.quiz_sessions(code) ON DELETE CASCADE,
    name TEXT NOT NULL,
    division TEXT DEFAULT '',
    total_points INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_session_participant UNIQUE (session_code, name)
);

-- 3. Tabel Log / Riwayat Poin Partisipasi
CREATE TABLE IF NOT EXISTS public.quiz_point_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_code TEXT NOT NULL REFERENCES public.quiz_sessions(code) ON DELETE CASCADE,
    participant_id UUID NOT NULL REFERENCES public.quiz_participants(id) ON DELETE CASCADE,
    category TEXT NOT NULL,                      -- 'ask', 'crit', 'ans', 'minus'
    points INT NOT NULL,                         -- Nilai perubahan (+5, +10, -2, dsb)
    description TEXT DEFAULT '',                 -- Catatan / Isi pertanyaan
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 4. Tabel Pengajuan Pertanyaan / Tanggapan dari Peserta (Menunggu Persetujuan Panitia)
CREATE TABLE IF NOT EXISTS public.class_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_code TEXT NOT NULL REFERENCES public.quiz_sessions(code) ON DELETE CASCADE,
    participant_id UUID NOT NULL REFERENCES public.quiz_participants(id) ON DELETE CASCADE,
    participant_name TEXT NOT NULL,
    participant_division TEXT DEFAULT '',
    category TEXT NOT NULL DEFAULT 'ask',        -- 'ask' (Bertanya), 'crit' (Tanggapan Kritis), 'ans' (Menjawab)
    question_text TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',      -- 'pending', 'approved', 'rejected'
    points_awarded INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ============================================================
-- KEAMANAN: ROW LEVEL SECURITY (RLS) UNTUK ANON KEY
-- ============================================================
ALTER TABLE public.quiz_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_point_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public all on quiz_sessions" ON public.quiz_sessions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public all on quiz_participants" ON public.quiz_participants FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public all on quiz_point_logs" ON public.quiz_point_logs FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public all on class_questions" ON public.class_questions FOR ALL USING (true) WITH CHECK (true);

-- ============================================================
-- AKTIFKAN SUPABASE REALTIME
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.quiz_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.quiz_participants;
ALTER PUBLICATION supabase_realtime ADD TABLE public.quiz_point_logs;
ALTER PUBLICATION supabase_realtime ADD TABLE public.class_questions;
