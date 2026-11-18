CHINOINFIERNO · KEY MANAGER V1
=============================================

QUÉ HACE
- Tus amigos entran a un enlace y ven cuántas keys hay AVAILABLE, FULL y RESERVED.
- Pueden filtrar y buscar keys sin iniciar sesión.
- Para reclamar, inician sesión por correo (enlace de Supabase).
- Solo reciben el código de la key que reclamen.
- La key se marca FULL de forma atómica: nadie más puede recibirla.
- Se permite una sola key reclamada por cuenta de correo.
- Tú tienes un panel privado para añadir 1-50 keys de golpe, cambiar estados y borrar.
- La información se sincroniza aproximadamente cada 10 segundos en todas las pantallas.
- El código secreto de una key NO aparece en el inventario público.

IMPORTANTE SOBRE LA DEMO
- Abre index.html SIN configurar nada para ver la demo visual y probar botones.
- Las keys DEMO-KEY-XXXX-NO-VALIDA son inventadas y no sirven para ninguna app.
- En modo demo, los cambios SOLO se guardan en el navegador local.
- Para usar la web entre varios teléfonos y compas, necesitas Supabase.

CONFIGURAR PARA USO REAL
1. Crea una cuenta y un proyecto GRATIS en https://supabase.com
2. En Supabase abre SQL Editor > New query.
3. Copia TODO database.sql, pégalo y pulsa Run.
4. En tu proyecto abre Project Settings > API (o Connect).
5. Copia "Project URL" y la "publishable key" (o legacy anon public key).
6. Abre config.js y reemplaza:
   supabaseUrl: "PON_AQUI_TU_SUPABASE_URL"
   supabaseAnonKey: "PON_AQUI_TU_PUBLISHABLE_O_ANON_KEY"
   NUNCA PONGAS una service_role key, secret API key o contraseña allí.
7. En Supabase > Authentication > Providers > Email, deja habilitado el acceso
   mediante enlaces por correo / Magic link.
   NOTA: para enviar correos a usuarios externos reales, Supabase puede
   requerir configurar un proveedor SMTP propio. El envío predeterminado
   tiene límites/restricciones para pruebas.
8. Publica los archivos (index.html, styles.css, app.js, config.js)
   en un hosting de páginas estáticas como GitHub Pages o Netlify.
9. En Supabase > Authentication > URL Configuration:
   - Site URL: URL pública EXACTA de tu web.
   - Redirect URLs: agrega esa misma URL (p.ej. https://usuario.github.io/repo/).
   Si la web carga en una subruta, respeta la barra final y ruta completa.
10. Visita la web publicada e inicia sesión con TU correo.
11. Vuelve a Supabase > SQL Editor, pega esto sustituyendo tu correo:

   insert into public.chino_admins (user_id)
   select id from auth.users where lower(email) = lower('TUCORREO@EJEMPLO.COM')
   on conflict do nothing;

12. Actualiza la web: aparecerá "Panel privado".
13. Agrega tus keys REALES desde el panel y comparte el link.

CÓMO SUBIR A GITHUB PAGES
- Crea un repositorio en GitHub (puede ser público: los códigos reales
  NO se guardan en el repositorio, sino en la base de datos protegida).
- En "Add file > Upload files", sube index.html, styles.css, app.js, config.js.
- En Settings > Pages > Build and deployment > Deploy from a branch,
  elige main / root. Guarda.
- GitHub mostrará el enlace público cuando termine la publicación.
- No subas database.sql si no lo necesitas: es el esquema, sin contraseñas.

SEGURIDAD / LIMITACIONES
- La key del API pública de Supabase sí puede estar en config.js; así está
  diseñado su SDK. La seguridad se basa en RLS y en las funciones SQL.
- Nunca subas la service_role key (salta la seguridad de RLS).
- El listado público solo muestra ID, tipo, estado y fecha, NO los códigos.
- Supabase Auth identifica al reclamante por cuenta de correo.
- La protección es una key por cuenta, NO por persona física: alguien podría
  crear varias cuentas/correos. Si esto importa, implementa verificación
  adicional de identidad o invitaciones individuales.
- Marcar FULL / cambiar una key aquí no modifica el estado de una key en
  Luarmor u otro proveedor. Es un inventario de entregas independiente.
- Marcar una key reclamada AVAILABLE la libera y se elimina su relación con
  el usuario anterior dentro de esta web. NO desactiva la licencia real.
- Para producción, configura tu propio dominio/SMTP, revisa límites de
  correo y activa límites antiabuso en Supabase según sea necesario.
- El primer administrador debe registrarse ANTES de ejecutar el INSERT SQL.

ARCHIVOS
index.html   Página principal y estructura
styles.css   Diseño morado / negro, responsive en iPhone
app.js       Funcionamiento (inventario, login, reclamos, administración)
config.js    Tu URL y clave PÚBLICA de Supabase
database.sql Esquema seguro y funciones de reclamo atómico
README.txt   Esta guía

Hecho para CHINOINFIERNO.
