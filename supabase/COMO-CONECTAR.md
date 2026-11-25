# Conectar la casa compartida (una sola vez, unos 10 minutos)

La app guarda todo **cifrado en vuestro móvil** con la *clave de la casa* antes de subirlo.
La base de datos (Supabase) solo ve texto ilegible, y sus reglas hacen que cada persona
solo pueda acceder a lo común de su casa y a su parte personal.

## 1. Crear la base de datos (lo hace una persona)
1. Entra en **supabase.com** y pulsa **Start your project**. Regístrate con tu email.
2. **New project**:
   - Name: `mi-pared`
   - Database password: inventa una y guárdala (no la usa la app, pero no la pierdas).
   - Region: **Central EU (Frankfurt)** o **West EU (Ireland)**, para que los datos estén en Europa.
   - Plan: **Free**.
3. Espera 1–2 minutos a que se cree.

## 2. Preparar las tablas y las reglas de privacidad
1. En el menú de la izquierda, **SQL Editor** → **New query**.
2. Copia todo el contenido de [`setup.sql`](setup.sql) y pégalo.
3. Pulsa **Run**. Tiene que salir *Success*.

## 3. Ajustar el inicio de sesión
1. **Authentication** → **URL Configuration** → **Site URL**:
   `https://noeliaserrano.github.io/dashboard-life/`
2. Guarda.

## 4. Copiar los datos de conexión
**Project Settings** → **API** (o **Data API** / **API Keys**). Copia:
- **Project URL** (algo como `https://abcd1234.supabase.co`)
- **anon public** key (una clave larga)

Esta clave es pública a propósito: sola no da acceso a nada, porque hace falta iniciar
sesión, pertenecer a la casa y, además, conocer la clave de la casa para leer los datos.

## 5. En la app
**Tú (creas la casa):**
1. **Ajustes → Cuenta y casa compartida** → pega la URL y la clave → **Conectar**.
2. Email y contraseña → **Crear cuenta**. Confirma el email con el enlace que te llega y vuelve a la app → **Entrar**.
3. Tu nombre + **clave de la casa** (mínimo 8 caracteres) → **Crear casa**.
4. Te saldrá un **código**. Pásaselo a tu pareja junto con la clave de la casa (en persona, mejor).

**Tu pareja (se une):**
1. Abre el enlace de la app en Safari → **Compartir → Añadir a pantalla de inicio**.
2. **Ajustes → Cuenta y casa compartida** → pega la URL y la clave → **Conectar** (si ya vienen puestas, se salta este paso).
3. **Crear cuenta** con su email, confirma, **Entrar**.
4. Su nombre + la **misma clave de la casa** + el **código** → **Unirme con código**.

## 6. Cerrar la puerta (recomendado)
Cuando ya tengáis cuenta los dos: **Authentication → Sign In / Providers** (o *Settings*) →
desactiva **Allow new users to sign up**. Así nadie más puede crear cuentas en vuestra base de datos.

## Importante
- Si olvidáis la **clave de la casa**, los datos no se pueden recuperar. Guardadla en un sitio seguro.
- Cada uno sigue teniendo **su agenda, estudio, dinero y horario personales**; solo **Casa** es común.
