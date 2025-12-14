# In-App Purchase Setup Guide - CalTrackPro Premium

## Overview
Setting up freemium pricing with subscriptions and one-time purchase options.

## Pricing Structure

### Free Tier (Base App)
- Basic food logging (manual entry)
- Barcode scanning (limited to 10 scans/day)
- Basic nutrition tracking
- 7-day food history

### Premium Tier - Pricing Options
1. **Monthly:** $6.99/month (7-day free trial)
2. **Annual:** $49.99/year (7-day free trial) - Save 40%
3. **Lifetime:** $79.99 one-time (launch special: $59.99)

---

## Step-by-Step Setup in App Store Connect

### STEP 1: Set Base App Price to FREE

1. Go to **App Store Connect** → https://appstoreconnect.apple.com
2. Navigate to **"My Apps"** → **"CalTrackPro"**
3. Click **"Pricing and Availability"** in the left sidebar
4. Under **"Price Schedule"**:
   - Click **"Add Pricing"**
   - Select **"Free"** (or enter $0.00)
   - Click **"Next"** → **"Add"**
5. ✅ Base app is now free to download

---

### STEP 2: Create Subscription Group

1. In your app's page, go to **"Features"** → **"Subscriptions"** (or "In-App Purchases")
2. Click **"Create"** or **"+"** button
3. Select **"Create Subscription Group"**
4. Fill in details:
   - **Reference Name:** Premium Access
   - **App Name (Localization):** CalTrackPro Premium
5. Click **"Create"**

---

### STEP 3: Create Monthly Premium Subscription

1. Inside the **"Premium Access"** subscription group
2. Click **"Create Subscription"** or **"+"**
3. Fill in the form:

**Product ID:** `com.easyaiflows.CalTrackProFixed.premium.monthly`
- (Use your actual bundle identifier format)

**Reference Name:** Premium Monthly Subscription

**Subscription Duration:** 1 Month

**Subscription Prices:**
- Click **"Add Subscription Price"**
- Select **"USD"** → **$6.99**
- Add other currencies/regions as needed
- Click **"Next"**

**Free Trial:**
- Enable **"Introductory Offer"**
- Type: **"Free Trial"**
- Duration: **7 Days**
- Click **"Add"**

**Localizations (App Store Info):**
- Click **"Add Localization"**
- Language: **English (U.S.)**
- **Display Name:** Premium Monthly
- **Description:**
  ```
  Unlock all premium features including unlimited voice input, Apple Health sync, advanced analytics, meal planning, and more. Includes 7-day free trial.
  ```

4. Click **"Save"**

---

### STEP 4: Create Annual Premium Subscription

1. In the **"Premium Access"** subscription group
2. Click **"Create Subscription"** or **"+"**
3. Fill in the form:

**Product ID:** `com.easyaiflows.CalTrackProFixed.premium.annual`

**Reference Name:** Premium Annual Subscription

**Subscription Duration:** 1 Year

**Subscription Prices:**
- Click **"Add Subscription Price"**
- Select **"USD"** → **$49.99**
- Add other currencies/regions
- Click **"Next"**

**Free Trial:**
- Enable **"Introductory Offer"**
- Type: **"Free Trial"**
- Duration: **7 Days**
- Click **"Add"**

**Localizations (App Store Info):**
- Language: **English (U.S.)**
- **Display Name:** Premium Annual (Save 40%)
- **Description:**
  ```
  Unlock all premium features for an entire year at a 40% discount. Includes unlimited voice input, Apple Health sync, advanced analytics, meal planning, and more. Includes 7-day free trial.
  ```

4. Click **"Save"**

---

### STEP 5: Create Lifetime Premium Purchase

1. Go to **"Features"** → **"In-App Purchases"** (NOT subscriptions)
2. Click **"Create"** or **"+"**
3. Select **"Non-Consumable"** (one-time purchase)
4. Fill in the form:

**Product ID:** `com.easyaiflows.CalTrackProFixed.premium.lifetime`

**Reference Name:** Premium Lifetime

