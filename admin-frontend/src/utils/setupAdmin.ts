/**
 * Admin User Setup Script
 *
 * This script helps set up an admin user in Supabase with the correct role.
 *
 * INSTRUCTIONS:
 * 1. Run this function from the browser console after importing it
 * 2. Or create a temporary admin setup page that calls this function
 *
 * Usage:
 * - Call setupAdminUser() to create a new admin user
 * - Call updateUserRole('user-id-here', 'ADMIN') to update an existing user's role
 */

import { supabase } from '@/lib/supabase'

export interface AdminSetupResult {
  success: boolean
  message: string
  userId?: string
}

/**
 * Create a new admin user in Supabase
 * Note: You need to be signed in as an admin or use the Supabase dashboard
 */
export async function setupAdminUser(
  email: string = 'admin@servio.lk',
  password: string = 'Admin@2026',
  fullName: string = 'Admin User'
): Promise<AdminSetupResult> {
  try {
    // Sign up the user with admin role in metadata
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
          role: 'ADMIN', // Set the role in user_metadata
        },
      },
    })

    if (error) {
      return {
        success: false,
        message: `Error creating admin user: ${error.message}`,
      }
    }

    if (data.user) {
      return {
        success: true,
        message: `Admin user created successfully! User ID: ${data.user.id}`,
        userId: data.user.id,
      }
    }

    return {
      success: false,
      message: 'Unknown error: No user data returned',
    }
  } catch (err: any) {
    return {
      success: false,
      message: `Exception: ${err.message}`,
    }
  }
}

/**
 * Update an existing user's role to ADMIN
 * Note: This requires direct database access or using Supabase admin API
 * For now, this is a placeholder - you'll need to use the Supabase dashboard
 */
export async function updateUserRoleInMetadata(_userId: string, role: 'ADMIN' | 'CUSTOMER' | 'STAFF'): Promise<AdminSetupResult> {
  try {
    // Note: Updating user metadata requires admin privileges
    // This needs to be done via Supabase dashboard or admin API

    const { data, error } = await supabase.auth.updateUser({
      data: {
        role: role,
      },
    })

    if (error) {
      return {
        success: false,
        message: `Error updating user role: ${error.message}`,
      }
    }

    return {
      success: true,
      message: `User role updated to ${role}`,
      userId: data.user?.id,
    }
  } catch (err: any) {
    return {
      success: false,
      message: `Exception: ${err.message}`,
    }
  }
}

/**
 * Get current user's role from metadata
 */
export async function getCurrentUserRole(): Promise<string | null> {
  const { data } = await supabase.auth.getUser()
  return data.user?.user_metadata?.role || null
}

/**
 * Check if current user is admin
 */
export async function isCurrentUserAdmin(): Promise<boolean> {
  const role = await getCurrentUserRole()
  return role === 'ADMIN'
}

