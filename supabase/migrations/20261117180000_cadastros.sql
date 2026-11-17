-- =====================================================================
-- CONEXXA LOCAÇÕES — schema do cadastro de motoristas (Supabase)
-- Rode inteiro em: Supabase > SQL Editor > New query > Run
-- =====================================================================

-- 1) Tabela principal ---------------------------------------------------
create table if not exists public.cadastros (
  id                    uuid primary key,
  created_at            timestamptz not null default now(),
  status                text not null default 'novo'
                        check (status in ('novo','em_analise','aprovado','reprovado')),
  notas                 text,

  nome_completo         text not null check (char_length(nome_completo) between 3 and 150),
  rg                    text not null check (char_length(rg) between 4 and 30),
  cpf                   text not null check (cpf ~ '^\d{3}\.\d{3}\.\d{3}-\d{2}$'),
  telefone              text not null check (char_length(telefone) between 10 and 20),
  instagram             text check (instagram ~ '^@[A-Za-z0-9._]{1,30}$'),  -- opcional
  endereco_moradia      text not null check (char_length(endereco_moradia) between 8 and 300),
  endereco_pernoite     text not null check (char_length(endereco_pernoite) between 8 and 300),

  km_medio_dia          integer not null check (km_medio_dia between 1 and 1500),
  horario_inicio        text not null,
  horario_fim           text not null,
  apps                  text[] not null default '{}',
  apps_outro            text,
  tempo_uber            text not null
                        check (tempo_uber in ('0 a 1 ano','1 a 2 anos','2 a 4 anos','Mais de 4 anos')),
  categoria_black       text not null check (categoria_black in ('Sim','Não')),
  faz_particular        text not null check (faz_particular in ('Sim','Não')),
  outra_atividade       text not null check (outra_atividade in ('Sim','Não')),
  outra_atividade_detalhe text check (char_length(outra_atividade_detalhe) <= 150),
  exp_eletrico          text not null check (exp_eletrico in ('Sim','Não')),
  exp_eletrico_detalhe  text,

  contato1_nome         text not null,
  contato1_telefone     text not null,
  contato1_parentesco   text,
  contato2_nome         text not null,
  contato2_telefone     text not null,
  contato2_parentesco   text,

  cnh_path              text not null,
  selfie_path           text not null,
  comprovante_path      text not null,

  lgpd_aceite_em        timestamptz not null default now()
);

-- Se você JÁ rodou a versão anterior deste arquivo, rode também estas 2 linhas:
-- alter table public.cadastros add column if not exists instagram text check (instagram ~ '^@[A-Za-z0-9._]{1,30}$');
-- alter table public.cadastros add column if not exists outra_atividade text not null default 'Não',
--                              add column if not exists outra_atividade_detalhe text;

create index if not exists cadastros_created_idx on public.cadastros (created_at desc);
create index if not exists cadastros_status_idx  on public.cadastros (status);

-- 2) Lista de administradores ------------------------------------------
create table if not exists public.admins (
  email text primary key
);
alter table public.admins enable row level security;   -- sem policies = ninguém lê direto

create or replace function public.is_admin()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (select 1 from public.admins where lower(email) = lower(auth.jwt() ->> 'email'));
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

-- 3) RLS da tabela ------------------------------------------------------
alter table public.cadastros enable row level security;

-- Público (formulário): SOMENTE inserir, e sempre como "novo" e sem notas.
drop policy if exists "form_insere" on public.cadastros;
create policy "form_insere" on public.cadastros
  for insert to anon
  with check (status = 'novo' and notas is null);

-- Admin: ler e atualizar (status / notas). Sem delete.
drop policy if exists "admin_le" on public.cadastros;
create policy "admin_le" on public.cadastros
  for select to authenticated using (public.is_admin());

drop policy if exists "admin_atualiza" on public.cadastros;
create policy "admin_atualiza" on public.cadastros
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

revoke all on public.cadastros from anon, authenticated;
grant insert on public.cadastros to anon;
grant select, update on public.cadastros to authenticated;

-- 4) Storage privado para documentos ------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('documentos', 'documentos', false, 8388608,
        array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do update
  set public = false, file_size_limit = 8388608,
      allowed_mime_types = array['image/jpeg','image/png','image/webp','application/pdf'];

-- Público só consegue ENVIAR (nunca listar/ler). Admin só lê.
drop policy if exists "docs_upload_publico" on storage.objects;
create policy "docs_upload_publico" on storage.objects
  for insert to anon with check (bucket_id = 'documentos');

drop policy if exists "docs_admin_le" on storage.objects;
create policy "docs_admin_le" on storage.objects
  for select to authenticated using (bucket_id = 'documentos' and public.is_admin());

