# Strapi - TestBot Deployment

TestBot-compatible deployment scripts for Strapi headless CMS. Builds from the forked repository source to support PR-level code changes.

## Files

- **Dockerfile** - Builds Strapi from source code
- **docker-compose.yml** - Service configuration (includes PostgreSQL)
- **setup.sh** - Starts Strapi, initializes database, creates admin user
- **get-token.sh** - Logs in and outputs JWT authentication token

## TestBot Configuration

```yaml
- uses: skyramp/testbot@v1
  with:
    skyramp_license_file: ${{ secrets.SKYRAMP_LICENSE }}
    cursor_api_key: ${{ secrets.CURSOR_API_KEY }}
    target_setup_command: './deployment-testbot/strapi/setup.sh'
    target_ready_check_command: 'curl -f http://localhost:1337/_health'
    auth_token_command: './deployment-testbot/strapi/get-token.sh'
    target_teardown_command: 'docker-compose -f deployment-testbot/strapi/docker-compose.yml down'
```

## Application Details

- **Port:** 1337
- **API Base:** http://localhost:1337/api
- **Admin Panel:** http://localhost:1337/admin
- **Health Endpoint:** /_health
- **Auth Type:** JWT Bearer Token
- **Database:** PostgreSQL 16
- **Node Version:** 20.x

## Building from Source

The `docker-compose.yml` file uses environment variables to point to the Strapi repository:

```bash
# Default: Uses parent directory (assumes deployment-testbot is in the Strapi fork)
STRAPI_REPO_PATH=/path/to/strapi-fork ./setup.sh

# For TestBot: Set in workflow
env:
  STRAPI_REPO_PATH: ${{ github.workspace }}
```

The Dockerfile:
1. Copies the entire repository (`COPY . .`)
2. Installs npm dependencies
3. Builds the Strapi admin panel
4. Starts in development mode

This ensures PR changes are included in the Docker image.

## API Endpoints

### Admin Endpoints (require JWT token)
- `POST /admin/login` - Admin login
- `GET /admin/users` - List admin users
- `POST /admin/content-manager/collection-types/:contentType` - Create content
- `GET /admin/content-manager/collection-types/:contentType` - List content

### Public API Endpoints (require API token)
- `GET /api/:contentType` - List content
- `GET /api/:contentType/:id` - Get single content
- `POST /api/:contentType` - Create content
- `PUT /api/:contentType/:id` - Update content
- `DELETE /api/:contentType/:id` - Delete content

## Manual Testing

```bash
# Start services
cd deployment-testbot/strapi
./setup.sh

# Get JWT token
TOKEN=$(./get-token.sh)
echo "Token: $TOKEN"

# Test admin API
curl http://localhost:1337/admin/users \
  -H "Authorization: Bearer $TOKEN"

# Stop services
docker-compose down
```

## Initial Setup

The setup script:
1. Builds Strapi from source in the Docker container
2. Waits for PostgreSQL to be ready
3. Initializes the Strapi database
4. Creates an admin user via the registration endpoint
5. Verifies the health endpoint responds

### Admin Credentials

- **Email:** admin@testbot.com
- **Password:** TestBot123!

## Content Types

Strapi requires content types to be defined before creating content. Content types can be:
- Defined in code (`src/api/*/content-types/`)
- Created via the Admin Panel UI
- Created via the Content-Type Builder API

For TestBot evaluation, you should:
1. Fork the Strapi repository to your account
2. Add sample content types in the fork
3. Use the setup script to seed initial data

## Environment Variables

The docker-compose.yml configures:
- `HOST=0.0.0.0` - Bind to all interfaces
- `PORT=1337` - Strapi port
- `DATABASE_CLIENT=postgres` - Use PostgreSQL
- `NODE_ENV=development` - Development mode
- Various secrets (APP_KEYS, JWT_SECRET, etc.)

## Troubleshooting

### Build fails with dependency errors
```bash
# Check Node.js version (requires 18.x, 20.x, or 22.x)
docker exec testbot-strapi node --version

# Check build logs
docker-compose -f deployment-testbot/strapi/docker-compose.yml logs strapi
```

### Admin registration fails
```bash
# Check if admin already exists
curl -s http://localhost:1337/admin/init

# Manually create admin via CLI
docker exec testbot-strapi npm run strapi admin:create-user \
  --firstname=TestBot --lastname=Admin \
  --email=admin@testbot.com --password=TestBot123!
```

### Health check timeout
```bash
# Increase start_period in docker-compose.yml
healthcheck:
  start_period: 120s

# Check Strapi logs
docker-compose -f deployment-testbot/strapi/docker-compose.yml logs strapi
```

## Repository Structure

This deployment expects the following structure:

```
strapi-testbot-eval/                    # Your forked Strapi repository
├── deployment-testbot/
│   └── strapi/
│       ├── Dockerfile                  # Builds from parent directory
│       ├── docker-compose.yml          # Points to STRAPI_REPO_PATH
│       ├── setup.sh
│       ├── get-token.sh
│       └── README.md (this file)
├── packages/                           # Strapi source code
├── package.json                        # Strapi root package.json
└── ... (rest of Strapi repository)
```

## Next Steps

After setting up the deployment scripts:

1. **Test locally:**
   ```bash
   cd /path/to/strapi-testbot-eval
   ./deployment-testbot/strapi/setup.sh
   ```

2. **Add .github/workflows/skyramp-testbot.yml** to the fork

3. **Configure GitHub secrets:**
   - `SKYRAMP_LICENSE`
   - `CURSOR_API_KEY` (or `SKYRAMP_TESTBOT_API_KEY`)

4. **Create a test PR** to verify TestBot runs

## References

- [Strapi Documentation](https://docs.strapi.io)
- [Strapi GitHub](https://github.com/strapi/strapi)
- [TestBot GitHub Action](https://github.com/marketplace/actions/skyramp-testbot)
