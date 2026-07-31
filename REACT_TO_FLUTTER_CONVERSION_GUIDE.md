# React → Flutter Conversion Guide

A generic, reusable framework for converting React (TypeScript/JS) projects to Flutter (Dart) with an AI assistant, covering the entire lifecycle from initial prompt to APK release.

---

## 1. INITIAL PROMPT PATTERN

The foundation of every conversion. The initial prompt must establish:

### Required Elements

```
You are opencode, an expert Flutter developer with deep knowledge of {API_PLATFORM} integration.

React project: {PATH_TO_REACT_PROJECT}
Flutter project: {PATH_TO_FLUTTER_PROJECT}

Key constraints:
- {PLATFORM_SPECIFIC_CONSTRAINTS}
- {API_BASE_URLS}
- {AUTH_MECHANISM}
- {STATE_MANAGEMENT_PREFERENCE}
- {TARGET_PLATFORMS}
```

### What the prompt should include

| Element | Example | Purpose |
|---------|---------|---------|
| Base URLs | `VITE_AUGMONT_BASE_URL=https://uatbckend.karatly.net` | API endpoints |
| Auth tokens | `Bearer` token in headers | Authentication |
| SDK URLs | `VITE_CASHFREE_SDK_URL=https://sdk.cashfree.com/js/v3/cashfree.js` | Third-party integrations |
| Payment gateway | Cashfree, Razorpay, etc. | Payment flow |
| Merchant/Client IDs | `VITE_AUGMONT_MERCHANT_ID=11692` | Business identifiers |
| Platform splits | Web vs mobile conditional imports | Cross-platform handling |
| Styling system | Dark/light theme, CSS framework used | UI parity |

### Example Starting Prompt

```
You are opencode, an expert Flutter developer.

React project: C:\Users\...\react_app
Flutter project: C:\...\flutter_app

Key constraints:
- Auth backend: https://auth-api.example.com
- Main backend: https://api.example.com
- Merchant ID: 12345
- Payment SDK: https://sdk.payment.com/sdk.js
- Web uses iframe for viewer, mobile uses WebView
- Dark theme, mobile-first responsive design
- Frontend sends quantity as integer, not string
- Certain fields are backend-generated (don't send from frontend)
```

---

## 2. INITIAL EXPLORATION PHASE

### Step 1: Explore Both Projects

Send parallel exploration tasks:

```
Explore the React project at {PATH} very thoroughly.
Return:
1. Top-level directory structure
2. All folders and every .tsx/.ts file
3. All routes and their component names
4. Every API service file and function
5. Every reusable component
6. State management approach
```

```
Explore the Flutter project at {PATH} very thoroughly.
Return:
1. All folders and every .dart file
2. All routes and screen names
3. Every API service file and function
4. Every provider/service
5. Any empty/unimplemented directories
```

### Step 2: Generate Gap Analysis

After both explorations complete, compile a gap report:

| Section | Content |
|---------|---------|
| Critical missing | Entire screens/flows absent from Flutter |
| Moderate gaps | Partially implemented features |
| API gaps | Endpoints in React not in Flutter |
| Routing gaps | Routes defined but not registered |
| Effort estimates | Lines of code per gap |

---

## 3. IMPLEMENTATION PHASES

### Phase Order (by priority)

```
Phase 1: Core Infrastructure
├── API layer (Dio/Axios equivalent)
├── Route definitions (go_router / react-router equivalent)
├── State management (Riverpod / Redux/Context equivalent)
├── Data models
├── Auth flow
└── Shared widgets

Phase 2: Primary User Flows
├── Home / Dashboard
├── Buy / Purchase flow
├── Sell / Redemption flow
├── Payment gateway integration
├── Product marketplace
└── KYC verification

Phase 3: Supporting Features
├── Orders history
├── Profile / Settings
├── Charts / Analytics
├── Notifications
├── Certificate / Report generation
├── Legal / Policy pages
└── Invoice generation/download

Phase 4: Gap Filling
├── React parity fixes (features that exist but don't match)
├── API format matching
├── Navigation fixes
├── UI polish / theming parity
└── Edge case handling
```

---

## 4. DEBUGGING & ISSUE RESOLUTION PATTERN

### The Diagnostic Loop

