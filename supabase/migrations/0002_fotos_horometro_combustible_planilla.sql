-- ORVEXA · fotos, mantenimiento por horómetro, combustible y cierre de planilla

-- ---------------------------------------------------------------- fotos y horómetro en registros
alter table public.daily_reports
  add column photos text[] not null default '{}',
  add column hour_meter numeric(10,1);
alter table public.maintenance_logs add column photos text[] not null default '{}';

-- ---------------------------------------------------------------- planes de mantenimiento por horómetro
create table public.maintenance_plans (
  id uuid primary key default gen_random_uuid(),
  machine_id uuid not null references public.machines(id) on delete cascade,
  type public.maintenance_type not null,
  label text not null,
  interval_hours numeric(8,1) not null check (interval_hours > 0),
  last_done_hours numeric(10,1) not null default 0,
  last_done_date date,
  created_at timestamptz not null default now()
);
create index on public.maintenance_plans (machine_id);

-- ---------------------------------------------------------------- combustible
create table public.fuel_logs (
  id uuid primary key default gen_random_uuid(),
  machine_id uuid not null references public.machines(id) on delete cascade,
  project_id uuid references public.projects(id) on delete set null,
  reported_by uuid references public.profiles(id) on delete set null,
  log_date date not null default current_date,
  gallons numeric(8,2) not null check (gallons > 0),
  cost_gtq numeric(10,2) not null default 0 check (cost_gtq >= 0),
  hour_meter numeric(10,1),
  fx_rate numeric(8,4) not null default 7.64,
  photos text[] not null default '{}',
  notes text,
  created_at timestamptz not null default now()
);
create index on public.fuel_logs (machine_id, log_date);
create index on public.fuel_logs (project_id);
create index on public.fuel_logs (reported_by);

-- ---------------------------------------------------------------- planilla
create type public.payroll_adjustment_kind as enum ('adelanto', 'descuento', 'bono');
create type public.payroll_status as enum ('abierto', 'pagado');

create table public.payroll_adjustments (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.profiles(id) on delete cascade,
  adj_date date not null default current_date,
  kind public.payroll_adjustment_kind not null,
  amount numeric(10,2) not null check (amount > 0), -- Q
  note text,
  created_at timestamptz not null default now()
);
create index on public.payroll_adjustments (person_id, adj_date);

create table public.payroll_periods (
  id uuid primary key default gen_random_uuid(),
  start_date date not null,
  end_date date not null,
  status public.payroll_status not null default 'abierto',
  paid_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  check (end_date >= start_date)
);

create table public.payroll_payments (
  id uuid primary key default gen_random_uuid(),
  period_id uuid not null references public.payroll_periods(id) on delete cascade,
  person_id uuid references public.profiles(id) on delete set null,
  person_name text not null,
  role text not null,
  days integer not null default 0,
  gross numeric(12,2) not null default 0,       -- días × pago (Q)
  bonuses numeric(12,2) not null default 0,
  advances numeric(12,2) not null default 0,
  deductions numeric(12,2) not null default 0,
  net numeric(12,2) not null default 0,
  created_at timestamptz not null default now(),
  unique (period_id, person_id)
);
create index on public.payroll_payments (person_id);

-- ---------------------------------------------------------------- disparadores
create or replace function public.fill_daily_report()
returns trigger language plpgsql security definer set search_path = public as $$
declare a public.assignments;
begin
  select * into a from public.assignments where id = new.assignment_id;
  if a.id is null then raise exception 'Asignación no existe'; end if;
  new.project_id := a.project_id;
  new.machine_id := a.machine_id;
  if not public.is_admin() then
    new.operator_id := auth.uid();
    new.pay_day := case when tg_op = 'INSERT' then true else old.pay_day end;
  end if;
  if new.downtime_hours = 0 then new.downtime_reason := null; end if;
  new.operator_pay := case when new.pay_day then a.operator_daily_pay else 0 end;
  new.helper_pay := case when new.pay_day and a.helper_id is not null and new.helper_present then a.helper_daily_pay else 0 end;
  if tg_op = 'INSERT' then
    select usd_to_gtq into new.fx_rate from public.company_settings where id = 1;
  else
    new.fx_rate := old.fx_rate;
  end if;
  if new.hour_meter is not null then
    update public.machines set hour_meter = greatest(coalesce(hour_meter, 0), new.hour_meter) where id = a.machine_id;
  end if;
  return new;
end $$;

create or replace function public.fill_maintenance()
returns trigger language plpgsql security definer set search_path = public as $$
declare h numeric;
begin
  if not public.is_admin() then new.reported_by := auth.uid(); end if;
  if new.hour_meter is not null then
    update public.machines set hour_meter = greatest(coalesce(hour_meter, 0), new.hour_meter) where id = new.machine_id;
  end if;
  -- Reinicia el contador del plan de ese tipo de mantenimiento
  select coalesce(new.hour_meter, hour_meter, 0) into h from public.machines where id = new.machine_id;
  update public.maintenance_plans set last_done_hours = h, last_done_date = new.log_date
    where machine_id = new.machine_id and type = new.type;
  return new;
end $$;

create or replace function public.fill_fuel()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then new.reported_by := auth.uid(); end if;
  select usd_to_gtq into new.fx_rate from public.company_settings where id = 1;
  if new.hour_meter is not null then
    update public.machines set hour_meter = greatest(coalesce(hour_meter, 0), new.hour_meter) where id = new.machine_id;
  end if;
  return new;
end $$;
create trigger fuel_fill before insert on public.fuel_logs for each row execute function public.fill_fuel();

