import mlflow
import mlflow.pyfunc
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import numpy as np
import threading
import time

# Define FastAPI app
app = FastAPI()


# Pydantic model for request validation
class PredictionRequest(BaseModel):
    features: list[float]


# Function to fetch the latest production model
def fetch_production_model():
    client = mlflow.tracking.MlflowClient()
    print("Connecting to MLflow...")
    models = client.search_model_versions(
        "name='Deployment_Model'"
    )  # Ganti dengan nama model
    print(f"Found models: {models}")

    if not models:
        raise Exception("No registered models found.")

    latest_model = max(models, key=lambda x: int(x.version))
    print(f"Loading model version: {latest_model.version}")
    return mlflow.pyfunc.load_model(latest_model.source)


# Load the current registered model
current_model = None


def load_model():
    global current_model
    try:
        current_model = fetch_production_model()
        print("Model loaded successfully.")
    except Exception as e:
        print(f"Error fetching model: {e}")


# Set MLflow tracking URI
mlflow.set_tracking_uri(
    "http://localhost:5000"
)  # Pastikan server MLflow berjalan di sini

# Load the model initially
load_model()


@app.get("/status")
def status():
    if current_model:
        return {"status": "Model loaded successfully."}
    else:
        return {"status": "No model available."}


@app.post("/predict")
def predict(request: PredictionRequest):
    global current_model
    if not current_model:
        raise HTTPException(
            status_code=503, detail="No model available for predictions."
        )
    try:
        features = np.array(request.features).reshape(1, -1)
        prediction = current_model.predict(features)
        return {"prediction": prediction.tolist()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# Background task to refresh the model periodically
def refresh_model():
    global current_model
    while True:
        try:
            updated_model = fetch_production_model()
            if updated_model != current_model:
                current_model = updated_model
                print("Model updated successfully.")
        except Exception as e:
            print(f"Error updating model: {e}")
        time.sleep(60)  # Check for updates every 60 seconds


# Start the background thread
thread = threading.Thread(target=refresh_model, daemon=True)
thread.start()