```
1. REPRODUCE
   User: "X is broken" + screenshot/error
   
2. INVESTIGATE
   - Read the React implementation
   - Read the Flutter implementation
   - Compare API calls line by line
   - Check state management flow
   
3. HYPOTHESIZE
   - Form root cause theory
   - Verify with evidence (grep patterns, code paths)
   
4. PLAN
   - Present: file, line numbers, before/after code
   - Explain WHY this fixes it
   - Explain impact on other pages
   
5. IMPLEMENT
   - Minimal change, no refactors
   - Preserve existing behavior exactly
   
6. VERIFY
   - dart analyze / flutter analyze
   - No new warnings
   - No regressions

7. ITERATE (if needed)
   - User: "it didnt fix"
   - Re-investigate with different hypothesis
   - Try another approach
```

### Common Issue Categories

| Issue Type | Symptoms | Root Cause | Fix Pattern |
|------------|----------|------------|-------------|
| Type error | `List<dynamic>' not subtype of Map` | API returns array, code expects object | `is List` check before cast |
| Navigation crash | `"no pages left to show"` | `pop()` on GoRouter standalone route | Replace with `context.go()` |
| Web rendering | Unexpected underlines/dots | `SelectableText` HTML renderer artifact | Wrap in `DefaultTextStyle(decoration:TextDecoration.none)` |
| API 404 | `"Record not found"` | Missing required request fields | Match React request format exactly |
| Dead UI | Click does nothing | Missing GestureDetector wrapper | Wrap in GestureDetector |

---

## 5. REACT-TO-FLUTTER MAPPING

### Framework Equivalents

| React | Flutter |
|-------|---------|
| TypeScript `.tsx` | Dart `.dart` |
| Tailwind CSS | `Container` + `EdgeInsets` + `Border` |
| Context + useReducer | Riverpod `StateNotifier` |
| React Router | GoRouter |
| Axios | Dio |
| shadcn/ui | Custom widgets |
| Framer Motion | Implicit animations |
| localStorage | SharedPreferences |
| secure localStorage | FlutterSecureStorage |
| Lucide/Feather icons | Material Icons / custom SVGs |
| jsPDF + html2canvas | `package:pdf` |
| Capacitor/Cordova | Flutter native plugins |

### CSS-to-Flutter Conversion

| Tailwind | Flutter |
|----------|---------|
| `px-4` | `EdgeInsets.symmetric(horizontal: 16)` |
| `py-3` | `EdgeInsets.symmetric(vertical: 12)` |
| `rounded-xl` | `BorderRadius.circular(12)` |
| `text-[14px]` | `fontSize: 14` |
| `font-bold` | `fontWeight: FontWeight.bold` |
| `text-[#F7CD57]` | `color: Color(0xFFF7CD57)` |
| `bg-[#0F1416]` | `color: Color(0xFF0F1416)` |
| `border border-[#2E2E2E]` | `Border.all(color: Color(0xFF2E2E2E))` |
| `gap-3` | `SizedBox(width: 12)` / `SizedBox(height: 12)` |
| `grid grid-cols-2` | `Row(children: [Expanded(...), Expanded(...)])` |
| `flex items-center` | `Row(crossAxisAlignment: CrossAxisAlignment.center)` |
| `opacity-60` | `Opacity(opacity: 0.6)` |

### Gradient Mapping

| React (Tailwind) | Flutter |
|------------------|---------|
| `bg-gradient-to-br from-[#1E2A28] to-[#0D1117]` | `LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E2A28), Color(0xFF0D1117)])` |
| `radial-gradient(103.89% 37.92% at 97.55% 0%, #4A3A1E 0%, #000000 100%)` | `RadialGradient(center: Alignment(0.9755, -0.3792), radius: 1.04, colors: [Color(0xFF4A3A1E), Colors.black])` |

---

## 6. STATE MANAGEMENT MIGRATION

### React → Riverpod Pattern

```
React Context + useReducer
    ↓
Riverpod StateNotifier + StateNotifierProvider
```

### Mapping Guide

| React | Riverpod |
|-------|----------|
| `const [state, dispatch] = useReducer(reducer, initialState)` | `class MyNotifier extends StateNotifier<MyState>` |
| `const { state, dispatch } = useAuth()` | `ref.watch(authProvider)` |
| `dispatch({ type: 'SET_USER', payload: user })` | `ref.read(authProvider.notifier).setUser(user)` |
| `useEffect(() => { ... }, [])` | `Notifier` constructor or `initState()` |
| `useMemo(() => { ... }, [deps])` | `Provider((ref) => ...)` with `ref.watch` |

