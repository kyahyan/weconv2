-- RPC to delete an entire attendance session
CREATE OR REPLACE FUNCTION delete_attendance_session(
    p_branch_id UUID,
    p_date DATE,
    p_service_type TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.attendance
    WHERE branch_id = p_branch_id
    AND service_date = p_date
    AND service_type = p_service_type;
END;
$$;
