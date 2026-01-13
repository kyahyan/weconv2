-- Create service_assignments table
CREATE TABLE service_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id uuid REFERENCES services(id) ON DELETE CASCADE NOT NULL,
  member_id uuid REFERENCES organization_members(id) ON DELETE CASCADE NOT NULL,
  role_name text NOT NULL,
  confirmed boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE service_assignments ENABLE ROW LEVEL SECURITY;

-- Policies (Adjust based on your app's needs, for now allow all authenticated users)
CREATE POLICY "Enable read access for all users" ON service_assignments FOR SELECT USING (true);
CREATE POLICY "Enable insert for all users" ON service_assignments FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update for all users" ON service_assignments FOR UPDATE USING (true);
CREATE POLICY "Enable delete for all users" ON service_assignments FOR DELETE USING (true);