### Provider Types to Use

| Provider Type | Use Case |
|---------------|----------|
| `StateNotifierProvider` | Mutable state with actions (auth, cart, forms) |
| `Provider` | Computed/derived state (filtered lists, formatted values) |
| `FutureProvider` | Async data fetching (API responses) |
| `StreamProvider` | Real-time data (WebSocket, rate polling) |

---

## 7. ROUTING MIGRATION

### React Router → GoRouter

```
React Router (BrowserRouter + Routes + Route)
    ↓
GoRouter (GoRouter + GoRoute + ShellRoute)
```

### Key Differences

| React Router | GoRouter |
|--------------|----------|
| `<Route path="/home" element={<Home />} />` | `GoRoute(path: '/home', builder: (_, __) => const HomeScreen())` |
| `<Outlet />` for layouts | `ShellRoute(builder: ...)` for persistent UI |
| `navigate('/path')` | `context.go('/path')` |
| `navigate(-1)` | `Navigator.maybePop(context)` — but only works in shell routes |
| `useParams()` | `state.pathParameters` |
| `useSearchParams()` | `state.uri.queryParameters` |

### Critical GoRouter Rule

**Standalone routes** (registered outside a `ShellRoute`):
- `context.go()` REPLACES the current route — no history to pop
- Back buttons must use `context.go('/home')` NOT `Navigator.pop()`

**Shell routes** (inside `ShellRoute`):
- `Navigator.maybePop(context)` works because the shell maintains its own stack
- Safe to use for back navigation within tabs

---

## 8. API LAYER MIGRATION

### Axios → Dio

| Axios | Dio |
|-------|-----|
| `axios.get(url)` | `dio.get(url)` |
| `axios.post(url, data)` | `dio.post(url, data: data)` |
| `axios.interceptors` | `dio.interceptors.add(InterceptorsWrapper(...))` |
| `const instance = axios.create()` | `Dio(BaseOptions(...))` |

### API Function Structure

**React:**
```typescript
export const fetchSomething = async (params) => {
  const response = await requestEndpoint("/api/v1/endpoint", {
    key: params.key,
  });
  if (!response.ok) return { ...response, data: [] };
  const payload = response.data?.payload;
  const result = payload?.result;
  return { ok: true, data: result?.data || [] };
};
```

**Flutter:**
```dart
Future<Map<String, dynamic>> fetchSomething({required String key}) async {
  final response = await _requestEndpoint('/api/v1/endpoint', {
    'key': key.trim(),
  });
  if (!response['ok']) return {...response, 'data': []};
  final payload = (response['data'] as Map<String, dynamic>?)?['payload'] as Map<String, dynamic>?;
  final result = payload?['result'];
  final list = result is List ? result : (result as Map<String, dynamic>?)?['data'] ?? [];
  return {'ok': true, 'data': list is List ? list : []};
}
```

### Safe Response Parsing Pattern

Always use this pattern when `result` could be a List or Map:

```dart
final result = payload?['result'];
final list = result is List
    ? result
    : (result as Map<String, dynamic>?)?['data'] ?? [];
```

---

## 9. APK BUILD & OPTIMIZATION

### Build Configuration

**`android/app/build.gradle.kts`:**
```kotlin
android {
    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

**`android/gradle.properties`:**
```properties
android.enableR8.fullMode=true
```

### Build Command
```bash
flutter clean
flutter pub get
flutter build apk --target-platform=android-arm64 \
  --split-per-abi \
  --release \
  --split-debug-info=build/debug-info \
  --obfuscate
```

### Optimization Checklist

- [ ] Enable minification (`isMinifyEnabled = true`)
- [ ] Enable shrink resources (`isShrinkResources = true`)
- [ ] Enable R8 full mode (`android.enableR8.fullMode=true`)
- [ ] Create ProGuard rules (`proguard-rules.pro`)
- [ ] Compress images (reduce to <100KB where possible)
- [ ] Subset fonts (remove unused character sets)
- [ ] Remove unused packages from pubspec.yaml
- [ ] Build with `--split-per-abi` (separate APK per architecture)
- [ ] Build with `--obfuscate` + `--split-debug-info` (code obfuscation)

### Unused Package Detection

```bash
# Find packages in pubspec.yaml that are never imported
grep -r "import.*package:" lib/ | sort -u
# Compare against pubspec.yaml dependencies
```

---

## 10. USER COMMUNICATION PATTERNS

### How the User Reports Issues

```
Pattern: [Problem description] + [Screenshot/Error] + [Expected behavior]
Example: "in terms page lines are coming its breaking ui in mobile view"
         + screenshot showing yellow underlines
