# Security Setup Guide

## API Key Configuration

This project uses a secure configuration system to prevent API keys from being committed to version control.

### Setup Steps

1. **Copy the example config:**
   ```bash
   cp Config.example.xcconfig Config.xcconfig
   ```

2. **Add your API keys to Config.xcconfig:**
   ```
   REVENUECAT_API_KEY = your_actual_revenuecat_key_here
   ```

3. **In Xcode:**
   - Open project settings
   - Select the project (top level)
   - Go to "Info" tab
   - Under "Configurations", set Config.xcconfig for both Debug and Release builds

4. **Add to Info.plist:**
   - Open Info.plist as source code
   - Add this key:
   ```xml
   <key>REVENUECAT_API_KEY</key>
   <string>$(REVENUECAT_API_KEY)</string>
   ```

5. **Verify .gitignore:**
   Config.xcconfig is already in .gitignore, so your actual keys won't be committed.

### Getting API Keys

#### RevenueCat
1. Go to https://app.revenuecat.com/
2. Select your app
3. Go to API keys section
4. Copy the "Public SDK Key" (starts with `appl_` or similar)

### What NOT to do

❌ DO NOT commit Config.xcconfig with actual keys
❌ DO NOT hardcode keys in Swift files
❌ DO NOT share your API keys publicly
❌ DO NOT use the same keys for development and production

### Troubleshooting

If you see "RevenueCat API key not configured" error:
1. Verify Config.xcconfig exists and contains your key
2. Verify Config.xcconfig is set in project configurations
3. Clean build folder (Cmd+Shift+K)
4. Rebuild project

### For Team Development

Each developer should:
1. Get their own development API keys
2. Create their own Config.xcconfig (not in git)
3. Never share keys via Slack/email
4. Use separate keys for production (set via CI/CD)
