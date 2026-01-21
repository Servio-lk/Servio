import { Link, useLocation } from 'react-router-dom';
import { Home, List, FileText, User, LogOut, Menu, X, Bell, Car, Settings } from 'lucide-react';
import { useState, type ReactNode } from 'react';
import { useAuth } from '@/contexts/AuthContext';

interface AppLayoutProps {
  children: ReactNode;
  showNav?: boolean;
}

// Tab bar items for both mobile and desktop
const navItems = [
  { icon: Home, label: 'Home', path: '/home' },
  { icon: List, label: 'Services', path: '/services' },
  { icon: FileText, label: 'Activity', path: '/activity' },
  { icon: User, label: 'Account', path: '/account' },
];

// Desktop sidebar component
function DesktopSidebar() {
  const location = useLocation();
  const { user, logout } = useAuth();

  return (
    <aside className="hidden lg:flex flex-col w-64 bg-white border-r border-black/10 h-screen fixed left-0 top-0">
      {/* Logo */}
      <div className="p-6 border-b border-black/10">
        <h1 className="text-2xl font-bold text-[#ff5d2e]">Servio</h1>
      </div>

      {/* User info */}
      <div className="p-4 border-b border-black/10">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-[#ffe7df] rounded-full flex items-center justify-center">
            <User className="w-5 h-5 text-[#ff5d2e]" />
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-semibold text-black truncate">
              {user?.fullName || 'Guest'}
            </p>
            <p className="text-xs text-black/50 truncate">{user?.email}</p>
          </div>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 p-4">
        <ul className="flex flex-col gap-2">
          {navItems.map((item) => {
            const isActive = location.pathname === item.path || 
              (item.path !== '/home' && location.pathname.startsWith(item.path));
            return (
              <li key={item.path}>
                <Link
                  to={item.path}
                  className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                    isActive
                      ? 'bg-[#ffe7df] text-[#ff5d2e]'
                      : 'text-black/70 hover:bg-[#fff7f5]'
                  }`}
                >
                  <item.icon className="w-5 h-5" />
                  <span className="font-medium">{item.label}</span>
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>

      {/* Quick actions */}
      <div className="p-4 border-t border-black/10">
        <div className="flex flex-col gap-2">
          <Link
            to="/vehicles"
            className="flex items-center gap-3 px-4 py-3 rounded-lg text-black/70 hover:bg-[#fff7f5] transition-colors"
          >
            <Car className="w-5 h-5" />
            <span className="font-medium">My Vehicles</span>
          </Link>
          <Link
            to="/settings"
            className="flex items-center gap-3 px-4 py-3 rounded-lg text-black/70 hover:bg-[#fff7f5] transition-colors"
          >
            <Settings className="w-5 h-5" />
            <span className="font-medium">Settings</span>
          </Link>
          <button
            onClick={logout}
            className="flex items-center gap-3 px-4 py-3 rounded-lg text-red-500 hover:bg-red-50 transition-colors w-full"
          >
            <LogOut className="w-5 h-5" />
            <span className="font-medium">Logout</span>
          </button>
        </div>
      </div>
    </aside>
  );
}

// Desktop header component
function DesktopHeader() {
  const { user } = useAuth();

  return (
    <header className="hidden lg:flex items-center justify-between h-16 px-6 bg-white border-b border-black/10 fixed top-0 left-64 right-0 z-10">
      {/* Search */}
      <div className="flex-1 max-w-md">
      </div>

      {/* Actions */}
      <div className="flex items-center gap-4">
        <button className="relative p-2 hover:bg-[#fff7f5] rounded-lg transition-colors">
          <Bell className="w-5 h-5 text-black/70" />
          <span className="absolute top-1 right-1 w-2 h-2 bg-[#ff5d2e] rounded-full" />
        </button>
        <div className="flex items-center gap-2 px-3 py-2 rounded-lg">
          <div className="w-8 h-8 bg-[#ffe7df] rounded-full flex items-center justify-center">
            <User className="w-4 h-4 text-[#ff5d2e]" />
          </div>
          <span className="text-sm font-medium text-black">
            {user?.fullName?.split(' ')[0] || 'User'}
          </span>
        </div>
      </div>
    </header>
  );
}

// Mobile header component
function MobileHeader({ onMenuOpen }: { onMenuOpen: () => void }) {
  return (
    <header className="lg:hidden flex items-center justify-between px-4 py-3 bg-white border-b border-black/10 sticky top-0 z-20">
      <button
        onClick={onMenuOpen}
        className="p-2 -ml-2 hover:bg-[#fff7f5] rounded-lg transition-colors"
      >
        <Menu className="w-6 h-6" />
      </button>
      <h1 className="text-xl font-bold text-[#ff5d2e]">Servio</h1>
      <div className="w-8 h-8 bg-[#ffe7df] rounded-full flex items-center justify-center">
        <User className="w-4 h-4 text-[#ff5d2e]" />
      </div>
    </header>
  );
}

// Mobile bottom tab bar
function MobileTabBar() {
  const location = useLocation();

  return (
    <nav className="lg:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-black/10 safe-area-pb z-20">
      <div className="flex items-center justify-around py-2">
        {navItems.map((item) => {
          const isActive = location.pathname === item.path || 
            (item.path !== '/home' && location.pathname.startsWith(item.path));
          return (
            <Link
              key={item.path}
              to={item.path}
              className="flex flex-col items-center gap-1 px-4 py-2"
            >
              <item.icon
                className={`w-6 h-6 ${isActive ? 'text-black' : 'text-black/50'}`}
              />
              <span
                className={`text-xs ${
                  isActive ? 'font-semibold text-black' : 'font-medium text-black/50'
                }`}
              >
                {item.label}
              </span>
              {isActive && <div className="w-4 h-0.5 bg-[#ff5d2e] rounded-lg" />}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}

// Mobile slide-out menu
function MobileMenu({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) {
  const location = useLocation();
  const { user, logout } = useAuth();

  if (!isOpen) return null;

  return (
    <div className="lg:hidden fixed inset-0 z-50">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/50"
        onClick={onClose}
      />
      
      {/* Menu panel */}
      <div className="absolute left-0 top-0 bottom-0 w-72 bg-white shadow-xl flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-black/10">
          <h1 className="text-xl font-bold text-[#ff5d2e]">Servio</h1>
          <button
            onClick={onClose}
            className="p-2 hover:bg-[#fff7f5] rounded-lg transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* User info */}
        <div className="p-4 border-b border-black/10">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 bg-[#ffe7df] rounded-full flex items-center justify-center">
              <User className="w-6 h-6 text-[#ff5d2e]" />
            </div>
            <div>
              <p className="font-semibold text-black">{user?.fullName || 'Guest'}</p>
              <p className="text-sm text-black/50">{user?.email}</p>
            </div>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 p-4 overflow-y-auto">
          <ul className="flex flex-col gap-2">
            {navItems.map((item) => {
              const isActive = location.pathname === item.path;
              return (
                <li key={item.path}>
                  <Link
                    to={item.path}
                    onClick={onClose}
                    className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                      isActive
                        ? 'bg-[#ffe7df] text-[#ff5d2e]'
                        : 'text-black/70 hover:bg-[#fff7f5]'
                    }`}
                  >
                    <item.icon className="w-5 h-5" />
                    <span className="font-medium">{item.label}</span>
                  </Link>
                </li>
              );
            })}
          </ul>

          <div className="mt-6 pt-6 border-t border-black/10">
            <ul className="flex flex-col gap-2">
              <li>
                <Link
                  to="/vehicles"
                  onClick={onClose}
                  className="flex items-center gap-3 px-4 py-3 rounded-lg text-black/70 hover:bg-[#fff7f5] transition-colors"
                >
                  <Car className="w-5 h-5" />
                  <span className="font-medium">My Vehicles</span>
                </Link>
              </li>
              <li>
                <Link
                  to="/settings"
                  onClick={onClose}
                  className="flex items-center gap-3 px-4 py-3 rounded-lg text-black/70 hover:bg-[#fff7f5] transition-colors"
                >
                  <Settings className="w-5 h-5" />
                  <span className="font-medium">Settings</span>
                </Link>
              </li>
            </ul>
          </div>
        </nav>

        {/* Logout */}
        <div className="p-4 border-t border-black/10">
          <button
            onClick={() => {
              logout();
              onClose();
            }}
            className="flex items-center gap-3 px-4 py-3 rounded-lg text-red-500 hover:bg-red-50 transition-colors w-full"
          >
            <LogOut className="w-5 h-5" />
            <span className="font-medium">Logout</span>
          </button>
        </div>
      </div>
    </div>
  );
}

