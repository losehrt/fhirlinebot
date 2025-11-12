# FHIR LINE Bot - Local Setup Guide

This guide helps you set up the FHIR LINE Bot application locally for development.

## Prerequisites

- Ruby 3.4.2
- PostgreSQL 12+
- Node.js 18+
- Git

## Step 1: Clone and Install Dependencies

```bash
# Clone the repository
git clone <repository-url>
cd fhirlinebot

# Install Ruby gems
bundle install

# Install Node.js packages
npm install
```

## Step 2: Setup Environment Variables

### Copy the Example File

```bash
cp .env.example .env
```

### Configure LINE OAuth Credentials

1. Go to [LINE Developers Console](https://developers.line.biz/)
2. Create a new account or log in
3. Create a new Channel:
   - Choose "Login" as the service type
   - Fill in basic information
4. After creation, you'll see:
   - **Channel ID** (client ID)
   - **Channel Secret** (client secret)

### Update .env File

Edit `.env` and update these values:

```bash
# Line 7-9: Replace with your actual LINE credentials
LINE_LOGIN_CHANNEL_ID=your_channel_id_here
LINE_LOGIN_CHANNEL_SECRET=your_channel_secret_here
LINE_LOGIN_REDIRECT_URI=http://localhost:3000/auth/line/callback
```

Keep the redirect URI as `http://localhost:3000/auth/line/callback` for local development.

### Other Important Variables

```bash
# Database (should work as-is for local PostgreSQL)
DATABASE_URL=postgres://postgres:postgres@localhost:5432/fhirlinebot_development

# Rails environment
RAILS_ENV=development
```

## Step 3: Setup Database

```bash
# Create databases
rails db:create

# Run migrations
rails db:migrate

# Optional: Seed sample data
rails db:seed
```

## Step 4: Start the Application

```bash
bin/dev
```

This script will:
1. ✓ Load environment variables from .env
2. ✓ Start Rails server (port 3000)
3. ✓ Watch Tailwind CSS for changes
4. ✓ Display the startup confirmation

You should see:
```
✓ Loaded environment variables from .env
```

## Step 5: Access the Application

Open your browser and navigate to:

```
http://localhost:3000
```

You should see:
- ✅ Home page loads without errors
- ✅ Blue "Login with LINE" button appears
- ✅ No "Failed to load login button" error

## Troubleshooting

### "Failed to load login button" Error

**Cause**: LINE credentials not configured

**Solution**:
```bash
# Check if .env exists
ls -la .env

# Check if environment variables are set
cat .env | grep LINE_LOGIN_CHANNEL

# If .env is missing, create it:
cp .env.example .env
vim .env  # Add your real credentials
```

Then restart the app:
```bash
# Stop the current process (Ctrl+C)
# Start again
bin/dev
```

### Database Connection Error

**Error**: `could not connect to server: Connection refused`

**Solution**: Ensure PostgreSQL is running

```bash
# macOS with Homebrew
brew services start postgresql

# Linux
sudo service postgresql start

# Then create databases
rails db:create db:migrate
```

### Port 3000 Already in Use

**Solution**: Use a different port

```bash
PORT=3001 bin/dev
```

Then visit: `http://localhost:3001`

### Gem Install Errors

**Solution**: Update bundler and reinstall

```bash
gem install bundler
bundle install
```

## Running Tests

```bash
# Run all tests
rails test

# Run system tests (requires Chrome)
rails test:system

# Run security checks
bin/brakeman
bin/rubocop
```

## Common Commands

```bash
# Start development server
bin/dev

# Open Rails console (interactive)
rails console

# Database operations
rails db:migrate
rails db:rollback
rails db:reset
rails db:seed

# Run tests
rails test
rails test:system

# Code quality
bin/brakeman      # Security scan
bin/rubocop       # Code style

# Generate new model
rails generate model User name:string

# Create migration
rails generate migration CreateUsers
```

## LINE Login Testing

### Test Login Flow Locally

1. Ensure .env has correct LINE credentials
2. Visit http://localhost:3000 (not logged in)
3. Click "Login with LINE"
4. You'll be redirected to LINE OAuth consent screen
5. Authorize the application
6. You'll be logged in and redirected to dashboard

### Production LINE Channel

When deploying to production:
1. Create a new LINE Channel for production
2. Update LINE channel settings:
   - Callback URL: `https://yourdomain.com/auth/line/callback`
   - Enable features as needed
3. Update production .env with new credentials

## Next Steps

After successful setup:
1. Explore the codebase structure (see README.md)
2. Check out the test suite (test/ directory)
3. Read DEPLOYMENT.md for production setup
4. Review PROJECT_COMPLETION_SUMMARY.md for architecture overview

## Getting Help

- Check DEPLOYMENT.md for deployment instructions
- See README.md for project overview
- Review test files for usage examples
- Check GitHub Issues for known problems

## Quick Reference

| Task | Command |
|------|---------|
| Start dev server | `bin/dev` |
| Run tests | `rails test` |
| Database setup | `rails db:create db:migrate` |
| Rails console | `rails console` |
| Check environment | `grep LINE_ .env` |
| Stop server | `Ctrl + C` |
| View logs | Check console output |

---

**All set!** Your FHIR LINE Bot should now be running locally. 🎉
