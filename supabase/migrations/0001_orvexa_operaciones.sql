-- ORVEXA · Operaciones (admin / operador)
-- Moneda: US$. Cobro por inca (precio por proyecto) o por día (bobcat).

create type public.user_role as enum ('admin', 'operador', 'ayudante');
create type public.machine_type as enum ('hincadora', 'bobcat', 'otra');
create type public.machine_status as enum ('disponible', 'en_proyecto', 'mantenimiento', 'fuera_servicio');
create type public.project_type as enum ('hincado', 'bobcat', 'otro');
create type public.project_status as enum ('planificado', 'activo', 'pausado', 'completado');
create type public.billing_mode as enum ('por_unidad', 'por_dia');
create type public.maintenance_type as enum ('preventivo', 'correctivo', 'cambio_aceite', 'engrase', 'filtros', 'llantas_orugas', 'otro');
create type public.expense_category as enum ('renta', 'seguro', 'combustible', 'impuesto', 'planilla_extra', 'otro');
create type public.recurrence as enum ('unica', 'semanal', 'mensual', 'anual');

-- ---------------------------------------------------------------- perfiles
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  username text unique,
  phone text,
  role public.user_role not null default 'operador',
  active boolean not null default false,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin' and active);
$$;

create or replace function public.is_active_user()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and active);
$$;

-- ¿La app necesita crear el primer administrador?
create or replace function public.needs_setup()
returns boolean language sql stable security definer set search_path = public as $$
  select not exists (select 1 from public.profiles where role = 'admin');
$$;
grant execute on function public.needs_setup() to anon, authenticated;

-- Cada usuario nuevo entra como operador INACTIVO; solo la función admin-users lo activa.
create or replace function public.orvexa_handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, username)
  values (new.id,
          coalesce(new.raw_user_meta_data->>'full_name', ''),
          nullif(new.raw_user_meta_data->>'username', ''));
  return new;
end $$;

-- Proyecto reutilizado: se desactiva el disparador de la app anterior (insertaba en public.users con un rol inexistente).
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created_orvexa
  after insert on auth.users for each row execute function public.orvexa_handle_new_user();

