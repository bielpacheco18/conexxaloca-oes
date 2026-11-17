# Conexxa — Cadastro + Painel Admin

Arquivos
- index.html            → formulário público do motorista
- gestao-7f3a9c.html    → painel admin (rota: /gestao-7f3a9c) — NÃO é linkado em lugar nenhum
- sql/schema.sql        → tabela, RLS e bucket privado (rodar no Supabase)
- vercel.json           → cabeçalhos de segurança + noindex/no-store no painel

Setup (10 min)
1. supabase.com → New project.
2. SQL Editor → cole sql/schema.sql → Run.
3. Authentication → Providers → Email: DESLIGUE "Allow new users to sign up".
4. Authentication → Users → Add user (seu e-mail + senha forte).
5. SQL Editor: insert into public.admins (email) values ('seu@email.com');
6. Project Settings → API: copie a URL e a chave "anon public".
7. Cole URL + chave no CONFIG de index.html E de gestao-7f3a9c.html.
8. (opcional) troque 7f3a9c por outro código: renomeie o arquivo e ajuste a regra no vercel.json.
9. Deploy: npx vercel deploy --prod  (ou GitHub → Vercel).
10. Acesse https://SEU-DOMINIO/gestao-7f3a9c e faça login.
