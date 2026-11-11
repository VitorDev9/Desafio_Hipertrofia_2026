-- Execute SOMENTE se já executou o setup antigo com contas.
-- Este modo permite que qualquer visitante leia e altere o desafio.
begin;
drop policy if exists group_read on public.challenge_settings;
revoke all on public.challenge_settings from anon, authenticated;
grant select on public.challenge_settings to anon, authenticated;
create policy group_read on public.challenge_settings for select to anon, authenticated using (true);
drop policy if exists group_read on public.participants;
revoke all on public.participants from anon, authenticated;
grant select on public.participants to anon, authenticated;
create policy group_read on public.participants for select to anon, authenticated using (true);
drop policy if exists group_read on public.weekly_records;
revoke all on public.weekly_records from anon, authenticated;
grant select on public.weekly_records to anon, authenticated;
create policy group_read on public.weekly_records for select to anon, authenticated using (true);
create or replace function public.read_challenge() returns jsonb language plpgsql security definer set search_path = '' as $$
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
create or replace function public.write_challenge(payload jsonb,expected_revision bigint) returns bigint language plpgsql security definer set search_path = '' as $$
declare actual bigint;
begin
 select revision into actual from public.challenge_settings where id=1 for update;
 if actual is distinct from expected_revision then raise exception 'Dados alterados em outro dispositivo. Sincronize e tente novamente'; end if;
 if jsonb_typeof(payload->'participants') is distinct from 'object' or jsonb_typeof(payload->'entries') is distinct from 'array' then raise exception 'Formato inválido'; end if;
 if (select count(*) from jsonb_object_keys(payload->'participants'))<>4 then raise exception 'São necessários quatro participantes'; end if;
 delete from public.weekly_records;
 delete from public.participants;
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
-- A tabela challenge_members antiga pode permanecer; não é mais utilizada.
