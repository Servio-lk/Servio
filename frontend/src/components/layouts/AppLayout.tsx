import { Link, useLocation } from 'react-router-dom';
import { Home, List, FileText, User, Settings, LogOut } from 'lucide-react';
import { type ReactNode } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import LogoImage from '/ServioLogo.png';
import { NotificationBell } from '@/components/NotificationBell';

interface AppLayoutProps {
  children: ReactNode;
  showNav?: boolean;
}

// Tab bar items for both mobile and desktop
const navItems = [
  { icon: Home, label: 'Home', path: '/home' },
  { icon: List, label: 'Services', path: '/services' },
  { icon: FileText, label: 'Activity', path: '/activity' },
  { icon: User, label: 'Account', path: '/account' }
];

// Desktop sidebar component
function DesktopSidebar() {
  const location = useLocation();
  const { logout } = useAuth();

  return (
    <aside className="hidden lg:flex flex-col w-64 bg-white border-r border-black/10 h-screen fixed left-0 top-0">
      {/* Logo */}
      <div className="px-6 h-[64px] border-b border-black/10 inline-flex justify-center items-center">
        <img src={LogoImage} alt="Servio" className="h-10 w-auto" />
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
        <NotificationBell />
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
function MobileHeader() {
  return (
    <header className="lg:hidden flex items-center justify-between px-4 py-3 bg-white border-b border-black/10 sticky top-0 z-20">
      <img src={LogoImage} alt="Servio" className="h-8 w-auto" />
      <div className="flex items-center gap-1">
        <NotificationBell />
        <div className="w-8 h-8 bg-[#ffe7df] rounded-full flex items-center justify-center">
          <User className="w-4 h-4 text-[#ff5d2e]" />
        </div>
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


// Main AppLayout component
export function AppLayout({ children, showNav = true }: AppLayoutProps) {
  if (!showNav) {
    return (
      <div className="min-h-screen w-full max-w-full overflow-x-hidden bg-[#fff7f5]">
        {/* Desktop sidebar + header always visible */}
        <DesktopSidebar />
        <DesktopHeader />

        {/* Desktop: offset for sidebar + header; Mobile: full width */}
        <main className="lg:ml-64 lg:pt-16">
          {children}
        </main>
      </div>
    );
  }

  return (
    <div className="min-h-screen w-full max-w-full overflow-x-hidden bg-[#fff7f5]">
      {/* Desktop sidebar */}
      <DesktopSidebar />
      
      {/* Desktop header */}
      <DesktopHeader />
      
      {/* Mobile header */}
      <MobileHeader />

      {/* Main content */}
      <main className="lg:ml-64 lg:pt-16 pb-20 lg:pb-6">
        <div className="max-w-4xl mx-auto px-4 lg:px-6 py-4 lg:py-6">
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
