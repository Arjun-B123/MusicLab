-- Time signature per piece, used to convert note timestamps into bar
-- numbers for the comparison screen. Auto-detected from attached sheet
-- music via the omr_service (best-effort, can be wrong on messy photos),
-- but always user-editable/overridable — defaults to the most common
-- signature until set.
alter table public.pieces
  add column if not exists time_signature text not null default '4/4';
