# In-App Purchase Compliance Checklist for App Store Review

## Apple Review Rejection Details
- **Guideline**: 2.1 - Performance - App Completeness
- **Issue**: Purchase error when attempting to buy subscription
- **Test Device**: iPad Air 11-inch (M3), iPadOS 26.2

---

## CRITICAL: Pre-Submission Checklist

### 1. App Store Connect - Paid Apps Agreement
- [ ] Go to **App Store Connect → Business**
- [ ] Ensure **Paid Applications Agreement** is signed and ACTIVE (not expired)
- [ ] Check for any "Action Required" banners
- [ ] Verify banking and tax information is complete

### 2. App Store Connect - In-App Purchase Products
Go to **App Store Connect → Your App → Monetization → In-App Purchases**

For EACH product, verify:

#### Monthly Subscription (`com.caltrackpro.premium.monthly`)
- [ ] Product ID matches EXACTLY (case-sensitive)
- [ ] Type: **Auto-Renewable Subscription**
- [ ] Status: **Ready to Submit** or **Approved**
- [ ] Price: $4.99/month configured
- [ ] Localization: Display name and description in English (US) at minimum
- [ ] Subscription Group: Created and configured
- [ ] Review Information: Screenshot uploaded (if required)

#### Yearly Subscription (`com.caltrackpro.premium.yearly`)
- [ ] Product ID matches EXACTLY (case-sensitive)
- [ ] Type: **Auto-Renewable Subscription**
- [ ] Status: **Ready to Submit** or **Approved**
- [ ] Price: $39.99/year configured
- [ ] Localization: Display name and description in English (US) at minimum
- [ ] In same Subscription Group as Monthly
- [ ] Review Information: Screenshot uploaded (if required)

#### Lifetime Purchase (`com.caltrackpro.premium.lifetime.v2`)
- [ ] Product ID matches EXACTLY (case-sensitive)
- [ ] Type: **Non-Consumable** (NOT Non-Renewing Subscription)
- [ ] Status: **Ready to Submit** or **Approved**
- [ ] Price: $79.99 configured
- [ ] Localization: Display name and description in English (US) at minimum
- [ ] Review Information: Screenshot uploaded (if required)

### 3. Xcode Project - Capabilities
- [ ] Open project in Xcode
- [ ] Select your app target → Signing & Capabilities
- [ ] Verify **In-App Purchase** capability is added (+ Capability → In-App Purchase)
- [ ] Verify **Automatically manage signing** is enabled
- [ ] Verify correct Team is selected (D66KWXXM88)

### 4. Product ID Verification
The code uses these product IDs (must match App Store Connect EXACTLY):
```
com.caltrackpro.premium.monthly
com.caltrackpro.premium.yearly
com.caltrackpro.premium.lifetime.v2
```

### 5. Sandbox Testing (BEFORE Resubmission)
- [ ] Create or use existing Sandbox Apple ID
  - Settings → App Store → Sandbox Account (on device)
- [ ] Sign out of production Apple ID on test device
- [ ] Sign in with Sandbox account
- [ ] Build and run app from Xcode on device
- [ ] Attempt to purchase each subscription type
- [ ] Verify purchase completes without error
- [ ] Verify subscription status updates correctly
- [ ] Test "Restore Purchases" functionality

---

## Common Issues That Cause Review Rejection

### Issue 1: Products Not Loaded
**Symptom**: "Unable to connect to App Store" or products list is empty
**Causes**:
- Product IDs don't match App Store Connect exactly
- Products not in "Ready to Submit" status
- Paid Apps Agreement not signed
- In-App Purchase capability not enabled in Xcode

### Issue 2: Purchase Fails with Error
**Symptom**: Error when tapping "Subscribe Now"
**Causes**:
- StoreKit not properly initialized
- Product type mismatch (code expects subscription but product is non-consumable)
- Network issues during review

### Issue 3: Sandbox Environment Issues
**Symptom**: Works in development but fails in review
**Causes**:
- Reviewer's sandbox account has issues
- Products not properly synced to sandbox
- Receipt validation pointing to wrong environment

---

## App Store Review Notes (Add to App Store Connect)

When resubmitting, add this to the "Notes for Reviewer" field:

```
In-App Purchase Testing Instructions:

1. The app offers three subscription options:
   - Monthly Premium: $4.99/month
   - Yearly Premium: $39.99/year
   - Lifetime Premium: $79.99 (one-time)

2. To test purchases:
   - Open the app
   - Navigate to Settings → Upgrade to Premium
   - OR tap any premium feature lock icon
   - Select a subscription plan and tap "Subscribe Now"

3. All purchases use Apple's StoreKit 2 framework
4. Restore Purchases is available at the bottom of the upgrade screen

If you encounter any issues, please contact us at [your-email].
```

---

## After Fixing Issues

1. [ ] Increment build number in Xcode
2. [ ] Archive and upload new build to App Store Connect
3. [ ] Add new build to your app submission
4. [ ] Ensure all IAP products are attached to this version
5. [ ] Add detailed review notes (see above)
6. [ ] Submit for review

---

## Sources & References
- [Overview for configuring in-app purchases](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases)
- [View and edit in-app purchase information](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/view-and-edit-in-app-purchase-information)
- [Testing in-app purchases with sandbox](https://developer.apple.com/documentation/StoreKit/testing-in-app-purchases-with-sandbox)
- [TN3186: Troubleshooting IAP in sandbox](https://developer.apple.com/documentation/technotes/tn3186-troubleshooting-in-app-purchases-availability-in-the-sandbox)
