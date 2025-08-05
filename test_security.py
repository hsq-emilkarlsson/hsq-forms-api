#!/usr/bin/env python3
"""
Test script för säkerhetskonfiguration
"""
import os
import sys

# Lägg till projektroot till Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_security_config():
    """Testar säkerhetskonfigurationen"""
    print("🔍 Testing HSQ Forms API Security Configuration")
    print("=" * 50)
    
    # Test environment
    os.environ['APP_ENVIRONMENT'] = 'development'
    
    try:
        from src.forms_api.config import Settings
        
        # Test development config
        print("\n📍 Testing Development Configuration:")
        dev_settings = Settings()
        print(f"   Environment: {dev_settings.environment}")
        print(f"   CORS Origins: {dev_settings.cors_origins}")
        print(f"   API Docs: {dev_settings.api_docs_url}")
        print(f"   Debug Mode: {dev_settings.debug}")
        
        # Test production config
        print("\n📍 Testing Production Configuration:")
        os.environ['APP_ENVIRONMENT'] = 'production'
        prod_settings = Settings()
        print(f"   Environment: {prod_settings.environment}")
        print(f"   CORS Origins: {prod_settings.cors_origins}")
        print(f"   API Docs: {prod_settings.api_docs_url}")
        print(f"   Debug Mode: {prod_settings.debug}")
        
        # Test CORS validation
        print("\n🔒 Security Validation:")
        
        if '*' in str(prod_settings.cors_origins):
            print("   ❌ CRITICAL: Production CORS allows all origins!")
        else:
            print("   ✅ Production CORS is restricted")
            
        if prod_settings.api_docs_url is not None:
            print("   ❌ WARNING: API docs enabled in production!")
        else:
            print("   ✅ API docs disabled in production")
            
        if not prod_settings.debug:
            print("   ✅ Debug mode disabled in production")
        else:
            print("   ❌ WARNING: Debug mode enabled in production!")
            
        print("\n🎯 Security Test Complete!")
        return True
        
    except Exception as e:
        print(f"❌ Error testing security config: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_security_config()
    sys.exit(0 if success else 1)
