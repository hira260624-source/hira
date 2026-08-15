/* R2 파일 서빙 — /api/r2/file/{key} (하위 경로 포함)
   퍼블릭 버킷 없이도 이 경로로 이미지가 열립니다. */
export async function onRequestGet({ params, env }) {
  if (!env.DRESS) return new Response("R2 바인딩(DRESS) 없음", { status: 500 });

  const key = Array.isArray(params.path) ? params.path.join("/") : String(params.path || "");
  if (!key) return new Response("key 필요", { status: 400 });

  const obj = await env.DRESS.get(key);
  if (!obj) return new Response("Not Found", { status: 404 });

  const h = new Headers();
  obj.writeHttpMetadata(h);
  h.set("etag", obj.httpEtag);
  h.set("Access-Control-Allow-Origin", "*");
  if (!h.get("cache-control")) h.set("cache-control", "public, max-age=31536000, immutable");
  return new Response(obj.body, { headers: h });
}
