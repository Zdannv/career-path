-- ===========================================================================
-- 0045_feedback.sql
--
-- Kotak masukan untuk menu "Support" dan "Feedback".
--
-- Siapa pun boleh mengirim, termasuk pengunjung yang belum masuk: halaman
-- bantuan juga dipakai orang yang justru tidak bisa login. Tidak ada yang
-- boleh MEMBACA lewat API publik; isinya dibaca tim lewat dashboard Supabase
-- (service role melewati RLS).
--
-- user_id tidak dipercaya dari klien. Trigger mengisinya dengan auth.uid(),
-- jadi pengunjung tidak bisa mengirim masukan atas nama akun lain.
--
-- Kategori "hapus_data" adalah jalur resmi permintaan penghapusan akun dan
-- data yang dijanjikan di Kebijakan Privasi.
--
-- Jalankan setelah 0044. Aman diulang.
-- ===========================================================================

begin;

create table if not exists public.feedback (
  id          bigint generated always as identity primary key,
  user_id     uuid references auth.users (id) on delete set null,
  kategori    text not null
              check (kategori in ('saran', 'masalah', 'pertanyaan', 'hapus_data', 'lainnya')),
  rating      smallint check (rating between 1 and 5),
  pesan       text not null check (char_length(btrim(pesan)) between 10 and 2000),
  email       text check (email is null or (char_length(email) <= 254 and email like '%_@_%._%')),
  halaman     text check (halaman is null or char_length(halaman) <= 300),
  user_agent  text check (user_agent is null or char_length(user_agent) <= 500),
  status      text not null default 'baru' check (status in ('baru', 'diproses', 'selesai')),
  created_at  timestamptz not null default now()
);

create index if not exists feedback_created_at_idx on public.feedback (created_at desc);
create index if not exists feedback_status_idx on public.feedback (status) where status <> 'selesai';

create or replace function public.feedback_isi_pengirim()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.user_id := auth.uid();
  new.status := 'baru';
  new.created_at := now();
  -- Pengguna yang masuk tidak perlu mengetik email; ambil dari akunnya.
  if new.email is null and new.user_id is not null then
    select u.email into new.email from auth.users u where u.id = new.user_id;
  end if;
  return new;
end;
$$;

drop trigger if exists feedback_isi_pengirim on public.feedback;
create trigger feedback_isi_pengirim
  before insert on public.feedback
  for each row execute function public.feedback_isi_pengirim();

alter table public.feedback enable row level security;

drop policy if exists "siapa pun boleh mengirim masukan" on public.feedback;
create policy "siapa pun boleh mengirim masukan"
  on public.feedback for insert
  to anon, authenticated
  with check (true);

-- Hanya INSERT. Tanpa policy SELECT/UPDATE/DELETE, isi tabel tertutup bagi
-- klien; klien juga tidak perlu membaca balik barisnya (insert tanpa
-- .select()).
revoke all on public.feedback from anon, authenticated;
grant insert on public.feedback to anon, authenticated;

commit;
