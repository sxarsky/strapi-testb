# Strapi TestBot Eval Setup Guide

Complete guide for setting up the strapi-testbot-eval fork with TestBot integration.

## Prerequisites

- GitHub account with fork of strapi/strapi (e.g., sxarsky/strapi)
- Access to GitHub Actions secrets
- Docker and docker-compose installed locally

## Repository Structure

The Strapi fork should have this structure:

```
strapi-testbot-eval/                    # Your forked Strapi repository
├── deployment-testbot/                 # TestBot integration files
│   └── strapi/
│       ├── Dockerfile                  # Builds Strapi from source
│       ├── docker-compose.yml          # Service configuration
│       ├── setup.sh                    # Initialization script
│       ├── get-token.sh                # Auth token generator
│       ├── teardown.sh                 # Cleanup script
│       ├── README.md                   # Documentation
│       └── SETUP-GUIDE.md (this file)
├── .github/
│   └── workflows/
│       └── skyramp-testbot.yml         # TestBot workflow (to be created)
├── packages/                           # Strapi source code
├── package.json                        # Strapi root package.json
└── ... (rest of Strapi repository)
```

## Step 1: Fork Strapi Repository

If you haven't already forked the Strapi repository:

1. Go to https://github.com/strapi/strapi
2. Click "Fork" button
3. Choose your account (e.g., sxarsky)
4. Name it `strapi-testbot-eval` or keep as `strapi`

## Step 2: Clone Your Fork

```bash
cd /Users/syedsky/Skyramp/content/product/features/testbot/testing/forks

# Clone your fork
git clone https://github.com/sxarsky/strapi.git strapi-testbot-eval

cd strapi-testbot-eval

# Add upstream remote
git remote add upstream https://github.com/strapi/strapi.git

# Verify remotes
git remote -v
```

## Step 3: Copy Deployment Files

Copy the deployment-testbot/strapi/ directory into your fork:

```bash
# From the deployment-testbot directory
cp -r /Users/syedsky/Skyramp/content/product/features/testbot/deployment-testbot/strapi \
      /Users/syedsky/Skyramp/content/product/features/testbot/testing/forks/strapi-testbot-eval/deployment-testbot/
```

## Step 4: Create TestBot Workflow

Create `.github/workflows/skyramp-testbot.yml` in your fork:

```yaml
name: Skyramp TestBot

on:
  pull_request:
    types: [opened, synchronize, reopened]
    paths:
      - 'packages/**'
      - 'src/**'
      - 'package.json'
      - 'package-lock.json'

jobs:
  test-maintenance:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run Skyramp TestBot
        uses: skyramp/testbot@v1
        with:
          skyramp_license_file: ${{ secrets.SKYRAMP_LICENSE }}
          cursor_api_key: ${{ secrets.CURSOR_API_KEY }}

          # Point to the forked repo
          target_setup_command: |
            export STRAPI_REPO_PATH=${{ github.workspace }}
            ./deployment-testbot/strapi/setup.sh

          target_ready_check_command: 'curl -f http://localhost:1337/_health'

          auth_token_command: './deployment-testbot/strapi/get-token.sh'

          target_teardown_command: |
            cd deployment-testbot/strapi && docker-compose down -v
```

## Step 5: Configure GitHub Secrets

Go to your fork's settings and add these secrets:

### Required Secrets

1. **SKYRAMP_LICENSE**
   - Skyramp license file content
   - Get from Skyramp team

2. **CURSOR_API_KEY** (or **SKYRAMP_TESTBOT_API_KEY**)
   - Anthropic API key for Claude
   - Format: `sk-ant-...`
   - Get from https://console.anthropic.com/

### Optional Secrets (for GitHub App integration)

3. **SKYRAMP_TESTBOT_APP_ID**
   - GitHub App ID for PR comments

4. **SKYRAMP_TESTBOT_APP_PRIVATE_KEY**
   - GitHub App private key (PEM format)

### Add Secrets via GitHub UI

```
https://github.com/sxarsky/strapi-testbot-eval/settings/secrets/actions
```

1. Click "New repository secret"
2. Enter name and value
3. Click "Add secret"

## Step 6: Test Locally

Before creating a PR, test the deployment locally:

