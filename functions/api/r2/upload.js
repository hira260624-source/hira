/* R2 업로드 — 바인딩 변수명: DRESS (버킷: hira-studio)
   POST multipart/form-data { file, dir? } → { ok, key, url }
   다른 프로젝트 이식 시: 바인딩만 연결하면 그대로 동작 */
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type"
};
const MAX = 20 * 1024 * 1024; // 20MB
const OK_TYPES = ["image/png","image/jpeg","image/webp","image/gif","image/avif"];

export function onRequestOptions() {
  return new Response(null, { headers: CORS });
}

export async function onRequestPost({ request, env }) {
  const j = (o, s = 200) =>
    new Response(JSON.stringify(o), { status: s, headers: { ...CORS, "Content-Type": "application/json" } });

  if (!env.DRESS) return j({ error: "R2 바인딩(DRESS) 없음" }, 500);

  try {
    const form = await request.formData();
    const file = form.get("file");
    if (!file || typeof file === "string") return j({ error: "file 필요" }, 400);
    if (file.size > MAX) return j({ error: "20MB 초과" }, 413);

    const type = file.type || "application/octet-stream";
    if (!OK_TYPES.includes(type)) return j({ error: "이미지 파일만 가능" }, 415);

    const dir = String(form.get("dir") || "studio").replace(/[^a-z0-9/_-]/gi, "");
    const ext = (type.split("/")[1] || "bin").replace("jpeg", "jpg");
    const key = `${dir}/${Date.now()}-${crypto.randomUUID().slice(0, 8)}.${ext}`;

    await env.DRESS.put(key, file.stream(), {
      httpMetadata: { contentType: type, cacheControl: "public, max-age=31536000, immutable" }
    });

    const origin = new URL(request.url).origin;
    return j({ ok: true, key, url: `${origin}/api/r2/file/${key}` });
  } catch (e) {
    return j({ error: String(e && e.message || e) }, 500);
  }
}