**Pricing:**
- Click **"Add Pricing"**
- **Regular Price:** $79.99 USD
- *Note: You can change this to $59.99 for launch special*
- Add other currencies/regions

**Localizations:**
- Language: **English (U.S.)**
- **Display Name:** Lifetime Premium Access
- **Description:**
  ```
  Unlock all premium features forever with a one-time purchase. No subscriptions, no recurring charges. Includes unlimited voice input, Apple Health sync, advanced analytics, meal planning, and lifetime updates.
  ```

**Review Notes (for Apple reviewers):**
```
This is a one-time purchase option for users who prefer not to subscribe. It unlocks the same features as the subscription tiers but with a single payment.
```

5. Click **"Save"**

---

### STEP 6: Configure Subscription Settings

1. Go back to your **"Premium Access"** subscription group
2. Click **"Subscription Group Settings"**
3. Configure:

**Auto-Renewable Subscription Information:**
- Required for App Store review
- Explain what subscribers get

**Subscription Rank:**
- Set **Annual** as **Level 1** (highest value/best deal)
- Set **Monthly** as **Level 2**

4. Click **"Save"**

---

### STEP 7: Submit for Review

1. Each in-app purchase needs to be submitted with your app
2. Make sure each one shows **"Ready to Submit"** status
3. When you submit your app for review, these will be reviewed too

---

## Testing In-App Purchases

### Create Sandbox Test Account

1. In **App Store Connect**, go to **"Users and Access"**
2. Click **"Sandbox Testers"** (under "Testers" section)
3. Click **"+"** to add a tester
4. Fill in:
   - **First Name:** Test
   - **Last Name:** User
   - **Email:** test@example.com (use a real email you control)
   - **Password:** [secure password]
   - **Country:** United States
5. Click **"Create"**

### Test on Device

1. On your iPhone, go to **Settings** → **App Store**
2. Scroll down to **"Sandbox Account"**
3. Sign in with your sandbox test account
4. Open CalTrackPro and test purchasing premium features
5. You won't be charged - these are test purchases

---

## Product IDs Summary

Use these exact product IDs in your Swift code:

```swift
// Product IDs for StoreKit
enum PremiumProduct: String {
    case monthly = "com.easyaiflows.CalTrackProFixed.premium.monthly"
    case annual = "com.easyaiflows.CalTrackProFixed.premium.annual"
    case lifetime = "com.easyaiflows.CalTrackProFixed.premium.lifetime"
}
```

---

## Premium Features to Gate

Implement these features behind the premium paywall:

### Free Users Get:
- ✅ Manual food entry
- ✅ 10 barcode scans per day
- ✅ Basic nutrition tracking
- ✅ 7-day history
- ✅ Basic diary view

### Premium Users Get:
- ✅ **Unlimited voice input** (killer feature!)
- ✅ **Unlimited barcode scanning**
- ✅ **Apple Health sync** (bi-directional)
- ✅ **Advanced analytics dashboard**
- ✅ **Meal planning**
- ✅ **Unlimited history**
- ✅ **Intermittent fasting tracker**
- ✅ **Data export (PDF/CSV)**
- ✅ **Home screen widgets**
- ✅ **Priority support**
- ✅ **No ads** (if you add ads to free tier later)

---

## Launch Pricing Special

For the first month, you can manually change the Lifetime price:

1. Edit the Lifetime In-App Purchase
2. Change price from $79.99 to **$59.99**
3. Add to description: **"Launch Special: $20 OFF"**
4. After 30 days, change it back to $79.99

---

## Next Steps After Setup

1. ✅ Implement StoreKit in your app (if not already done)
2. ✅ Add paywall screens
3. ✅ Test with sandbox accounts
4. ✅ Submit for App Store review
5. ✅ Monitor conversion rates in App Store Connect Analytics

---

## Support Resources

- **StoreKit Documentation:** https://developer.apple.com/storekit/
- **App Store Connect Guide:** https://help.apple.com/app-store-connect/
- **Subscription Best Practices:** https://developer.apple.com/app-store/subscriptions/

---

**Remember:** The 7-day free trial is KEY for conversions. Users can try all premium features risk-free!
