-- ============================================================================
-- ClearedToGo — completion_type on checklist_completions
--
-- The pre-boarding checklist screens were the only callers of
-- checklist_completions until now. This brings the other paperwork PDFs
-- (previously handled by the retired PdfUploadService no-op shim) onto the
-- same table instead of a new one, tagged by completion_type.
-- ============================================================================

alter table public.checklist_completions
  add column completion_type text not null default 'checklist'
    check (completion_type in (
      'checklist',
      'tech_log',
      'fuel_uplift',
      'departure_briefing',
      'passenger_brief',
      'weight_balance',
      'emergency_procedures',
      'pave_assessment'
    ));

comment on column public.checklist_completions.completion_type is
  'Which kind of PDF this row represents. ''checklist'' is the original pre-boarding checklist; the others cover tech log, fuel uplift, departure briefing, passenger brief, weight & balance, emergency procedures and PAVE assessment PDFs that previously went nowhere (PdfUploadService no-op shim).';

create index checklist_completions_completion_type_idx
  on public.checklist_completions (completion_type);
