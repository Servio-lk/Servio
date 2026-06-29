import type { ReactNode } from 'react';

interface MobileLayoutProps {
  children: ReactNode;
  showTabBar?: boolean;
  showStatusBar?: boolean;
}

export function MobileLayout({ 
  children, 
  showTabBar = false,
  showStatusBar = true 
}: MobileLayoutProps) {
  return (
    <div className="flex flex-col h-screen w-full max-w-[428px] mx-auto bg-[#fff7f5]">
      {showStatusBar && (
        <div className="flex items-center justify-between px-4 pt-5 pb-5">
          <div className="font-semibold text-[17px]">9:41</div>
          <div className="flex items-center gap-2">
            <div className="w-5 h-3" />
            <div className="w-4 h-3" />
            <div className="w-7 h-3" />
          </div>
        </div>
      )}
      
      {children}
      
      {showTabBar && (
        <>
          {/* Tab Bar content would go here if needed */}
        </>
      )}
    </div>
  );
}

interface StatusBarProps {
  time?: string;
}

export function StatusBar({ time = '9:41' }: StatusBarProps) {
  return (
    <div className="flex items-center justify-between px-4 pt-5 pb-5 w-full">
      <div className="font-semibold text-[17px]">{time}</div>
      <div className="flex items-center gap-2">
        <div className="w-5 h-3">{/* Cellular */}</div>
        <div className="w-4 h-3">{/* Wifi */}</div>
        <div className="w-7 h-3">{/* Battery */}</div>
      </div>
    </div>
  );
}

interface HomeIndicatorProps {
  className?: string;
}

export function HomeIndicator({ className = '' }: HomeIndicatorProps) {
  return (
    <div className={`h-[34px] flex items-end justify-center pb-2 ${className}`}>
      <div className="w-36 h-[5px] bg-black rounded-full" />
    </div>
  );
}

interface TabBarProps {
  activeTab: 'home' | 'services' | 'activity' | 'account';
  onTabChange?: (tab: string) => void;
}

export function TabBar({ activeTab, onTabChange }: TabBarProps) {
  const tabs = [
    { id: 'home', label: 'Home', icon: '🏠' },
    { id: 'services', label: 'Services', icon: '📋' },
    { id: 'activity', label: 'Activity', icon: '📄' },
    { id: 'account', label: 'Account', icon: '👤' },
  ];

  return (
    <div className="bg-white border-t border-black/20 flex items-center justify-center gap-4 px-6 py-0">
      {tabs.map((tab) => (
        <button
          key={tab.id}
          onClick={() => onTabChange?.(tab.id)}
          className={`flex flex-col items-center gap-2 py-2 px-2 w-[75.75px] ${
            activeTab === tab.id ? '' : 'h-[59px]'
          }`}
        >
          <div className={`w-6 h-6 ${activeTab === tab.id ? 'text-black' : 'text-black/50'}`}>
            {tab.icon}
          </div>
          <p
            className={`text-xs text-center ${
              activeTab === tab.id
                ? 'font-semibold text-black'
                : 'font-medium text-black/50'
            }`}
          >
            {tab.label}
          </p>
          {activeTab === tab.id && (
            <div className="w-4 h-0.5 bg-[#ff5d2e] rounded-lg" />
          )}
        </button>
      ))}
    </div>
  );
}
