-- ============================================================================
-- FE & VIDA · Esquema para Supabase
-- Pegá todo este archivo en Supabase → SQL Editor → Run.
-- Es idempotente: se puede volver a ejecutar sin duplicar los 34 libros.
-- ============================================================================

create extension if not exists pgcrypto;

-- ----------------------------------------------------------------------------
-- 1. LIBROS
-- ----------------------------------------------------------------------------
create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(trim(title)) between 1 and 140),
  price numeric(12, 2) not null check (price >= 0),
  image_url text,
  image_urls text[] not null default '{}',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Migración para bases creadas con la versión anterior de una sola portada.
alter table public.books add column if not exists image_urls text[] not null default '{}';

update public.books
set image_urls = array[image_url]
where image_url is not null
  and btrim(image_url) <> ''
  and (image_urls is null or cardinality(image_urls) = 0);


create index if not exists books_sort_order_idx
  on public.books (sort_order, created_at);

-- ----------------------------------------------------------------------------
-- 2. AJUSTES (una sola fila: id = 1)
-- ----------------------------------------------------------------------------
create table if not exists public.settings (
  id smallint primary key default 1 check (id = 1),
  store_name text not null default 'Fe & Vida',
  whatsapp text not null default '',
  instagram text not null default '',
  email text not null default '',
  updated_at timestamptz not null default now()
);

insert into public.settings (id, store_name, whatsapp)
values (1, 'Fe & Vida', '')
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- 3. updated_at automático
-- ----------------------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists books_touch_updated_at on public.books;
create trigger books_touch_updated_at
  before update on public.books
  for each row execute function public.touch_updated_at();

drop trigger if exists settings_touch_updated_at on public.settings;
create trigger settings_touch_updated_at
  before update on public.settings
  for each row execute function public.touch_updated_at();

-- ----------------------------------------------------------------------------
-- 4. PERMISOS Y SEGURIDAD (RLS)
--    - Cualquiera puede LEER el catálogo y los ajustes.
--    - Solo una sesión autenticada puede CREAR, EDITAR o BORRAR.
--    - Deshabilitá el registro público en Supabase Authentication.
-- ----------------------------------------------------------------------------
alter table public.books enable row level security;
alter table public.settings enable row level security;

grant select on public.books to anon, authenticated;
grant select on public.settings to anon, authenticated;
grant insert, update, delete on public.books to authenticated;
grant insert, update, delete on public.settings to authenticated;

drop policy if exists books_public_read on public.books;
create policy books_public_read
  on public.books for select
  to anon, authenticated
  using (true);

drop policy if exists books_admin_insert on public.books;
create policy books_admin_insert
  on public.books for insert
  to authenticated
  with check (true);

drop policy if exists books_admin_update on public.books;
create policy books_admin_update
  on public.books for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists books_admin_delete on public.books;
create policy books_admin_delete
  on public.books for delete
  to authenticated
  using (true);

drop policy if exists settings_public_read on public.settings;
create policy settings_public_read
  on public.settings for select
  to anon, authenticated
  using (true);

drop policy if exists settings_admin_insert on public.settings;
create policy settings_admin_insert
  on public.settings for insert
  to authenticated
  with check (id = 1);

drop policy if exists settings_admin_update on public.settings;
create policy settings_admin_update
  on public.settings for update
  to authenticated
  using (id = 1)
  with check (id = 1);

-- ----------------------------------------------------------------------------
-- 5. STORAGE: bucket público para las portadas
-- ----------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'portadas',
  'portadas',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists portadas_public_read on storage.objects;
create policy portadas_public_read
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'portadas');

drop policy if exists portadas_admin_insert on storage.objects;
create policy portadas_admin_insert
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'portadas');

drop policy if exists portadas_admin_update on storage.objects;
create policy portadas_admin_update
  on storage.objects for update
  to authenticated
  using (bucket_id = 'portadas')
  with check (bucket_id = 'portadas');

drop policy if exists portadas_admin_delete on storage.objects;
create policy portadas_admin_delete
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'portadas');

-- ----------------------------------------------------------------------------
-- 6. CATÁLOGO INICIAL (34 títulos)
--    Solo inserta si la tabla está vacía.
-- ----------------------------------------------------------------------------
insert into public.books (title, price, sort_order)
select seed.title, seed.price, seed.sort_order
from (values
  ('Jugar... Crear... Compartir', 13200.00, 1),
  ('30 Dinámicas con el Evangelio', 13200.00, 2),
  ('Treinta a San José y Devociones', 5100.00, 3),
  ('Año del Señor 2027', 4800.00, 4),
  ('El Pan de la Palabra (Nueva Edición)', 16100.00, 5),
  ('Rosario de Bendición Familiar', 2900.00, 6),
  ('La Alegría de Ser Agente de Paz', 13100.00, 7),
  ('El Estrés de Jesús (Ensayo Meditado)', 31500.00, 8),
  ('Bolsa Eco 25 x 35', 4200.00, 9),
  ('Devoción Sagrado Corazón de Jesús y María', 15200.00, 10),
  ('Mamá Antula', 2900.00, 11),
  ('Historias de la Vida', 3600.00, 12),
  ('40 Formas de Oración Personal', 7300.00, 13),
  ('Transitar Nuestras Crisis', 13600.00, 14),
  ('Sinodalidad en la Vida y en la Iglesia', 2200.00, 15),
  ('Huellas del Pastor', 22300.00, 16),
  ('Magnifica Humanitas', 6600.00, 17),
  ('Amor Hospitalario (El Buen Samaritano)', 5300.00, 18),
  ('Dios te Quiere Feliz', 5300.00, 19),
  ('Amor que Reconcilia al Pecador', 5300.00, 20),
  ('Dios, ¿Por qué Sufro? Acompañando el Dolor', 5300.00, 21),
  ('Las Parábolas de la Misericordia', 1500.00, 22),
  ('Rosario de Sanación (Nueva Edición)', 4600.00, 23),
  ('Celebremos en Familia el Cumpleaños', 3700.00, 24),
  ('Charlando con María Navideñas', 6500.00, 25),
  ('Para Gustar Más la Misa', 6500.00, 26),
  ('Cuando Visites A Un Enfermo', 5300.00, 27),
  ('Agenda Mujer Virtuosa (Permanente)', 29300.00, 28),
  ('365 Días con Cristo 2027 (Mini)', 12900.00, 29),
  ('365 Días con Cristo 2027 (Grande)', 26000.00, 30),
  ('Mi Diario Santos Varios', 27300.00, 31),
  ('Imitación de Cristo', 12300.00, 32),
  ('Tratado de la Verdadera Devoción', 12800.00, 33),
  ('Evangelio Cotidiano 2027', 6400.00, 34)
) as seed(title, price, sort_order)
where not exists (select 1 from public.books);

-- ============================================================================
-- FIN
-- ============================================================================
