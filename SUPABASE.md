# Puesta en marcha con Supabase

Esta versión puede funcionar de dos maneras:

- **Modo local** (sin configurar): sigue usando `localStorage` y la contraseña local.
- **Modo Supabase** (configurado): libros, ajustes y portadas viven en la nube, y el acceso se hace con una cuenta real de Supabase Auth.

---

## 1. Crear el proyecto

1. Entrá a <https://supabase.com> y creá un proyecto.
2. Guardá la contraseña de la base de datos que te pide Supabase.
3. Esperá a que termine de aprovisionarse.

## 2. Crear las tablas, políticas y el catálogo inicial

1. En el panel de Supabase, abrí **SQL Editor → New query**.
2. Copiá todo el contenido de `supabase-schema.sql` y pegalo.
3. Ejecutá con **Run**.

Eso crea:

- `public.books` con los 34 títulos iniciales y la columna `image_urls` para varias fotos por libro.
- `public.settings` con una fila para los datos del emprendimiento.
- Políticas RLS: lectura pública, escritura solo para usuarios autenticados.
- El bucket público `portadas` en Storage, con límite de 5 MB por imagen.

> Si ya habías ejecutado una versión anterior de este SQL, volvé a ejecutarlo: la migración agrega `image_urls` y copia la portada existente de `image_url` sin borrar datos.

## 3. Crear la cuenta de administración

1. En Supabase, andá a **Authentication → Users → Add user → Create new user**.
2. Poné tu email y una contraseña segura.
3. Marcá la opción para **auto-confirmar** el usuario (o confirmá el email).
4. En **Authentication → Sign In / Providers → Email**, desactivá **Allow new users to sign up** para que nadie pueda registrarse solo.

La contraseña no se guarda en ninguna tabla visible: Supabase la almacena cifrada en `auth.users`. Desde la web solo se puede iniciar sesión y cambiarla con la sesión activa.

## 4. Conectar la página

Abrí `index.html` y buscá este bloque al inicio del script:

```js
const SUPABASE_URL = 'TU_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'TU_SUPABASE_ANON_KEY';
```

Reemplazalo con los datos de **Project Settings → API**:

```js
const SUPABASE_URL = 'https://tuproyecto.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOi...'; // anon public key
```

> La `anon public key` está pensada para usarse en el navegador. **No pegues la `service_role key`**: esa clave omite las políticas RLS y nunca debe llegar al frontend.

## 5. Probar en local

Serví la carpeta con un servidor local (no abras el archivo con `file://` si querés probar Storage):

```bash
python -m http.server 8765 --bind 127.0.0.1
```

Abrí <http://127.0.0.1:8765/> y entrá con el email y la contraseña que creaste en Supabase.

## 6. Publicar

Podés subir `index.html` a Netlify, Vercel, GitHub Pages o cualquier hosting estático. No hace falta backend propio: el navegador habla directo con Supabase usando la `anon key` y las políticas RLS.

## 7. Después de publicar

- Entrá a **Administración → Ajustes** y cargá tu WhatsApp real. El número inicial queda vacío para que no se envíen pedidos a un número de ejemplo.
- Subí hasta 8 fotos por libro desde **Gestionar → botón de fotos** o al agregar un libro. Se guardan en el bucket `portadas`.
- Hacé clic en la portada de un libro con varias fotos para abrir la galería pública.
- Cambiá la contraseña desde **Ajustes → Seguridad del panel**.
- Usá **Exportar respaldo** antes de hacer cambios grandes.

---

## Cómo funciona la seguridad

- **Lectura pública:** cualquiera puede leer `books` y `settings` para ver el catálogo.
- **Escritura protegida:** las políticas RLS solo permiten `insert`, `update` y `delete` a usuarios autenticados.
- **Storage:** lectura pública de las portadas y escritura solo autenticada.
- **Contraseña:** la maneja Supabase Auth; no se guarda en el código ni en `localStorage`.
- **Sesión:** esta versión no persiste la sesión al recargar. Cada visita nueva pide email y contraseña. El botón **Bloquear panel ahora** cierra la sesión.

## Si algo no funciona

| Problema | Qué revisar |
| --- | --- |
| “No se pudo cargar la base de datos” | Que el SQL se haya ejecutado y que la URL/clave estén bien copiadas. |
| “Email o contraseña incorrectos” | Que el usuario exista y esté confirmado en **Authentication → Users**. |
| El catálogo se ve vacío | Que la tabla `books` tenga filas. El SQL inserta los 34 títulos solo si estaba vacía. |
| No se pueden subir portadas | Que exista el bucket `portadas` y las políticas de Storage. |
| Solo se guarda una foto por libro | Volvé a ejecutar `supabase-schema.sql` para agregar la columna `image_urls`. |
| Los cambios no se guardan | Que hayas iniciado sesión y que la sesión siga activa. Probá **Bloquear panel ahora** y volver a entrar. |
| El login no aparece con email | Que `SUPABASE_URL` y `SUPABASE_ANON_KEY` estén reemplazadas y que el CDN de `supabase-js` cargue. |

## Volver al modo local

Si dejás los valores `TU_SUPABASE_URL` / `TU_SUPABASE_ANON_KEY`, la página funciona como antes: `localStorage` y la contraseña local (`FeVida2026` por defecto). Ese modo es solo para desarrollo o pruebas; para producción usá Supabase.
