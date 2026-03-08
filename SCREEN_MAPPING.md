# Dietician Babu — Screen & Function Mapping v1.3.0

## USER ROLES
- **Public** — not logged in
- **Client (Non-subscriber)** — logged in, onboarding complete, no active plan
- **Client (Subscriber)** — logged in, active paid subscription
- **Admin** — `dieticianbabu@gmail.com`

---

## PUBLIC SCREENS (No login required)

### 1. Landing Screen `/landing`
| Feature | Status |
|---|---|
| Hero section + CTA (Get Started / Chat) | ✅ Static |
| Stats (500+ clients, 7 yrs, 98% satisfaction) | ⚠️ Hardcoded |
| Plan pricing preview (Regular ₹2499 / Rapid ₹4499 / Super ₹5999) | ⚠️ Hardcoded |
| WhatsApp contact button (918871448064) | ✅ Real link |
| Call button | ✅ Real link |
| Navigate to Login / Signup | ✅ |

### 2. Login Screen `/login-screen`
| Feature | Status |
|---|---|
| Phone OTP (10-digit, Firebase phone auth) | ✅ Firebase |
| Email + Password login | ✅ Firebase |
| Google Sign-In | ✅ Firebase |
| Forgot password (email reset) | ✅ Firebase |
| Auto-routes: Admin → admin dash, Client → onboarding/dashboard | ✅ |

### 3. Signup Screen `/signup`
| Feature | Status |
|---|---|
| Name, email, phone, password form with validation | ✅ |
| Creates user in Firebase Auth + `users` Firestore doc | ✅ Firebase |
| Navigates to Health Profile Onboarding | ✅ |

---

## CLIENT SCREENS (Login required)

### 4. Health Profile Onboarding `/health-profile-onboarding`
*Shown once — after first signup or if onboardingComplete = false*
| Feature | Status |
|---|---|
| Step 1: Goal selection | ✅ |
| Step 2: Activity level slider | ✅ |
| Step 3: Age / height / weight / gender | ✅ |
| Step 4: Medical conditions (multi-select) | ✅ |
| Step 5: Food preferences (cuisines, dietary restrictions) | ✅ |
| Step 6: Summary / review | ✅ |
| Saves to `clients` collection, sets onboardingComplete=true | ✅ Firebase |
| Routes to Subscription Plans on completion | ✅ |

### 5. Dashboard Home `/dashboard-home`
| Feature | Status |
|---|---|
| Personalised greeting (real name from Firebase) | ✅ Firebase |
| Subscription status banner (plan name or upgrade prompt) | ✅ Firebase |
| My Diet Plan tile → `/diet-plan-viewer` | ✅ |
| Weekly Check-in tile → `/weekly-checkin` | ✅ |
| My Progress tile → `/progress-tracking` | ✅ |
| Subscription tile → `/subscription-plans` | ✅ |
| Daily Calorie Progress widget | ⚠️ Hardcoded (1800 kcal target, mock meals) |
| Water Intake Tracker | ⚠️ Hardcoded/mock |
| Today's Meal Plan preview | ⚠️ Hardcoded |
| Step Counter widget | ⚠️ Hardcoded |
| Consultation Reminder | ⚠️ Hardcoded mock |
| Motivational message banner | ⚠️ Hardcoded |
| Weather (24°C) | ⚠️ Hardcoded |
| Logout → `/landing` | ✅ Firebase signOut |
| Bottom nav (Home / Meals / Progress / Chat / Profile) | ✅ UI |

### 6. Settings & Profile `/settings-profile`
| Feature | Status |
|---|---|
| Profile header (real name, email, plan from Firebase) | ✅ Firebase |
| Personal Info modal (name, email, phone) | ✅ Firebase (display only) |
| Change Password (Firebase email reset) | ✅ Firebase |
| Subscription Management link | ✅ UI only |
| Notification toggles | ⚠️ UI only (not persisted) |
| Language selector (English / Hindi) | ⚠️ UI only |
| Theme selector (System / Light / Dark) | ⚠️ UI only |
| Google Fit / Apple Health integration | ⚠️ Not implemented |
| Export Data | ⚠️ Not implemented |
| Biometric toggle | ⚠️ UI only |
| Offline sync toggle | ⚠️ UI only |
| Storage usage (245 MB) | ⚠️ Hardcoded |
| Help / Contact Support / Feedback | ⚠️ Dead-end routes |
| Logout → `/landing` | ✅ Firebase signOut |
| Delete Account | ⚠️ UI only (no Firebase delete) |

