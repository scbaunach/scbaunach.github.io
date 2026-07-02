-- 1. Create a profiles table that links to Supabase's managed Auth users
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  is_author boolean default false
);

-- 2. Create the photos metadata table
create table public.photos (
  id uuid default gen_random_uuid() primary key,
  r2_url text not null,
  description text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  uploaded_by uuid references public.profiles(id)
);

-- 3. Enable Row Level Security (RLS)
alter table public.photos enable row level security;

-- 4. PUBLIC POLICY: Allow absolutely anyone (even unauthenticated guests) to view photos
create policy "Allow completely public read access"
on public.photos for select
using (true); -- "using (true)" means no restrictions whatsoever for reading

-- 5. AUTHOR POLICY: Keep this strict. Only logged-in authors can add photos
create policy "Allow authors to insert photos"
on public.photos for insert
with check (
  auth.role() = 'authenticated' AND
  exists (
    select 1 from public.profiles
    where id = auth.uid() and is_author = true
  )
);

-- Policies to require authorized users to view photos
-- First, drop the old public viewing policy if you created it earlier
-- drop policy if exists "Allow completely public read access" on public.photos;
-- 4. Policy: Anyone logged in can view photos
-- create policy "Allow logged-in users to view photos"
-- on public.photos for select
-- using (auth.role() = 'authenticated');

-- 5. Policy: Only authors can insert photos
-- create policy "Allow authors to insert photos"
-- on public.photos for insert
-- with check (
--   exists (
--     select 1 from public.profiles
--     where id = auth.uid() and is_author = true
--   )
-- );