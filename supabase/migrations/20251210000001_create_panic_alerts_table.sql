-- Create panic_alerts table to track unresolved panic button presses
CREATE TABLE public.panic_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  triggered_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE,
  resolved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX idx_panic_alerts_group_id ON panic_alerts(group_id);
CREATE INDEX idx_panic_alerts_user_id ON panic_alerts(user_id);
CREATE INDEX idx_panic_alerts_device_id ON panic_alerts(device_id);
CREATE INDEX idx_panic_alerts_resolved_at ON panic_alerts(resolved_at);

-- Create a trigger to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_panic_alerts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER panic_alerts_updated_at_trigger
BEFORE UPDATE ON panic_alerts
FOR EACH ROW
EXECUTE FUNCTION update_panic_alerts_updated_at();

-- Create function to create a panic alert
CREATE OR REPLACE FUNCTION create_panic_alert(
  p_device_id UUID,
  p_user_id UUID,
  p_group_id UUID
)
RETURNS UUID AS $$
DECLARE
  v_alert_id UUID;
BEGIN
  INSERT INTO panic_alerts (device_id, user_id, group_id, triggered_at)
  VALUES (p_device_id, p_user_id, p_group_id, NOW())
  RETURNING id INTO v_alert_id;
  
  RETURN v_alert_id;
END;
$$ LANGUAGE plpgsql;

-- Create function to resolve a panic alert
CREATE OR REPLACE FUNCTION resolve_panic_alert(
  p_alert_id UUID,
  p_resolved_by UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE panic_alerts
  SET resolved_at = NOW(), resolved_by = p_resolved_by
  WHERE id = p_alert_id AND resolved_at IS NULL;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Create function to get unresolved panic alerts for a group
CREATE OR REPLACE FUNCTION get_unresolved_panic_alerts(p_group_id UUID)
RETURNS TABLE (
  id UUID,
  device_id UUID,
  user_id UUID,
  group_id UUID,
  user_name TEXT,
  triggered_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pa.id,
    pa.device_id,
    pa.user_id,
    pa.group_id,
    p.full_name,
    pa.triggered_at
  FROM panic_alerts pa
  JOIN profiles p ON pa.user_id = p.id
  WHERE pa.group_id = p_group_id AND pa.resolved_at IS NULL
  ORDER BY pa.triggered_at DESC;
END;
$$ LANGUAGE plpgsql;
