-- ШтрихКасса — схема базы данных для Supabase
-- Выполнить целиком в Supabase: Project → SQL Editor → New query → вставить → Run

-- 1) Товары (справочник по штрихкодам)
create table if not exists products (
  barcode    text primary key,
  name       text not null,
  variant    text default '',
  price      numeric(12,2) not null default 0,
  updated_at timestamptz not null default now()
);

-- 2) Чеки (история продаж)
create table if not exists receipts (
  id         uuid primary key default gen_random_uuid(),
  items      jsonb not null,        -- [{barcode,name,variant,price,qty}, ...]
  total      numeric(12,2) not null,
  item_count integer not null,
  created_at timestamptz not null default now()
);

-- 3) Настройки (валюта и т.п.) — одна строка на ключ
create table if not exists settings (
  key   text primary key,
  value jsonb not null
);

-- Индекс для быстрой выборки истории по дате
create index if not exists receipts_created_at_idx on receipts (created_at desc);

-- Включаем Row Level Security — без этого таблицы либо полностью открыты,
-- либо полностью закрыты в зависимости от настроек проекта. Явные политики
-- ниже разрешают доступ только вошедшим пользователям (см. README про
-- создание пользователя в Supabase Auth).
alter table products enable row level security;
alter table receipts enable row level security;
alter table settings enable row level security;

drop policy if exists "authenticated full access" on products;
create policy "authenticated full access" on products
  for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

drop policy if exists "authenticated full access" on receipts;
create policy "authenticated full access" on receipts
  for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

drop policy if exists "authenticated full access" on settings;
create policy "authenticated full access" on settings
  for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- Включаем realtime для истории чеков (необязательно, но приятно —
-- если открыть кассу на двух устройствах, история обновится сама)
alter publication supabase_realtime add table receipts;
