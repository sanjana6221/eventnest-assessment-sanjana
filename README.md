# EventNest — Event Ticketing Platform API

A Rails 7 API-only application for managing events, ticket sales, and orders.

## Quick Setup (Docker — Recommended)

```bash
# Clone and enter the repo
git clone <repo-url> && cd eventnest

# Start the app and database
docker-compose up --build

# In a separate terminal, set up the database
docker-compose exec web rails db:create db:migrate db:seed

# Run the test suite
docker-compose exec web bundle exec rspec

# The API is now running at http://localhost:3000
```

## Manual Setup (without Docker)

Requires: Ruby 3.2+, PostgreSQL 15+, Bundler

```bash
# Run the setup script (installs deps, sets up DB, configures git hooks)
chmod +x bin/setup
./bin/setup

# Or do it manually:
bundle install
git config core.hooksPath .git-hooks
rails db:create db:migrate db:seed
bundle exec rspec
rails server
```

## Authentication

Register or login to get a JWT token:

```bash
# Login as an attendee
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ananya@example.com","password":"password123"}'

# Use the returned token
curl -H "Authorization: Bearer <token>" http://localhost:3000/api/v1/events
```

## API Endpoints

### Auth
- `POST /api/v1/auth/register` — Create account
- `POST /api/v1/auth/login` — Sign in, get JWT

### Events
- `GET /api/v1/events` — List published upcoming events (public)
- `GET /api/v1/events/:id` — Event details (public)
- `POST /api/v1/events` — Create event (authenticated)
- `PUT /api/v1/events/:id` — Update event (authenticated)
- `DELETE /api/v1/events/:id` — Delete event (authenticated)

### Ticket Tiers
- `GET /api/v1/events/:event_id/ticket_tiers` — List tiers (public)
- `POST /api/v1/events/:event_id/ticket_tiers` — Create tier (authenticated)
- `PUT /api/v1/events/:event_id/ticket_tiers/:id` — Update tier (authenticated)
- `DELETE /api/v1/events/:event_id/ticket_tiers/:id` — Delete tier (authenticated)

### Orders
- `GET /api/v1/orders` — List orders (authenticated)
- `GET /api/v1/orders/:id` — Order details (authenticated)
- `POST /api/v1/orders` — Create order (authenticated)
- `POST /api/v1/orders/:id/cancel` — Cancel order (authenticated)

### Bookmarks
- `GET /api/v1/bookmarks` — List bookmarked events (authenticated)
- `POST /api/v1/events/:event_id/bookmark` — Bookmark event (authenticated)
- `DELETE /api/v1/events/:event_id/bookmark` — Remove bookmark (authenticated)

### Issue fix proofing
- This fix eliminates a critical privilege escalation vulnerability by enforcing server-side role assignment and preventing user-controlled access level manipulation.
#### Before:
  curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test",
    "email": "test111@example.com",
    "password": "password124",
    "password_confirmation": "password124",
    "role": "admin"
  }'
#### Response:
{
  "user": {
    "role": "admin"
  }
}

#### After:
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test",
    "email": "test222@example.com",
    "password": "password124",
    "password_confirmation": "password124",
    "role": "admin"
  }'
#### Response:
{
  "user": {
    "role": "attendee"
  }
}


### Bookmarking an event:
curl -X POST http://localhost:3000/api/v1/events/1/bookmark \
  -H "Authorization: Bearer <token>"
{"message":"Bookmarked successfully"}


curl -X POST http://localhost:3000/api/v1/events/1/bookmark   -H "Authorization: Bearer <same_user_token>"
{"error":"Already bookmarked"}

