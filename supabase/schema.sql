-- RG Fit: tabelas próprias. Não altera os sistemas RG3D ou Medical R.G.
begin;
create table if not exists public.rgfit_records (
 user_id uuid not null references auth.users(id) on delete cascade,
 id text not null check(length(id) between 1 and 100),
 kind text not null check(kind in ('profile','plan','meals','workouts','weights')),
 data jsonb not null default '{}'::jsonb check(octet_length(data::text)<500000),
 deleted boolean not null default false,
 revision bigint not null default 1,
 updated_at timestamptz not null default now(),
 primary key(user_id,id)
);
alter table public.rgfit_records enable row level security;
do $$ begin
 if not exists(select 1 from pg_policies where schemaname='public' and tablename='rgfit_records' and policyname='rgfit_read_own') then
 create policy rgfit_read_own on public.rgfit_records for select to authenticated using(user_id=auth.uid());
 end if;
end $$;
grant select on public.rgfit_records to authenticated;
revoke insert, update, delete on public.rgfit_records from anon, authenticated;
create or replace function public.rgfit_apply(payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare
 actor uuid:=auth.uid(); existing public.rgfit_records; target_id text:=payload->>'id';
 expected bigint:=coalesce((payload->>'expected_revision')::bigint,0);
 target_kind text:=payload->>'kind'; target_data jsonb:=coalesce(payload->'data','{}');
 target_deleted boolean:=coalesce((payload->>'deleted')::boolean,false);
begin
 if actor is null then raise exception 'Inicie sessão'; end if;
 if length(target_id) not between 1 and 100 or target_kind not in ('profile','plan','meals','workouts','weights') or jsonb_typeof(target_data)!='object' or octet_length(target_data::text)>499000 then raise exception 'Registo inválido'; end if;
 -- Bloqueio por utilizador evita corrida entre as duas primeiras inserções.
 perform pg_advisory_xact_lock(hashtextextended(actor::text,0));
 select * into existing from public.rgfit_records where user_id=actor and id=target_id for update;
 if found then
  if existing.revision!=expected then return jsonb_build_object('applied',false,'server',to_jsonb(existing)); end if;
  update public.rgfit_records set kind=target_kind,data=target_data,deleted=target_deleted,revision=revision+1,updated_at=now() where user_id=actor and id=target_id returning * into existing;
 else
  if expected!=0 then raise exception 'Registo inexistente. Recarregue os dados da conta.'; end if;
  insert into public.rgfit_records(user_id,id,kind,data,deleted) values(actor,target_id,target_kind,target_data,target_deleted) returning * into existing;
 end if;
 return jsonb_build_object('applied',true,'server',to_jsonb(existing));
end $$;
revoke all on function public.rgfit_apply(jsonb) from public, anon;
grant execute on function public.rgfit_apply(jsonb) to authenticated;
create table if not exists public.rgfit_ai_members(user_id uuid primary key references auth.users(id) on delete cascade);
create table if not exists public.rgfit_ai_usage(user_id uuid references auth.users(id) on delete cascade,day date not null,calls integer not null default 0,primary key(user_id,day));
alter table public.rgfit_ai_members enable row level security;
alter table public.rgfit_ai_usage enable row level security;
revoke all on public.rgfit_ai_members,public.rgfit_ai_usage from anon,authenticated;
create or replace function public.rgfit_claim_ai() returns integer language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid(); used integer; today date:=(now() at time zone 'Europe/Lisbon')::date;
begin
 if actor is null or not exists(select 1 from public.rgfit_ai_members where user_id=actor) then raise exception 'Análise de fotos não ativada para esta conta.'; end if;
 insert into public.rgfit_ai_usage(user_id,day,calls) values(actor,today,1) on conflict(user_id,day) do update set calls=public.rgfit_ai_usage.calls+1 where public.rgfit_ai_usage.calls<30 returning calls into used;
 if used is null then raise exception 'Limite diário de 30 análises atingido.'; end if;
 return used;
end $$;
revoke all on function public.rgfit_claim_ai() from public,anon;
grant execute on function public.rgfit_claim_ai() to authenticated;
commit;
-- Depois de criar o seu utilizador em Authentication > Users, execute:
-- insert into public.rgfit_ai_members(user_id)
-- select id from auth.users where lower(email)=lower('SEU_EMAIL')
-- on conflict do nothing;
