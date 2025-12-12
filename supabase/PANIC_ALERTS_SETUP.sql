-- ============================================
-- PANIC ALERTS IMPLEMENTATION
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Create panic_alerts table
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

-- Create indexes for faster queries
CREATE INDEX idx_panic_alerts_group_id ON panic_alerts(group_id);
CREATE INDEX idx_panic_alerts_user_id ON panic_alerts(user_id);
CREATE INDEX idx_panic_alerts_device_id ON panic_alerts(device_id);
CREATE INDEX idx_panic_alerts_resolved_at ON panic_alerts(resolved_at);

-- Step 2: Create trigger for updated_at
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

-- Step 3: Create RPC function to resolve panic alert
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION resolve_panic_alert(UUID, UUID) TO authenticated;

-- Step 4: Update the main RPC function to create panic alerts
-- First, drop the old function if it exists
DROP FUNCTION IF EXISTS public.rpc_insert_device_payload(text, jsonb);

-- Create the new version
CREATE OR REPLACE FUNCTION public.rpc_insert_device_payload(p_device_key text, p_payload jsonb)
  RETURNS jsonb
  LANGUAGE plpgsql SECURITY DEFINER
  SET search_path = public
AS $$
DECLARE
  v_device UUID;
  v_user_id UUID;
  v_group_id UUID;
  v_panic_alert BOOLEAN;
BEGIN
  -- Find the active device matching the token
  SELECT id INTO v_device FROM public.devices 
  WHERE device_key = p_device_key AND is_active 
  LIMIT 1;
  
  IF v_device IS NULL THEN
    RAISE EXCEPTION 'invalid_device_token' USING HINT = 'check device key or device is deactivated';
  END IF;

  -- Get device's user_id and group_id
  SELECT registered_by, group_id INTO v_user_id, v_group_id FROM public.devices WHERE id = v_device;

  -- Insert device data
  INSERT INTO public.device_data(device_id, payload) VALUES (v_device, p_payload);

  -- Check if panic_alert is true in the payload
  v_panic_alert := (p_payload ->> 'panic_alert')::BOOLEAN;
  
  -- If panic alert is triggered, create a panic_alert record
  IF v_panic_alert THEN
    INSERT INTO public.panic_alerts (device_id, user_id, group_id, triggered_at)
    VALUES (v_device, v_user_id, v_group_id, NOW());
  END IF;

  RETURN jsonb_build_object('status', 'ok', 'device_id', v_device);
END;
$$;

-- Grant execute on the rpc to anon so devices can call the RPC using the anon key
GRANT EXECUTE ON FUNCTION public.rpc_insert_device_payload(text, jsonb) TO anon;

-- Step 5: Test (Optional - remove if not needed)
-- SELECT * FROM panic_alerts;
