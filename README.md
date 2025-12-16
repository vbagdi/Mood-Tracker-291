

<img width="203" height="382" alt="moodtracker" src="https://github.com/user-attachments/assets/303a27c1-40c7-4ba2-bf79-677eb354fdf7" />


# Mood Tracker iOS App

An iOS application that helps users understand their daily wellbeing by tracking behavioral data and predicting mood patterns using machine learning.

## Overview

This project explores whether sleep and activity patterns can predict end-of-day mood. We built a native iOS app that collects behavioral data via Apple HealthKit and uses ML classification models to identify mood patterns.

## Features

- **Automatic Health Data Collection**: Steps, distance, flights climbed via HealthKit
- **Daily Mood Logging**: 1-5 Likert scale mood ratings
- **Sleep Tracking**: Manual sleep duration entry
- **Push Notifications**: Morning (8 AM) and evening (9 PM) reminders
- **Real-time Sync**: Firebase Firestore backend for cross-device data access
- **Trend Visualization**: Charts showing mood and activity over time

## Tech Stack

| Component | Technology |
|-----------|------------|
| Frontend | SwiftUI |
| Health Data | Apple HealthKit |
| Backend | Firebase Firestore |
| Notifications | UserNotifications |
| ML Models | scikit-learn (Python) |

## Machine Learning

We trained three classification models to predict mood (1-5) from behavioral features:

| Model | Overall Accuracy | Best Individual Accuracy |
|-------|------------------|--------------------------|
| Logistic Regression | 43% | 60% (Asif, Mizuho) |
| Decision Tree | 53% | 76% (Asif) |
| K-Nearest Neighbors | 64% | 72% (Mizuho) |

**Key Finding**: Individual models outperform aggregated models significantly, suggesting mood patterns are highly personalized.

## Data Collection

- **Duration**: 25 days (Nov 11 - Dec 5, 2025)
- **Participants**: 4 users
- **Features**: mood, sleep, steps, distance, flights climbed

## Project Structure

```
├── MoodTracker/          # iOS app source code
│   ├── Views/            # SwiftUI views
│   ├── Models/           # Data models
│   └── Services/         # HealthKit & Firebase services
├── analysis/             # Python notebooks for ML
└── data/                 # Collected mood data
```

## Key Takeaways

1. **Personalized patterns exist**: Each user shows distinct mood rhythms
2. **Aggregation hurts accuracy**: Cross-user models perform worse than individual models
3. **More data needed**: 25 days is insufficient for robust mood prediction
4. **Activity correlates with mood**: Distance and steps show moderate correlation for some users

## Future Work

- Integrate wearable data (Apple Watch, Fitbit)
- Apply time-series models (LSTM, Transformer)
- Add geospatial/contextual features
- Build adaptive per-user models
- Real-time mood intervention suggestions

## Team

Vinayak Bagdi, Asif Mahdin, Ashley Ho, Mizuho Fukuda

*DSC 291 - Mobile Computing, UC San Diego*
