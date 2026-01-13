-- RPC to get aggregated attendance stats
CREATE OR REPLACE FUNCTION get_attendance_stats(branch_uuid UUID)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    total_count INTEGER;
    weekly_count INTEGER;
    monthly_count INTEGER;
    yearly_count INTEGER;
    type_stats JSONB;
    tag_stats JSONB;
BEGIN
    -- Total individual attendance records
    SELECT COUNT(*) INTO total_count FROM attendance WHERE branch_id = branch_uuid;

    -- Current Week (Starting Monday)
    SELECT COUNT(*) INTO weekly_count 
    FROM attendance 
    WHERE branch_id = branch_uuid 
    AND service_date >= (DATE_TRUNC('week', CURRENT_DATE)::DATE);

    -- Current Month
    SELECT COUNT(*) INTO monthly_count 
    FROM attendance 
    WHERE branch_id = branch_uuid 
    AND service_date >= (DATE_TRUNC('month', CURRENT_DATE)::DATE);

    -- Current Year
    SELECT COUNT(*) INTO yearly_count 
    FROM attendance 
    WHERE branch_id = branch_uuid 
    AND service_date >= (DATE_TRUNC('year', CURRENT_DATE)::DATE);

    -- Stats by Service Type
    SELECT jsonb_object_agg(service_type, count) INTO type_stats
    FROM (
        SELECT service_type, COUNT(*) as count
        FROM attendance
        WHERE branch_id = branch_uuid
        GROUP BY service_type
    ) t;

    -- Stats by Member Tags
    -- We join attendance with members, unnest the tags, and count
    SELECT jsonb_object_agg(tag, count) INTO tag_stats
    FROM (
        SELECT t.tag, COUNT(*) as count
        FROM attendance a
        JOIN organization_members om ON a.user_id = om.user_id
        CROSS JOIN unnest(om.tags) as t(tag)
        WHERE a.branch_id = branch_uuid
        GROUP BY t.tag
    ) t;

    -- Prepare result
    RETURN jsonb_build_object(
        'total_attendance', total_count,
        'weekly_attendance', weekly_count,
        'monthly_attendance', monthly_count,
        'yearly_attendance', yearly_count,
        'by_type', type_stats,
        'by_tag', COALESCE(tag_stats, '{}'::jsonb)
    );
END;
$$;
