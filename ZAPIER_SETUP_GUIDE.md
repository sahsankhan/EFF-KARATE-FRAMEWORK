# Zapier Setup Guide - Trigger Automation on Dev Repo Push

## Step-by-Step Instructions

### Step 1: Create Zapier Account
1. Go to: https://zapier.com
2. Click "Sign up" (free account works)
3. Complete registration

### Step 2: Create a New Zap
1. Click "Create Zap" (top left)
2. You'll see "1. Choose App & Event"

### Step 3: Set Up Webhook Trigger
1. In the search box, type: **"Webhooks by Zapier"**
2. Click on "Webhooks by Zapier"
3. Select **"Catch Hook"** as the trigger event
4. Click "Continue"

### Step 4: Get Your Webhook URL
1. You'll see a webhook URL like: `https://hooks.zapier.com/hooks/catch/xxxxx/xxxxx/`
2. **Copy this URL** - you'll need it for GitHub webhook setup
3. Click "Continue"
4. Click "Test trigger" (Zapier will wait for a test webhook)
5. **Don't close this page yet!**

### Step 5: Configure GitHub Webhook
1. Open a new tab: `https://github.com/ExtremeFF-org/EFF_Portal/settings/hooks`
2. Click "Add webhook"
3. Fill in:
   - **Payload URL:** Paste the Zapier webhook URL you copied
   - **Content type:** Select `application/json`
   - **Secret:** Leave empty (or create a random string for security)
   - **Which events:** Select "Just the push event"
   - **Active:** ✅ Checked
4. Click "Add webhook"
5. GitHub will send a test "ping" event

### Step 6: Complete Zapier Trigger Test
1. Go back to Zapier tab
2. You should see the test webhook received
3. Click "Continue"

### Step 7: Create Personal Access Token (PAT)
1. Open: `https://github.com/settings/tokens/new`
2. **Note:** `Zapier Automation Trigger`
3. **Expiration:** Choose your preference (90 days recommended)
4. **Scopes:** Check ✅ **`repo`** (Full control of private repositories)
5. Click "Generate token"
6. **Copy the token immediately** (starts with `ghp_...`)
7. **Save it somewhere safe** - you won't see it again!

### Step 8: Set Up GitHub API Action in Zapier
1. Back in Zapier, you'll see "2. Choose App & Event"
2. In search box, type: **"Webhooks by Zapier"**
3. Click "Webhooks by Zapier"
4. Select **"POST"** as the action event
5. Click "Continue"

### Step 9: Configure POST Request
1. **URL:** 
   ```
   https://api.github.com/repos/ExtremeFF-org/EFF-Automation-Framework/dispatches
   ```

2. **Method:** `POST`

3. **Data Pass-Through:** `No`

4. **Headers:** Click "Show options" and add:
   - **Header 1:**
     - Key: `Authorization`
     - Value: `Bearer YOUR_PAT_TOKEN` (replace YOUR_PAT_TOKEN with the token you copied)
   - **Header 2:**
     - Key: `Accept`
     - Value: `application/vnd.github.v3+json`
   - **Header 3:**
     - Key: `Content-Type`
     - Value: `application/json`

5. **Data:** Click "Show options" and add this JSON:
   ```json
   {
     "event_type": "trigger-tests",
     "client_payload": {
       "ref": "{{1.ref}}",
       "sha": "{{1.after}}",
       "actor": "{{1.pusher.name}}",
       "repository": "{{1.repository.full_name}}"
     }
   }
   ```

   **Note:** The `{{1.xxx}}` references data from the webhook trigger. Zapier will show you available fields.

### Step 10: Test the Action
1. Click "Continue"
2. Click "Test & Continue"
3. Zapier will send a test request to GitHub
4. You should see a success message
5. Check your GitHub Actions: `https://github.com/ExtremeFF-org/EFF-Automation-Framework/actions`
6. You should see a workflow run triggered!

### Step 11: Activate Your Zap
1. Click "Turn on Zap" (top right)
2. Your Zap is now active!

## Testing

### Test the Full Flow:
1. Make a small change in `EFF_Portal` repo
2. Push to `main` branch
3. Within seconds, check:
   - Zapier dashboard - should show the Zap ran
   - GitHub Actions - should show your automation workflow running

## Troubleshooting

### If Zap doesn't trigger:
1. Check Zapier dashboard - look for errors
2. Verify webhook URL in GitHub is correct
3. Check GitHub webhook deliveries: `https://github.com/ExtremeFF-org/EFF_Portal/settings/hooks` → Click on your webhook → "Recent Deliveries"

### If GitHub API returns 403:
1. Verify your PAT token has `repo` scope
2. Check token is correct in Zapier headers
3. Make sure token hasn't expired

### If workflow doesn't run:
1. Check your automation repo workflow has `repository_dispatch` trigger
2. Verify event type matches: `trigger-tests`
3. Check GitHub Actions logs for errors

## Important Notes

- **Free Zapier Plan:** Limited to 100 tasks/month (each webhook + API call = 2 tasks)
- **Token Security:** Never share your PAT token publicly
- **Token Expiration:** Set a reminder to renew your token before it expires

## Quick Reference

- **Zapier Dashboard:** https://zapier.com/app/zaps
- **GitHub Tokens:** https://github.com/settings/tokens
- **GitHub Webhooks:** https://github.com/ExtremeFF-org/EFF_Portal/settings/hooks
- **Your Automation Repo:** https://github.com/ExtremeFF-org/EFF-Automation-Framework

