-- ============================================================================
-- ClearedToGo — private storage bucket for checklist-completion PDFs
--
-- Object path convention (enforced by policy): {user_id}/{completion_id}.pdf
--   -> folder segment 1 is the owning pilot's auth uid.
--
-- Policies mirror checklist_completions:
--   * the owning pilot: full read/write on their own folder
--   * a flight_school_admin: read-only on files owned by a pilot currently in
--     their school
-- ============================================================================

insert into storage.buckets (id, name, public)
values ('checklist-pdfs', 'checklist-pdfs', false)
on conflict (id) do nothing;

-- Owner: full access to objects under their own {user_id}/ prefix.
create policy "checklist-pdfs: owner reads own"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'checklist-pdfs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "checklist-pdfs: owner uploads own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'checklist-pdfs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "checklist-pdfs: owner updates own"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'checklist-pdfs'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'checklist-pdfs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "checklist-pdfs: owner deletes own"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'checklist-pdfs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Flight school admin: read-only on their current pilots' files.
create policy "checklist-pdfs: admin reads own-school pilot files"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'checklist-pdfs'
    and public.current_user_role() = 'flight_school_admin'
    and exists (
      select 1
      from public.profiles p
      where p.id::text = (storage.foldername(name))[1]
        and p.role = 'pilot'
        and p.flight_school_id is not null
        and p.flight_school_id = public.current_user_flight_school_id()
    )
  );
