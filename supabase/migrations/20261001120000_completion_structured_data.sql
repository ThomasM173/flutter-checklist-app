-- ============================================================================
-- ClearedToGo — structured completion data (data-first "Finish")
--
-- Every completion flow currently generates a PDF immediately and uploads
-- it before the completions row even exists. This adds a `data` column so
-- "Finish" can write the structured form values straight to the row with
-- NO PDF involved, and a PDF can be generated later, on demand, purely from
-- this stored data (see lib/utils/completion_pdf_builder.dart).
--
-- pdf_storage_path is untouched and stays populated for completions created
-- before this migration (their PDF already exists in storage); it simply
-- goes unused for new completions going forward.
-- ============================================================================

alter table public.checklist_completions
  add column data jsonb;

comment on column public.checklist_completions.data is
  'Structured form field values captured at Finish time (checklist items, readings, free text, etc. - shape varies by completion_type). PDFs for new completions are generated on demand from this, not stored separately. Null for completions created before this column existed, which still have their original pdf_storage_path.';
