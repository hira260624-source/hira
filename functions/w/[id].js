/* 위젯 짧은 URL — /w/{id}
   ① SOOP 게시판이 쿼리 포함 iframe(특히 img=https%3A%2F%2F...)을 EMBED_BLOCK으로 차단하므로
      쿼리 없는 URL로 받아 R2(widgets/{id}.txt)에 저장된 쿼리를 사용.
   ② 공용 런타임의 카드 폭이 --w 기본 370px 고정이라 큰 캔버스에서 작게 렌더되는 문제가 있어
      302 리다이렉트 대신 HTML을 프록시하며 <head>에 3가지를 주입한다.
        1) replaceState — 프록시 주소엔 쿼리가 없어 location.search가 비므로 복원
        2) base 태그    — 런타임의 상대경로 리소스 보호
        3) 카드 크기 CSS — 370px 제한 해제, 캔버스의 s%(기본 96)까지 채움
   ⚠️ 주입 순서 고정: 1) script가 2) base보다 앞.
      base가 먼저면 replaceState의 URL 기준이 straker 도메인이 되어 SecurityError. */
const RUNTIME = "https://straker.pages.dev/runtime";

export async function onRequestGet({ params, env }) {
  const id = String(params.id || "");
  if (!/^[a-z0-9]{4,24}$/i.test(id)) return new Response("bad id", { status: 400 });
  if (!env.DRESS) return new Response("R2 바인딩(DRESS) 없음", { status: 500 });

  const obj = await env.DRESS.get(`widgets/${id}.txt`);
  if (!obj) return new Response("not found", { status: 404 });

  const qs = (await obj.text()).trim();
  if (!qs) return new Response("empty", { status: 404 });

  let up;
  try {
    up = await fetch(`${RUNTIME}?${qs}`);
  } catch (e) {
    return Response.redirect(`${RUNTIME}?${qs}`, 302);
  }
  if (!up.ok) return Response.redirect(`${RUNTIME}?${qs}`, 302); // 프록시 실패 시 폴백

  let html = await up.text();

  // s 파라미터(30~100, 기본 96)로 카드 채움 비율 조절
  const sp = new URLSearchParams(qs);
  const s = Math.min(100, Math.max(30, parseInt(sp.get("s") || "96", 10) || 96));

  const inject =
    `<script>history.replaceState(null,'',location.pathname+${JSON.stringify("?" + qs)})</` + `script>` +
    `<base href="https://straker.pages.dev/">` +
    `<style>.card{width:min(${s}vw,calc(${s}vh*var(--ar,.7048)))!important}</style>`;
  html = html.replace("<head>", "<head>" + inject);

  return new Response(html, {
    headers: { "content-type": "text/html;charset=utf-8", "cache-control": "public,max-age=300" }
  });
}
