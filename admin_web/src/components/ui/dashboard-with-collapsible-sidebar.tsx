"use client"
import React, { useState, useEffect } from "react";
import { collection, query, where, onSnapshot, getCountFromServer, orderBy, limit, doc } from "firebase/firestore";
import { signInWithEmailAndPassword, onAuthStateChanged, signOut, User as FirebaseUser } from "firebase/auth";
import { db, auth } from "@/lib/firebase";
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  Home,
  DollarSign,
  Monitor,
  ShoppingCart,
  Tag,
  BarChart3,
  Users,
  ChevronDown,
  ChevronsRight,
  Moon,
  Sun,
  TrendingUp,
  Activity,
  Package,
  Bell,
  Settings,
  HelpCircle,
  User,
} from "lucide-react";

export const Example = () => {
  const [isDark, setIsDark] = useState(false);
  const [user, setUser] = useState<FirebaseUser | null>(null);
  const [loadingAuth, setLoadingAuth] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [authError, setAuthError] = useState('');

  const handleEmailLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setAuthError('');
    try {
      await signInWithEmailAndPassword(auth, email, password);
    } catch (error: any) {
      setAuthError('Invalid email or password');
    }
  };

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (u) => {
      setUser(u);
      setLoadingAuth(false);
    });
    return () => unsub();
  }, []);

  useEffect(() => {
    if (isDark) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [isDark]);

  if (loadingAuth) {
    return (
      <div className={`min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-950 text-gray-900 dark:text-gray-100 ${isDark ? 'dark' : ''}`}>
        <div className="animate-pulse flex flex-col items-center">
          <Logo />
          <p className="mt-4 font-medium">Loading Admin Portal...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className={`min-h-screen flex flex-col items-center justify-center bg-gray-50 dark:bg-gray-950 text-gray-900 dark:text-gray-100 p-4 ${isDark ? 'dark' : ''}`}>
        <div className="absolute top-4 right-4">
          <button
            onClick={() => setIsDark(!isDark)}
            className="flex h-10 w-10 items-center justify-center rounded-lg border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
          >
            {isDark ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
          </button>
        </div>

        <div className="bg-white dark:bg-gray-900 p-8 rounded-2xl shadow-sm border border-gray-200 dark:border-gray-800 flex flex-col items-center max-w-sm w-full">
          <Logo />
          <h1 className="mt-6 text-2xl font-bold">Admin Portal</h1>
          <p className="mt-2 text-gray-500 dark:text-gray-400 text-center text-sm mb-6">
            Please sign in with your authorized admin account to access the dashboard.
          </p>

          <form onSubmit={handleEmailLogin} className="w-full space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-blue-500 outline-none"
                placeholder="admin@dieticianbabu.com"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Password</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-blue-500 outline-none"
                placeholder="••••••••"
              />
            </div>
            {authError && <p className="text-red-500 text-sm text-center">{authError}</p>}
            <button
              type="submit"
              className="flex w-full justify-center items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-xl font-medium transition-colors shadow-sm mt-2"
            >
              Sign In
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className={`flex min-h-screen w-full ${isDark ? 'dark' : ''}`}>
      <div className="flex w-full bg-gray-50 dark:bg-gray-950 text-gray-900 dark:text-gray-100">
        <Sidebar />
        <ExampleContent isDark={isDark} setIsDark={setIsDark} />
      </div>
    </div>
  );
};

const Sidebar = () => {
  const [open, setOpen] = useState(true);
  const pathname = usePathname();

  return (
    <nav
      className={`sticky top-0 h-screen shrink-0 border-r transition-all duration-300 ease-in-out ${open ? 'w-64' : 'w-16'
        } border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-2 shadow-sm`}
    >
      <TitleSection open={open} />

      <div className="space-y-1 mb-8">
        <Option
          Icon={Home}
          title="Dashboard"
          href="/"
          selected={pathname === '/'}
          open={open}
        />
        <Option
          Icon={DollarSign}
          title="Sales"
          href="/sales"
          selected={pathname === '/sales'}
          open={open}
          notifs={3}
        />
        <Option
          Icon={Users}
          title="Members"
          href="/members"
          selected={pathname === '/members'}
          open={open}
          notifs={12}
        />
        <Option
          Icon={ShoppingCart}
          title="Products"
          href="/products"
          selected={pathname === '/products'}
          open={open}
        />
        <Option
          Icon={BarChart3}
          title="Analytics"
          href="/analytics"
          selected={pathname === '/analytics'}
          open={open}
        />
      </div>

      {open && (
        <div className="border-t border-gray-200 dark:border-gray-800 pt-4 space-y-1">
          <div className="px-3 py-2 text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide">
            Account
          </div>
          <Option
            Icon={Settings}
            title="Settings"
            href="/settings"
            selected={pathname === '/settings'}
            open={open}
          />
        </div>
      )}

      <ToggleClose open={open} setOpen={setOpen} />
    </nav>
  );
};

const Option = ({ Icon, title, href, selected, open, notifs }: any) => {
  return (
    <Link
      href={href}
      className={`relative flex h-11 w-full items-center rounded-md transition-all duration-200 ${selected
        ? "bg-blue-50 dark:bg-blue-900/50 text-blue-700 dark:text-blue-300 shadow-sm border-l-2 border-blue-500"
        : "text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-gray-200"
        }`}
    >
      <div className="grid h-full w-12 place-content-center">
        <Icon className="h-4 w-4" />
      </div>

      {open && (
        <span
          className={`text-sm font-medium transition-opacity duration-200 ${open ? 'opacity-100' : 'opacity-0'
            }`}
        >
          {title}
        </span>
      )}

      {notifs && open && (
        <span className="absolute right-3 flex h-5 w-5 items-center justify-center rounded-full bg-blue-500 dark:bg-blue-600 text-xs text-white font-medium">
          {notifs}
        </span>
      )}
    </Link>
  );
};

const TitleSection = ({ open }: any) => {
  return (
    <div className="mb-6 border-b border-gray-200 dark:border-gray-800 pb-4">
      <div className="flex cursor-pointer items-center justify-between rounded-md p-2 transition-colors hover:bg-gray-50 dark:hover:bg-gray-800">
        <div className="flex items-center gap-3">
          <Logo />
          {open && (
            <div className={`transition-opacity duration-200 ${open ? 'opacity-100' : 'opacity-0'}`}>
              <div className="flex items-center gap-2">
                <div>
                  <span className="block text-sm font-semibold text-gray-900 dark:text-gray-100">
                    Dietician Babu
                  </span>
                  <span className="block text-xs text-gray-500 dark:text-gray-400">
                    Admin Portal
                  </span>
                </div>
              </div>
            </div>
          )}
        </div>
        {open && (
          <ChevronDown className="h-4 w-4 text-gray-400 dark:text-gray-500" />
        )}
      </div>
    </div>
  );
};

const Logo = () => {
  return (
    <div className="grid size-10 shrink-0 place-content-center rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 shadow-sm">
      <svg
        width="20"
        height="auto"
        viewBox="0 0 50 39"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="fill-white"
      >
        <path
          d="M16.4992 2H37.5808L22.0816 24.9729H1L16.4992 2Z"
        />
        <path
          d="M17.4224 27.102L11.4192 36H33.5008L49 13.0271H32.7024L23.2064 27.102H17.4224Z"
        />
      </svg>
    </div>
  );
};

const ToggleClose = ({ open, setOpen }: any) => {
  return (
    <button
      onClick={() => setOpen(!open)}
      className="absolute bottom-0 left-0 right-0 border-t border-gray-200 dark:border-gray-800 transition-colors hover:bg-gray-50 dark:hover:bg-gray-800"
    >
      <div className="flex items-center p-3">
        <div className="grid size-10 place-content-center">
          <ChevronsRight
            className={`h-4 w-4 transition-transform duration-300 text-gray-500 dark:text-gray-400 ${open ? "rotate-180" : ""
              }`}
          />
        </div>
        {open && (
          <span
            className={`text-sm font-medium text-gray-600 dark:text-gray-300 transition-opacity duration-200 ${open ? 'opacity-100' : 'opacity-0'
              }`}
          >
            Hide
          </span>
        )}
      </div>
    </button>
  );
};

const ExampleContent = ({ isDark, setIsDark }: any) => {
  const [stats, setStats] = useState({
    activeUsers: 0,
    dietPlans: 0,
    pendingApprovals: 0,
    totalSales: 0,
  });

  const [activities, setActivities] = useState<any[]>([]);
  const [topProducts, setTopProducts] = useState<any[]>([]);
  const [quickStats, setQuickStats] = useState({ pageViews: 0, bounceRate: '0%', conversion: '0%' });

  useEffect(() => {
    // 1. Users & Pending Approvals
    const usersUnsub = onSnapshot(collection(db, 'users'), (snapshot) => {
      let active = 0;
      let pending = 0;
      snapshot.forEach(docSnap => {
        const data = docSnap.data();
        if (data.status === 'active' || data.subscriptionStatus === 'active' || data.role === 'client') active++;
        if (data.status === 'pending' || data.subscriptionStatus === 'pending' || data.subscriptionStatus === 'none') pending++;
      });
      setStats(s => ({ ...s, activeUsers: active, pendingApprovals: pending }));
    });

    // 2. Diet Plans
    const plansUnsub = onSnapshot(collection(db, 'plans'), (snapshot) => {
      setStats(s => ({ ...s, dietPlans: snapshot.size }));
    }, (error) => console.error("Error fetching diet plans. Check Firestore Rules:", error));

    // 3. Payments for Total Sales & Top Products
    const paymentsUnsub = onSnapshot(query(collection(db, 'payments'), where('status', '==', 'success')), (snapshot) => {
      let total = 0;
      const pMap: Record<string, { revenue: number; sales: number }> = {};

      snapshot.forEach(docSnap => {
        const data = docSnap.data();
        const price = data.priceInr ? Number(data.priceInr) : 0;
        total += price;

        const name = data.planName || "Custom Plan";
        if (!pMap[name]) pMap[name] = { revenue: 0, sales: 0 };
        pMap[name].revenue += price;
        pMap[name].sales += 1;
      });

      setStats(s => ({ ...s, totalSales: total }));

      const sorted = Object.entries(pMap)
        .map(([name, data]) => ({ name, ...data }))
        .sort((a, b) => b.revenue - a.revenue)
        .slice(0, 5);
      setTopProducts(sorted);
    }, (error) => {
      console.error("Permission Denied reading 'payments'. Need to update Firestore rules to allow admin access:", error);
    });

    // 4. Recent Activities (Payments & Checkins)
    const recentPmtsUnsub = onSnapshot(query(collection(db, 'payments'), orderBy('paidAt', 'desc'), limit(5)), (snapshot) => {
      const pmts = snapshot.docs.map(docSnap => {
        const data = docSnap.data();
        return {
          id: docSnap.id,
          icon: DollarSign,
          title: "Payment Received",
          desc: `${data.userName || 'Client'} purchased ${data.planName || 'Plan'} for ₹${data.priceInr || 0}`,
          timeObject: data.paidAt?.toDate() || new Date(),
          color: "green",
          type: "payment"
        };
      });

      setActivities(prev => {
        const filtered = prev.filter(a => a.type !== 'payment');
        const combined = [...filtered, ...pmts].sort((a: any, b: any) => b.timeObject - a.timeObject).slice(0, 8);
        return combined;
      });
    }, (error) => console.error("Permission Denied reading recent payments:", error));

    const recentCheckinsUnsub = onSnapshot(query(collection(db, 'weeklyUpdates'), orderBy('submittedAt', 'desc'), limit(5)), (snapshot) => {
      const checks = snapshot.docs.map(docSnap => {
        const data = docSnap.data();
        return {
          id: docSnap.id,
          icon: Activity,
          title: "Weekly Check-in",
          desc: `${data.userName || 'Client'} submitted check-in. Mood: ${data.mood || 'N/A'}`,
          timeObject: data.submittedAt?.toDate() || new Date(),
          color: "blue",
          type: "checkin"
        };
      });

      setActivities(prev => {
        const filtered = prev.filter(a => a.type !== 'checkin');
        const combined = [...filtered, ...checks].sort((a: any, b: any) => b.timeObject - a.timeObject).slice(0, 8);
        return combined;
      });
    }, (error) => console.error("Permission Denied reading recent check-ins:", error));

    // 5. Quick Stats
    const statsUnsub = onSnapshot(doc(db, 'adminAnalytics', 'websiteStats'), (docSnap) => {
      if (docSnap.exists()) {
        setQuickStats(docSnap.data() as any);
      } else {
        // Fallback fake data if not initialized
        setQuickStats({ pageViews: 1250, bounceRate: '32%', conversion: '4.2%' });
      }
    }, (error) => {
      console.error("Permission Denied reading adminAnalytics. Using fallback data.", error);
      setQuickStats({ pageViews: 1250, bounceRate: '32%', conversion: '4.2%' });
    });

    return () => {
      usersUnsub();
      plansUnsub();
      paymentsUnsub();
      recentPmtsUnsub();
      recentCheckinsUnsub();
      statsUnsub();
    };
  }, []);

  return (
    <div className="flex-1 bg-gray-50 dark:bg-gray-950 p-6 overflow-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-gray-100">Dashboard</h1>
          <p className="text-gray-600 dark:text-gray-400 mt-1">Welcome back to your dashboard</p>
        </div>
        <div className="flex items-center gap-4">
          <button className="relative p-2 rounded-lg bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 transition-colors">
            <Bell className="h-5 w-5" />
            <span className="absolute -top-1 -right-1 h-3 w-3 bg-red-500 rounded-full"></span>
          </button>
          <button
            onClick={() => setIsDark(!isDark)}
            className="flex h-10 w-10 items-center justify-center rounded-lg border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-gray-100 transition-colors"
          >
            {isDark ? (
              <Sun className="h-4 w-4" />
            ) : (
              <Moon className="h-4 w-4" />
            )}
          </button>
          <button
            onClick={() => signOut(auth)}
            title="Sign Out"
            className="p-2 rounded-lg bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 text-gray-600 dark:text-gray-400 hover:text-red-600 dark:hover:text-red-400 hover:border-red-200 dark:hover:border-red-900 transition-colors"
          >
            <User className="h-5 w-5" />
          </button>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="p-6 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 shadow-sm hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between mb-4">
            <div className="p-2 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
              <DollarSign className="h-5 w-5 text-blue-600 dark:text-blue-400" />
            </div>
            <TrendingUp className="h-4 w-4 text-green-500" />
          </div>
          <h3 className="font-medium text-gray-600 dark:text-gray-400 mb-1">Total Sales</h3>
          <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">${stats.totalSales}</p>
          <p className="text-sm text-green-600 dark:text-green-400 mt-1">Live data</p>
        </div>

        <div className="p-6 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 shadow-sm hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between mb-4">
            <div className="p-2 bg-green-50 dark:bg-green-900/20 rounded-lg">
              <Users className="h-5 w-5 text-green-600 dark:text-green-400" />
            </div>
            <TrendingUp className="h-4 w-4 text-green-500" />
          </div>
          <h3 className="font-medium text-gray-600 dark:text-gray-400 mb-1">Active Users</h3>
          <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">{stats.activeUsers}</p>
          <p className="text-sm text-green-600 dark:text-green-400 mt-1">Live from Firestore</p>
        </div>

        <div className="p-6 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 shadow-sm hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between mb-4">
            <div className="p-2 bg-purple-50 dark:bg-purple-900/20 rounded-lg">
              <ShoppingCart className="h-5 w-5 text-purple-600 dark:text-purple-400" />
            </div>
            <TrendingUp className="h-4 w-4 text-green-500" />
          </div>
          <h3 className="font-medium text-gray-600 dark:text-gray-400 mb-1">Diet Plans</h3>
          <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">{stats.dietPlans}</p>
          <p className="text-sm text-green-600 dark:text-green-400 mt-1">Live from Firestore</p>
        </div>

        <div className="p-6 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 shadow-sm hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between mb-4">
            <div className="p-2 bg-orange-50 dark:bg-orange-900/20 rounded-lg">
              <Package className="h-5 w-5 text-orange-600 dark:text-orange-400" />
            </div>
            <TrendingUp className="h-4 w-4 text-green-500" />
          </div>
          <h3 className="font-medium text-gray-600 dark:text-gray-400 mb-1">Pending Approvals</h3>
          <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">{stats.pendingApprovals}</p>
          <p className="text-sm text-green-600 dark:text-green-400 mt-1">Live from Firestore</p>
        </div>
      </div>

      {/* Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Recent Activity */}
        <div className="lg:col-span-2">
          <div className="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">Recent Activity</h3>
              <button className="text-sm text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 font-medium">
                View all
              </button>
            </div>
            <div className="space-y-4">
              {activities.map((activity, i) => (
                <div key={i} className="flex items-center space-x-4 p-3 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors cursor-pointer">
                  <div className={`p-2 rounded-lg ${activity.color === 'green' ? 'bg-green-50 dark:bg-green-900/20' :
                    activity.color === 'blue' ? 'bg-blue-50 dark:bg-blue-900/20' :
                      activity.color === 'purple' ? 'bg-purple-50 dark:bg-purple-900/20' :
                        activity.color === 'orange' ? 'bg-orange-50 dark:bg-orange-900/20' :
                          'bg-red-50 dark:bg-red-900/20'
                    }`}>
                    <activity.icon className={`h-4 w-4 ${activity.color === 'green' ? 'text-green-600 dark:text-green-400' :
                      activity.color === 'blue' ? 'text-blue-600 dark:text-blue-400' :
                        activity.color === 'purple' ? 'text-purple-600 dark:text-purple-400' :
                          activity.color === 'orange' ? 'text-orange-600 dark:text-orange-400' :
                            'text-red-600 dark:text-red-400'
                      }`} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900 dark:text-gray-100 truncate">
                      {activity.title}
                    </p>
                    <p className="text-xs text-gray-500 dark:text-gray-400 truncate">
                      {activity.desc}
                    </p>
                  </div>
                  <div className="text-xs text-gray-400 dark:text-gray-500 whitespace-nowrap">
                    {activity.timeObject?.toLocaleDateString() || 'Just now'}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Extra Features Sidebar */}
        <div className="space-y-8">
          {/* Quick Stats */}
          <div className="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-6">Quick Stats</h3>
            <div className="space-y-4">
              <div className="flex items-center justify-between p-3 rounded-lg bg-gray-50 dark:bg-gray-800/50">
                <span className="text-sm font-medium text-gray-600 dark:text-gray-400">Page Views</span>
                <span className="font-bold text-gray-900 dark:text-gray-100">{quickStats.pageViews}</span>
              </div>
              <div className="flex items-center justify-between p-3 rounded-lg bg-gray-50 dark:bg-gray-800/50">
                <span className="text-sm font-medium text-gray-600 dark:text-gray-400">Bounce Rate</span>
                <span className="font-bold text-gray-900 dark:text-gray-100">{quickStats.bounceRate}</span>
              </div>
              <div className="flex items-center justify-between p-3 rounded-lg bg-gray-50 dark:bg-gray-800/50">
                <span className="text-sm font-medium text-gray-600 dark:text-gray-400">Conversion</span>
                <span className="font-bold text-green-600 dark:text-green-400">{quickStats.conversion}</span>
              </div>
            </div>
          </div>

          {/* Top Products */}
          <div className="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-6">Top Plans</h3>
            <div className="space-y-4">
              {topProducts.length === 0 && (
                <p className="text-sm text-gray-500 dark:text-gray-400 text-center py-4">No sales data yet.</p>
              )}
              {topProducts.map((product, i) => (
                <div key={i} className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
                      <Package className="h-4 w-4 text-blue-600 dark:text-blue-400" />
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-900 dark:text-gray-100">{product.name}</p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">{product.sales} sales</p>
                    </div>
                  </div>
                  <span className="text-sm font-bold text-gray-900 dark:text-gray-100">₹{product.revenue}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Example;
