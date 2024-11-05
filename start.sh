#!/bin/sh

echo "Environment Variables for Debugging:"
echo "------------------------------------"
echo "POSTGRES_USER: $POSTGRES_USER"
echo "POSTGRES_PASSWORD: $POSTGRES_PASSWORD"
echo "POSTGRES_DB: $POSTGRES_DB"
echo "POSTGRES_URL: $DB_URL"
echo "GCS_BUCKET_NAME_TRACKER: $GCS_BUCKET_NAME_TRACKER"
echo "GOOGLE_APPLICATION_CREDENTIALS: $GOOGLE_APPLICATION_CREDENTIALS"
echo "------------------------------------"

# Run mlflow server with the new .ini file
mlflow server --app-name basic-auth \
  --backend-store-uri "postgresql+psycopg2://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${DB_URL}/${POSTGRES_DB}" \
  --host "0.0.0.0" \
  --port "5000" \
  --serve-artifacts \
  --default-artifact-root "gs://${GCS_BUCKET_NAME_TRACKER}" \
