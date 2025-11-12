# FHIR LINE Bot - Deployment Guide

This guide covers deployment strategies for the FHIR LINE Bot application across different environments.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Local Development](#local-development)
4. [Docker Deployment](#docker-deployment)
5. [Kamal Deployment](#kamal-deployment)
6. [Production Checklist](#production-checklist)
7. [Monitoring and Maintenance](#monitoring-and-maintenance)

---

## Prerequisites

### System Requirements

- **Ruby**: 3.4.2 (see `.ruby-version`)
- **Rails**: 8.0.4
- **Node.js**: 18+ (for asset compilation)
- **PostgreSQL**: 12+
- **Docker**: 20+ (for containerized deployments)

### LINE Platform Setup

1. Create a LINE Developers account at https://developers.line.biz/
2. Create a new Channel with "Login" as the service type
3. Configure the OAuth flow with your application URL
4. Obtain your `Channel ID` and `Channel Secret`

### SSL Certificate (Production)

- For self-managed deployments, obtain an SSL certificate (Let's Encrypt recommended)
- For Kamal deployments with proxy enabled, SSL is auto-provisioned via Let's Encrypt

---

## Environment Setup

### 1. Copy Environment Configuration

```bash
cp .env.example .env
```

### 2. Edit Environment Variables

Edit `.env` with your actual values:

```bash
# LINE Login OAuth Configuration
LINE_LOGIN_CHANNEL_ID=your_actual_channel_id
LINE_LOGIN_CHANNEL_SECRET=your_actual_channel_secret
LINE_LOGIN_REDIRECT_URI=https://yourdomain.com/auth/line/callback

# Application URL
APP_URL=https://yourdomain.com

# Database (for production)
DATABASE_URL=postgres://user:password@db.example.com:5432/fhirlinebot_production

# Secret Key Base
SECRET_KEY_BASE=$(rails secret)
```

### 3. Generate Rails Master Key

For production deployments, Rails uses encrypted credentials:

```bash
# The master.key is already generated, keep it secure
# Store it in your deployment platform's secret management (e.g., GitHub Secrets, Kamal secrets)
cat config/master.key
```

### Important Security Notes

- **Never commit `.env` files** to git
- **Never commit `config/master.key`** to git
- Always use environment variables for sensitive data in production
- Store master key in your CI/CD platform's secret management system

---

## Local Development

### 1. Setup Database

```bash
# Create databases
rails db:create

# Run migrations
rails db:migrate

# (Optional) Seed with sample data
rails db:seed
```

### 2. Start Development Server

Using Procfile.dev with multiple processes:

```bash
bin/dev
```

This starts:
- Rails server (port 3000)
- Tailwind CSS watcher

Or manually:

```bash
rails s
```

### 3. Test Authentication Locally

1. Visit http://localhost:3000
2. Click "Login with LINE" button
3. You'll be redirected to LINE's OAuth consent screen
4. Complete the LINE login flow

---

## Docker Deployment

### Build Docker Image

```bash
docker build -t your-user/fhirlinebot:latest .
```

### Run Container Locally

```bash
docker run -d \
  -p 80:80 \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  -e DATABASE_URL=postgres://user:pass@host:5432/db \
  -e LINE_LOGIN_CHANNEL_ID=your_id \
  -e LINE_LOGIN_CHANNEL_SECRET=your_secret \
  --name fhirlinebot \
  your-user/fhirlinebot:latest
```

### Push to Docker Registry

```bash
# Login to Docker Hub
docker login

# Push image
docker push your-user/fhirlinebot:latest
```

### Key Files

- **Dockerfile**: Multi-stage build optimized for production
- **.dockerignore**: Excludes unnecessary files from Docker context
- **bin/docker-entrypoint**: Handles database setup on container start

### Docker Entrypoint Behavior

The `docker-entrypoint` script:
1. Enables jemalloc for memory efficiency
2. Prepares database if running Rails server
3. Executes the provided command

---

## Kamal Deployment

Kamal is Rails 8's first-class deployment solution. See `config/deploy.yml` for configuration.

### Prerequisites

```bash
# Install Kamal (if not already installed)
gem install kamal

# Install Docker on your server
```

### Configuration

Edit `config/deploy.yml`:

```yaml
service: fhirlinebot
image: your-registry/fhirlinebot

servers:
  web:
    - 192.168.0.1  # Your server IP

registry:
  username: your-registry-user
  password:
    - KAMAL_REGISTRY_PASSWORD  # Set via environment variable

env:
  secret:
    - RAILS_MASTER_KEY
    - LINE_LOGIN_CHANNEL_ID
    - LINE_LOGIN_CHANNEL_SECRET
  clear:
    RAILS_ENV: production
    SOLID_QUEUE_IN_PUMA: true

proxy:
  ssl: true
  host: app.yourdomain.com  # Your domain
```

### Setup and Deploy

```bash
# First-time setup (creates volumes, configures proxy)
kamal setup

# Deploy new version
kamal deploy

# View logs
kamal logs -f

# Run commands on server
kamal app exec --interactive "bin/rails console"

# SSH into server
kamal app exec --interactive "bash"
```

### Environment Variables

Store secrets in `.kamal/secrets`:

```bash
# Create secrets file
mkdir -p .kamal
echo "KAMAL_REGISTRY_PASSWORD=your_registry_token" > .kamal/secrets
echo "RAILS_MASTER_KEY=$(cat config/master.key)" >> .kamal/secrets
echo "LINE_LOGIN_CHANNEL_ID=your_channel_id" >> .kamal/secrets
echo "LINE_LOGIN_CHANNEL_SECRET=your_channel_secret" >> .kamal/secrets

# Protect the file
chmod 600 .kamal/secrets
```

### SSL via Let's Encrypt

With the proxy configuration enabled:
- SSL is automatically provisioned and renewed
- Your application is accessible over HTTPS
- Redirects HTTP to HTTPS automatically

---

## Production Checklist

### Security

- [ ] Generate strong `RAILS_MASTER_KEY` and store securely
- [ ] Set `RAILS_ENV=production`
- [ ] Enable HTTPS/SSL
- [ ] Configure CORS if needed
- [ ] Set secure cookie settings in `config/initializers/session_store.rb`
- [ ] Review and harden database user permissions
- [ ] Enable database encryption at rest
- [ ] Set up DDoS protection (Cloudflare, WAF, etc.)

### Performance

- [ ] Precompile assets: `rails assets:precompile`
- [ ] Configure `WEB_CONCURRENCY` based on server CPU cores
- [ ] Set `RAILS_MAX_THREADS` appropriately (default: 5)
- [ ] Enable caching headers on static assets
- [ ] Configure a CDN for static assets if needed
- [ ] Monitor database query performance
- [ ] Set up connection pooling for database

### Database

- [ ] Run migrations: `rails db:migrate RAILS_ENV=production`
- [ ] Create database backups before deployment
- [ ] Test backup restoration process
- [ ] Monitor database disk space
- [ ] Set up automated backups
- [ ] Configure write-ahead logging (WAL) for PostgreSQL

### Monitoring

- [ ] Set up logging (check logs via `kamal logs`)
- [ ] Configure error tracking (e.g., Sentry)
- [ ] Set up health checks (`/up` endpoint)
- [ ] Monitor server CPU, memory, disk usage
- [ ] Set up alerts for critical issues
- [ ] Monitor LINE OAuth connectivity

### LINE Integration

- [ ] Verify `LINE_LOGIN_REDIRECT_URI` matches production URL exactly
- [ ] Test LINE login flow end-to-end
- [ ] Verify token refresh behavior
- [ ] Monitor OAuth token expiration handling
- [ ] Set up fallback authentication if needed

### CI/CD

- [ ] GitHub Actions CI pipeline is configured (`.github/workflows/ci.yml`)
- [ ] Tests run on all pull requests
- [ ] Security scanning enabled (Brakeman, bundler-audit)
- [ ] Code linting enforced (Rubocop)
- [ ] Add deployment step to CI/CD pipeline

Example GitHub Actions deployment step:

```yaml
deploy:
  needs: test
  runs-on: ubuntu-latest
  if: github.ref == 'refs/heads/main'
  steps:
    - uses: actions/checkout@v4
    - name: Deploy with Kamal
      run: kamal deploy
      env:
        KAMAL_REGISTRY_PASSWORD: ${{ secrets.KAMAL_REGISTRY_PASSWORD }}
        RAILS_MASTER_KEY: ${{ secrets.RAILS_MASTER_KEY }}
```

---

## Monitoring and Maintenance

### Health Check

```bash
# Check application health
curl https://yourdomain.com/up
```

Should return a 200 status code.

### View Logs

```bash
# Real-time logs
kamal logs -f

# Specific time range
kamal logs --since "1 hour ago"

# Follow specific component
kamal logs -f -r web
```

### Database Maintenance

```bash
# Analyze query plans
rails db:statistics

# Vacuum PostgreSQL tables
kamal app exec "psql -d $DATABASE_URL -c 'VACUUM ANALYZE'"

# Create backup
kamal app exec "pg_dump -d $DATABASE_URL" > backup.sql
```

### Updates and Patching

```bash
# Update dependencies
bundle update

# Test updates locally
bundle exec rake test

# Deploy
kamal deploy
```

### Scaling

For multiple application servers, update `config/deploy.yml`:

```yaml
servers:
  web:
    - 192.168.0.1
    - 192.168.0.2
    - 192.168.0.3
  job:
    - 192.168.0.4
```

---

## Troubleshooting

### Database Connection Issues

```bash
# Check database connectivity
kamal app exec "rails dbconsole"

# Verify environment variables
kamal app exec "printenv | grep DATABASE"
```

### LINE OAuth Failures

1. Verify `LINE_LOGIN_REDIRECT_URI` matches exactly
2. Check `LINE_LOGIN_CHANNEL_ID` and `LINE_LOGIN_CHANNEL_SECRET` are correct
3. Ensure LINE channel is configured for "Login" service
4. Check network connectivity to LINE's OAuth endpoints

### Asset Loading Issues

```bash
# Precompile assets
kamal app exec "bin/rails assets:precompile"

# Clear asset cache
kamal app exec "bin/rails assets:clobber"
```

### Memory Issues

Adjust `WEB_CONCURRENCY` or `RAILS_MAX_THREADS`:

```bash
# In .env or deploy.yml
WEB_CONCURRENCY=1          # Reduce if memory is limited
RAILS_MAX_THREADS=3        # Reduce thread pool size
```

---

## Reference

- [Rails Deployment Guide](https://guides.rubyonrails.org/deployment.html)
- [Kamal Documentation](https://kamal-deployment.org/)
- [Docker Documentation](https://docs.docker.com/)
- [PostgreSQL Manual](https://www.postgresql.org/docs/current/)
- [LINE Login Documentation](https://developers.line.biz/en/services/line-login/)
- [Rails 8 Security Guide](https://guides.rubyonrails.org/security.html)
