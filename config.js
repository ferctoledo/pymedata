/* ============================================================
   PyMEdata v2.0 — Configuración Supabase
   Fernando Toledo · FCE-UNLP · Mayo 2026
   
   ⚠️  ANTES DE PUBLICAR: reemplazá los valores de abajo
       con los de tu proyecto en Supabase:
       Dashboard → Settings → API
   ============================================================ */

const SUPABASE_URL  = 'sb_publishable_qMLCum-FwIM5_7_sdpieyw_3LNzPyMn';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlvdWd1c3J6dHhldGJ6dHZoaGFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5MDU5MzEsImV4cCI6MjA5MzQ4MTkzMX0.BGWe5vYOb9zfOC3_o6EhjaNFoOuRa_j9Kl97CcPFy_I';

/* Límites por plan */
const PLAN_LIMITES = {
  starter:   { diagnosticos: 0,  planes: 0,  consultas: 0,  escenarios: 0  },
  pro:       { diagnosticos: 15, planes: 15, consultas: 10, escenarios: 5  },
  premium:   { diagnosticos: -1, planes: -1, consultas: -1, escenarios: -1 },
  contador:  { diagnosticos: -1, planes: -1, consultas: -1, escenarios: -1 },
};

/* -1 = ilimitado */
function puedeUsar(plan, tipo, usoActual) {
  const limite = PLAN_LIMITES[plan]?.[tipo] ?? 0;
  if (limite === -1) return true;
  return usoActual < limite;
}

/* Precios */
const PLANES = {
  starter:  { nombre: 'Starter',         usd: 0,  ars: 0      },
  pro:      { nombre: 'Pro',             usd: 19, ars: 26600  },
  premium:  { nombre: 'Premium',         usd: 49, ars: 68600  },
  contador: { nombre: 'Contador/Asesor', usd: 89, ars: 124600 },
};
