# SafeShift AI - Hackathon Demo Script (3-5 Minutes)

Use this script as a guide for recording the submission video or performing a live walk-through for the hackathon judges.

---

## Part 1: Problem & Onboarding (0:00 - 0:30)

1. **Presenter Narration**:
   > *"In Pakistan's informal shifting economy, finding a reliable loader or packing service is highly chaotic. Families search roadside stands or Google Maps, but face constant hidden surcharges, broken items, and unannounced cancellations. Welcome to SafeShift AI: an agentic moving orchestrator designed to inject trust, transparent pricing, and robust recovery into informal shifting."*

2. **Actions**:
   - Open the app on the **Onboarding Screen**.
   - Show the elegant dark Mughal Indigo theme with the premium terracotta highlights.
   - Click the **"Start Smart Move"** button.

---

## Part 2: Request Input & Agent Understanding (0:30 - 1:15)

1. **Presenter Narration**:
   > *"We start by typing a code-switched request in Roman Urdu and English. The user types: 'G-13 shift hona hai Bahria Town Phase 8 se, 2 bed flat hai with heavy double bed and fragile glass dining table. 3rd floor, no lift.' We also select our pickup and drop-off locations. We can upload multiple images of our room to automatically scan and detect moving inventory. If we upload a valid room photo, the system accepts it and extracts a structured inventory manifest. We can then review, edit, and confirm the detected items, adding missing ones or fixing quantities before proceeding."*

2. **Actions**:
   - Select **Bahria Phase 8** as Pickup and **G-13 Islamabad** as Drop-off.
   - Toggle **Evaluation Mode** (Agent Trace) in the AppBar.
   - Tap **"Upload Room Photo"** and select mock photos.
   - Show how the app extracts the structured inventory manifest, highlighting weight classes and fragility.
   - Edit a quantity and confirm the manifest items.
   - Click **"Analyze Request"** to move to the **Confirm Moving Details Screen**.
   - Point out how price and mover ranking will adapt based on the heavy and fragile items confirmed in this manifest.

---

## Part 3: Complexity, Risk & Scheduling (1:15 - 2:00)

1. **Presenter Narration**:
   > *"Clicking 'Proceed' sends our parsed data to the Complexity and Scheduling Agents. The app categorizes items into fragile, heavy, and standard. Since we bypassed the photo verification, the Risk and Resource Analysis displays an 'Insufficient inventory data' warning. The pricing engine also marks quotes as 'Low-Confidence Estimate' due to the unverified inventory. The Scheduling Agent warns us about gated community gate lockouts after 9 PM, helping the customer avoid delays."*

2. **Actions**:
   - Click **"Proceed"** to go to the **Inventory & Complexity Screen**. Note the **Insufficient inventory data** warnings under Access Risk.
   - Click **"Proceed to Schedule Check"**. Point out the scheduling trace cards and warning flags.

---

## Part 4: Matcher, Map Routing & Pricing Engine (2:00 - 2:45)

1. **Presenter Narration**:
   > *"Now we move to matching. SafeShift AI renders an interactive OpenStreetMap displaying the routing path and distance. Below the map, we see our matched local movers. Each quote is generated deterministically by the Pricing Agent, adding specific surcharges for stairs and fragile items. Let's inspect 'Reliable Packers'."*

2. **Actions**:
   - Click **"Find Available Movers"** to open the **Live Bidding Screen**.
   - Show the interactive map zooming in on Islamabad/Rawalpindi coordinate polyline.
   - Tap **"Transparent Price Breakdown"** on Costa Logistics or Reliable Packers to show the exact surcharges.
   - Tap **"Review Evidence Summary"** on Reliable Packers. Show the deterministic review evidence counts (hidden charges, fragile damage, delay issues), data provenance (Google Maps source URL, confidence %), and synthetic MVP review samples label.
   - Point out that **"Budget Loaderz"** is flagged as "High Risk" due to review complaints about hidden surcharges.

---

## Part 5: Chat, Booking & Conflict Recovery (2:45 - 3:30)

1. **Presenter Narration**:
   > *"If we select a registered certified partner like Reliable Packers, we can chat with them in-app — with a simulated prototype response powered by Gemini, clearly labeled as 'prototype demo response.' But if we select a publicly discovered mover like Costa Logistics, SafeShift dynamically drafts an outreach message detailing our items, constraints, and locked price, allowing copy-paste into WhatsApp or direct call. Let's select Reliable Packers, connect to chat, and book them. Next, we'll simulate a real-world conflict: the mover gets delayed. The Recovery Agent immediately steps in to recommend backups with a Rs. 500 delay rebate."*

2. **Actions**:
   - Tap **"Connect & Chat (Certified)"** on **Reliable Packers**.
   - Send a chat message (e.g. "discount milega?"). Show the Roman Urdu simulated driver response.
   - (Optional) Go back and select Costa Logistics to briefly show the **AI Outreach Assistant** page with the drafted Roman Urdu message and clipboard copying.
   - Return to Reliable Packers, click **"BOOK NOW"** to reach the Confirmation Screen.
   - Click **"Simulate Delay / Cancellation"** (or use the simulation button on the bidding screen).
   - Show the **Recovery Screen** scanning backups, recommending Zain Packers with the rebate, and offering a one-click switch. Click **"Switch to Backup Now"**.

---

## Part 6: Damage Disputes & Baseline Comparison (3:30 - 4:15)

1. **Presenter Narration**:
   > *"If an item breaks during shifting, SafeShift AI uses Gemini to analyze damage claims. We describe the damage and upload a photo (or use a demo mock). The Dispute Agent reviews the claim and recommends a compensation amount — but clearly states this requires human operator approval before any real payout. Let's also look at the Baseline Comparison to see the formula-based risk scores: sorting by cheapest price yields a risk score of 80+, while SafeShift's recommended provider scores below 20."*

2. **Actions**:
   - On the Confirmation screen, click **"Report Damage / Missing Item"**.
   - Input description and click **"Submit Claim to AI Agent"**. Point out the AI-recommended compensation and the prototype notice that human review is required.
   - Navigate to the **Baseline Comparison Screen** (accessible via the Live Bidding page icon).
   - Contrast the Traditional Sort (picking Budget Loaderz, leading to broken tables and hidden fees) against SafeShift's Risk-Mitigating Agentic selection.
   - Conclude the video.
