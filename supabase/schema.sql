-- Pasang hanya pada project Supabase yang sama dengan tiga aplikasi sumber.
-- Tidak mengubah tabel, trigger, policy atau peran aplikasi lama.
begin;
create table public.owner_profiles(singleton boolean primary key default true check(singleton),user_id uuid not null unique references auth.users(id),name text not null default 'Owner',active boolean not null default true);
alter table owner_profiles enable row level security;
create policy owner_profile_self on owner_profiles for select to authenticated using(user_id=auth.uid());
create function public.owner_is_owner() returns boolean language sql stable security definer set search_path=public,pg_temp as $$select exists(select 1 from public.owner_profiles where user_id=auth.uid() and active)$$;
revoke all on function owner_is_owner() from public;grant execute on function owner_is_owner() to authenticated;
grant select on owner_profiles to authenticated;revoke all on owner_profiles from anon;
create table public.owner_products(id uuid primary key default gen_random_uuid(),sku text not null unique check(sku=upper(trim(sku)) and length(sku) between 2 and 80),name text not null check(length(trim(name)) between 1 and 120),unit text not null check(unit in ('box','botol','pcs','paket')),active boolean not null default true);
create table public.owner_mappings(id uuid primary key default gen_random_uuid(),division text not null check(division in ('acq','crm','mp')),source_key text not null,source_name text not null,product_id uuid not null references owner_products(id),factor numeric(14,4) not null default 1 check(factor>0 and factor<=100000),unique(division,source_key));
create table public.owner_hpp(id uuid primary key default gen_random_uuid(),product_id uuid not null references owner_products(id),effective_from date not null,amount numeric(18,2) not null check(amount>=0),note text not null default '' check(length(note)<=1000),created_at timestamptz not null default now(),unique(product_id,effective_from));
create table public.owner_targets(id uuid primary key default gen_random_uuid(),month date not null check(extract(day from month)=1),division text not null check(division in ('all','acq','crm','mp')),product_id uuid references owner_products(id),amount numeric(18,2) not null check(amount>0));
create unique index owner_target_scope on owner_targets(month,division,coalesce(product_id,'00000000-0000-0000-0000-000000000000'::uuid));
create table public.owner_notes(id uuid primary key default gen_random_uuid(),date date not null,title text not null check(length(trim(title)) between 1 and 150),body text not null check(length(body)<=4000),created_at timestamptz not null default now());
do $$declare t text;begin foreach t in array array['owner_products','owner_mappings','owner_targets','owner_notes'] loop execute format('alter table public.%I enable row level security',t);execute format('create policy owner_only on public.%I for all to authenticated using(public.owner_is_owner()) with check(public.owner_is_owner())',t);execute format('grant select,insert,update,delete on public.%I to authenticated',t);execute format('revoke all on public.%I from anon',t);end loop;end$$;
alter table owner_hpp enable row level security;
create policy owner_hpp_read on owner_hpp for select to authenticated using(owner_is_owner());
create policy owner_hpp_add on owner_hpp for insert to authenticated with check(owner_is_owner());
grant select,insert on owner_hpp to authenticated;revoke all on owner_hpp from anon;
-- Satu RPC read-only dengan daftar tabel tetap. Tidak memberikan akses sumber kepada admin/tim lain.
create function public.owner_read_source(p_division text,p_table text,p_offset integer default 0,p_limit integer default 200) returns setof jsonb language plpgsql stable security definer set search_path=public,pg_temp as $$
declare relation_name text;
begin
 if not public.owner_is_owner() then raise exception 'Akses khusus Owner.';end if;
 if p_offset<0 or p_limit<1 or p_limit>500 then raise exception 'Halaman tidak valid.';end if;
 relation_name=case
 when p_division='acq' and p_table in ('catalog','reports','ads','assignments') then p_table
 when p_division='crm' and p_table in ('products','reports','regions','profiles','targets') then 'crm_'||p_table
 when p_division='mp' and p_table in ('products','skus','mappings','orders','ads','daily','shops','imports','ad_parts','order_days','ad_rules','targets') then 'mp_'||p_table end;
 if relation_name is null then raise exception 'Tabel sumber tidak diizinkan.';end if;
 if to_regclass('public.'||quote_ident(relation_name)) is null then raise exception 'Tabel sumber % belum tersedia. Pasang pembaruan aplikasi sumber.',relation_name;end if;
 return query execute format('select to_jsonb(t) - ''email'' - ''rows'' from public.%I t order by id limit $1 offset $2',relation_name) using p_limit,p_offset;
end$$;
revoke all on function owner_read_source(text,text,integer,integer) from public;grant execute on function owner_read_source(text,text,integer,integer) to authenticated;
commit;
