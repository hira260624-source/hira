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

-- ───────── 업보: 시즌(월별) ─────────
create table if not exists public.upbo_seasons (
  id         uuid default gen_random_uuid() primary key,
  name       text not null,
  sort_order int default 0,
  is_active  boolean default false,
  created_at timestamptz default now()
);
alter table public.upbo_seasons enable row level security;
drop policy if exists "public read seasons" on public.upbo_seasons;
drop policy if exists "auth write seasons"  on public.upbo_seasons;
create policy "public read seasons" on public.upbo_seasons for select using (true);
create policy "auth write seasons"  on public.upbo_seasons for all to authenticated using (true) with check (true);

-- 시청자를 시즌에 연결 (시즌 삭제 시 해당 월 시청자도 삭제)
alter table public.upbo_viewers add column if not exists season_id uuid references public.upbo_seasons(id) on delete cascade;
create index if not exists idx_upbo_viewers_season on public.upbo_viewers(season_id);

-- 기본 시즌 1개 시드(없을 때만)
insert into public.upbo_seasons (name, sort_order, is_active)
select '2026년 6월', 0, true
where not exists (select 1 from public.upbo_seasons);

-- 시즌 없는 기존 시청자를 첫 시즌으로 귀속(최초 1회)
update public.upbo_viewers
set season_id = (select id from public.upbo_seasons order by sort_order limit 1)
where season_id is null;


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
  ('songclip','https://vod.sooplive.com/player/189985747'),
  ('guide_rules','[{"t":"뇌절 X","d":"도배, 유기·산책 드립, 무지성 남친 드립, 과한 억빠 (예: ''방종 전에 좌표 찍고 가'', 어디 갈 때마다 ㄴㅊㅇㄴ)"},{"t":"신상 관련 언급 X","d":"제가 먼저 언급하지 않는 이상 주의 바랍니다"},{"t":"방송 흐름 끊기 X","d":"일기장·TMI, 주제에서 벗어난 잦은 채팅, 방종 아닌데 히바, 히라가 모르는 내용 떠들기 — 할 거면 100풍부터 받습니다"},{"t":"논란이 될 만한 주제 X","d":"당연합니다"},{"t":"팬들 간의 친목 X","d":"팬들끼리의 대화는 금지합니다. 서로 아는 척 X"},{"t":"타 비제이 언급 및 비하·비방 X","d":"상황에 맞지 않는 타 비제이 언급 X, 과한 중계 X"},{"t":"타 비제이 방에서 히라 언급 X","d":"저에게도 타 비제이분께도 피해가 될 수 있고 친목의 우려가 있습니다"},{"t":"유입 배려 O","d":"음지 드립·물타기, 오팬무, 청자끼리 네임드 시키기 X"}]'),
  ('guide_terms','[{"t":"종겜","d":"종합게임 — 여러 게임을 돌아가며 하는 방송."},{"t":"휴방","d":"쉬는 날. 방송이 없는 요일."},{"t":"별풍 / 도네","d":"후원. 별풍선 등으로 보내는 응원."},{"t":"다시보기","d":"지난 방송 VOD. 놓친 방송을 다시 시청."},{"t":"클립","d":"방송 중 짧게 잘라 공유하는 영상."}]')
on conflict (key) do nothing;

-- 방송 규칙/용어 최신화 (재실행 시 기존 값을 위 기본값으로 덮어씀)
-- 규칙을 어드민에서 직접 관리할 거면 이 블록은 첫 적용 후 지워도 됩니다.
update site_settings s set value = d.value
from (values
  ('guide_rules','[{"t":"뇌절 X","d":"도배, 유기·산책 드립, 무지성 남친 드립, 과한 억빠 (예: ''방종 전에 좌표 찍고 가'', 어디 갈 때마다 ㄴㅊㅇㄴ)"},{"t":"신상 관련 언급 X","d":"제가 먼저 언급하지 않는 이상 주의 바랍니다"},{"t":"방송 흐름 끊기 X","d":"일기장·TMI, 주제에서 벗어난 잦은 채팅, 방종 아닌데 히바, 히라가 모르는 내용 떠들기 — 할 거면 100풍부터 받습니다"},{"t":"논란이 될 만한 주제 X","d":"당연합니다"},{"t":"팬들 간의 친목 X","d":"팬들끼리의 대화는 금지합니다. 서로 아는 척 X"},{"t":"타 비제이 언급 및 비하·비방 X","d":"상황에 맞지 않는 타 비제이 언급 X, 과한 중계 X"},{"t":"타 비제이 방에서 히라 언급 X","d":"저에게도 타 비제이분께도 피해가 될 수 있고 친목의 우려가 있습니다"},{"t":"유입 배려 O","d":"음지 드립·물타기, 오팬무, 청자끼리 네임드 시키기 X"}]')
) as d(key,value)
where s.key = d.key;

-- ───────── 업보 종류 시드 예시 — 테이블 비었을 때만 ─────────
insert into public.upbo_types (name, color, sort_order)
select v.name, v.color, v.sort_order
from (values
  ('단컷방셀','#ffb3d1',1),
  ('움짤방셀','#c5b8e8',2),
  ('노래방셀','#a8d8d4',3)
) as v(name,color,sort_order)
where not exists (select 1 from public.upbo_types);

-- ───────── 일정 (schedule_events · 두미 기준) ─────────
create table if not exists public.schedule_events (
  id          bigserial primary key,
  date        date not null,
  time        time,
  title       text not null,
  description text,
  is_hidden   boolean default false,
  created_at  timestamptz default now()
);
create index if not exists idx_schedule_date on public.schedule_events(date);
alter table public.schedule_events add column if not exists event_type text default 'broadcast';
alter table public.schedule_events add column if not exists color text;
alter table public.schedule_events add column if not exists is_anniversary boolean default false;
alter table public.schedule_events add column if not exists anniv_color text;
alter table public.schedule_events enable row level security;
drop policy if exists "public read schedule" on public.schedule_events;
drop policy if exists "auth all schedule"  on public.schedule_events;
create policy "public read schedule" on public.schedule_events for select using (is_hidden = false);
create policy "auth all schedule"  on public.schedule_events for all to authenticated using (true) with check (true);
