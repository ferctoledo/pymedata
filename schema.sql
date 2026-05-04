-- ============================================================
-- PyMEdata v2.0 — Esquema de base de datos Supabase
-- Fernando Toledo · FCE-UNLP · Mayo 2026
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- ============================================================

-- ── EXTENSIONES ──────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── TABLA: profiles ──────────────────────────────────────────
-- Un registro por usuario. Vinculado a auth.users de Supabase.
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email         TEXT NOT NULL,
  nombre        TEXT,
  empresa       TEXT,
  sector        TEXT,
  empleados     TEXT,
  telefono      TEXT,
  ciudad        TEXT DEFAULT 'La Plata',
  plan          TEXT NOT NULL DEFAULT 'starter'
                  CHECK (plan IN ('starter','pro','premium','contador')),
  plan_activo   BOOLEAN DEFAULT TRUE,
  plan_inicio   TIMESTAMPTZ DEFAULT NOW(),
  plan_vence    TIMESTAMPTZ,
  es_admin      BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── TABLA: empresa_perfiles ───────────────────────────────────
-- Perfil de la PyME (puede actualizarse sin perder historial)
CREATE TABLE IF NOT EXISTS public.empresa_perfiles (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  sector        TEXT,
  empleados     TEXT,
  exporta       BOOLEAN DEFAULT FALSE,
  importa       BOOLEAN DEFAULT FALSE,
  credito       BOOLEAN DEFAULT FALSE,
  insumos_usd   BOOLEAN DEFAULT FALSE,
  venta_online  BOOLEAN DEFAULT FALSE,
  problema      TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── TABLA: diagnosticos ───────────────────────────────────────
-- Historial completo de diagnósticos IA por usuario
CREATE TABLE IF NOT EXISTS public.diagnosticos (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  sector        TEXT,
  empleados     TEXT,
  caracteristicas TEXT,
  problema      TEXT,
  resultado     TEXT,
  tipo          TEXT DEFAULT 'diagnostico'
                  CHECK (tipo IN ('diagnostico','plan','escenario','consulta')),
  escenario     TEXT,
  tokens_usados INTEGER DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── TABLA: consultas ─────────────────────────────────────────
-- Historial del asesor IA
CREATE TABLE IF NOT EXISTS public.consultas (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  pregunta      TEXT NOT NULL,
  respuesta     TEXT,
  sector        TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── TABLA: suscripciones ─────────────────────────────────────
-- Historial de pagos y suscripciones
CREATE TABLE IF NOT EXISTS public.suscripciones (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  plan          TEXT NOT NULL,
  precio_usd    NUMERIC(10,2),
  precio_ars    NUMERIC(12,2),
  estado        TEXT DEFAULT 'activa'
                  CHECK (estado IN ('activa','vencida','cancelada','prueba')),
  metodo_pago   TEXT,
  referencia    TEXT,
  fecha_inicio  TIMESTAMPTZ DEFAULT NOW(),
  fecha_vence   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── TABLA: uso_mensual ───────────────────────────────────────
-- Control de cuotas por plan
CREATE TABLE IF NOT EXISTS public.uso_mensual (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  mes           DATE NOT NULL DEFAULT date_trunc('month', NOW()),
  diagnosticos  INTEGER DEFAULT 0,
  planes        INTEGER DEFAULT 0,
  consultas     INTEGER DEFAULT 0,
  escenarios    INTEGER DEFAULT 0,
  UNIQUE(user_id, mes)
);

-- ── ROW LEVEL SECURITY (RLS) ──────────────────────────────────
-- Seguridad multitenant: cada usuario ve SOLO sus datos

ALTER TABLE public.profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.empresa_perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diagnosticos    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consultas       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suscripciones   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.uso_mensual     ENABLE ROW LEVEL SECURITY;

-- Policies: profiles
CREATE POLICY "Usuario ve su propio perfil"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Usuario edita su propio perfil"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admin ve todos los perfiles"
  ON public.profiles FOR ALL
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND es_admin = TRUE)
  );

-- Policies: empresa_perfiles
CREATE POLICY "Usuario ve su perfil de empresa"
  ON public.empresa_perfiles FOR ALL
  USING (auth.uid() = user_id);

-- Policies: diagnosticos
CREATE POLICY "Usuario ve sus diagnósticos"
  ON public.diagnosticos FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Admin ve todos los diagnósticos"
  ON public.diagnosticos FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND es_admin = TRUE)
  );

-- Policies: consultas
CREATE POLICY "Usuario ve sus consultas"
  ON public.consultas FOR ALL
  USING (auth.uid() = user_id);

-- Policies: suscripciones
CREATE POLICY "Usuario ve sus suscripciones"
  ON public.suscripciones FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admin gestiona suscripciones"
  ON public.suscripciones FOR ALL
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND es_admin = TRUE)
  );

-- Policies: uso_mensual
CREATE POLICY "Usuario ve su uso"
  ON public.uso_mensual FOR ALL
  USING (auth.uid() = user_id);

-- ── FUNCIÓN: crear perfil automáticamente al registrarse ──────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, plan)
  VALUES (NEW.id, NEW.email, 'starter');

  INSERT INTO public.uso_mensual (user_id, mes)
  VALUES (NEW.id, date_trunc('month', NOW()));

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── FUNCIÓN: incrementar uso ──────────────────────────────────
CREATE OR REPLACE FUNCTION public.incrementar_uso(
  p_user_id UUID,
  p_tipo TEXT
) RETURNS VOID AS $$
BEGIN
  INSERT INTO public.uso_mensual (user_id, mes)
  VALUES (p_user_id, date_trunc('month', NOW()))
  ON CONFLICT (user_id, mes) DO NOTHING;

  EXECUTE format(
    'UPDATE public.uso_mensual SET %I = %I + 1 WHERE user_id = $1 AND mes = date_trunc(''month'', NOW())',
    p_tipo, p_tipo
  ) USING p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── VISTA ADMIN: resumen de usuarios ─────────────────────────
CREATE OR REPLACE VIEW public.admin_usuarios AS
SELECT
  p.id,
  p.email,
  p.nombre,
  p.empresa,
  p.sector,
  p.plan,
  p.plan_activo,
  p.plan_vence,
  p.created_at,
  COALESCE(u.diagnosticos, 0) as diag_mes,
  COALESCE(u.consultas, 0) as consultas_mes,
  COUNT(d.id) as diag_total
FROM public.profiles p
LEFT JOIN public.uso_mensual u ON u.user_id = p.id
  AND u.mes = date_trunc('month', NOW())
LEFT JOIN public.diagnosticos d ON d.user_id = p.id
GROUP BY p.id, p.email, p.nombre, p.empresa, p.sector,
         p.plan, p.plan_activo, p.plan_vence, p.created_at,
         u.diagnosticos, u.consultas;

-- ── DATOS DE PRUEBA: admin ────────────────────────────────────
-- Ejecutar DESPUÉS de registrar el usuario admin:
-- UPDATE public.profiles SET es_admin = TRUE WHERE email = 'tu-email@ejemplo.com';

-- ============================================================
-- FIN DEL ESQUEMA
-- PyMEdata v2.0 · Fernando Toledo · FCE-UNLP
-- ============================================================
