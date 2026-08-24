# 📜 রেডিও চারু — সেশন অ্যাক্টিভিটি লগ ও চেঞ্জলগ (ACTIVITY LOG)
**উদ্দেশ্য:** প্রতিটি কাজের সেশন, অডিট, পরিবর্তন ও সিদ্ধান্তের কালানুক্রমিক ইতিহাস  

---

## 🗓️ ২০২৬-০৮-২৪ (সেশন ১: ফায়ারবেজ ও সিস্টেম অডিট এবং মাস্টার মেমোরি কিট স্থাপন)
- **অংশগ্রহণকারী:** Johny Mahmud (Project Owner) & Antigravity AI Assistant
- **সক্রিয় ব্রাঞ্চ:** `Home_Test`

### 🔍 সম্পন্ন অডিট ও ইনভেস্টিগেশন:
1. **Firebase Project Audit:**
   - কনসোল প্রজেক্ট অডিট করা হয়েছে। মোট ২টি প্রজেক্ট চিহ্নিত:
     - `radio-charu-app` (ID: `radio-charu-app`) — সক্রিয় ও মূল অ্যাপের ফায়ারবেজ ব্যাকএন্ড।
     - `fine-arts-club-bangladesh` — পৃথক প্রজেক্ট।
   - নিশ্চিত করা হয়েছে কোনো অতিরিক্ত ডামি প্রজেক্ট নেই এবং ফায়ারবেজ পুরোপুরি গোছানো।
2. **Environment & Toolchain Audit:**
   - Flutter 3.44.6, Dart 3.12.2, Android Studio, OpenJDK 21, Android SDK 36, Pixel 7 Emulator অডিট করে ৯৮% রেডি ঘোষণা করা হয়েছে।
3. **Caster.fm Free Tier Bypass Architecture Audit:**
   - [docs/index.html](index.html) ব্রিজ, Iframe Breakout (`_openDirectCasterPlayer`), Play/Pause DOM ট্র্যাকিং (`_installPlaybackTracking`), এবং Smart Resume (`_attemptSmartResume`) এর বিস্তারিত মেকানিজম পরীক্ষা করা হয়েছে।

### 📦 তৈরি করা ফাইল ও ডকুমেন্টেশন:
- [AGENTS.md](../AGENTS.md) — এআই এজেন্টের অপারেটিং রুলবুক ও গার্ডরেল।
- [docs/AUDIO_STREAMING_BLUEPRINT.md](AUDIO_STREAMING_BLUEPRINT.md) — টেকনিক্যাল আর্কিটেকচার মাস্টার ব্লুপ্রিন্ট।
- [docs/SYSTEM_WALKTHROUGH_NON_TECH.md](SYSTEM_WALKTHROUGH_NON_TECH.md) — সহজ ভাষায় নন-টেকি গাইড ও ওনার্স ওয়াকথ্রু।
- [docs/WORKFLOW_AND_SAFETY_GUIDELINES.md](WORKFLOW_AND_SAFETY_GUIDELINES.md) — ব্রাঞ্চিং ও সেফটি নীতিমালা।
- [docs/PROJECT_STATE.md](PROJECT_STATE.md) — লাইভ স্ট্যাটাস বোর্ড ও রোডম্যাপ।
- [docs/DECISION_LOG.md](DECISION_LOG.md) — আর্কিটেকচারাল ডিসিশন রেকর্ড (ADR)।
- [docs/DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) — লোকজ কালার ও UI ডিজাইন সিস্টেম।
- [README.md](../README.md) — সবগুলোর কেন্দ্রীয় লিঙ্ক আপডেট।

### 🚀 Git Commit & Push:
- কমিট হ্যাশ: `63d34ed` (Branch: `Home_Test`)
- স্ট্যাটাস: ক্লিন ও সফলভাবে সিঙ্কড।

---

## 🗓️ ২০২৬-০৮-২৪ (সেশন ২: লাইভ এমুলেটর ভেরিফিকেশন ও স্ট্রিমিং সাকসেস)
- **অংশগ্রহণকারী:** Johny Mahmud (Project Owner) & Antigravity AI Assistant
- **সক্রিয় ব্রাঞ্চ:** `Home_Test`

### 🎯 সম্পন্ন কার্যকলাপ:
1. **Pixel 7 AVD Launch & USB Debugging:**
   - Pixel 7 এমুলেটর সফলভাবে চালু ও USB Debugging পারমিশন প্রদান।
2. **Flutter Run (`Home_Test`):**
   - `flutter run` চালিয়ে অ্যাপ এমুলেটরে সফলভাবে ইনস্টল ও এক্সিকিউট।
3. **লাইভ স্ট্রিমিং ও UI ভেরিফিকেশন:**
   - **রেডিও চারু** লোকজ ডিজাইন, লাইভ হেডার, এবং **ON AIR** ইন্ডিকেটর নিখুঁতভাবে প্রদর্শিত।
   - Caster.fm ফ্রি টিয়ার অডিও স্ট্রিম এবং **96 KBPS** ব্রডকাস্ট সফলভাবে প্লে হচ্ছে।
   - লাইভ মেটাডাটা পোলিং (`LISTENERS: 1`, `BROADCAST: LIVE`) সক্রিয়।
   - প্লেয়ার ভিজ্যুয়ালাইজার অ্যানিমেশন এবং প্লে/পজ টগল শতভাগ নিখুঁতভাবে কাজ করছে।
