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

# Paths
INI_FILE_PATH="/app/auth_temp.ini"
FINAL_INI_FILE_PATH="/app/auth.ini"

echo "Modifying .ini Configuration with Environment Variables:"
echo "------------------------------------"

# Create a new .ini file with substitutions
sed "s/\${POSTGRES_USER}/$POSTGRES_USER/g;
     s/\${POSTGRES_PASSWORD}/$POSTGRES_PASSWORD/g;
     s/\${POSTGRES_URL}/$POSTGRES_URL/g;
     s/\${DB_URL}/$DB_URL/g;
     s/\${POSTGRES_DB}/$POSTGRES_DB/g;
     s/\${MLFLOW_ADMIN_USERNAME}/$MLFLOW_ADMIN_USERNAME/g;
     s/\${MLFLOW_ADMIN_PASSWORD}/$MLFLOW_ADMIN_PASSWORD/g" "$INI_FILE_PATH" > "$FINAL_INI_FILE_PATH"

# Verify the modified .ini contents
echo "Updated .ini file contents after substitution:"
cat "$FINAL_INI_FILE_PATH"
echo "------------------------------------"

# Run mlflow server with the new .ini file
mlflow server --app-name basic-auth \
  --backend-store-uri "postgresql+psycopg2://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${DB_URL}/${POSTGRES_DB}" \
  --host "0.0.0.0" \
  --port "5000" \
  --serve-artifacts \
  --default-artifact-root "gs://${GCS_BUCKET_NAME_TRACKER}" \
  --gunicorn-opts "--log-level=debug" \
  --gunicorn-opts "--timeout 120 --workers 2" \
