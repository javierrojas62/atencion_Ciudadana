-- =====================================================================
--  09 - Fotos (Supabase Storage)
--  Bucket público "reclamos". Cada usuario sube a su propia carpeta:
--    reclamos/<id_del_usuario>/<archivo>.jpg
--  Vecinos suben la foto del problema; operarios, la del arreglo.
-- =====================================================================

insert into storage.buckets (id, name, public)
values ('reclamos', 'reclamos', true)
on conflict (id) do nothing;

create policy "vecinos y operarios suben fotos a su carpeta"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'reclamos'
    and public.mi_rol() in ('vecino', 'operario')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "todos ven las fotos de reclamos"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'reclamos');
