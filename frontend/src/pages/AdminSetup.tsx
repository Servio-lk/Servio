import React, { useState } from 'react';
import { setupAdminUser } from '@/utils/setupAdmin';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { toast } from 'sonner';

export default function AdminSetup() {
    const [email, setEmail] = useState('admin@servio.lk');
    const [password, setPassword] = useState('Admin@2026');
    const [fullName, setFullName] = useState('Admin User');
    const [loading, setLoading] = useState(false);

    const handleSetup = async () => {
        setLoading(true);
        try {
            const result = await setupAdminUser(email, password, fullName);
            if (result.success) {
                toast.success(result.message);
            } else {
                toast.error(result.message);
            }
        } catch (error: any) {
            toast.error('Failed to set up admin user: ' + error.message);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="flex h-screen w-full items-center justify-center bg-gray-50">
            <div className="w-full max-w-md p-8 bg-white rounded-lg shadow-md flex flex-col gap-4">
                <h2 className="text-2xl font-bold text-center mb-4">Admin Setup</h2>
                <div className="flex flex-col gap-2">
                    <label className="text-sm font-medium">Email</label>
                    <Input value={email} onChange={(e) => setEmail(e.target.value)} />
                </div>
                <div className="flex flex-col gap-2">
                    <label className="text-sm font-medium">Password</label>
                    <Input type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
                </div>
                <div className="flex flex-col gap-2">
                    <label className="text-sm font-medium">Full Name</label>
                    <Input value={fullName} onChange={(e) => setFullName(e.target.value)} />
                </div>
                <Button
                    onClick={handleSetup}
                    disabled={loading}
                    className="bg-[#FF5D2E] hover:bg-[#FF5D2E]/90 mt-4"
                >
                    {loading ? 'Setting up...' : 'Create Admin User'}
                </Button>
            </div>
        </div>
    );
}
