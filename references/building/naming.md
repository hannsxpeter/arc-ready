# Naming Conventions

Inconsistent naming is how a dashboard ends up with `getUserData`, `fetchUserInfo`, and `loadUserDetails` all doing the same thing. Pick a convention per layer and enforce it everywhere.

**The single most important naming rule:** the same concept has the same name in every layer. If the sidebar says "Customers," the page title says "Customers," the breadcrumb says "Customers," the API endpoint is `/api/customers`, the database table is `customers`, the query key is `['customers']`, the event is `customer.created`, and the permission is `customers:read`. One word, everywhere.

---

## Code naming

| Layer | Convention | Examples |
|---|---|---|
| **Files and directories** | `kebab-case`, colocated by feature | `orders/OrderList.tsx`, `orders/OrderList.test.tsx`, `orders/use-orders.ts` |
| **Type/schema files** | Suffix with role when not obvious | `order.types.ts`, `order.schema.ts`, `order.constants.ts`, `order.seed.ts` |
| **Components** | `PascalCase`, noun-based | `UserTable`, `OrderDetail`, `CreateCustomerForm` |
| **Functions / hooks** | `camelCase`, verb-first | `createUser`, `updateOrder`, `useUsers`, `useOrderById` |
| **Service functions** | `camelCase`, verb plus entity | `updateUserRole`, `deleteProject`, `inviteMember` |
| **Booleans** | `is/has/can/should` prefix (reads as a question) | `isActive`, `hasPermission`, `canEdit`, `shouldRetry` |
| **Database tables** | `snake_case`, plural | `users`, `orders`, `audit_logs`, `order_items` |
| **Database columns** | `snake_case`, FK as `{singular}_id` | `created_at`, `user_id`, `is_active`, `total_amount` |
| **Junction tables** | Domain name if it has extra columns, alphabetical if pure join | `team_memberships` (has `role`), `roles_users` (pure IDs) |
| **Indexes** | `{table}_{columns}_{type}` | `orders_customer_id_idx`, `users_email_key`, `orders_pkey` |
| **Migrations** | Timestamp plus imperative verb | `20260411_add_status_to_orders.ts`, `20260412_create_audit_logs.ts` |
| **Enum values (DB)** | `snake_case` lowercase | `active`, `pending_review`, `archived` (not `ACTIVE`) |
| **API endpoints** | Plural nouns, max 1 level nesting | `/api/users/:id/orders` (fine), `/api/users/:id/orders/:oid/items` (promote to `/api/order-items/:id`) |
| **API action endpoints** | Sub-resource verb for non-CRUD | `POST /orders/:id/refund`, `POST /users/:id/invite` |
| **API query params** | Match your JSON response casing | `?sortBy=createdAt` (if JSON is camelCase), `?sort_by=created_at` (if snake_case) |
| **API error codes** | `snake_case` lowercase | `card_declined`, `rate_limit_exceeded`, `validation_error` |
| **Environment variables** | `SCREAMING_SNAKE_CASE` | `DATABASE_URL`, `STRIPE_SECRET_KEY`, `NEXT_PUBLIC_API_URL` |
| **Events** | `entity.verb_past_tense` | `user.created`, `order.fulfilled`, `billing.payment_failed` |
| **Permissions** | `resource:action` | `users:read`, `users:delete`, `billing:edit`, `audit_log:read` |
| **Query keys** | Array starting with entity name | `['users']`, `['users', id]`, `['users', 'list', filters]` |
| **CSS / design tokens** | Semantic names, not literal | `--color-primary` (not `--color-blue-500`), `--button-primary-bg` |
| **Feature flags** | `kebab-case` | `ai-ticket-routing`, `new-billing-page`, `dark-mode-v2` |
| **TypeScript types** | `PascalCase`, no `I` prefix | `User`, `OrderStatus`, `CreateUserInput` (not `IUser`) |
| **Zod schemas** | `camelCase` plus `Schema` suffix, derive type | `userSchema`, then `type User = z.infer<typeof userSchema>` |
| **Enums** | `PascalCase` name, `PascalCase` members | `enum OrderStatus { Pending, Shipped, Delivered }` |
| **i18n keys** | Dot-separated, by feature plus component | `checkout.paymentForm.submitButton`, `orders.emptyState.title` |
| **Test files** | Colocated, `.test.ts` (or `.spec.ts`, pick one) | `OrderList.test.tsx` next to `OrderList.tsx` |
| **Test IDs** | `data-testid`, kebab-case | `data-testid="order-list-search-input"` |
| **Git branches** | `{type}/{ticket}-{description}` | `feature/PROJ-123-add-order-filters`, `fix/PROJ-456-login-redirect` |
| **Commits** | Conventional commits | `feat(orders): add bulk export to CSV`, `fix(auth): handle expired sessions` |
| **Tags** | Semver with `v` prefix | `v1.0.0`, `v1.2.3-beta.1` |