```

### How the User Validates Fixes

| Signal | Meaning |
|--------|---------|
| "do it" / "proceed" | Approves the plan |
| "it didnt fix" / "still there" | Fix didn't work — reinvestigate |
| "do the same for X" | Apply same fix pattern to related screens |
| "like in react" / "check react" | Use React implementation as reference |
| *Provides API request/response data* | Backend format confirmation |

### Decision Patterns

- Presents options with "(Recommended)" label
- Usually approves the recommended option
- Sometimes chooses the more specific option ("Only fix the specific screens mentioned")
- Quick to approve when presented with clear before/after evidence

---

## 11. WEB-SPECIFIC ISSUES & FIXES

### Flutter Web Rendering Artifacts

| Issue | Cause | Fix |
|-------|-------|-----|
| Text underlines | `SelectableText` on HTML renderer | Replace with `Text` or add `DefaultTextStyle(decoration: TextDecoration.none)` |
| Text invisible | Default text color on web is white-on-white | Add explicit `color: Colors.black` or `color: Colors.white` |
| Overflow | Fixed-height containers on small screens | Remove fixed height, use flexible layout |
| Scrollbar gap | Web scrollbar overlay | Add `SingleChildScrollView` + proper padding |

### Web vs Mobile Conditional Imports

```dart
// File: feature.dart
export 'feature_stub.dart'
    if (dart.library.js_interop) 'feature_web.dart';

// File: feature_stub.dart (mobile)
import 'package:webview_flutter/webview_flutter.dart';

// File: feature_web.dart (web)
import 'dart:html';
```

---

## 12. QUALITY CHECKS

### Before Each Edit

- [ ] Read the file first (required by tool)
- [ ] Understand surrounding context (imports, patterns)
- [ ] Identify exact oldString match (must be unique in file)
- [ ] Verify edit won't break other parts of the file

### After Each Edit

- [ ] `dart analyze {file}` — no errors, no new warnings
- [ ] Only info-level deprecation notices are acceptable
- [ ] Verify no unintended side effects

### Pre-Release Checklist

- [ ] All critical features match React
- [ ] API request format matches React exactly
- [ ] Back navigation works on all screens
- [ ] Web rendering artifacts resolved
- [ ] Mobile layout verified on multiple screen sizes
- [ ] APK builds with optimizations
- [ ] No warnings in `flutter analyze`

---

## 13. KEY FLAWS TO WATCH FOR

| Flaw | Detection | Prevention |
|------|-----------|------------|
| `Navigator.pop()` on standalone routes | App crashes on back | Always use `context.go()` for standalone GoRouter pages |
| `as Map<String, dynamic>` on API response | Runtime crash when result is a List | Use `is List` check before cast |
| Unused packages in pubspec.yaml | APK bloat | Check for `import` statements before adding dependency |
| `const` widget + dynamic style inheritance | Theme styles not applied | Use non-const widget when inheriting theme |
| Missing request fields | 404 from backend | Match React request format exactly |
| Dead UI elements | Click does nothing | Wrap in GestureDetector with onTap |
| Fixed heights on web | Overflow on small screens | Use flexible layout + scroll |

---

## 14. GLOSSARY

| Term | Meaning |
|------|---------|
| ShellRoute | GoRouter's persistent layout wrapper (like ` <Outlet />`) |
| Standalone route | A GoRoute registered OUTSIDE any ShellRoute |
| StateNotifier | Riverpod's mutable state class with actions |
| Conditional import | Dart pattern: different implementations per platform |
| R8 | Android code shrinker/obfuscator |
| ProGuard | Configuration rules for R8 |
| `--split-per-abi` | Flutter build flag to generate separate APKs per CPU architecture |
| `--obfuscate` | Flutter build flag to rename symbols (harder to reverse-engineer) |
| `--split-debug-info` | Flutter build flag to strip debug symbols from the APK |
