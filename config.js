/* ============================================================
   PyMEdata v2.0 — Configuración Supabase
   Fernando Toledo · FCE-UNLP · Mayo 2026
   ============================================================ */

const SUPABASE_URL  = 'https://mnzddibsggoivqbbysni.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1uemRkaWJzZ2dvaXZxYmJ5c25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5Mjg0MzgsImV4cCI6MjA5MzUwNDQzOH0._iAFhH4NZ4UtTptoHlyNkG0kQ6IiewoKd2rTSoUnThY';

/* ============================================================
   ADMINISTRADOR / DUEÑO — Acceso total garantizado por código
   ============================================================
   Listado de emails que tienen acceso Premium + admin completo
   independientemente del valor almacenado en Supabase.
   → Agregar o quitar emails según sea necesario (siempre en minúsculas).
   ============================================================ */
const ADMIN_EMAILS_LIST = [
  'toledo.fernando.cesar@gmail.com', /* email principal Supabase        */
  'ferctoledo@gmail.com',            /* email alternativo GitHub/Google  */
  'fernando.toledo@econo.unlp.edu.ar', /* email institucional FCE-UNLP  */
];
/* ============================================================ */

/* Límites por plan (-1 = ilimitado) */
const PLAN_LIMITES = {
  starter:  { diagnosticos: 0,  planes: 0,  consultas: 0,  escenarios: 0  },
  pro:      { diagnosticos: 15, planes: 15, consultas: 10, escenarios: 5  },
  premium:  { diagnosticos: -1, planes: -1, consultas: -1, escenarios: -1 },
  contador: { diagnosticos: -1, planes: -1, consultas: -1, escenarios: -1 },
};

function puedeUsar(plan, tipo, usoActual) {
  const limite = PLAN_LIMITES[plan]?.[tipo] ?? 0;
  if (limite === -1) return true;
  return usoActual < limite;
}

const PLANES = {
  starter:  { nombre: 'Starter',          usd: 0,  ars: 0      },
  pro:      { nombre: 'Pro',              usd: 19, ars: 26600  },
  premium:  { nombre: 'Premium',          usd: 49, ars: 68600  },
  contador: { nombre: 'Contador/Asesor',  usd: 89, ars: 124600 },
};
