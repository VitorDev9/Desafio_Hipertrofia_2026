-- Execute no SQL Editor do Supabase como administrador. Uma única instalação.
begin;
create table public.challenge_settings (
 id integer primary key check(id=1), current_week integer not null check(current_week between 1 and 20), revision bigint not null default 0
);
insert into public.challenge_settings values(1,14,0);
create table public.participants (
 name text primary key check(name in ('Vitor','Alan','Gleicon','André')),
 status text not null check(status in ('Ativo','Pausado')),
"weight" numeric not null check ("weight" between 0 and 1000),
"armR" numeric not null check ("armR" between 0 and 1000),
"armL" numeric not null check ("armL" between 0 and 1000),
"foreR" numeric not null check ("foreR" between 0 and 1000),
"foreL" numeric not null check ("foreL" between 0 and 1000),
"shoulders" numeric not null check ("shoulders" between 0 and 1000), check(weight>0)
);
create table public.weekly_records (
 name text not null references public.participants(name),
 week integer not null check(week between 1 and 20),
 date date,
 status text not null check(status in ('Ativo','Pausado')),
"weight" numeric not null check ("weight" between 0 and 1000),
"armR" numeric not null check ("armR" between 0 and 1000),
"armL" numeric not null check ("armL" between 0 and 1000),
"foreR" numeric not null check ("foreR" between 0 and 1000),
"foreL" numeric not null check ("foreL" between 0 and 1000),
"shoulders" numeric not null check ("shoulders" between 0 and 1000),
"bench" numeric not null check ("bench" between 0 and 1000),
"reps" numeric not null check ("reps" between 0 and 1000),
 check(weight>0),check(reps=trunc(reps)), primary key(name,week)
);
alter table public.challenge_settings enable row level security;
revoke all on public.challenge_settings from anon, authenticated;
grant select on public.challenge_settings to anon, authenticated;
create policy group_read on public.challenge_settings for select to anon, authenticated using (true);
alter table public.participants enable row level security;
revoke all on public.participants from anon, authenticated;
grant select on public.participants to anon, authenticated;
create policy group_read on public.participants for select to anon, authenticated using (true);
alter table public.weekly_records enable row level security;
revoke all on public.weekly_records from anon, authenticated;
grant select on public.weekly_records to anon, authenticated;
create policy group_read on public.weekly_records for select to anon, authenticated using (true);
-- Desafio público: leitura e gravação via RPC sem login. Tabelas sem escrita direta.
-- SECURITY DEFINER usa nomes qualificados e restrições de esquema.
create function public.read_challenge() returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
 select jsonb_build_object('revision',s.revision,'state',case when (select count(*) from public.participants)=0 then null else jsonb_build_object(
 'currentWeek',s.current_week,
 'participants',(select jsonb_object_agg(p.name,to_jsonb(p)-'name') from public.participants p),
 'entries',coalesce((select jsonb_agg(to_jsonb(r)||jsonb_build_object('date',coalesce(r.date::text,'')) order by r.week,r.name) from public.weekly_records r),'[]'::jsonb)) end)
 into result from public.challenge_settings s where s.id=1;
 return result;
end $$;
-- Transação e revisão evitam sobrescrever silenciosamente outro dispositivo.
create function public.write_challenge(payload jsonb,expected_revision bigint) returns bigint language plpgsql security definer set search_path = '' as $$
declare actual bigint;
begin
 select revision into actual from public.challenge_settings where id=1 for update;
 if actual is distinct from expected_revision then raise exception 'Dados alterados em outro dispositivo. Sincronize e tente novamente'; end if;
 if jsonb_typeof(payload->'participants') is distinct from 'object' or jsonb_typeof(payload->'entries') is distinct from 'array' then raise exception 'Formato inválido'; end if;
 if (select count(*) from jsonb_object_keys(payload->'participants'))<>4 then raise exception 'São necessários quatro participantes'; end if;
 delete from public.weekly_records where true;
 delete from public.participants where true;
 insert into public.participants select x.* from jsonb_each(payload->'participants') p cross join lateral jsonb_populate_record(null::public.participants,p.value||jsonb_build_object('name',p.key)) x;
 insert into public.weekly_records select x.* from jsonb_array_elements(payload->'entries') e cross join lateral jsonb_populate_record(null::public.weekly_records,e.value||jsonb_build_object('date',nullif(e.value->>'date',''))) x;
 update public.challenge_settings set current_week=(payload->>'currentWeek')::integer,revision=actual+1 where id=1;
 return actual+1;
end $$;
revoke all on function public.read_challenge() from public, anon;
revoke all on function public.write_challenge(jsonb,bigint) from public, anon;
grant execute on function public.read_challenge() to anon, authenticated;
grant execute on function public.write_challenge(jsonb,bigint) to anon, authenticated;
commit;
