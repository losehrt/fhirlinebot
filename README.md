# FHIR LINE Bot

A healthcare communication platform MVP built with Rails 8, integrating FHIR standards and LINE Login OAuth for secure patient-provider communication.

**一個基於 Rails 框架開發的 Smart on FHIR 應用 MVP，透過 LINE 登入提供安全的醫療溝通平台。**

## Project Overview

FHIR LINE Bot is a healthcare communication platform that bridges patients and healthcare institutions through LINE's familiar interface. It implements FHIR standards for healthcare data interoperability while leveraging LINE's OAuth authentication for secure, convenient access.

## Key Features

- **Smart on FHIR Integration**: Implements FHIR standards for healthcare data interoperability
- **LINE Login OAuth**: Secure authentication via LINE platform
- **Healthcare Communication Platform**: Real-time communication between patients and hospitals
- **Secure Data Management**: Encrypted storage and transmission of medical information
- **Responsive Web UI**: Modern, mobile-friendly interface with Tailwind CSS

## Tech Stack

| Component | Version |
|-----------|---------|
| Ruby      | 3.4.2   |
| Rails     | 8.0.4   |
| PostgreSQL| 12+     |
| Node.js   | 18+     |
| Tailwind CSS | Latest |
| Hotwire (Turbo + Stimulus) | Built-in |

## Quick Start

### Prerequisites

- Ruby 3.4.2
- PostgreSQL 12+
- Node.js 18+
- Docker & Docker Compose (optional)

### Setup Options

#### Option 1: Native Development

```bash
# 1. Clone the repository
git clone <repository-url>
cd fhirlinebot

# 2. Install dependencies
bundle install
npm install

# 3. Setup database
rails db:create db:migrate

# 4. Configure environment variables
cp .env.example .env
# Edit .env with your LINE OAuth credentials

# 5. Start development server
bin/dev
```

Visit http://localhost:3000

#### Option 2: Docker Compose

```bash
# 1. Clone the repository
git clone <repository-url>
cd fhirlinebot

# 2. Setup environment
cp .env.example .env
# Edit .env with your LINE OAuth credentials

# 3. Start with Docker Compose
docker-compose up

# 4. In another terminal, setup database
docker-compose exec rails rails db:create db:migrate
```

Visit http://localhost:3000

## Configuration

### Environment Variables

See `.env.example` for all configuration options. Key variables:

```bash
# LINE Login OAuth
LINE_LOGIN_CHANNEL_ID=your_channel_id
LINE_LOGIN_CHANNEL_SECRET=your_channel_secret
LINE_LOGIN_REDIRECT_URI=http://localhost:3000/auth/line/callback

# Database
DATABASE_URL=postgres://user:password@localhost:5432/fhirlinebot_development

# Rails
SECRET_KEY_BASE=your-secret-key-base
RAILS_ENV=development
```

### LINE Platform Setup

