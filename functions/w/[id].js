/* 위젯 짧은 URL — /w/{id}
   SOOP 게시판이 쿼리스트링 포함 iframe(특히 img=https%3A%2F%2F...)을 EMBED_BLOCK으로
   차단하므로, 쿼리 없는 URL로 받아 R2에 저장된 쿼리를 읽어 런타임으로 302 리다이렉트.
   저장 위치: widgets/{id}.txt (내용 = 쿼리스트링 원문) */
const RUNTIME = "https://straker.pages.dev/runtime";

export async function onRequestGet({ params, env }) {
  const id = String(params.id || "");
  if (!/^[a-z0-9]{4,24}$/i.test(id)) return new Response("bad id", { status: 400 });
  if (!env.DRESS) return new Response("R2 바인딩(DRESS) 없음", { status: 500 });

  const obj = await env.DRESS.get(`widgets/${id}.txt`);
  if (!obj) return new Response("not found", { status: 404 });

  const qs = (await obj.text()).trim();
  if (!qs) return new Response("empty", { status: 404 });

  return Response.redirect(`${RUNTIME}?${qs}`, 302);
}
