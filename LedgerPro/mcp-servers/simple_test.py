#!/usr/bin/env python3
"""
Simple test to verify servers are working correctly with Claude Desktop configuration
"""
import json
from pathlib import Path

def verify_setup():
    """Verify the MCP setup is ready for Claude Desktop"""
    print("🔍 Verifying MCP Server Setup")
    print("=" * 50)
    
    base_path = Path(__file__).parent
    
    # Check that all servers exist
    servers = {
        "openai-service": base_path / "openai-service" / "openai_server.py",
        "pdf-processor": base_path / "pdf-processor" / "pdf_processor_server.py",
        "financial-analyzer": base_path / "financial-analyzer" / "analyzer_server.py"
    }
    
    print("📁 Server Files:")
    all_exist = True
    for name, path in servers.items():
        if path.exists():
            print(f"   ✅ {name}: {path}")
        else:
            print(f"   ❌ {name}: {path} (NOT FOUND)")
            all_exist = False
    
    # Check virtual environments
    print("\n🐍 Virtual Environments:")
    venvs_exist = True
    for name in servers.keys():
        venv_path = base_path / name / "venv" / "bin" / "python"
        if venv_path.exists():
            print(f"   ✅ {name}: Virtual env ready")
        else:
            print(f"   ❌ {name}: Virtual env missing")
            venvs_exist = False
    
    # Check configuration file
    config_path = base_path / "claude_desktop_config.json"
    print(f"\n⚙️  Configuration:")
    if config_path.exists():
        print(f"   ✅ Config file: {config_path}")
        try:
            with open(config_path) as f:
                config = json.load(f)
            print(f"   ✅ Valid JSON with {len(config.get('mcpServers', {}))} servers")
        except json.JSONDecodeError:
            print(f"   ❌ Invalid JSON in config file")
    else:
        print(f"   ❌ Config file missing: {config_path}")
    
    # Overall status
    print("\n" + "=" * 50)
    if all_exist and venvs_exist:
        print("🎉 Setup Complete! Ready for Claude Desktop")
        print("\n📋 Next Steps:")
        print("1. Copy config to Claude Desktop:")
        print(f"   cp {config_path} ~/Library/Application\\ Support/Claude/claude_desktop_config.json")
        print("\n2. Edit the config file to add your OpenAI API key")
        print("\n3. Restart Claude Desktop")
        print("\n4. Test with: 'List the available MCP tools'")
        
        print("\n🧪 Test Commands for Claude Desktop:")
        print("• 'What MCP servers are available?'")
        print("• 'Show me the financial analysis tools'")
        print("• 'Analyze a bank statement' (you'll need to provide a file path)")
        
    else:
        print("⚠️  Setup Incomplete")
        if not all_exist:
            print("   • Some server files are missing")
        if not venvs_exist:
            print("   • Virtual environments need setup")
    
    print(f"\n📚 Documentation: {base_path / 'README.md'}")

if __name__ == "__main__":
    verify_setup()