-- ---------------------------------------------------------------- cierre de planilla (servidor)
create or replace function public.close_payroll(p_period uuid)
returns integer language plpgsql security definer set search_path = public as $$
declare per public.payroll_periods; n integer;
begin
  if not public.is_admin() then raise exception 'Solo administradores'; end if;
  select * into per from public.payroll_periods where id = p_period for update;
  if per.id is null then raise exception 'Periodo no existe'; end if;
  if per.status = 'pagado' then raise exception 'El periodo ya está cerrado'; end if;

  insert into public.payroll_payments (period_id, person_id, person_name, role, days, gross, bonuses, advances, deductions, net)
  with work as (
    select r.operator_id as person_id, count(*) filter (where r.operator_pay > 0) as days, sum(r.operator_pay) as gross
      from public.daily_reports r
     where r.report_date between per.start_date and per.end_date and r.operator_id is not null
     group by r.operator_id
    union all
    select a.helper_id, count(*) filter (where r.helper_pay > 0), sum(r.helper_pay)
      from public.daily_reports r join public.assignments a on a.id = r.assignment_id
     where r.report_date between per.start_date and per.end_date and a.helper_id is not null and r.helper_pay > 0
     group by a.helper_id
  ), w as (
    select person_id, sum(days)::int days, sum(gross) gross from work group by person_id
  ), adj as (
    select person_id,
           sum(amount) filter (where kind = 'bono') bonuses,
           sum(amount) filter (where kind = 'adelanto') advances,
           sum(amount) filter (where kind = 'descuento') deductions
      from public.payroll_adjustments
     where adj_date between per.start_date and per.end_date
     group by person_id
  ), people as (
    select person_id from w union select person_id from adj
  )
  select p_period, pr.id, pr.full_name, pr.role::text,
         coalesce(w.days, 0), coalesce(w.gross, 0),
         coalesce(adj.bonuses, 0), coalesce(adj.advances, 0), coalesce(adj.deductions, 0),
         coalesce(w.gross, 0) + coalesce(adj.bonuses, 0) - coalesce(adj.advances, 0) - coalesce(adj.deductions, 0)
    from people
    join public.profiles pr on pr.id = people.person_id
    left join w on w.person_id = people.person_id
    left join adj on adj.person_id = people.person_id;
  get diagnostics n = row_count;

  update public.payroll_periods set status = 'pagado', paid_at = now() where id = p_period;
  return n;
end $$;

create or replace function public.reopen_payroll(p_period uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Solo administradores'; end if;
  delete from public.payroll_payments where period_id = p_period;
  update public.payroll_periods set status = 'abierto', paid_at = null where id = p_period;
end $$;

revoke execute on function public.fill_fuel() from public, anon, authenticated;
revoke execute on function public.fill_daily_report() from public, anon, authenticated;
revoke execute on function public.fill_maintenance() from public, anon, authenticated;
revoke execute on function public.close_payroll(uuid) from public, anon;
revoke execute on function public.reopen_payroll(uuid) from public, anon;
grant execute on function public.close_payroll(uuid), public.reopen_payroll(uuid) to authenticated;

-- ---------------------------------------------------------------- RLS
alter table public.maintenance_plans enable row level security;
alter table public.fuel_logs enable row level security;
alter table public.payroll_adjustments enable row level security;
alter table public.payroll_periods enable row level security;
alter table public.payroll_payments enable row level security;

create policy plans_admin on public.maintenance_plans for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy plans_mine on public.maintenance_plans for select to authenticated
  using (machine_id in (select machine_id from public.assignments where id in (select public.my_assignment_ids())));

create policy fuel_admin on public.fuel_logs for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy fuel_mine_select on public.fuel_logs for select to authenticated
  using (machine_id in (select machine_id from public.assignments where id in (select public.my_assignment_ids())));
create policy fuel_mine_insert on public.fuel_logs for insert to authenticated
  with check (machine_id in (select machine_id from public.assignments where id in (select public.my_assignment_ids()))
              and (select public.is_active_user()));

create policy adj_admin on public.payroll_adjustments for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy adj_mine on public.payroll_adjustments for select to authenticated
  using (person_id = (select auth.uid()));

create policy periods_admin on public.payroll_periods for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy periods_mine on public.payroll_periods for select to authenticated
  using (id in (select period_id from public.payroll_payments where person_id = (select auth.uid())));

create policy payments_admin on public.payroll_payments for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy payments_mine on public.payroll_payments for select to authenticated
  using (person_id = (select auth.uid()));

-- ---------------------------------------------------------------- fotos (Storage)
-- Rutas: r/<asignación>/<archivo> (reportes), m/<máquina>/<archivo> (mantenimiento), f/<máquina>/<archivo> (combustible)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('evidencias', 'evidencias', false, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'image/heic'])
on conflict (id) do nothing;

create or replace function public.can_access_photo(p_name text)
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_admin() or (
    public.is_active_user() and case (storage.foldername(p_name))[1]
      when 'r' then (storage.foldername(p_name))[2] in (select id::text from public.my_assignment_ids() id)
      when 'm' then (storage.foldername(p_name))[2] in
        (select machine_id::text from public.assignments where id in (select public.my_assignment_ids()))
      when 'f' then (storage.foldername(p_name))[2] in
        (select machine_id::text from public.assignments where id in (select public.my_assignment_ids()))
      else false end
  );
$$;
revoke execute on function public.can_access_photo(text) from public, anon;
grant execute on function public.can_access_photo(text) to authenticated;

create policy evidencias_select on storage.objects for select to authenticated
  using (bucket_id = 'evidencias' and public.can_access_photo(name));
create policy evidencias_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'evidencias' and public.can_access_photo(name));
create policy evidencias_delete on storage.objects for delete to authenticated
  using (bucket_id = 'evidencias' and (select public.is_admin()));
