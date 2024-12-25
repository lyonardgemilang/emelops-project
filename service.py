import mlflow
import mlflow.pyfunc
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import numpy as np
import threading
import time
import logging

# Configure logging
logging.basicConfig(
    filename="/app/logs/app.log",  # Ensure this path is writable in Docker
    level=logging.INFO,  # Set logging level to INFO
    format="%(asctime)s [%(levelname)s] %(message)s"
)
logger = logging.getLogger("fastapi_app")

# Define FastAPI app
app = FastAPI()

# Pydantic model for request validation
class PredictionRequest(BaseModel):
    features: list[float]

# Function to fetch the latest production model
def fetch_production_model():
    try:
        client = mlflow.tracking.MlflowClient()
        logger.info("Connecting to MLflow...")
        models = client.search_model_versions(
            "name='Deployment_Model'"  # Replace with your model name
        )
        logger.info(f"Found models: {models}")

        if not models:
            logger.error("No registered models found.")
            raise Exception("No registered models found.")

        latest_model = max(models, key=lambda x: int(x.version))
        logger.info(f"Loading model version: {latest_model.version}")
        return mlflow.pyfunc.load_model(latest_model.source)
    except Exception as e:
        logger.exception("Error fetching production model")
        raise

# Load the current registered model
current_model = None

def load_model():
    global current_model
    try:
        current_model = fetch_production_model()
        logger.info("Model loaded successfully.")
    except Exception as e:
        logger.error(f"Error fetching model: {e}")

# Set MLflow tracking URI
mlflow.set_tracking_uri("http://localhost:5000")  # Ensure your MLflow server is running

# Load the model initially
load_model()

@app.get("/status")
def status():
    if current_model:
        logger.info("Status check: Model loaded successfully.")
        return {"status": "Model loaded successfully."}
    else:
        logger.warning("Status check: No model available.")
        return {"status": "No model available."}

@app.post("/predict")
def predict(request: PredictionRequest):
    global current_model
    if not current_model:
        logger.error("Prediction request failed: No model available.")
        raise HTTPException(
            status_code=503, detail="No model available for predictions."
        )
    try:
        features = np.array(request.features).reshape(1, -1)
        logger.info(f"Received prediction request: {request.features}")
        prediction = current_model.predict(features)
        logger.info(f"Prediction result: {prediction.tolist()}")
        return {"prediction": prediction.tolist()}
    except Exception as e:
        logger.exception("Error during prediction")
        raise HTTPException(status_code=500, detail=str(e))

# Background task to refresh the model periodically
def refresh_model():
    global current_model
    while True:
        try:
            updated_model = fetch_production_model()
            if updated_model != current_model:
                current_model = updated_model
                logger.info("Model updated successfully.")
        except Exception as e:
            logger.error(f"Error updating model: {e}")
        time.sleep(60)  # Check for updates every 60 seconds

# Start the background thread
thread = threading.Thread(target=refresh_model, daemon=True)
thread.start()