---

## Navigation and UI naming

| Element | Convention | Right | Wrong |
|---|---|---|---|
| **Top-level nav labels** | Plural nouns for collections, singular for singletons | "Customers", "Orders", "Settings" | "Manage Customers", "Order List" |
| **Nav casing** | Pick sentence case or title case, never mix | "Audit log" everywhere | "Audit log" here, "Audit Log" there |
| **Sub-nav items** | More specific nouns | "All customers", "Segments" | "Customer list", "Customer segments" |
| **Page titles** | Match the nav label exactly | Sidebar: "Orders", then page: "Orders" | Sidebar: "Orders", then page: "Order Management" |
| **Breadcrumbs** | Match nav labels, not internal names | "Customers / Acme Corp" | "customer-list / cust_123" |
| **URL slugs** | `kebab-case`, plural for collections | `/customers`, `/customers/:id` | `/customerList`, `/customer/view/:id` |
| **Action buttons** | Verb plus noun | "Create Customer", "Export Report" | "New", "Submit", "Go" |
| **Status labels** | One vocabulary, used everywhere | "Active / Inactive" everywhere | "Active" here, "Enabled" there |
| **Empty/loading text** | Specific noun, not generic | "No customers yet" | "No data", "No results" |
| **Error messages** | What happened plus what to do | "Email already exists. Try signing in." | "Error", "Invalid input" |
| **Toast messages** | Past tense confirmation | "Customer created" | "Success!" |
| **Confirmation dialogs** | Verb plus specific noun as title | "Delete 3 customers?" | "Are you sure?", "Confirm" |
| **Settings sections** | Domain grouping, not alphabetical | General, Security, Billing | API, Billing, General |
| **Mobile nav labels** | Same words as desktop, drop to icon-only at narrow widths | Icon-only at 375px | Different words on mobile vs desktop |

---

## Casing boundary rule

Database is `snake_case`. API contract is either `camelCase` (JS-native) or `snake_case` (Stripe-style). Pick one. Transform at the serialization boundary (one place, not ad-hoc). The client receives the API casing and uses it as-is. Never transform casing inside business logic.

---

## Naming anti-patterns

Avoid these. They cause confusion in every dashboard codebase:

- **`IUser`.** Don't prefix interfaces with `I`. Use `User` for both interfaces and types.
- **Abbreviations.** `usr`, `btn`, `msg`, `tbl`, `val`, `cnt`, `tmp`. Use full words. Only `id`, `url`, `api` are universally understood.
- **Context-free names.** `data`, `info`, `item`, `value`, `result`, `payload`. What data? What item? Be specific: `activeUsers`, `orderTotal`.
- **God-suffix names.** `UserManager`, `OrderHandler`, `DataProcessor`, `ApiUtils`. These indicate too many responsibilities. Break into smaller named concepts.
- **Inconsistent collection naming.** `getUserList` vs `getOrders` vs `fetchAllProducts`. Pick one pattern.
- **Negated booleans.** `isNotActive`, `isDisabled`. Creates double-negative confusion (`if (!isNotActive)`). Use the positive form: `isActive`, `isEnabled`.
- **Redundant context.** Inside `OrderService`, use `create()` not `createOrder()`. Inside a `User` class, `getName()` not `getUserName()`.
