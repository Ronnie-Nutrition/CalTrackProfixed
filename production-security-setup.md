# Production Security Setup Guide

## Critical Security Updates Required Before App Store Submission

### 1. Remove Hardcoded API Keys

#### Current Issue
- API keys are hardcoded in `APIConfig.swift` for DEBUG builds
- This exposes sensitive credentials in the app binary

#### Solution A: Environment Variables (Recommended for CI/CD)
1. Update your build script:
```bash
# In Xcode Build Phases → Add New Run Script Phase
export EDAMAM_APP_ID="your_actual_app_id"
export EDAMAM_APP_KEY="your_actual_app_key"
```

2. The app will automatically detect and store these in Keychain

#### Solution B: Build Configuration (Recommended for Manual Builds)
1. Create `Config-Production.xcconfig`:
```
EDAMAM_APP_ID = your_actual_app_id
EDAMAM_APP_KEY = your_actual_app_key
```

2. Add to Info.plist:
```xml
<key>EDAMAM_APP_ID</key>
<string>$(EDAMAM_APP_ID)</string>
<key>EDAMAM_APP_KEY</key>
<string>$(EDAMAM_APP_KEY)</string>
```

3. **IMPORTANT**: Add `*.xcconfig` to `.gitignore`

### 2. Update Info.plist Security Settings

Add these entries to your Info.plist:

```xml
<!-- App Transport Security -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>api.edamam.com</key>
        <dict>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
        <key>world.openfoodfacts.org</key>
        <dict>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
    </dict>
</dict>

<!-- Prevent HTTP -->
<key>NSAllowsArbitraryLoads</key>
<false/>

<!-- File Protection -->
<key>NSSupportsSecureRestoration</key>
<true/>
```

### 3. Build Settings Security

Update your Xcode project build settings:

#### Debug Information Format
- **Debug**: DWARF
- **Release**: DWARF with dSYM File

#### Code Signing
- Enable "Hardened Runtime"
- Enable "Library Validation"

#### Other Security Flags
- `ENABLE_BITCODE = YES` (for App Store optimization)
- `STRIP_INSTALLED_PRODUCT = YES` (for Release)
- `COPY_PHASE_STRIP = YES` (for Release)

### 4. API Key Migration Process

The app will automatically migrate from old APIConfig to secure storage:

1. On first launch, checks Keychain
2. If empty, checks environment variables
3. If empty, checks Info.plist
4. Stores found credentials in Keychain
5. All future access uses Keychain

### 5. Security Validation Checklist

Before releasing:

#### Code Review
- [ ] No hardcoded secrets in source code
- [ ] All user inputs are validated
- [ ] All API URLs are validated
- [ ] Security headers are added to requests

#### Binary Analysis
- [ ] No sensitive strings in app binary
- [ ] API keys not visible in binary
- [ ] Proper code obfuscation applied

#### Runtime Testing
- [ ] App works without hardcoded credentials
- [ ] Jailbreak detection functioning (if applicable)
- [ ] Input validation prevents malicious inputs
- [ ] Network requests use HTTPS only

### 6. Emergency Security Measures

If API keys are compromised:

1. **Immediately** regenerate keys in Edamam dashboard
2. Update environment variables/config files
3. Force app update if keys were in binary
4. Monitor usage for abuse

### 7. Ongoing Security Maintenance

#### Monthly Tasks
- [ ] Review crash logs for security issues
- [ ] Update dependencies for security patches
- [ ] Monitor API usage for anomalies

#### Before Each Release
- [ ] Run security audit script
- [ ] Update security headers if needed
- [ ] Verify no new hardcoded secrets

## Implementation Priority

1. **CRITICAL**: Remove hardcoded API keys
2. **HIGH**: Implement Keychain storage
3. **HIGH**: Add input validation
4. **MEDIUM**: Configure ATS settings
5. **LOW**: Add jailbreak detection

## Testing Security

### Manual Tests
1. Build app without hardcoded keys
2. Test input validation with malicious strings
3. Verify HTTPS-only network requests
4. Check Keychain storage functionality

### Automated Tests
1. Binary analysis for secrets
2. Network request monitoring
3. Input fuzzing tests
4. Dependency vulnerability scanning

Remember: Security is not a one-time setup but an ongoing process!