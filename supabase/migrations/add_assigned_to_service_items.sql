-- Add assigned_to column to service_items
alter table public.service_items
add column assigned_to uuid references public.organization_members(id);

-- Note: We reference organization_members ID, not users ID directly, 
-- because assignments are specific to that organization/branch context.
-- This allows us to easily fetch the profile/details of the assigned member.
