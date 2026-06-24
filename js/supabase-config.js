// 히라 사이트 · Supabase 설정
// anon key는 클라이언트 노출 전제의 공개 키 — RLS 정책으로 데이터 보호됨.
const SUPABASE_URL  = 'https://lqwjfdptlmyfhjcmildd.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxxd2pmZHB0bG15ZmhqY21pbGRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIyOTA4MDksImV4cCI6MjA5Nzg2NjgwOX0.lT0jVnUmpce3OzV8xduO8SgUjIRuVcRo7Ok1MlEboEE';

let _sb = null;
function initSupabase(){
  if(!_sb && window.supabase){
    _sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON);
  }
  return _sb;
}
