-- ============================================================================
-- FE & VIDA · Categorías del catálogo
-- Ejecutá este archivo DESPUÉS de supabase-schema.sql:
--   Supabase → SQL Editor → New query → pegá todo → Run.
-- Es idempotente: se puede volver a ejecutar sin duplicar categorías ni
-- asignaciones. Si la tienda funciona con localStorage, este script no hace
-- falta hasta que conectes Supabase (la web funciona igual sin él).
-- ============================================================================

create extension if not exists pgcrypto;

-- ----------------------------------------------------------------------------
-- 1. CATEGORÍAS
-- ----------------------------------------------------------------------------
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 1 and 60),
  slug text not null unique,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

-- Evita dos categorías con el mismo nombre (sin distinguir mayúsculas).
create unique index if not exists categories_name_unique
  on public.categories (lower(name));

-- ----------------------------------------------------------------------------
-- 2. CONEXIÓN LIBRO ↔ CATEGORÍA (muchos a muchos)
--    Un libro puede estar en varias categorías y una categoría tener varios
--    libros. Al borrar un libro o una categoría se limpian sus conexiones.
-- ----------------------------------------------------------------------------
create table if not exists public.book_categories (
  book_id uuid not null references public.books (id) on delete cascade,
  category_id uuid not null references public.categories (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (book_id, category_id)
);

create index if not exists book_categories_book_idx
  on public.book_categories (book_id);

create index if not exists book_categories_category_idx
  on public.book_categories (category_id);

-- ----------------------------------------------------------------------------
-- 3. PERMISOS Y SEGURIDAD (RLS)
--    - Cualquiera puede LEER categorías y conexiones.
--    - Solo una sesión autenticada puede crear, editar o borrar.
-- ----------------------------------------------------------------------------
alter table public.categories enable row level security;
alter table public.book_categories enable row level security;

grant select on public.categories to anon, authenticated;
grant select on public.book_categories to anon, authenticated;
grant insert, update, delete on public.categories to authenticated;
grant insert, update, delete on public.book_categories to authenticated;

drop policy if exists categories_public_read on public.categories;
create policy categories_public_read
  on public.categories for select
  to anon, authenticated
  using (true);

drop policy if exists categories_admin_insert on public.categories;
create policy categories_admin_insert
  on public.categories for insert
  to authenticated
  with check (true);

drop policy if exists categories_admin_update on public.categories;
create policy categories_admin_update
  on public.categories for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists categories_admin_delete on public.categories;
create policy categories_admin_delete
  on public.categories for delete
  to authenticated
  using (true);

drop policy if exists book_categories_public_read on public.book_categories;
create policy book_categories_public_read
  on public.book_categories for select
  to anon, authenticated
  using (true);

drop policy if exists book_categories_admin_insert on public.book_categories;
create policy book_categories_admin_insert
  on public.book_categories for insert
  to authenticated
  with check (true);

drop policy if exists book_categories_admin_update on public.book_categories;
create policy book_categories_admin_update
  on public.book_categories for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists book_categories_admin_delete on public.book_categories;
create policy book_categories_admin_delete
  on public.book_categories for delete
  to authenticated
  using (true);

-- ----------------------------------------------------------------------------
-- 4. CATEGORÍAS INICIALES
-- ----------------------------------------------------------------------------
insert into public.categories (name, slug, sort_order) values
  ('Agendas', 'agendas', 1),
  ('Biblias', 'biblias', 2),
  ('Para la familia', 'para-la-familia', 3),
  ('Para jóvenes', 'para-jovenes', 4),
  ('Para niños', 'para-ninos', 5),
  ('Libros sobre Santos', 'libros-sobre-santos', 6),
  ('Espiritualidad', 'espiritualidad', 7),
  ('Oración y devoción', 'oracion-y-devocion', 8),
  ('Formación y estudio', 'formacion-y-estudio', 9),
  ('Acompañamiento y duelo', 'acompanamiento-y-duelo', 10),
  ('Regalos y detalles', 'regalos-y-detalles', 11)
on conflict (slug) do update set
  name = excluded.name,
  sort_order = excluded.sort_order;

-- ----------------------------------------------------------------------------
-- 5. ASIGNACIÓN AUTOMÁTICA DE LAS OBRAS DEL CATÁLOGO
--    Usa fragmentos del título (sin distinguir mayúsculas) para que también
--    funcione con variantes como «Treintena» / «Treinta» o «Días» / «Dias».
--    Solo conecta títulos que ya existan en public.books y nunca duplica.
--    Después podés ajustar cualquier libro desde el panel (botón de etiqueta).
-- ----------------------------------------------------------------------------
with seed(pattern, category) as (
  values
    ('%Padrenuestro de la Familia%', 'Para la familia'),
    ('%Padrenuestro de la Familia%', 'Oración y devoción'),
    ('%ALÉGRATE MARÍA%', 'Oración y devoción'),
    ('%Aprender a Orar%', 'Espiritualidad'),
    ('%Aprender a Orar%', 'Formación y estudio'),
    ('%Confesiones%', 'Espiritualidad'),
    ('%Confesiones%', 'Libros sobre Santos'),
    ('%Biblia%', 'Biblias'),
    ('%San Cayetano%', 'Agendas'),
    ('%San Cayetano%', 'Libros sobre Santos'),
    ('%San Benito%', 'Agendas'),
    ('%San Benito%', 'Libros sobre Santos'),
    ('%Nuestra Señora de Luján%', 'Agendas'),
    ('%Nuestra Señora de Luján%', 'Libros sobre Santos'),
    ('%Jugar%Crear%', 'Para la familia'),
    ('%Jugar%Crear%', 'Para niños'),
    ('%30 Dinámicas%', 'Para jóvenes'),
    ('%30 Dinámicas%', 'Para niños'),
    ('%30 Dinámicas%', 'Formación y estudio'),
    ('%San José y Devocion%', 'Libros sobre Santos'),
    ('%San José y Devocion%', 'Oración y devoción'),
    ('%Año del Señor%', 'Oración y devoción'),
    ('%Pan de la Palabra%', 'Oración y devoción'),
    ('%Pan de la Palabra%', 'Para la familia'),
    ('%Rosario de Bendición%', 'Oración y devoción'),
    ('%Rosario de Bendición%', 'Para la familia'),
    ('%agente de Pastoral%', 'Formación y estudio'),
    ('%Estrés de Jesús%', 'Espiritualidad'),
    ('%Estrés de Jesús%', 'Formación y estudio'),
    ('%Bolsa ecológica%', 'Regalos y detalles'),
    ('%sagrado corazón%', 'Oración y devoción'),
    ('%sagrado corazón%', 'Espiritualidad'),
    ('%Mamá Antula%', 'Libros sobre Santos'),
    ('%Historias de la Vida%', 'Para jóvenes'),
    ('%Historias de la Vida%', 'Formación y estudio'),
    ('%40 Formas de Oración%', 'Oración y devoción'),
    ('%40 Formas de Oración%', 'Espiritualidad'),
    ('%Transitar Nuestras Crisis%', 'Acompañamiento y duelo'),
    ('%Transitar Nuestras Crisis%', 'Espiritualidad'),
    ('%Sinodalidad%', 'Formación y estudio'),
    ('%Huellas del Pastor%', 'Formación y estudio'),
    ('%Huellas del Pastor%', 'Espiritualidad'),
    ('%Magnifica Humanitas%', 'Formación y estudio'),
    ('%Amor Hospitalario%', 'Acompañamiento y duelo'),
    ('%Dios te Quiere Feliz%', 'Espiritualidad'),
    ('%Dios te Quiere Feliz%', 'Para jóvenes'),
    ('%Amor que Reconcilia%', 'Espiritualidad'),
    ('%Amor que Reconcilia%', 'Oración y devoción'),
    ('%Por qué Sufro%', 'Acompañamiento y duelo'),
    ('%Por qué Sufro%', 'Espiritualidad'),
    ('%Parábolas de la Misericordia%', 'Oración y devoción'),
    ('%Parábolas de la Misericordia%', 'Formación y estudio'),
    ('%Rosario de Sanación%', 'Oración y devoción'),
    ('%Celebremos en Familia%', 'Para la familia'),
    ('%Celebremos en Familia%', 'Para niños'),
    ('%Charlando con María%', 'Para la familia'),
    ('%Charlando con María%', 'Oración y devoción'),
    ('%Gustar Más la Misa%', 'Oración y devoción'),
    ('%Gustar Más la Misa%', 'Espiritualidad'),
    ('%Cuando Visites%', 'Acompañamiento y duelo'),
    ('%Mujer Virtuosa%', 'Agendas'),
    ('%365 D_as con Cristo%', 'Agendas'),
    ('%365 D_as con Cristo%', 'Oración y devoción'),
    ('%Imitación de Cristo%', 'Espiritualidad'),
    ('%Tratado de la Verdadera Devoción%', 'Espiritualidad'),
    ('%Tratado de la Verdadera Devoción%', 'Oración y devoción'),
    ('%Evangelio Cotidiano%', 'Oración y devoción')
)
insert into public.book_categories (book_id, category_id)
select b.id, c.id
from seed s
join public.books b on b.title ilike s.pattern
join public.categories c on lower(c.name) = lower(s.category)
on conflict (book_id, category_id) do nothing;

-- ============================================================================
-- FIN
-- ============================================================================
