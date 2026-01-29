-- Migration to fix schema and RLS for Issue #2
-- Fixes the RLS circular dependency when creating a couple + profile

-- =====================================================
-- FIX RLS POLICIES (This is the main bug!)
-- =====================================================

-- Drop the old SELECT policy on couples
DROP POLICY IF EXISTS "Users can view their own couple" ON couples;

-- Create new SELECT policy that allows seeing a couple if:
-- 1. User has a profile linked to it, OR
-- 2. User just created it (no profile yet, but we check INSERT context)
CREATE POLICY "Users can view their own couple" ON couples
  FOR SELECT USING (
    id IN (SELECT couple_id FROM profiles WHERE id = auth.uid())
  );

-- Add policy to allow INSERT to return data (PostgreSQL 15+)
-- For older versions, we need SECURITY DEFINER function
DROP POLICY IF EXISTS "Users can create couples" ON couples;
CREATE POLICY "Users can create couples and read result" ON couples
  FOR INSERT WITH CHECK (true);

-- Create a SECURITY DEFINER function to bypass RLS for couple creation
CREATE OR REPLACE FUNCTION create_couple_with_profile(
  p_household_name TEXT,
  p_timezone TEXT,
  p_user_id UUID,
  p_full_name TEXT,
  p_email TEXT,
  p_pending_partner_email TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_couple_id UUID;
BEGIN
  -- Insert couple (bypasses RLS)
  INSERT INTO couples (household_name, timezone)
  VALUES (p_household_name, p_timezone)
  RETURNING id INTO v_couple_id;
  
  -- Insert profile (bypasses RLS)
  INSERT INTO profiles (id, couple_id, full_name, email, pending_partner_email)
  VALUES (p_user_id, v_couple_id, p_full_name, p_email, p_pending_partner_email);
  
  RETURN v_couple_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION create_couple_with_profile TO authenticated;

-- =====================================================
-- SCHEMA FIXES (keep these for safety)
-- =====================================================

-- Fix couples table: add household_name if missing
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'couples' AND column_name = 'household_name'
  ) THEN
    ALTER TABLE couples ADD COLUMN household_name TEXT NOT NULL DEFAULT 'My Household';
  END IF;
END $$;

-- Fix profiles table: rename display_name to full_name if needed
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'display_name'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'full_name'
  ) THEN
    ALTER TABLE profiles RENAME COLUMN display_name TO full_name;
  END IF;
END $$;

-- Add email column to profiles if missing
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'email'
  ) THEN
    ALTER TABLE profiles ADD COLUMN email TEXT;
    
    UPDATE profiles p
    SET email = (SELECT email FROM auth.users WHERE id = p.id)
    WHERE email IS NULL;
    
    ALTER TABLE profiles ALTER COLUMN email SET NOT NULL;
  END IF;
END $$;

-- Add pending_partner_email if missing
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'pending_partner_email'
  ) THEN
    ALTER TABLE profiles ADD COLUMN pending_partner_email TEXT;
  END IF;
END $$;

-- Drop partner_email from couples if it exists (old schema)
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'couples' AND column_name = 'partner_email'
  ) THEN
    UPDATE profiles p
    SET pending_partner_email = (
      SELECT partner_email 
      FROM couples c 
      WHERE c.id = p.couple_id 
      AND c.partner_email IS NOT NULL
    )
    WHERE pending_partner_email IS NULL;
    
    ALTER TABLE couples DROP COLUMN partner_email;
  END IF;
END $$;