1. Go to [LINE Developers Console](https://developers.line.biz/)
2. Create a new Channel with "Login" service
3. Configure OAuth redirect URI
4. Copy Channel ID and Channel Secret to `.env`

## Development

### Running Tests

```bash
# Run all tests (unit, integration, system)
rails test test:system

# Run specific test file
rails test test/models/user_test.rb

# Run with coverage
bundle exec simplecov

# Run security checks
bin/brakeman
bin/rubocop
```

### Database Commands

```bash
# Create databases
rails db:create

# Run migrations
rails db:migrate

# Rollback last migration
rails db:rollback

# Reset database (development only)
rails db:reset

# Seed sample data
rails db:seed
```

### Code Quality

```bash
# Run linter
bin/rubocop -a  # with auto-fix

# Security scan
bin/brakeman

# JS dependencies audit
bin/importmap audit

# Run full CI suite locally
.github/workflows/ci.yml
```

## Project Structure

```
fhirlinebot/
├── app/
│   ├── controllers/          # Rails controllers
│   │   ├── auth_controller.rb       # LINE OAuth handling
│   │   └── pages_controller.rb      # Page routes
│   ├── models/               # ActiveRecord models
│   │   ├── user.rb                  # User model
│   │   └── line_account.rb          # LINE account integration
│   ├── views/                # ERB templates
│   │   ├── layouts/application.html.erb    # Main layout
│   │   └── pages/                          # Page templates
│   └── assets/               # CSS, JS, images
├── config/
│   ├── deploy.yml            # Kamal deployment config
│   ├── database.yml          # Database configuration
│   └── routes.rb             # Route definitions
├── db/
│   ├── migrate/              # Database migrations
│   └── seeds.rb              # Sample data
├── test/                     # Test suite
├── Dockerfile                # Production Docker image
├── docker-compose.yml        # Development Docker setup
├── Gemfile                   # Ruby dependencies
└── DEPLOYMENT.md             # Deployment guide
```

## Authentication Flow

```
User visits app
    ↓
Clicks "Login with LINE"
    ↓
Redirected to LINE OAuth consent screen
    ↓
User authorizes app
    ↓
LINE redirects to /auth/line/callback with code
    ↓
App exchanges code for access token
    ↓
App creates/updates user with LINE info
    ↓
User is logged in and redirected to dashboard
```

## API Endpoints

### Authentication
- `POST /auth/request_login` - Request LINE login authorization URL
- `GET /auth/line/callback` - LINE OAuth callback handler
- `POST /auth/logout` - Logout current user

### Pages
- `GET /` - Home page (public/dashboard)
- `GET /dashboard` - Dashboard (logged-in users only)
- `GET /profile` - User profile page (logged-in users only)

### Health
- `GET /up` - Health check endpoint (returns 200 if healthy)

## Deployment

### Quick Deploy (Kamal)

```bash
# Setup (first time)
kamal setup

# Deploy
kamal deploy

# View logs
kamal logs -f

# SSH to server
kamal app exec --interactive "bash"
```

### Complete Guide

See [DEPLOYMENT.md](./DEPLOYMENT.md) for comprehensive deployment instructions covering:
- Docker containerization
- Kamal deployment
- Production checklist
- SSL/HTTPS setup
- Monitoring and maintenance
- Troubleshooting

### Supported Deployment Targets
- Self-managed VPS (Ubuntu, Debian)
- Kamal + Hetzner
- Docker + any cloud provider
- Heroku (with Procfile modifications)

## Testing

### Test Coverage
- Unit tests for models
- Integration tests for authentication flow
- System tests for user workflows
- Security scanning (Brakeman, Rubocop)

### Run Tests Locally

```bash
# All tests
rails test

# System tests (requires Chrome)
rails test:system

# Specific test
rails test test/controllers/auth_controller_test.rb
```

## Security

- **CSRF Protection**: All forms protected with CSRF tokens
- **Secure Sessions**: HttpOnly, Secure, SameSite cookies
- **Password Hashing**: bcrypt with salt
- **OAuth2 Security**: State parameter validation
- **Database Encryption**: Support for encrypted columns
- **SQL Injection Prevention**: Parameterized queries via ActiveRecord
- **HTTPS**: Enforced in production

### Security Scanning

```bash
# Run security checks
bin/brakeman          # Rails security
bin/rubocop -a        # Code quality
bundle audit          # Dependency vulnerabilities
bin/importmap audit   # JavaScript dependencies
```

## Contributing

1. Create a feature branch (`git checkout -b feature/amazing-feature`)
2. Commit your changes (`git commit -m 'Add amazing feature'`)
3. Push to the branch (`git push origin feature/amazing-feature`)
4. Open a Pull Request
5. Ensure all tests pass in CI

## CI/CD Pipeline

GitHub Actions automatically runs on every push and PR:
- **Security Scanning**: Brakeman, bundler-audit
- **Code Linting**: Rubocop
- **Tests**: Unit, integration, and system tests
- **Database**: PostgreSQL service available during tests

## License

[Specify your license here]

## Support

For issues, questions, or contributions:
- GitHub Issues: [Project Issues]
- Documentation: See [DEPLOYMENT.md](./DEPLOYMENT.md) for deployment help
- Security Issues: Please report privately to [security contact]

## Acknowledgments

- Rails community and documentation
- LINE Platform for OAuth services
- FHIR standards community
- Contributors and testers