```bash
cd /Users/syedsky/Skyramp/content/product/features/testbot/testing/forks/strapi-testbot-eval

# Set environment variable to point to current directory
export STRAPI_REPO_PATH=$(pwd)

# Run setup
./deployment-testbot/strapi/setup.sh

# Wait for it to complete (should see "✓ Strapi setup complete")

# Test health endpoint
curl http://localhost:1337/_health

# Get auth token
./deployment-testbot/strapi/get-token.sh

# Cleanup
./deployment-testbot/strapi/teardown.sh
```

## Step 7: Commit and Push

```bash
cd /Users/syedsky/Skyramp/content/product/features/testbot/testing/forks/strapi-testbot-eval

# Create a new branch
git checkout -b setup/testbot-integration

# Add the deployment files
git add deployment-testbot/
git add .github/workflows/skyramp-testbot.yml

# Commit
git commit -m "Add TestBot integration for replay eval

- Add deployment-testbot/strapi/ with Dockerfile, setup scripts
- Add GitHub workflow for TestBot
- Configure to build from source for PR testing
"

# Push to your fork
git push origin setup/testbot-integration
```

## Step 8: Create Test PR

Create a PR to test the TestBot integration:

```bash
# Using GitHub CLI
gh pr create \
  --title "Setup: TestBot Integration" \
  --body "Initial setup for TestBot replay evaluation.

This PR adds:
- Deployment scripts in deployment-testbot/strapi/
- GitHub workflow for TestBot
- Builds Strapi from source to test code changes

TestBot should:
- Build Strapi from source
- Initialize database
- Create admin user
- Run health checks
"

# Or manually: https://github.com/sxarsky/strapi-testbot-eval/compare
```

## Step 9: Verify TestBot Runs

1. Go to the PR page
2. Check the "Actions" tab
3. Look for "Skyramp TestBot" workflow
4. Verify it completes successfully
5. Check for TestBot comments on the PR

Expected workflow steps:
- ✅ Checkout code
- ✅ Run setup.sh (builds Docker image)
- ✅ Health check passes
- ✅ Get auth token
- ✅ TestBot analysis runs
- ✅ Teardown completes

## Step 10: Ready for Replay Eval

Once TestBot is working:

1. **Create replay-eval directory:**
   ```bash
   mkdir -p replay-eval/.claude
   ```

2. **Document the setup in fork registry:**
   - Update `/Users/syedsky/Skyramp/content/product/features/testbot/testing/forks/fork-registry.md`

3. **Create test scenarios:**
   - Plan PRs that introduce bugs
   - Document expected TestBot behavior

## Troubleshooting

### Build fails

```bash
# Check build logs
docker-compose -f deployment-testbot/strapi/docker-compose.yml logs

# Verify Dockerfile syntax
docker build -f deployment-testbot/strapi/Dockerfile .
```

### Health check timeout

```bash
# Increase timeout in docker-compose.yml
healthcheck:
  start_period: 120s

# Check Strapi logs
docker exec testbot-strapi npm run strapi version
```

### Token generation fails

```bash
# Check admin user exists
curl http://localhost:1337/admin/init

# Check login endpoint
curl -X POST http://localhost:1337/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@testbot.com","password":"TestBot123!"}'
```

### Workflow doesn't trigger

- Check paths in workflow file match your changes
- Verify workflow file is in `.github/workflows/`
- Check branch protection rules

## Key Differences from deployment-testbot/

The setup in `deployment-testbot/strapi/` is different from a standalone deployment:

1. **Builds from fork source** - Uses `context: ${STRAPI_REPO_PATH:-.}` to build from the repository
2. **Dockerfile in deployment-testbot/** - Custom Dockerfile that copies repository code
3. **Environment variable for path** - `STRAPI_REPO_PATH` points to the fork
4. **Workflow sets workspace** - GitHub Actions sets `STRAPI_REPO_PATH=${{ github.workspace }}`

This ensures TestBot tests actual PR changes, not a prebuilt image.

## Next Steps

After successful setup:

1. Merge the setup PR
2. Create PRs with intentional bugs for replay eval
3. Document TestBot's performance in catching bugs
4. Iterate on scenarios based on results

## Reference

- Prefect example: `/Users/syedsky/Skyramp/content/product/features/testbot/testing/forks/prefect-testbot-eval`
- Bagisto example: `/Users/syedsky/Skyramp/content/product/features/testbot/deployment-testbot/bagisto`
- Strapi docs: https://docs.strapi.io
- TestBot action: https://github.com/marketplace/actions/skyramp-testbot
