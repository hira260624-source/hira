-- ============================================================
-- 히라 사이트 Supabase 셋업 (멱등 — 여러 번 RUN 해도 안전)
-- Supabase 대시보드 → SQL Editor 에 붙여넣고 RUN
-- ============================================================

-- ───────── 프로필 (site_settings: key→value) ─────────
create table if not exists public.site_settings (
  key        text primary key,
  value      text,
  updated_at timestamptz default now()
);
alter table public.site_settings enable row level security;
drop policy if exists "public read settings" on public.site_settings;
drop policy if exists "auth write settings"  on public.site_settings;
create policy "public read settings" on public.site_settings for select using (true);
create policy "auth write settings"  on public.site_settings for all to authenticated using (true) with check (true);

-- ───────── 업보: 컬럼(업보 종류) ─────────
create table if not exists public.upbo_types (
  id         uuid default gen_random_uuid() primary key,
  name       text not null,
  color      text,
  sort_order int default 0,
  created_at timestamptz default now()
);
alter table public.upbo_types enable row level security;
drop policy if exists "public read types" on public.upbo_types;
drop policy if exists "auth write types"  on public.upbo_types;
create policy "public read types" on public.upbo_types for select using (true);
create policy "auth write types"  on public.upbo_types for all to authenticated using (true) with check (true);

-- ───────── 업보: 행(시청자) — counts jsonb { "<type_id>": n } ─────────
create table if not exists public.upbo_viewers (
  id         uuid default gen_random_uuid() primary key,
  name       text not null,
  counts     jsonb default '{}'::jsonb,
  sort_order int default 0,
  created_at timestamptz default now()
);
alter table public.upbo_viewers enable row level security;
drop policy if exists "public read viewers" on public.upbo_viewers;
drop policy if exists "auth write viewers"  on public.upbo_viewers;
create policy "public read viewers" on public.upbo_viewers for select using (true);
create policy "auth write viewers"  on public.upbo_viewers for all to authenticated using (true) with check (true);

-- ───────── 프로필 기본값 시드 (인테이크) — 없을 때만 ─────────
insert into public.site_settings (key, value) values
  ('name','히라'),
  ('reading','ヒラ · HIRA'),
  ('bio','기미라다. 8시에 온다. 쓰껄하러 와라.'),
  ('birthday','2002. 08. 23'),
  ('debut','2024. 03. 17'),
  ('mbti','einTfp'),
  ('gender','여'),
  ('personality','밝음 · 변태'),
  ('agency',''),
  ('fandom','꾸이 · 꾸이단'),
  ('schedule','저녁 8시 고정 (수 · 토 휴방)'),
  ('content','소통 · 종겜 · 노래'),
  ('games','스팀 종겜 · 그 외 메이저 게임'),
  ('music','K-POP · J-POP · 인디 · 감성힙합'),
  ('likes',''),
  ('dislikes',''),
  ('channel','https://www.sooplive.com/station/sjsr4611'),
  ('youtube','https://www.youtube.com/@%EC%9A%B0%EC%A3%BC%EC%B1%84%EA%B0%95%ED%9E%88%EB%9D%BC'),
  ('cafe','https://cafe.naver.com/hirarara'),
  ('songclip','https://vod.sooplive.com/player/189985747')
on conflict (key) do nothing;

-- ───────── 업보 종류 시드 예시 — 테이블 비었을 때만 ─────────
insert into public.upbo_types (name, color, sort_order)
select v.name, v.color, v.sort_order
from (values
  ('단컷방셀','#ffb3d1',1),
  ('움짤방셀','#c5b8e8',2),
  ('노래방셀','#a8d8d4',3)
) as v(name,color,sort_order)
where not exists (select 1 from public.upbo_types);
