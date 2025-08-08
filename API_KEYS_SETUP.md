# 🔑 API Keys Setup Guide

LedgerPro supports **Bring Your Own AI (BYOAI)** - you can plug in your own API keys for enhanced AI features like transaction categorization, financial analysis, and PDF processing.

## 🚀 Quick Setup

### 1. Backend API Configuration

The backend server doesn't require API keys for basic functionality, but you can configure secure authentication:

```bash
cd LedgerPro/backend
cp .env.example .env
```

Edit `.env` and update:
```bash
# Generate a secure secret key (required for production)
LEDGER_SECRET_KEY=your-secure-256-bit-key-here

# Optional: Set up demo user
DEMO_USER_EMAIL=admin@yourdomain.com
DEMO_USER_PASSWORD=your-secure-password
```

**Generate a secure key:**
```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

### 2. AI Services (Optional - For Enhanced Features)

To enable AI-powered categorization, analysis, and PDF processing:

```bash
cd LedgerPro/mcp-servers/openai-service
cp .env.example .env
```

Edit `.env` with your OpenAI credentials:
```bash
OPENAI_API_KEY=sk-your-openai-api-key-here
OPENAI_MODEL=gpt-4  # or gpt-3.5-turbo for lower cost
OPENAI_TEMPERATURE=0.7
OPENAI_MAX_TOKENS=2000
```

## 🔧 Detailed Configuration

### OpenAI API Key Setup

1. **Get an OpenAI API Key:**
   - Visit [OpenAI API Platform](https://platform.openai.com/api-keys)
   - Create an account or sign in
   - Go to "API Keys" section
   - Click "Create new secret key"
   - Copy the key (starts with `sk-`)

2. **Add to Environment:**
   ```bash
   # In mcp-servers/openai-service/.env
   OPENAI_API_KEY=sk-proj-your-actual-key-here
   ```

3. **Test the Setup:**
   ```bash
   cd LedgerPro/mcp-servers/openai-service
   python -c "from openai import OpenAI; import os; from dotenv import load_dotenv; load_dotenv(); print('✅ API Key loaded!' if os.getenv('OPENAI_API_KEY') else '❌ No API key found')"
   ```

### Model Selection & Cost Optimization

| Model | Cost | Speed | Quality | Best For |
|-------|------|-------|---------|----------|
| `gpt-3.5-turbo` | $ | Fast | Good | Basic categorization |
| `gpt-4` | $$$ | Slow | Excellent | Complex analysis |
| `gpt-4-turbo` | $$ | Medium | Excellent | Balanced performance |

**Recommended settings:**
```bash
# Budget-conscious setup
OPENAI_MODEL=gpt-3.5-turbo
OPENAI_MAX_TOKENS=1000

# High-quality setup
OPENAI_MODEL=gpt-4-turbo
OPENAI_MAX_TOKENS=2000
```

### Multiple AI Providers (Future)

LedgerPro is designed to support multiple AI providers:

```bash
# Coming soon - multiple provider support
AI_PROVIDER=openai  # openai, anthropic, azure, local
ANTHROPIC_API_KEY=your-claude-key
AZURE_OPENAI_ENDPOINT=your-azure-endpoint
```

## 🏃‍♂️ Running with AI Features

### Start with AI Enabled

```bash
# 1. Start backend server
cd LedgerPro/backend
python api_server_real.py

# 2. Start MCP servers (in another terminal)
cd LedgerPro/mcp-servers
python -m openai-service.openai_server

# 3. Launch LedgerPro app
cd LedgerPro
swift run
```

### Without AI (Local Only)

```bash
# Just start backend - no API keys needed
cd LedgerPro/backend
python api_server_real.py

# Launch app
cd LedgerPro
swift run
```

## 🔒 Security Best Practices

### Environment File Security

```bash
# Make sure .env files are not committed
echo "*.env" >> .gitignore
chmod 600 .env  # Restrict access to owner only
```

### Key Rotation

```bash
# Rotate keys regularly (every 90 days recommended)
# 1. Generate new key at OpenAI dashboard
# 2. Update .env file
# 3. Restart services
# 4. Revoke old key
```

### Local Development vs Production

**Development (.env):**
```bash
ENVIRONMENT=development
LEDGER_SECRET_KEY=dev-key-not-for-production
OPENAI_MODEL=gpt-3.5-turbo  # Lower cost
```

**Production (.env):**
```bash
ENVIRONMENT=production
LEDGER_SECRET_KEY=$(python -c "import secrets; print(secrets.token_urlsafe(32))")
OPENAI_MODEL=gpt-4-turbo  # Higher quality
```

## 🎛️ In-App Configuration

### Settings Panel

1. **Open LedgerPro**
2. **Go to Settings** (gear icon)
3. **AI Services Section:**
   - Click "Manage Servers"
   - Configure MCP servers
   - Test connections

### Backend Connection

1. **Settings → Backend Configuration**
2. **Server URL:** `http://127.0.0.1:8000`
3. **Click "Test Connection"**
4. **Status should show:** ✅ Connected

## 🆘 Troubleshooting

### Common Issues

**❌ "No API key found"**
```bash
# Check if .env file exists and has correct key
cd mcp-servers/openai-service
cat .env | grep OPENAI_API_KEY
```

**❌ "Invalid API key"**
```bash
# Test key directly
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

**❌ "Connection refused"**
```bash
# Make sure backend is running
curl http://127.0.0.1:8000/api/health
```

### Getting Help

- **Check logs:** `LedgerPro/backend/logs/`
- **Backend status:** `http://127.0.0.1:8000/api/health`
- **MCP server status:** Available in Settings → AI Services

## 💡 Feature Comparison

| Feature | Without API Keys | With OpenAI API |
|---------|------------------|-----------------|
| PDF Upload | ✅ Basic parsing | ✅ Enhanced with AI |
| CSV Import | ✅ Full support | ✅ Full support |
| Transaction Categorization | ✅ Rule-based | ✅ AI-powered + Rules |
| Bank Detection | ✅ Pattern matching | ✅ AI detection |
| Financial Insights | ✅ Basic stats | ✅ Advanced analysis |
| Report Generation | ✅ Standard reports | ✅ AI-generated insights |

## 🚀 Next Steps

1. **Set up your API keys** following this guide
2. **Test the connection** in Settings
3. **Upload a financial document** to see AI features in action
4. **Review the enhanced categorization** and insights

**Need help?** Check the [Installation Guide](INSTALLATION.md) or open an issue on GitHub.