### 7. Diet Plan Viewer `/diet-plan-viewer`
| Feature | Status |
|---|---|
| Streams active diet plan from `plans` collection | ✅ Firebase |
| PDF plan view (tap to open URL) | ✅ Real |
| 7-day structured AI plan (day carousel) | ✅ Firebase |
| Meals: Breakfast / Mid-Morning / Lunch / Evening / Dinner | ✅ Firebase |
| Food items with quantity and calories | ✅ Firebase |
| "No plan assigned yet" state | ✅ Handled |
| **Requires active plan assigned by admin** | ✅ |

### 8. Subscription Plans `/subscription-plans`
| Feature | Status |
|---|---|
| Regular Plan — ₹2499 / 30 days | ⚠️ Hardcoded pricing |
| Rapid Plan — ₹4499 / 60 days (Popular) | ⚠️ Hardcoded pricing |
| Super Plan — ₹5999 / 90 days | ⚠️ Hardcoded pricing |
| Razorpay payment gateway | ✅ Real (production key) |
| On success: saves to `payments`, updates `clients` subscription | ✅ Firebase |
| Skip / pay later | ✅ |

### 9. Weekly Check-in `/weekly-checkin`
| Feature | Status |
|---|---|
| Weight entry (kg, decimal) | ✅ Firebase write |
| Mood selector (Great / Good / Okay / Low / Struggling) | ✅ Firebase write |
| Energy level (4 options) | ✅ Firebase write |
| Plan adherence (Strictly / Mostly / Partially / Struggled) | ✅ Firebase write |
| Optional notes | ✅ Firebase write |
| Writes to `weeklyUpdates` collection | ✅ Firebase |
| Updates current weight in `clients` | ✅ Firebase |
| Success screen with "Submit Another" | ✅ |

### 10. Progress Tracking `/progress-tracking`
| Feature | Status |
|---|---|
| Weight chart (line chart, 6-month view) | ⚠️ MOCK DATA |
| Body measurements (waist, chest, arms, thighs) | ⚠️ MOCK DATA |
| Nutrition breakdown (protein/carbs/fats/fiber pie chart) | ⚠️ MOCK DATA |
| Activity metrics (calories burned, minutes, distance) | ⚠️ MOCK DATA |
| Time period selector (1W / 1M / 3M / 1Y) | ⚠️ UI only (mock) |
| Achievements / badges | ⚠️ 2 of 4 hardcoded unlocked |
| Photo comparison widget | ⚠️ Demo Pexels URLs |
| Quick entry sheet (log weight/measurements) | ⚠️ Firebase write implied, incomplete |
| **Status: Needs Firebase wiring to `weeklyUpdates` / progress collection** | ❌ |

---

## ADMIN SCREENS (Admin account only)

### 11. Admin Dashboard Overview `/admin-dashboard-overview`
| Feature | Status |
|---|---|
| Active Subscriptions count + growth % | ✅ Firebase |
| Monthly Revenue (current month) | ✅ Firebase |
| Pending Approvals count | ✅ Firebase |
| Total Clients count | ✅ Firebase |
| Revenue chart (time range selector) | ✅ Firebase |
| Recent activity feed | ✅ Firebase |
| Quick action panel | ✅ |

### 12. Client Management `/client-management-system`
| Feature | Status |
|---|---|
| Pending Approvals tab (approve / reject) | ✅ Firebase |
| Active Clients tab | ✅ Firebase |
| Inactive Clients tab | ✅ Firebase |
| Flagged Accounts tab | ✅ Firebase |
| Bulk approve | ✅ Firebase |
| Search + filter clients | ✅ |
| Client detail modal | ✅ Firebase |
| Send message to client | ✅ Firebase |
| Export client list | ⚠️ Partially |