-- ---------------------------------------------------------------- máquinas
create table public.machines (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text,
  type public.machine_type not null default 'hincadora',
  status public.machine_status not null default 'disponible',
  operator_daily_pay numeric(10,2) not null default 0,  -- pago diario sugerido al operador
  helper_daily_pay numeric(10,2) not null default 0,    -- pago diario sugerido al ayudante (hincadora)
  hour_meter numeric(10,1),
  notes text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------- proyectos
create table public.projects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  client text,
  location text,
  type public.project_type not null default 'hincado',
  status public.project_status not null default 'planificado',
  billing_mode public.billing_mode not null default 'por_unidad',
  total_units integer not null default 0,           -- incas totales a trabajar
  daily_target integer not null default 0,          -- meta diaria (ej. 200 incas/día)
  price_per_unit numeric(10,2) not null default 0,  -- US$ por inca (13 – 30)
  daily_rate numeric(10,2) not null default 0,      -- US$ por día (proyectos por día)
  start_date date,
  work_days_per_week smallint not null default 6 check (work_days_per_week between 1 and 7),
  notes text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------- asignaciones
create table public.assignments (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  machine_id uuid not null references public.machines(id) on delete restrict,
  operator_id uuid references public.profiles(id) on delete set null,
  helper_id uuid references public.profiles(id) on delete set null,
  operator_daily_pay numeric(10,2) not null default 0,
  helper_daily_pay numeric(10,2) not null default 0,
  start_date date not null default current_date,
  end_date date,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create index on public.assignments (project_id);
create index on public.assignments (machine_id);
create index on public.assignments (operator_id);
create index on public.assignments (helper_id);

-- ---------------------------------------------------------------- reportes diarios
create table public.daily_reports (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.assignments(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  machine_id uuid not null references public.machines(id) on delete cascade,
  operator_id uuid references public.profiles(id) on delete set null,
  report_date date not null default current_date,
  units_done integer not null default 0 check (units_done >= 0),
  hours_worked numeric(5,1),
  helper_present boolean not null default true,
  notes text,
  -- pago congelado al momento del reporte (si luego cambia la tarifa, el histórico no cambia)
  operator_pay numeric(10,2) not null default 0,
  helper_pay numeric(10,2) not null default 0,
  created_at timestamptz not null default now(),
  unique (assignment_id, report_date)
);
create index on public.daily_reports (project_id, report_date);
create index on public.daily_reports (operator_id);
create index on public.daily_reports (machine_id);

-- Copia proyecto, máquina y pagos desde la asignación (el operador no los puede falsear)
create or replace function public.fill_daily_report()
returns trigger language plpgsql security definer set search_path = public as $$
declare a public.assignments;
begin
  select * into a from public.assignments where id = new.assignment_id;
  if a.id is null then raise exception 'Asignación no existe'; end if;
  new.project_id := a.project_id;
  new.machine_id := a.machine_id;
  if not public.is_admin() then new.operator_id := auth.uid(); end if;
  new.operator_pay := a.operator_daily_pay;
  new.helper_pay := case when a.helper_id is not null and new.helper_present then a.helper_daily_pay else 0 end;
  return new;
end $$;
create trigger daily_reports_fill before insert or update on public.daily_reports
  for each row execute function public.fill_daily_report();

-- ---------------------------------------------------------------- mantenimiento
create table public.maintenance_logs (
  id uuid primary key default gen_random_uuid(),
  machine_id uuid not null references public.machines(id) on delete cascade,
  project_id uuid references public.projects(id) on delete set null,
  reported_by uuid references public.profiles(id) on delete set null,
  log_date date not null default current_date,
  type public.maintenance_type not null default 'preventivo',
  description text not null default '',
  hour_meter numeric(10,1),
  cost numeric(10,2) not null default 0,
  created_at timestamptz not null default now()
);
create index on public.maintenance_logs (machine_id, log_date);
create index on public.maintenance_logs (project_id);
create index on public.maintenance_logs (reported_by);

create or replace function public.fill_maintenance()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then new.reported_by := auth.uid(); end if;
  if new.hour_meter is not null then
    update public.machines set hour_meter = greatest(coalesce(hour_meter, 0), new.hour_meter) where id = new.machine_id;
  end if;
  return new;
end $$;
create trigger maintenance_fill before insert on public.maintenance_logs
  for each row execute function public.fill_maintenance();

-- ---------------------------------------------------------------- obligaciones / gastos
create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  category public.expense_category not null default 'otro',
  description text not null,
  amount numeric(12,2) not null default 0,
  recurrence public.recurrence not null default 'mensual',
  due_date date not null default current_date,
  paid boolean not null default false,
  paid_date date,
  project_id uuid references public.projects(id) on delete set null,
  created_at timestamptz not null default now()
);
create index on public.expenses (project_id);

-- ---------------------------------------------------------------- ajustes de empresa (una fila)
create table public.company_settings (
  id smallint primary key default 1 check (id = 1),
  company_name text not null default 'ORVEXA',
  income_tax_pct numeric(5,2) not null default 5,   -- % sobre ingresos (ajustable)
  employer_social_pct numeric(5,2) not null default 0, -- % patronal sobre planilla (ej. IGSS) – opcional
  updated_at timestamptz not null default now()
);
insert into public.company_settings (id) values (1);

-- ---------------------------------------------------------------- RLS
alter table public.profiles enable row level security;
alter table public.machines enable row level security;
alter table public.projects enable row level security;
alter table public.assignments enable row level security;
alter table public.daily_reports enable row level security;
alter table public.maintenance_logs enable row level security;
alter table public.expenses enable row level security;
alter table public.company_settings enable row level security;

-- perfiles
create policy profiles_select on public.profiles for select to authenticated
  using (id = (select auth.uid()) or (select public.is_admin()));
create policy profiles_admin_write on public.profiles for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

-- admin: todo
create policy machines_admin on public.machines for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy projects_admin on public.projects for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy assignments_admin on public.assignments for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy reports_admin on public.daily_reports for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy maint_admin on public.maintenance_logs for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy expenses_admin on public.expenses for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy settings_admin on public.company_settings for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

-- operador / ayudante: solo lo suyo
create or replace function public.my_assignment_ids()
returns setof uuid language sql stable security definer set search_path = public as $$
  select id from public.assignments
  where (operator_id = auth.uid() or helper_id = auth.uid()) and public.is_active_user();
$$;

create policy assignments_mine on public.assignments for select to authenticated
  using (id in (select public.my_assignment_ids()));
create policy projects_mine on public.projects for select to authenticated
  using (id in (select project_id from public.assignments where id in (select public.my_assignment_ids())));
create policy machines_mine on public.machines for select to authenticated
  using (id in (select machine_id from public.assignments where id in (select public.my_assignment_ids())));

create policy reports_mine_select on public.daily_reports for select to authenticated
  using (assignment_id in (select public.my_assignment_ids()));
create policy reports_mine_insert on public.daily_reports for insert to authenticated
  with check (assignment_id in (select id from public.assignments
                                where operator_id = (select auth.uid()) and active)
              and (select public.is_active_user()));
create policy reports_mine_update on public.daily_reports for update to authenticated
  using (operator_id = (select auth.uid()) and report_date >= current_date - 2)
  with check (operator_id = (select auth.uid()));

create policy maint_mine_select on public.maintenance_logs for select to authenticated
  using (machine_id in (select machine_id from public.assignments where id in (select public.my_assignment_ids())));
create policy maint_mine_insert on public.maintenance_logs for insert to authenticated
  with check (machine_id in (select machine_id from public.assignments where id in (select public.my_assignment_ids()))
              and (select public.is_active_user()));

-- nombres de compañeros de asignación (operador ve nombre de su ayudante y viceversa)
create or replace function public.assignment_people(p_assignment uuid)
returns table (operator_name text, helper_name text)
language sql stable security definer set search_path = public as $$
  select o.full_name, h.full_name
  from public.assignments a
  left join public.profiles o on o.id = a.operator_id
  left join public.profiles h on h.id = a.helper_id
  where a.id = p_assignment and (public.is_admin() or a.id in (select public.my_assignment_ids()));
$$;

revoke execute on function public.orvexa_handle_new_user() from public, anon, authenticated;
revoke execute on function public.fill_daily_report() from public, anon, authenticated;
revoke execute on function public.fill_maintenance() from public, anon, authenticated;

-- Funciones internas: solo usuarios con sesión
revoke execute on function public.is_admin() from public, anon;
revoke execute on function public.is_active_user() from public, anon;
revoke execute on function public.my_assignment_ids() from public, anon;
revoke execute on function public.assignment_people(uuid) from public, anon;
grant execute on function public.is_admin(), public.is_active_user(), public.my_assignment_ids(), public.assignment_people(uuid) to authenticated;

-- Inicio de una obligación recurrente (due_date = próximo vencimiento, avanza al pagar)
alter table public.expenses add column start_date date not null default current_date;

-- Meta diaria de cada máquina en el proyecto (si es null se usa la del proyecto)
alter table public.assignments add column daily_target integer check (daily_target is null or daily_target >= 0);
