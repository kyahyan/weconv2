-- Allow authenticated users to insert notifications (e.g. for Notify Team feature)
CREATE POLICY "Users can insert notifications"
    ON public.notifications FOR INSERT
    TO authenticated
    WITH CHECK (true);