### 13. Admin Diet Plan Creator `/admin-diet-plan-creator`
| Feature | Status |
|---|---|
| Step 1: Plan title + tags (10 predefined) | ✅ |
| Step 1: Assign to specific client (optional) | ✅ Firebase |
| Step 2: AI generation via Gemini 1.5 Flash | ✅ Real (Gemini API) |
| Step 2: Personalised with client's health profile | ✅ Firebase |
| Step 2: Manual edit (inline meal editing) | ✅ |
| Step 3: Save to `plans` collection | ✅ Firebase |
| Assigns plan to client (updates `clients.currentPlanId`) | ✅ Firebase |

### 14. Diet Plans Management `/diet-plans-management`
| Feature | Status |
|---|---|
| List all plans (AI + PDF) | ✅ Firebase |
| Search by title / client / tag | ✅ |
| Filter by type (All / AI / PDF) | ✅ |
| Tag-based filter row | ✅ |
| Assign unassigned plan to client | ✅ Firebase |
| Delete plan | ✅ Firebase |
| Stats: total / unassigned counts | ✅ Firebase |
| New Plan button → `/admin-diet-plan-creator` | ✅ |

### 15. Sales Analytics `/sales-analytics`
| Feature | Status |
|---|---|
| Total Revenue (all-time) | ✅ Firebase |
| This Month Revenue | ✅ Firebase |
| Average Order Value | ✅ Firebase |
| Plans Sold (total subscriptions) | ✅ Firebase |
| Revenue by Plan (bar chart) | ✅ Firebase |
| Monthly subscriptions trend (6 months) | ✅ Firebase |
| Full transaction history table | ✅ Firebase |

### 16. Subscriptions Management `/subscriptions-management`
| Feature | Status |
|---|---|
| Filter by status (Active / Paused / Expiring Soon / Expired) | ✅ Firebase |
| Days remaining for each subscription | ✅ Firebase |
| Extend subscription (1–12 weeks) | ✅ Firebase |
| Pause subscription (with days-remaining saved) | ✅ Firebase |
| Resume subscription (restores saved days) | ✅ Firebase |
| Cancel subscription (with confirmation) | ✅ Firebase |

### 17. Admin Settings `/admin-settings`
| Feature | Status |
|---|---|
| Admin profile (name, email from Firebase) | ✅ Firebase |
| Change password | ✅ Firebase |
| App info (version 1.3.0, business info) | ✅ |
| Logout → `/landing` | ✅ Firebase |

---

## WHAT'S WIRED vs WHAT NEEDS WORK

### ✅ Fully Connected to Firebase
- Authentication (Email, Phone OTP, Google Sign-In)
- Signup + Health Onboarding (create users + clients docs)
- Diet Plan Viewer (real-time stream from `plans`)
- Weekly Check-in (writes to `weeklyUpdates` + updates `clients`)
- Subscription payment flow (Razorpay → `payments` → `clients`)
- All 7 admin screens (client management, analytics, subscriptions, diet plans)

### ⚠️ Partially Connected (real user data, mock widgets)
- Dashboard Home — user greeting and subscription banner are real; all daily widgets (meals, calories, steps, water) are hardcoded
- Settings/Profile — name/email/plan are real; notifications/theme/language not persisted

### ❌ Mock Data Only (needs future wiring)
- **Progress Tracking** — all charts use static arrays; should read from `weeklyUpdates` and a `progress` collection
- **Dashboard daily widgets** — calorie tracking, meal plan display, water intake should pull from logged user data
- **Notification preferences** — should be persisted in Firestore
- **Landing page stats** — could be pulled dynamically from admin dashboard counts

---

## FIREBASE COLLECTIONS OVERVIEW

| Collection | Used By |
|---|---|
| `users` | Signup, Login, Splash, Dashboard, Settings, Admin |
| `clients` | Onboarding, Dashboard, Settings, Weekly Check-in, Subscription, Admin |
| `plans` | Diet Plan Viewer, Diet Plan Creator, Diet Plans Management |
| `payments` | Subscription Plans (write), Sales Analytics (read) |
| `weeklyUpdates` | Weekly Check-in (write), Progress Tracking (TODO: read) |

---

*Generated: 2026-03-08 | App version: 1.3.0*