// Main AppLayout component
export function AppLayout({ children, showNav = true }: AppLayoutProps) {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  if (!showNav) {
    return (
      <div className="min-h-screen w-full max-w-full overflow-x-hidden bg-gradient-to-b from-[#fff7f5] to-[#fbfbfb]">
        {children}
      </div>
    );
  }

  return (
    <div className="min-h-screen w-full max-w-full overflow-x-hidden bg-gradient-to-b from-[#fff7f5] to-[#fbfbfb]">
      {/* Desktop sidebar */}
      <DesktopSidebar />
      
      {/* Desktop header */}
      <DesktopHeader />
      
      {/* Mobile header */}
      <MobileHeader onMenuOpen={() => setMobileMenuOpen(true)} />
      
      {/* Mobile menu */}
      <MobileMenu isOpen={mobileMenuOpen} onClose={() => setMobileMenuOpen(false)} />

      {/* Main content */}
      <main className="lg:ml-64 lg:pt-16 pb-20 lg:pb-6">
        <div className="max-w-7xl mx-auto px-4 lg:px-6 py-4 lg:py-6">
          {children}
        </div>
      </main>

      {/* Mobile tab bar */}
      <MobileTabBar />
    </div>
  );
}

// Page container for consistent max-width and padding
export function PageContainer({ children, className = '' }: { children: ReactNode; className?: string }) {
  return (
    <div className={`w-full max-w-full ${className}`}>
      {children}
    </div>
  );
}
