# 🔑 Multi-Provider AI Setup Guide

LedgerPro supports **Bring Your Own AI (BYOAI)** with multiple popular AI providers! Choose from OpenAI, Claude, Groq, local models, and more for enhanced financial analysis.

## 🤖 Supported AI Providers

| Provider | Cost | Speed | Models | Best For |
|----------|------|-------|--------|----------|
| 🆓 **Ollama** | FREE | Fast | Llama3, Mistral | Privacy-focused, local |
| ⚡ **Groq** | $ | Ultra-fast | Llama, Mixtral | Budget + speed |
| 🧠 **OpenAI** | $$$ | Medium | GPT-4, GPT-3.5 | Highest quality |
| 💬 **Anthropic** | $$$ | Medium | Claude 3.5 | Helpful & harmless |
| 🏢 **Cohere** | $$ | Fast | Command-R | Enterprise features |
| 🇪🇺 **Mistral** | $$ | Fast | Mistral Large | European alternative |
| 🤗 **Hugging Face** | $ | Variable | 1000+ models | Open source variety |
| ☁️ **Azure OpenAI** | $$$ | Medium | GPT-4 | Enterprise + compliance |
| 🔍 **Google AI** | $$ | Fast | Gemini Pro | Multimodal capabilities |

## 🚀 Quick Setup

### Method 1: Through LedgerPro App (Recommended)
1. Open LedgerPro → Settings → AI Services
2. Click **"Configure API Keys"**
3. **Choose your AI provider** from the dropdown
4. **Enter your API key** and select model
5. **Test connection** and save

### Method 2: Manual Configuration

First, set up your backend:
```bash
cd LedgerPro/backend
cp .env.example .env
# Edit .env with secure settings
```

Then configure your chosen AI provider:
```bash
cd LedgerPro/mcp-servers/openai-service  # We use this folder for all providers
cp .env.example .env
```

## 🔧 Provider-Specific Setup

### 🆓 Ollama (Local, FREE)
```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama server
ollama serve

# Pull a model
ollama pull llama3

# Configure LedgerPro
AI_PROVIDER=ollama
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3
```

### ⚡ Groq (Ultra-fast, Budget-friendly)
```bash
# Get key from: https://console.groq.com/keys
AI_PROVIDER=groq
GROQ_API_KEY=gsk_your-groq-key-here
GROQ_MODEL=llama-3.1-8b-instant
```

### 🧠 OpenAI (Industry standard)
```bash
# Get key from: https://platform.openai.com/api-keys
AI_PROVIDER=openai
OPENAI_API_KEY=sk-your-openai-key-here
OPENAI_MODEL=gpt-4-turbo
```

### 💬 Anthropic Claude (High quality)
```bash
# Get key from: https://console.anthropic.com/
AI_PROVIDER=anthropic
ANTHROPIC_API_KEY=sk-ant-your-claude-key-here
ANTHROPIC_MODEL=claude-3-5-sonnet-20241022
```

### 🏢 Cohere (Enterprise-focused)
```bash
# Get key from: https://dashboard.cohere.ai/api-keys
AI_PROVIDER=cohere
COHERE_API_KEY=co-your-cohere-key-here
COHERE_MODEL=command-r
```

### 🇪🇺 Mistral AI (European alternative)
```bash
# Get key from: https://console.mistral.ai/
AI_PROVIDER=mistral
MISTRAL_API_KEY=your-mistral-key-here
MISTRAL_MODEL=mistral-large-latest
```

### 🤗 Hugging Face (Open source models)
```bash
# Get token from: https://huggingface.co/settings/tokens
AI_PROVIDER=huggingface
HUGGINGFACE_API_KEY=hf_your-hf-token-here
HUGGINGFACE_MODEL=meta-llama/Llama-2-7b-chat-hf
```

### ☁️ Azure OpenAI (Enterprise compliance)
```bash
# Get from Azure Portal: AI Services → OpenAI
AI_PROVIDER=azure
AZURE_OPENAI_KEY=your-azure-key-here
AZURE_OPENAI_MODEL=gpt-4
```

### 🔍 Google AI (Multimodal capabilities)
```bash
# Get from: https://console.cloud.google.com/
AI_PROVIDER=google
GOOGLE_API_KEY=AI-your-google-key-here
GOOGLE_MODEL=gemini-pro
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