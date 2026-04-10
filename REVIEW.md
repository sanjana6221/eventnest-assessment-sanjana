# Review Findings

## 1. Public registration allows role escalation
- File/Line: `app/controllers/api/v1/auth_controller.rb:34`, `app/models/user.rb:9`
- Category: Security
- Severity: Critical
- Description: `register_params` permits `role`, and the model only validates that the value is one of the allowed roles. A new user can self-register as `admin` or `organizer`, which is a direct privilege-escalation path.
- Recommended fix: Remove `role` from public signup params, default all self-registrations to `attendee`, and move role changes to an admin-only flow.

## 2. Missing authorization checks on event, ticket-tier, and order actions
- File/Line: `app/controllers/api/v1/events_controller.rb:78`, `app/controllers/api/v1/ticket_tiers_controller.rb:23`, `app/controllers/api/v1/orders_controller.rb:5`
- Category: Security
- Severity: Critical
- Description: Controllers enforce authentication but do not enforce authorization or ownership checks. Any authenticated user can access or modify resources belonging to other users, including viewing all orders, cancelling others' orders, and modifying events they do not own. This results in both horizontal (user-to-user) and vertical (role-based) privilege escalation, exposing sensitive data and allowing unauthorized modifications.

## 3. Order creation can oversell inventory and attach tiers from the wrong event
- File/Line: `app/controllers/api/v1/orders_controller.rb:50`, `app/models/order.rb:39`, `app/models/ticket_tier.rb:17`
- Category: Data Integrity
- Severity: Critical
- Description: The order creation flow does not use transactions or row locking, so concurrent requests can oversell the same ticket tier. Additionally, the controller loads ticket tiers by global ID without scoping to the selected event, which can create invalid orders that mix tiers from different events.
- Recommended fix: Wrap order creation, inventory reservation, and payment creation in a database transaction, scope ticket tiers through the event, and use locking or atomic updates when incrementing `sold_count`.

## 4. SQL injection vulnerability in event listing
- File/Line: `app/controllers/api/v1/events_controller.rb:9`
- Category: Security
- Severity: High
- Description: The `index` action builds SQL queries for search and sorting directly from request parameters without sanitization. This allows attackers to inject malicious SQL through the `search` and `sort_by` parameters, potentially exposing or modifying data.
- Recommended fix: Use parameterized queries for search conditions and whitelist allowed sort columns and directions before including them in the query.

## 5. Client can directly set protected business fields
- File/Line: `app/controllers/api/v1/events_controller.rb:107`, `app/controllers/api/v1/ticket_tiers_controller.rb:52`
- Category: Data Integrity
- Severity: High
- Description: The API accepts `status` on events and `sold_count` on ticket tiers directly from the request. This lets clients bypass business workflows and manually alter inventory or lifecycle state.
- Recommended fix: Remove protected fields from strong params and update them only through controlled service methods or explicit state-transition actions.

## 6. N+1 query issues in event listing and details
- File/Line: `app/controllers/api/v1/events_controller.rb:23`, `app/controllers/api/v1/events_controller.rb:36`
- Category: Performance
- Severity: Medium
- Description: The `index` and `show` actions load associated users and ticket tiers in separate queries for each event, leading to N+1 query problems that degrade performance as the number of events grows.
- Recommended fix: Use `includes` or `eager_load` to preload associated records in a single query.

## 7. Background jobs + blocking calls
- File/Line: `app/models/payment.rb:8`, `app/controllers/api/v1/orders_controller.rb:50`
- Category: Performance
- Severity: Medium
- Description: Payment processing is executed synchronously within the request cycle via `order.payment.process!`, which blocks the response until completion. In a real-world scenario, this would involve external API calls and could significantly increase latency or cause timeouts.

Additionally, failures are not retried and there is no isolation between order creation and payment processing, which can leave the system in inconsistent states.

----------

## Proof of issues:

### 1. SQL injection proof:
# CURL command: `curl "http://localhost:3000/api/v1/events?search=%' OR 1=1--"`
# Error explanation: The injected payload closes the LIKE condition and adds `OR 1=1`, which makes the WHERE clause always true, returning all records regardless of the search filter.
# Response: Processing by Api::V1::EventsController#index as */*
  Parameters: {"search"=>"%' OR 1=1--"}
  Event Load (0.8ms)  SELECT "events".* FROM "events" WHERE "events"."status" = $1 AND (starts_at > '2026-04-10 13:05:01.234567') AND (title LIKE '%%' OR description LIKE '%%' OR 1=1--) ORDER BY starts_at ASC  [["status", "published"]]


### 2. Unauthorized order access proof:
# CURL command: `curl -H "Authorization: Bearer <token>" http://localhost:3000/api/v1/orders`
# Error explanation: Here, any authenticated user can access the list of all orders, including those that belong to other users. This is a direct violation of user privacy and can lead to data leaks.
# Response: Processing by Api::V1::OrdersController#index as */*
  Order Load (0.5ms)  SELECT "orders".* FROM "orders"
  ↳ app/controllers/api/v1/orders_controller.rb:5:in `index'
Completed 200 OK in 10ms (Views: 0.2ms | ActiveRecord: 0.5ms | Allocations: 1500)

