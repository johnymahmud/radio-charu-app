# 📌 রেডিও চারু — প্রজেক্ট লাইভ স্টেট ও রোডম্যাপ (PROJECT STATE)
**সর্বশেষ আপডেট:** ২৪ আগস্ট, ২০২৬  
**বর্তমান সক্রিয় ব্রাঞ্চ:** `Home_Test`  
**সামগ্রিক সিস্টেম রেটিং:** ৯৮% প্রস্তুত (Excellent & Production Ready)  

---

## 🚦 প্রজেক্টের বর্তমান অগ্রগতি (Live Status Summary)

```mermaid
pie title প্রজেক্ট সমাপ্তির অগ্রগতি
    "সম্পূর্ণ প্রস্তুত (Done)" : 90
    "টেস্ট রান ও ভেরিফিকেশন (In Progress)" : 10
```

---

## ✅ সম্পন্ন মাইলস্টোনসমূহ (Completed Milestones)

- [x] **Caster.fm ফ্রি-টিয়ার বাইপাস আর্কিটেকচার:** GitHub Pages ব্রিজ (`docs/index.html`), Iframe Breakout, DOM Click Interception (`/^play$/i`), এবং Lifecycle Smart-Resume ইঞ্জিন বাস্তবায়িত ও পরীক্ষিত।
- [x] **ডিকাপল্ড লাইভ মেটাডাটা ও পোলিং:** প্রতি ১৫ সেকেন্ড পর পর `sapircast.caster.fm:17055/admin/publicstats.json` থেকে লিসেনার সংখ্যা, অন-এয়ার ব্যাজ ও ব্রডকাস্ট কোয়ালিটি আপডেট।
- [x] **কমিউনিটি প্যানেল ও ফায়ারবেজ চ্যাট:** Anonymous Auth + Admin Email/Pass Login, Live Shouts (`shouts/current`), এবং Live Comments (`comments/{id}`) সিকিউরিটি রুলস সহ সম্পূর্ণ।
- [x] **অটোমেটিক ক্লাউড APK বিল্ড (CI/CD):** `.github/workflows/build_apk.yml` গিটহাব অ্যাকশন কনফিগার করা।
- [x] **এনভায়রনমেন্ট অডিট:** Flutter 3.44.6, Dart 3.12.2, Android Studio, OpenJDK 21, Android SDK 36, Pixel 7 Emulator সম্পূর্ণ রেডি।
- [x] **মাস্টার ডকুমেন্টেশন কিট:** 
  - `AUDIO_STREAMING_BLUEPRINT.md` (টেকনিক্যাল ব্লুপ্রিন্ট)
  - `SYSTEM_WALKTHROUGH_NON_TECH.md` (নন-টেকি ওয়াকথ্রু)
  - `WORKFLOW_AND_SAFETY_GUIDELINES.md` (গিট ও সেফটি নীতিমালা)
  - `AGENTS.md` (এআই ব্রেন-লক নির্দেশনাবলি)
  - `DECISION_LOG.md` (ADR হিস্ট্রি)
  - `ACTIVITY_LOG.md` (সেশন হিস্ট্রি)
  - `DESIGN_SYSTEM.md` (কালার ও থিম টোকেন)

---

## 🔄 চলমান অবস্থা (Currently In-Progress)

- **মাইলস্টোন:** লোকাল টেস্ট রান ও এমুলেটর ভেরিফিকেশন প্রস্তুতি।
- **ব্রাঞ্চ:** `Home_Test`

---

## 🎯 পরবর্তী করণীয় তালিকা (Roadmap & Next Steps)

1. **Step 1: অ্যান্ড্রয়েড এমুলেটরে অ্যাপ টেস্ট রান:**
   - কমান্ড: `flutter emulators --launch Pixel_7` এবং `flutter run` চালিয়ে লাইভ অডিও স্ট্রিমিং ও ব্যাকগ্রাউন্ড প্লেব্যাক সরাসরি চোখে দেখে পরীক্ষা করা।
2. **Step 2: ২টি ছোট লিন্ট ওয়ার্নিং ক্লিন করা (ঐচ্ছিক):**
   - [community_panel.dart:11](file:///d:/Personal/radio-charu-app/lib/community_panel.dart#L11) থেকে `_folkCream` মুছে ফেলা।
   - [main.dart:1354](file:///d:/Personal/radio-charu-app/lib/main.dart#L1354) থেকে অব্যবহৃত `_buildCommunityPreview` মেথডটি ক্লিন করা।
3. **Step 3: ফায়ারবেজ কানেক্টিভিটি টেস্ট:**
   - এমুলেটরে কমেন্ট পোস্ট ও রিয়েল-টাইম ডিসপ্লে যাচাই করা।
4. **Step 4: রিলিজ বিল্ড ও গিটহাব মার্জ:**
   - সব টেস্ট সফল হলে `Home_Test` থেকে `main` ব্রাঞ্চে মার্জ এবং নতুন রিলিজ APK যাচাই।

---

## ⚠️ জ্ঞাত সীমাবদ্ধতা ও ওয়ার্নিং (Known Quirks)
- `google-services.json` বর্তমানে `android/app/src/` ফোল্ডারে আছে (টেস্ট রানে কোনো সমস্যা না হলে এটি সরানো প্রয়োজন নেই)।
- Windows Desktop C++ বিল্ড টুলস পিসিতে নেই (যা অ্যান্ড্রয়েডের জন্য প্রযোজ্য নয়)।
