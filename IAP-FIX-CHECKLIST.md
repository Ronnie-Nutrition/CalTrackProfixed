# In-App Purchase Fix Checklist for App Store Review

**Error Seen:** "Unable to load subscription. Please check your internet connection and try again."

This error occurs when StoreKit cannot load products from App Store Connect. Follow this checklist to fix it.

---

## STEP 1: Verify Paid Apps Agreement

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **Business** (left sidebar) or go to **Agreements, Tax, and Banking**
3. Ensure **Paid Apps** agreement shows **"Active"** status
4. If not active, complete all required information (banking, tax forms, contact info)

**Status:** [ ] Verified Active

---

## STEP 2: Verify In-App Purchase Products in App Store Connect

Go to **App Store Connect > Your App > Subscriptions** or **In-App Purchases**

### Required Products (Product IDs MUST match exactly):

| Product ID | Type | Price | Status Required |
|------------|------|-------|-----------------|
| `com.caltrackpro.premium.monthly` | Auto-Renewable Subscription | $4.99/month | Ready to Submit |
| `com.caltrackpro.premium.yearly` | Auto-Renewable Subscription | $39.99/year | Ready to Submit |
| `com.caltrackpro.premium.lifetime.v2` | Non-Renewing Subscription OR Non-Consumable | $99.99 | Ready to Submit |

### For Each Product, Verify:
- [ ] **Product ID matches exactly** (case-sensitive)
- [ ] **Status is "Ready to Submit"** (not "Missing Metadata", "Developer Action Needed", etc.)
- [ ] **Price is set** and territory is enabled for reviewer's region (USA typically)
- [ ] **Localization is complete** (Display Name, Description)
- [ ] **Review Screenshot uploaded** (required for initial review)

---

## STEP 3: Subscription Group Configuration

If using Auto-Renewable Subscriptions:

1. Go to **Subscriptions** in your app
2. Ensure you have a **Subscription Group** (e.g., "Premium")
3. All subscription products must be in this group
4. Check that subscriptions are ordered by level (yearly > monthly typically)

**Status:** [ ] Subscription Group Configured

---

## STEP 4: Create Sandbox Test Account (if not done)

1. Go to App Store Connect > **Users and Access**
2. Click **Sandbox** tab
3. Click **+** to add a Sandbox Tester
4. Use a unique email (not your real Apple ID)
5. Complete all fields

**Note:** Apple reviewers use their own sandbox accounts, but having a test account helps you verify the flow.

---

## STEP 5: Verify App Uses Correct Bundle ID

Your app's bundle ID must match what's in App Store Connect:

- **Bundle ID:** `easyaiflows.com.CalTrackProFixed`

In Xcode:
1. Select project in navigator
2. Select your app target
3. Go to **Signing & Capabilities**
4. Verify Bundle Identifier matches

---

## STEP 6: Test in Sandbox Environment

Before resubmitting:

1. Build and run on a **real device** (not simulator - StoreKit doesn't work in simulator for real purchases)
2. Sign out of App Store on device: Settings > [Your Name] > Media & Purchases > Sign Out
3. Launch your app
4. Tap a subscription to purchase
5. When prompted, sign in with your **Sandbox test account**
6. Complete the purchase flow

**Expected Result:** Purchase should complete successfully in sandbox.

---

## COMMON ISSUES AND FIXES

### Issue: "Invalid Product ID"
- Product ID in code doesn't match App Store Connect exactly
- Fix: Copy/paste product ID directly from App Store Connect

### Issue: "Cannot connect to iTunes Store"
- Products not configured or not in "Ready to Submit" status
- Paid Apps Agreement not active
- Fix: Complete all product metadata and agreement

### Issue: Products load in simulator but fail on device
- Simulator uses local StoreKit configuration file
- Device connects to real App Store Connect
- Fix: Ensure App Store Connect products match local configuration

### Issue: Lifetime purchase doesn't work
- If configured as Non-Consumable: It won't have a `subscription` property
- If configured as Non-Renewing Subscription: It will have `subscription` property
- Fix: Our code now handles both cases

---

## BEFORE RESUBMITTING

1. [ ] Paid Apps Agreement is ACTIVE
2. [ ] All 3 products show "Ready to Submit" status
3. [ ] All product IDs match code exactly:
   - `com.caltrackpro.premium.monthly`
   - `com.caltrackpro.premium.yearly`
   - `com.caltrackpro.premium.lifetime.v2`
4. [ ] Tested purchase flow on real device with sandbox account
5. [ ] Uploaded new build with version number increment
6. [ ] Added note for reviewers explaining sandbox testing

---

## REVIEWER NOTE TEMPLATE

Add this in App Store Connect under "Notes for Review":

```
In-App Purchase Testing:
- All subscription products are configured and ready for testing
- Product IDs: com.caltrackpro.premium.monthly, com.caltrackpro.premium.yearly, com.caltrackpro.premium.lifetime.v2
- Subscription Group: Premium
- Please use sandbox environment to test purchases
- The app will automatically load products from the App Store
```

---

## Code Changes Made (December 23, 2025)

1. **Fixed lifetime product handling** - Now handles both Non-Consumable and Non-Renewing Subscription types
2. **Added retry logic** - Products now retry loading up to 3 times with exponential backoff
3. **Improved error messages** - More specific errors for network issues, sign-in problems, etc.
4. **Added extensive logging** - Console shows `[StoreKit]` prefixed messages for debugging
5. **Better product matching** - Falls back to matching by type if exact ID match fails

Files modified:
- `Services/SubscriptionManager.swift`
- `Models/Views/PremiumUpgradeView.swift`
