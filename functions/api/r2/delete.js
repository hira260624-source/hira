/* R2 삭제 — POST /api/r2/delete { key } */
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type"
};

export function onRequestOptions() {
  return new Response(null, { headers: CORS });
}

export async function onRequestPost({ request, env }) {
  const j = (o, s = 200) =>
    new Response(JSON.stringify(o), { status: s, headers: { ...CORS, "Content-Type": "application/json" } });

  if (!env.DRESS) return j({ error: "R2 바인딩(DRESS) 없음" }, 500);

  try {
    const { key } = await request.json();
    if (!key) return j({ error: "key 필요" }, 400);
    await env.DRESS.delete(String(key));
    return j({ ok: true });
  } catch (e) {
    return j({ error: String(e && e.message || e) }, 500);
  }
}
