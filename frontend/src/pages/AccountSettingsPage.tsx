import { useEffect, useState } from 'react';
import { AppLayout } from '@/components/layouts/AppLayout';
import { apiService, type NotificationPreferences } from '@/services/api';
import { toast } from 'sonner';

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const passwordPattern = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;

const fieldClass = 'w-full rounded-lg border border-black/10 px-3 py-2 text-sm focus:outline-none focus:border-[#ff5d2e]';

export default function AccountSettingsPage() {
  const [loading, setLoading] = useState(true);
  const [savingProfile, setSavingProfile] = useState(false);
  const [savingPassword, setSavingPassword] = useState(false);
  const [savingEmail, setSavingEmail] = useState(false);
  const [savingPrefs, setSavingPrefs] = useState(false);

  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [bio, setBio] = useState('');
  const [avatarUrl, setAvatarUrl] = useState('');
  const [profileError, setProfileError] = useState('');

  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [passwordError, setPasswordError] = useState('');

  const [email, setEmail] = useState('');
  const [emailPassword, setEmailPassword] = useState('');
  const [emailError, setEmailError] = useState('');

  const [prefs, setPrefs] = useState<NotificationPreferences>({
    promotionalOffers: true,
    pushNotifications: true,
    securityAlerts: true,
  });

  useEffect(() => {
    let cancelled = false;
    Promise.all([apiService.getProfile(), apiService.getNotificationPreferences()])
      .then(([profileRes, prefRes]) => {
        if (cancelled) return;
        if (profileRes.success && profileRes.data) {
          setFullName(profileRes.data.fullName || '');
          setPhone(profileRes.data.phone || '');
          setBio(profileRes.data.bio || '');
          setAvatarUrl(profileRes.data.avatarUrl || '');
          setEmail(profileRes.data.email || '');
        }
        if (prefRes.success && prefRes.data) {
          setPrefs(prefRes.data);
        }
      })
      .catch(() => {
        if (!cancelled) toast.error('Could not load account settings');
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => { cancelled = true; };
  }, []);

  const saveProfile = async () => {
    setProfileError('');
    if (!fullName.trim()) {
      setProfileError('Full name is required');
      return;
    }
    setSavingProfile(true);
    try {
      const res = await apiService.updateProfile({ fullName: fullName.trim(), phone, bio, avatarUrl });
      if (res.success) toast.success('Profile saved');
      else setProfileError(res.message || 'Could not save profile');
    } catch (err: any) {
      setProfileError(err?.message || 'Could not save profile');
    } finally {
      setSavingProfile(false);
    }
  };

  const savePassword = async () => {
    setPasswordError('');
    if (!passwordPattern.test(newPassword)) {
      setPasswordError('Use at least 8 characters with uppercase, lowercase, and a number');
      return;
    }
    if (newPassword !== confirmPassword) {
      setPasswordError('New password and confirmation do not match');
      return;
    }
    setSavingPassword(true);
    try {
      const res = await apiService.changePassword({ currentPassword, newPassword, confirmPassword });
      if (res.success) {
        toast.success('Password updated');
        setCurrentPassword('');
        setNewPassword('');
        setConfirmPassword('');
      } else {
        setPasswordError(res.message || 'Could not update password');
      }
    } catch (err: any) {
      setPasswordError(err?.message || 'Could not update password');
    } finally {
      setSavingPassword(false);
    }
  };

  const saveEmail = async () => {
    setEmailError('');
    if (!emailPattern.test(email)) {
      setEmailError('Enter a valid email address');
      return;
    }
    setSavingEmail(true);
    try {
      const res = await apiService.changeEmail({ email, currentPassword: emailPassword });
      if (res.success) {
        toast.success('Email updated');
        setEmailPassword('');
      } else {
        setEmailError(res.message || 'Could not update email');
      }
    } catch (err: any) {
      setEmailError(err?.message || 'Could not update email');
    } finally {
      setSavingEmail(false);
    }
  };

  const savePrefs = async () => {
    setSavingPrefs(true);
    try {
      const res = await apiService.updateNotificationPreferences(prefs);
      if (res.success) toast.success('Preferences saved');
      else toast.error(res.message || 'Could not save preferences');
    } catch (err: any) {
      toast.error(err?.message || 'Could not save preferences');
    } finally {
      setSavingPrefs(false);
    }
  };

  return (
    <AppLayout>
      <div className="max-w-2xl text-left px-4 py-6 flex flex-col gap-4">
        <h1 className="text-2xl font-semibold text-black text-left">Account settings</h1>
        {loading ? (
          <p className="text-black/50 text-left">Loading settings...</p>
        ) : (
          <>
            <section className="bg-white rounded-2xl shadow-sm p-5 flex flex-col gap-3">
              <h2 className="font-semibold text-black">Profile</h2>
              <label className="text-sm text-black/70">Full name
                <input className={fieldClass} value={fullName} onChange={(e) => setFullName(e.target.value)} />
              </label>
              <label className="text-sm text-black/70">Phone
                <input className={fieldClass} value={phone} onChange={(e) => setPhone(e.target.value)} />
              </label>
              <label className="text-sm text-black/70">Bio
                <textarea className={fieldClass} rows={3} value={bio} onChange={(e) => setBio(e.target.value)} />
              </label>
              <label className="text-sm text-black/70">Avatar URL
                <input className={fieldClass} value={avatarUrl} onChange={(e) => setAvatarUrl(e.target.value)} />
              </label>
              {profileError && <p className="text-sm text-red-600">{profileError}</p>}
              <button type="button" disabled={savingProfile} onClick={saveProfile}
                className="self-start bg-[#ff5d2e] text-white text-sm font-semibold px-4 py-2 rounded-lg disabled:opacity-50">
                {savingProfile ? 'Saving...' : 'Save profile'}
              </button>
            </section>

            <section className="bg-white rounded-2xl shadow-sm p-5 flex flex-col gap-3">
              <h2 className="font-semibold text-black">Password</h2>
              <input type="password" placeholder="Current password" className={fieldClass} value={currentPassword} onChange={(e) => setCurrentPassword(e.target.value)} />
              <input type="password" placeholder="New password" className={fieldClass} value={newPassword} onChange={(e) => setNewPassword(e.target.value)} />
              <input type="password" placeholder="Confirm new password" className={fieldClass} value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} />
              {passwordError && <p className="text-sm text-red-600">{passwordError}</p>}
              <button type="button" disabled={savingPassword} onClick={savePassword}
                className="self-start bg-[#ff5d2e] text-white text-sm font-semibold px-4 py-2 rounded-lg disabled:opacity-50">
                {savingPassword ? 'Saving...' : 'Update password'}
              </button>
            </section>

            <section className="bg-white rounded-2xl shadow-sm p-5 flex flex-col gap-3">
              <h2 className="font-semibold text-black">Email</h2>
              <input type="email" className={fieldClass} value={email} onChange={(e) => setEmail(e.target.value)} />
              <input type="password" placeholder="Current password" className={fieldClass} value={emailPassword} onChange={(e) => setEmailPassword(e.target.value)} />
              {emailError && <p className="text-sm text-red-600">{emailError}</p>}
              <button type="button" disabled={savingEmail} onClick={saveEmail}
                className="self-start bg-[#ff5d2e] text-white text-sm font-semibold px-4 py-2 rounded-lg disabled:opacity-50">
                {savingEmail ? 'Saving...' : 'Update email'}
              </button>
            </section>

            <section className="bg-white rounded-2xl shadow-sm p-5 flex flex-col gap-3">
              <h2 className="font-semibold text-black">Notifications</h2>
              {([
                ['promotionalOffers', 'Receive promotional offers'],
                ['pushNotifications', 'Push notifications'],
                ['securityAlerts', 'Security alerts'],
              ] as const).map(([key, label]) => (
                <label key={key} className="flex items-center justify-between gap-3 text-sm text-black">
                  <span>{label}</span>
                  <input
                    type="checkbox"
                    checked={prefs[key]}
                    onChange={(e) => setPrefs((prev) => ({ ...prev, [key]: e.target.checked }))}
                  />
                </label>
              ))}
              <button type="button" disabled={savingPrefs} onClick={savePrefs}
                className="self-start bg-[#ff5d2e] text-white text-sm font-semibold px-4 py-2 rounded-lg disabled:opacity-50">
                {savingPrefs ? 'Saving...' : 'Save preferences'}
              </button>
            </section>
          </>
        )}
      </div>
    </AppLayout>
  );
}
