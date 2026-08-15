/* R2 목록 — GET /api/r2/list?dir=studio&limit=100&cursor=xxx
   → { ok, items:[{key,url,size,uploaded}], cursor } */
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type"
};

export function onRequestOptions() {
  return new Response(null, { headers: CORS });
}

export async function onRequestGet({ request, env }) {
  const j = (o, s = 200) =>
    new Response(JSON.stringify(o), { status: s, headers: { ...CORS, "Content-Type": "application/json" } });

  if (!env.DRESS) return j({ error: "R2 바인딩(DRESS) 없음" }, 500);

  try {
    const u = new URL(request.url);
    const dir = String(u.searchParams.get("dir") || "").replace(/[^a-z0-9/_-]/gi, "");
    const limit = Math.min(200, Math.max(1, parseInt(u.searchParams.get("limit") || "100")));
    const cursor = u.searchParams.get("cursor") || undefined;

    const res = await env.DRESS.list({ prefix: dir ? dir + "/" : undefined, limit, cursor });
    const origin = u.origin;
    const items = (res.objects || []).map(o => ({
      key: o.key,
      url: `${origin}/api/r2/file/${o.key}`,
      size: o.size,
      uploaded: o.uploaded
    })).sort((a, b) => new Date(b.uploaded) - new Date(a.uploaded));

    return j({ ok: true, items, cursor: res.truncated ? res.cursor : null });
  } catch (e) {
    return j({ error: String(e && e.message || e) }, 500);
  }
}
