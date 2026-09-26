# 🥗 NutriGo — Smart AI Nutrition & Wellness Ecosystem

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-2E7D32?style=for-the-badge)

**NutriGo** holo ekta all-in-one smart mobile health ebong nutrition application ja Computer Vision AI, structured habit tracking, gamification ebong automated vector PDF reporting eksathe provide kore. Traditonal jhamelapurna calorie counting-er poriborte NutriGo instant meal recognition ebong clinical-grade tracking deliver kore.

---

## 🚀 Key Features

### 🤖 1. Smart AI Food Scanner & Macronutrient Breakdown
- **Instant Photo Recognition:** Camera diye khabarer chobi tolar shathe shathe AI dish detect kore ebong assigned diet targets-er sathe match kore.
- **Detailed Macro Analysis:** Calories, Protein (g), Carbohydrates (g), Fat (g), ebong Dietary Fiber (g) er precision metrics show kore.
- **Healthy Status & Feedback:** Khabarer quality onujayi "Healthy" ba "Needs Improvement" status ebong AI dietary feedback provide kore.

### 🍽️ 2. Daily Meal Missions & Habit Formation
- **Three-Tier Daily Goals:** Breakfast, Lunch, ebong Dinner-er structured daily tasks.
- **Diurnal Time Window Detection:** Shokal (05:00-11:00) ebong rat (18:00-23:00) er meal windows auto-match kore task status update kore.
- **Dynamic Suggestions:** Julian calendar day logic use kore daily fresh meal ideas show kore.

### 📚 3. Guided Nutrition Curriculum
- **Structured Pathways:** 4-ti complete nutrition tracks jekhane total 44-ti guided lessons royeche.
- **Sequential Unlocking:** Previous lesson shesh na hole porer lesson lock thake.
- **Spaced-Repetition Cooldown:** Proti lesson seshe 6-ghontar cooldown window enforce kora hoy jate learning retention maximum thake.

### 🎮 4. Gamification, Streaks & Leaderboard
- **90-Day Cyclical Scoring:** Meals (+1 pt), Lessons (+3 pts), ebong Analysis (+1 pt) er dynamic point accumulation.
- **Quarterly Score Archive:** Proti 90-din por por current cycle points `score_history` te auto-archive hoy ebong fresh cycle start hoy.
- **Day Streaks & Leaderboard:** Active participation er jonno dynamic fire streak counter (🔥) ebong global ranking leaderboard.

### 👥 5. Community & Social Feed
- Healthy meals share kora, community meal photos dekha ebong inter-user likes/cheers er moddhome social motivation build kora.

### 📄 6. Two-Page Vector PDF Health Report Engine
- **Multi-Source Aggregation:** Firestore profile data, local SharedPreferences meal logs ebong completed courses aggregate kore clinical-grade report banay.
- **Vector PDF Layout:**
  - **Page 1:** User biometrics, BMI, overall health score, scanned foods list ebong course progression summary.
  - **Page 2:** Puro masher 31-day activity completion matrix (Breakfast, Dinner, Daily Tasks).
- **Native Platform Channels:** Dedicated **Download** (device local storage save) ebong **Share** (WhatsApp, Mail etc.) button actions.

---

## 🏗️ System Architecture & Data Engineering

NutriGo ekta hybrid **Cloud + Local Storage Engine** use kore:
