-- ORVEXA · portal del cliente
-- El cliente solo ve el avance de los proyectos que el admin le asigna: producción, horas, paros
-- y fotos de los reportes. Nunca ve precios, pagos, costos, nombres del personal ni notas internas,
-- por eso no recibe permisos sobre las tablas: todo lo lee por funciones que filtran columnas.

-- ---------------------------------------------------------------- proyectos de cada cliente
create table public.project_clients (
  project_id uuid not null references public.projects(id) on delete cascade,
  client_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (project_id, client_id)
);
create index on public.project_clients (client_id);
alter table public.project_clients enable row level security;

create or replace function public.my_client_project_ids()
returns setof uuid language sql stable security definer set search_path = public as $$
  select pc.project_id
    from public.project_clients pc
    join public.profiles p on p.id = pc.client_id
   where pc.client_id = auth.uid() and p.role = 'cliente' and p.active;
$$;

create policy project_clients_admin on public.project_clients for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy project_clients_mine on public.project_clients for select to authenticated
  using (client_id = (select auth.uid()));

-- ---------------------------------------------------------------- datos de la empresa (pie de los PDF)
alter table public.company_settings
  add column legal_name text,
  add column nit text,
  add column address text,
  add column phone text,
  add column email text,
  add column website text;

-- Solo los datos de contacto; los porcentajes y el tipo de cambio siguen siendo del admin.
create or replace function public.company_public()
returns table (company_name text, legal_name text, nit text, address text, phone text, email text, website text)
language sql stable security definer set search_path = public as $$
  select s.company_name, s.legal_name, s.nit, s.address, s.phone, s.email, s.website
    from public.company_settings s
   where s.id = 1 and public.is_active_user();
$$;

-- ---------------------------------------------------------------- lecturas del cliente
create or replace function public.client_projects()
returns table (
  id uuid, name text, client text, location text, type text, status text, billing_mode text,
  total_units integer, daily_target integer, start_date date, work_days_per_week smallint, active_machines integer
)
language sql stable security definer set search_path = public as $$
  select p.id, p.name, p.client, p.location, p.type::text, p.status::text, p.billing_mode::text,
         p.total_units, p.daily_target, p.start_date, p.work_days_per_week,
         (select count(*)::int from public.assignments a where a.project_id = p.id and a.active)
    from public.projects p
   where p.id in (select public.my_client_project_ids())
   order by p.created_at desc;
$$;

create or replace function public.client_reports(p_project uuid)
returns table (
  id uuid, report_date date, machine_id uuid, machine_name text, units_done integer,
  hours_worked numeric, downtime_hours numeric, downtime_reason text, photos text[]
)
language sql stable security definer set search_path = public as $$
  select r.id, r.report_date, r.machine_id, m.name, r.units_done, r.hours_worked,
         r.downtime_hours, r.downtime_reason::text, r.photos
    from public.daily_reports r
    join public.machines m on m.id = r.machine_id
   where r.project_id = p_project
     and p_project in (select public.my_client_project_ids())
   order by r.report_date desc;
$$;

-- Fotos de reportes (r/<asignación>/…) de sus proyectos: solo lectura.
create or replace function public.client_can_view_photo(p_name text)
returns boolean language sql stable security definer set search_path = public as $$
  select (storage.foldername(p_name))[1] = 'r'
     and (storage.foldername(p_name))[2] in (
       select a.id::text from public.assignments a
        where a.project_id in (select public.my_client_project_ids()));
$$;

drop policy evidencias_select on storage.objects;
create policy evidencias_select on storage.objects for select to authenticated
  using (bucket_id = 'evidencias' and (public.can_access_photo(name) or public.client_can_view_photo(name)));

revoke execute on function public.my_client_project_ids(), public.company_public(), public.client_projects(),
  public.client_reports(uuid), public.client_can_view_photo(text) from public, anon;
grant execute on function public.my_client_project_ids(), public.company_public(), public.client_projects(),
  public.client_reports(uuid), public.client_can_view_photo(text) to authenticated;
