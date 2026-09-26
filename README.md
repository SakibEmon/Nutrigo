# 🥗 NutriGo — Smart AI Nutrition & Wellness Ecosystem

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-2E7D32?style=for-the-badge)

**NutriGo** is a comprehensive, AI-powered health and wellness mobile application designed to simplify personal nutrition tracking. Replacing tedious manual calorie counters, NutriGo leverages Computer Vision AI for instant meal logging, structured daily habit missions, gamified score cycles, and clinical-grade multi-page vector PDF reporting.

---

## 🚀 Key Features

### 🤖 1. Smart AI Food Scanner & Macronutrient Profiler
- **Instant Image Recognition:** Snap a photo of any meal to identify the food type and evaluate dietary matches in real time.
- **Detailed Macronutrient Profiling:** Automatically extracts and computes precision values for Calories, Protein (g), Carbohydrates (g), Fat (g), and Dietary Fiber (g).
- **Nutritional Quality Classification:** Generates an immediate "Healthy" or "Needs Improvement" assessment alongside personalized dietary feedback.

### 🍽️ 2. Daily Meal Missions & Habit Tracking
- **Three-Tier Daily Goals:** Structured logging targets for Breakfast, Lunch, and Dinner to maintain daily eating discipline.
- **Diurnal Time Window Detection:** Automatically categorizes meals into morning (05:00–11:00) and evening (18:00–23:00) eating periods to track adherence seamlessly.
- **Dynamic Meal Recommendations:** Rotates curated recipe suggestions using Julian calendar day calculations to prevent meal plan fatigue.

### 📚 3. Guided Nutrition Curriculum
- **Structured Learning Roadmaps:** 4 complete nutrition tracks comprising 44 interactive, bite-sized lessons.
- **Sequential Pacing:** Enforces prerequisite-based lesson unlocking to ensure steady, structured learning.
- **Spaced-Repetition Cooldown:** Implements a mandatory 6-hour cooldown window between lesson completions to encourage real-world implementation.

### 🎮 4. Gamification, Streaks & Leaderboard
- **Dynamic 90-Day Score Cycles:** Users earn points for logged meals (+1 pt), finished lessons (+3 pts), and AI analyses (+1 pt).
- **Automated Cycle Archiving:** Automatically preserves scores into the user's `score_history` sub-collection every 90 days before resetting the cycle.
- **Day Streaks & Social Rankings:** Features active fire streaks (🔥) and an interactive leaderboard to encourage consistent daily engagement.

### 👥 5. Community & Social Meal Feed
- Share healthy plates, review community meal submissions, and motivate peers with reactions and positive feedback.

### 📄 6. Multi-Page Vector PDF Health Report Engine
- **Multi-Source Data Aggregation:** Aggregates remote user profile data from Firestore with local meal histories and course progress from SharedPreferences.
- **Two-Page Vector Document:**
  - **Page 1:** Summarizes personal biometrics, BMI, health scores, scanned food logs, and course completion metrics.
  - **Page 2:** Displays a complete day-by-day compliance matrix tracking Breakfast, Dinner, and Daily Tasks.
- **Native Action Channels:** Features dedicated **Download** (saving directly to local device storage) and **Share** (system share sheet integration) buttons.

---

## 🏗️ System Architecture & Data Engineering

NutriGo implements a dual **Cloud + Local Storage Engine** for high reliability and low latency:
