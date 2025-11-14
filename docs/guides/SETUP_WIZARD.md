# Smart LINE OAuth Setup Wizard

## Overview

The FHIR LINE Bot now includes an intelligent setup wizard that automatically guides healthcare institutions through configuring LINE OAuth credentials when first launching the application.

**No more manual configuration! No more missing environment variables!**

## Key Benefits

### For Healthcare IT Teams
- ✅ **Zero Pre-Configuration**: Deploy the app without setting up credentials
- ✅ **Self-Guided Setup**: Users can configure credentials directly in the app
- ✅ **Visual Feedback**: Real-time validation and error messages
- ✅ **Secure Storage**: Credentials encrypted in database, never in code

### For Smart on FHIR Applications
- ✅ **Easy Deployment**: Works with Docker, Kubernetes, traditional servers
- ✅ **Multi-Organization Support**: Each instance has its own settings
- ✅ **Flexible Updates**: Change credentials without redeploying
- ✅ **Audit Trail**: Track when credentials were last validated

## User Experience Flow

### First Time Installation

```
User visits http://localhost:3000
        ↓
Application checks for configured credentials
        ↓
None found → Redirect to /setup
        ↓
Setup Wizard displays with:
  • Step-by-step instructions
  • Link to LINE Developers Console
  • Form to enter Channel ID & Secret
        ↓
User enters credentials
        ↓
Click "Validate Credentials" button
        ↓
Real-time validation against LINE API:
  ✓ Format validation
  ✓ Credential testing
  ✓ Connectivity check
        ↓
Success → Click "Save & Continue"
        ↓
Credentials encrypted and saved to database
        ↓
Redirected to home page
        ↓
App is ready to use! 🎉
```

### Subsequent Visits

```
User visits http://localhost:3000
        ↓
Application checks for configured credentials
        ↓
Credentials found in database
        ↓
Normal application flow
```

## Technical Architecture

### Database Model

```ruby
ApplicationSetting
  ├── line_channel_id: string
  ├── line_channel_secret: string (encrypted)
  ├── configured: boolean
  ├── last_validated_at: datetime
  ├── validation_error: text
  └── timestamps
```

### Controllers

**SetupController** (`app/controllers/setup_controller.rb`)

- `index` - Display setup wizard
- `validate_credentials` - Real-time AJAX validation
- `update` - Save credentials after validation
- `test` - Test existing credentials
- `clear` - Reset configuration

### Services

**LineValidator** (`lib/line_validator.rb`)

- Validates credential format
- Tests API connectivity
- Returns detailed error messages

### Views

**Setup Wizard** (`app/views/setup/index.html.erb`)

- Responsive design (desktop & mobile)
- Step-by-step instructions
- Live validation feedback
- CSRF protection

## Configuration Steps for Users

### 1. Get LINE Credentials

1. Go to [LINE Developers Console](https://developers.line.biz/)
2. Create a new account or log in
3. Create a new Channel:
   - Select "Login" as service type
   - Fill in basic information
4. After creation, find:
   - **Channel ID** (in Basic Settings)
   - **Channel Secret** (in Basic Settings)

### 2. Configure in Application

1. Start the application
2. Visit `http://localhost:3000` (or your domain)
3. You'll be redirected to `/setup`
4. Enter your:
   - Channel ID
   - Channel Secret
5. Click "Validate Credentials"
6. Click "Save & Continue"

### 3. Done!

The application is now configured and ready to use.

## Security Features

### Encryption
- Channel Secret is encrypted at rest in database
- Uses Rails encrypted attributes
- Never displayed after saving
- Immune to SQL injection

### Validation
- Both fields required for saving
- Format validation (minimum length checks)
- API connectivity test
- Detailed error messages

### Protection
- CSRF tokens on all forms
- Secure headers on AJAX requests
- Safe exception handling
- No credentials in logs

### Audit Trail
- `last_validated_at` tracks validation history
- `validation_error` logs why validation failed
- timestamps track when settings changed

## API Endpoints

### Setup Routes

```
GET  /setup                    # Show setup wizard
POST /setup/validate           # Validate credentials (AJAX)
POST /setup/update             # Save credentials
POST /setup/test               # Test existing credentials
DELETE /setup/clear            # Clear configuration
```

### Hidden from Setup Check

These routes work even without credentials configured:
- GET `/` (redirects to setup or home based on config)
- POST `/auth/request_login` (LINE OAuth initiation)
- GET `/auth/line/callback` (LINE OAuth callback)
- GET `/up` (health check)

## Integration with Existing Features

### ApplicationController

The setup check is implemented in `ApplicationController` as a `before_action`:

```ruby
before_action :require_setup_completion, unless: :skip_setup_check?
```

Routes that skip the check:
- Setup controller routes
- Auth controller routes
- Health check endpoint

### Environment Variables

The application no longer requires pre-configured environment variables for LINE credentials:

- ✗ `LINE_LOGIN_CHANNEL_ID` (env variable) - No longer required
- ✗ `LINE_LOGIN_CHANNEL_SECRET` (env variable) - No longer required
- ✓ Credentials stored in database instead

Other variables still supported:
- `DATABASE_URL` - Database connection
- `RAILS_ENV` - Environment (development/production)
- `SECRET_KEY_BASE` - Rails encryption key

## Deployment Scenarios

### Docker Deployment

```bash
# Build image (no credentials needed!)
docker build -t fhir-line-bot .

# Run container
docker run -p 3000:3000 fhir-line-bot

# Visit http://localhost:3000
# Follow setup wizard
# Done!
```

### Traditional VPS

```bash
# Clone and setup
git clone <repo>
cd fhirlinebot
bundle install
rails db:create db:migrate

# Start server
rails server

# Visit http://yourdomain.com
# Follow setup wizard
# Done!
```

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fhir-line-bot
spec:
  template:
    spec:
      containers:
      - name: app
        image: your-registry/fhir-line-bot:latest
        ports:
        - containerPort: 3000
        # No LINE credentials needed in env!
```

## Testing the Setup Wizard

### Integration Tests

Test files created:
- `spec/models/application_setting_spec.rb`
- `spec/factories/application_settings.rb`

### Manual Testing

```bash
# 1. Start the app
bin/dev

# 2. Visit setup page
curl http://localhost:3000/setup

# 3. Validate credentials
curl -X POST http://localhost:3000/setup/validate \
  -H "Content-Type: application/json" \
  -d '{"line_channel_id":"YOUR_ID","line_channel_secret":"YOUR_SECRET"}'

# 4. Check database
rails console
ApplicationSetting.first.attributes
```

## Troubleshooting

### Setup Wizard Not Appearing

**Problem**: When visiting `/`, you see home page instead of setup wizard

**Solution**:
- Database migration might not have run
- Run: `rails db:migrate`
- Restart the app

### Validation Failing

**Problem**: Credentials are rejected during validation

**Solutions**:
1. Check credentials are correct
   - Copy from LINE Developers Console exactly
   - No extra spaces or quotes
2. Check LINE API connectivity
   - Ping `https://api.line.me` from server
   - Check firewall/VPN settings
3. Check credential format
   - Channel ID should be numeric
   - Secret should be 20+ characters

### Can't Access Setup After Initial Config

**Problem**: Want to reconfigure but no way to access setup page

**Solution**: Use "Test Connection" to verify, then "Reconfigure" button

If needed, clear configuration:
```bash
rails console
ApplicationSetting.first.clear_configuration!
```

Then visit `/setup` again.

## Advanced Configuration

### Programmatic Configuration

```ruby
# In Rails console or migrations
setting = ApplicationSetting.current
setting.update(
  line_channel_id: ENV['LINE_CHANNEL_ID'],
  line_channel_secret: ENV['LINE_CHANNEL_SECRET']
)
setting.validate_line_credentials!
```

### Custom Validation

Extend `LineValidator` for additional checks:

```ruby
# lib/line_validator.rb
class LineValidator
  # Add custom validation logic
end
```

### Multiple Environments

For multi-tenant setup, consider extending ApplicationSetting:

```ruby
# Future enhancement for multiple organizations
class ApplicationSetting
  belongs_to :organization, optional: true
  # Support different credentials per organization
end
```

## Future Enhancements

Possible improvements:
1. **Multi-Tenant Support**: Different credentials per organization
2. **Credential Rotation**: Automatic expiration and renewal
3. **Admin Dashboard**: Manage credentials through web UI
4. **Audit Logging**: Track all credential changes
5. **SCIM Integration**: Auto-populate users from directory
6. **Custom Scopes**: Configure LINE Login scopes via wizard

## Related Files

- **Model**: `app/models/application_setting.rb`
- **Controller**: `app/controllers/setup_controller.rb`
- **View**: `app/views/setup/index.html.erb`
- **Validator**: `lib/line_validator.rb`
- **Migration**: `db/migrate/xxx_create_application_settings.rb`
- **Routes**: `config/routes.rb` (setup routes)

## Support

For issues or questions:
1. Check browser console for errors
2. Check Rails logs: `tail -f log/development.log`
3. Review setup guide: `SETUP.md`
4. Check GitHub issues

---

**The Smart LINE OAuth Setup Wizard makes deploying Smart on FHIR applications simpler and more user-friendly! 🚀**
