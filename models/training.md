# SleepScorePredictor Training Guide

This document outlines how to train a simple regression model for SleepSense using **Python**, **scikit-learn**, and **coremltools**, targeting **Xcode 12.5 / iOS 14** compatibility.

## 1. Prepare your training data

Each row should represent one night of sleep:

- `duration` – total sleep duration in seconds (or hours)
- `deepPct` – percentage of time in deep sleep (0–1)
- `remPct` – percentage of time in REM sleep (0–1)
- `awakePct` – percentage of time awake after sleep onset (0–1)
- `score` – target sleep score you want the model to learn (0–100)

Example CSV header:

```csv
duration,deepPct,remPct,awakePct,score
28800,0.25,0.20,0.05,82
25200,0.18,0.18,0.12,70
...
```

## 2. Create a Python environment

Use Python 3.8+ and install dependencies:

```bash
python -m venv venv
source venv/bin/activate
pip install numpy pandas scikit-learn coremltools==4.1
```

> coremltools 4.x is compatible with Xcode 12.5. Newer versions may require newer Xcode/iOS.

## 3. Train a simple regression model

Example script `train_sleep_score_model.py`:

```python
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error
import coremltools as ct

# 1) Load data
csv_path = "sleep_data.csv"  # update with your path
df = pd.read_csv(csv_path)

feature_cols = ["duration", "deepPct", "remPct", "awakePct"]
X = df[feature_cols]
y = df["score"]

# 2) Train / test split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# 3) Train model (Random Forest for robustness)
model = RandomForestRegressor(
    n_estimators=200,
    max_depth=8,
    random_state=42,
)
model.fit(X_train, y_train)

# 4) Evaluate
preds = model.predict(X_test)
mae = mean_absolute_error(y_test, preds)
print(f"MAE: {mae:.2f}")

# 5) Convert to Core ML
input_features = [
    ("duration", ct.models.datatypes.Array(1)),
    ("deepPct", ct.models.datatypes.Array(1)),
    ("remPct", ct.models.datatypes.Array(1)),
    ("awakePct", ct.models.datatypes.Array(1)),
]

mlmodel = ct.converters.sklearn.convert(
    model,
    input_features,
    output_feature_names=["score"],
)

mlmodel.author = "SleepSense"
mlmodel.short_description = "Predicts a nightly sleep score based on duration and sleep stage percentages."
mlmodel.save("SleepScorePredictor.mlmodel")
print("Saved SleepScorePredictor.mlmodel")
```

You can simplify the datatype definitions (e.g., use `double` inputs) depending on your converter/version. The key is that the **input names** match what the app uses.

## 4. Integrate the model into Xcode

1. Run the training script; it will produce `SleepScorePredictor.mlmodel`.
2. Drag the generated `.mlmodel` into Xcode under `SleepSense/Models/`, replacing the stub.
3. Make sure the file is included in the **SleepSense** target.
4. Build the project once; Xcode will generate Swift classes (if you prefer using the typed API).

## 5. Matching app features

The app expects the model to use:

- Inputs: `duration`, `deepPct`, `remPct`, `awakePct` (all numeric)
- Output: `score` (0–100, double)

If you change feature names or ranges, also update:

- `CoreMLService.swift` feature provider keys
- Any normalization logic (e.g., scaling duration from seconds to hours).

## 6. Iterating on the model

- Experiment with different regressors (e.g., GradientBoostingRegressor, XGBoost if you’re comfortable adding it).
- Try adding more features: bedtime hour, wake time, variability metrics, previous-night sleep, etc.
- Track MAE or RMSE and compare versions before shipping a new model.

When you’re happy with a new model:

1. Save it as `SleepScorePredictor.mlmodel`.
2. Replace the file in your Xcode project.
3. Rebuild and test predictions on-device.
