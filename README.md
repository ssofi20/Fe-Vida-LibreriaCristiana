# Fe & Vida · Librería Cristiana

Landing page del emprendimiento, con catálogo público y panel de administración.

## Archivos

| Archivo | Para qué sirve |
| --- | --- |
| `index.html` | Toda la página: catálogo, filtros, galería, carrito de pedidos, panel de administración y conexión con Supabase. |
| `supabase-schema.sql` | Crea las tablas `books` y `settings`, los permisos (RLS), el bucket de portadas y los 34 libros iniciales. |
| `supabase-categorias.sql` | Crea las tablas `categories` y `book_categories` (conexión muchos a muchos), sus permisos y las categorías iniciales. |

## Puesta en marcha

1. Creá un proyecto en [Supabase](https://supabase.com).
2. En **SQL Editor**, ejecutá primero `supabase-schema.sql` y después `supabase-categorias.sql`.
3. En `index.html`, reemplazá `SUPABASE_URL` y `SUPABASE_ANON_KEY` por los datos de tu proyecto
   (**Project Settings → API**). La `anon key` es pública: la seguridad real la dan las políticas RLS.
4. Creá la cuenta de administración en **Authentication → Users** y deshabilitá el registro público.
5. Abrí `index.html` y entrá al panel desde **Administración** (o con `Ctrl + Shift + A`).

Sin Supabase configurado, la página funciona igual con `localStorage` en un solo navegador.

## Categorías

- Categorías iniciales: **Agendas, Biblias, Para la familia, Para jóvenes, Para niños,
  Libros sobre Santos, Espiritualidad, Oración y devoción, Formación y estudio,
  Acompañamiento y duelo y Regalos y detalles**.
- Cada libro puede pertenecer a varias categorías.
- El script asigna automáticamente las categorías al catálogo actual usando fragmentos del título.
  Después se pueden ajustar desde el panel: pestaña **Gestionar → botón de etiqueta** de cada libro,
  o al agregar uno nuevo en **Agregar → Categorías**.
- En el catálogo público aparecen como filtros rápidos y dentro de cada tarjeta.
- La búsqueda (pública y del panel) encuentra libros por **título o categoría**.

## Carrito y pedidos

- Cada tarjeta tiene **Agregar al carrito** debajo de «Consultar por WhatsApp». Al agregar, la tarjeta
  muestra los controles **− / +** para ajustar la cantidad (hasta 99 por título).
- El botón flotante **Carrito** (abajo a la derecha) abre el resumen con portadas, cantidades,
  subtotales y total estimado. También se llega desde **Cómo comprar → Ver mi carrito**.
- **Enviar pedido por WhatsApp** arma un mensaje con todos los títulos, cantidades, precios y total.
- El carrito se guarda en el navegador del visitante (`localStorage`) y se revalida contra el catálogo
  actual, así los precios y títulos siempre coinciden con lo publicado. No requiere cuenta ni pago online.

## Respaldo

Desde **Administración → Ajustes → Respaldo de datos** podés exportar o importar todo el catálogo
(incluidas las categorías) en un archivo JSON.