4. **স্বয়ংক্রিয় টার্মিনাল রান ও মাল্টি-পিসি সেলফ-হিলিং SOP ডকুমেন্টেশন:**
   - [AGENTS.md](../AGENTS.md) এবং [docs/WORKFLOW_AND_SAFETY_GUIDELINES.md](WORKFLOW_AND_SAFETY_GUIDELINES.md)-এ ভবিষ্যৎ সেশন এবং ভিন্ন মেশিনে এমুলেটর বুট, কনফিগারেশন মিসিং ফিক্স, ডিপেন্ডেন্সি আপডেট এবং স্বয়ংক্রিয় টার্মিনাল পরিচালনার স্থায়ী স্ট্যান্ডার্ড অপারেটিং প্রসিডিউর (SOP) অন্তর্ভুক্ত করা হয়েছে।
5. **রেডিও চারু অফিশিয়াল Favicon ব্র্যান্ডিং:**
   - [docs/favicon.png](favicon.png) হিসেবে রেডিও চারুর গোল লাল-সবুজ লোগোটি স্থাপন এবং [docs/index.html](index.html)-এ Favicon ট্যাগ যুক্ত করা হয়েছে। এর ফলে ব্রাউজার ট্যাবে সার্বক্ষণিকভাবে নিজস্ব ব্র্যান্ড লোগো ফুটে থাকবে।

---

## 🗓️ ২০২৬-০৮-২৪ (সেশন ৩: এমুলেটর ১-ক্লিক ফাস্ট লঞ্চার ও ফায়ারবেজ হোস্টিং অডিট)
- **অংশগ্রহণকারী:** Johny Mahmud (Project Owner) & Antigravity AI Assistant
- **সক্রিয় ব্রাঞ্চ:** `Home_Test`

### 🎯 সম্পন্ন কার্যকলাপ:
1. **Pixel 7 ১-ক্লিক ফাস্ট লঞ্চার স্ক্রিপ্ট:**
   - [run_emulator.bat](../run_emulator.bat) স্ক্রিপ্ট তৈরি করা হয়েছে, যা স্টেল লক স্বয়ংক্রিয়ভাবে ক্লিন করে এবং Host GPU এক্সিলারেশন সহ চোখের পলকে এমুলেটর চালু করে।
2. **Firebase Hosting আর্কিটেকচারাল অডিট:**
   - Caster.fm ব্রিজ হোস্টিংয়ের জন্য GitHub Pages-এর পাশাপাশি Firebase Hosting (`https://radiocharu.web.app`) এর সম্ভাব্যতা ও ফ্রি টিয়ার বিশ্লেষণ সম্পন্ন।

---

## 🗓️ ২০২৬-০৮-২৪ (সেশন ৪: ফায়ারবেজ মাল্টি-সাইট হোস্টিং ডিপ্লয় ও ডুয়াল ফ্রন্টএন্ড রোডম্যাপ)
- **অংশগ্রহণকারী:** Johny Mahmud (Project Owner) & Antigravity AI Assistant
- **সক্রিয় ব্রাঞ্চ:** `firebase_hosting_deploy`

### 🎯 সম্পন্ন কার্যকলাপ:
1. **Firebase Multi-Site Hosting ডিপ্লয়মেন্ট:**
   - Firebase Hosting-এ `radiocharu` সাইট ক্রিয়েট ও ডিপ্লয় সম্পন্ন। লাইভ URL: [https://radiocharu.web.app/](https://radiocharu.web.app/)
2. **Flutter অ্যাপ ইন্টিগ্রেশন:**
   - [lib/main.dart](../lib/main.dart)-এ `_playerUrl` ভেরিয়েবল নতুন দ্রুতগতির `https://radiocharu.web.app/` লিংকে আপডেট করা হয়েছে।
3. **ডুয়াল ফ্রন্টএন্ড আর্কিটেকচার ও ADR-005 নথিভুক্তকরণ:**
   - [docs/DECISION_LOG.md](DECISION_LOG.md)-এ `ADR-005` (Flutter Native Mobile + Firebase Web Portal) যোগ করা হয়েছে।
   - [docs/AUDIO_STREAMING_BLUEPRINT.md](AUDIO_STREAMING_BLUEPRINT.md)-এ সেকশন ৭ (Dual-Platform Ecosystem Architecture) যুক্ত করা হয়েছে।
   - [docs/PROJECT_STATE.md](PROJECT_STATE.md)-এ Web Portal V2 Roadmap (লাইভ স্ট্যাটাস, কমেন্ট বক্স, আরজে শিডিউল) সংরক্ষিত হয়েছে।

---

## 🗓️ ২০২৬-০৮-২৪ (সেশন ৫: মাল্টি-পিসি স্মার্ট এমুলেটর অটো-লঞ্চার বাস্তবায়ন)
- **অংশগ্রহণকারী:** Johny Mahmud (Project Owner) & Antigravity AI Assistant
- **সক্রিয় ব্রাঞ্চ:** `firebase_hosting_deploy`

### 🎯 সম্পন্ন কার্যকলাপ:
1. **মাল্টি-পিসি এনভায়রনমেন্ট অডিট:**
   - বাসা ও অফিসের পিসির মধ্যে গিট সিঙ্কিংয়ের ক্ষেত্রে AVD নামের অমিল (`Pixel_7` vs `Pixel_8`) এবং পাওয়ারশেল সিনট্যাক্স সমস্যা চিহ্নিত করা হয়েছে।
2. **স্মার্ট ডাইনামিক এমুলেটর লঞ্চার (`run_emulator.bat`):**
   - [run_emulator.bat](../run_emulator.bat) আপগ্রেড করা হয়েছে। এটি যেকোনো পিসিতে (বাসা/অফিস) ইনস্টল থাকা AVD স্বয়ংক্রিয়ভাবে ডিটেক্ট (`emulator.exe -list-avds`) করে ১-ক্লিকে ফাস্ট বুট নিশ্চিত করে।
   - জিরো-কনফিগারেশন ও জিরো-মেইনটেন্যান্স নিশ্চিত করা হয়েছে।
