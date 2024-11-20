# Variabel
VENV_DIR = venv
PYTHON = $(VENV_DIR)/bin/python
PIP = $(VENV_DIR)/bin/pip
NOTEBOOKS_DIR = notebooks
NOTEBOOKS = Example.ipynb Example_cloud.ipynb Example_local.ipynb
MLFLOW_SERVER_PORT = 8888
MLFLOW_BACKEND_STORE = ./mlruns
MLFLOW_ARTIFACT_STORE = ./mlartifacts

# Target untuk membuat virtual environment
$(VENV_DIR)/bin/activate: requirements.txt
	@echo "Membuat virtual environment..."
	python3 -m venv $(VENV_DIR)
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

# Menjalankan MLflow Tracking Server
mlflow_server: $(VENV_DIR)/bin/activate
	@echo "Menjalankan MLflow Tracking Server di port $(MLFLOW_SERVER_PORT)..."
	$(VENV_DIR)/bin/mlflow server \
		--backend-store-uri $(MLFLOW_BACKEND_STORE) \
		--default-artifact-root $(MLFLOW_ARTIFACT_STORE) \
		--port $(MLFLOW_SERVER_PORT)

# Menjalankan notebook 'Example.ipynb'
run_example: $(VENV_DIR)/bin/activate
	@echo "Menjalankan notebook Example.ipynb..."
	$(VENV_DIR)/bin/jupyter nbconvert --to notebook --execute $(NOTEBOOKS_DIR)/Example.ipynb --inplace

# Menjalankan notebook 'Example_cloud.ipynb'
run_example_cloud: $(VENV_DIR)/bin/activate
	@echo "Menjalankan notebook Example_cloud.ipynb..."
	$(VENV_DIR)/bin/jupyter nbconvert --to notebook --execute $(NOTEBOOKS_DIR)/Example_cloud.ipynb --inplace

# Menjalankan notebook 'Example_local.ipynb'
run_example_local: $(VENV_DIR)/bin/activate
	@echo "Menjalankan notebook Example_local.ipynb..."
	$(VENV_DIR)/bin/jupyter nbconvert --to notebook --execute $(NOTEBOOKS_DIR)/Example_local.ipynb --inplace

# Menjalankan semua notebook
run_all_notebooks: run_example run_example_cloud run_example_local

# Membersihkan environment
clean:
	@echo "Menghapus virtual environment dan file sementara..."
	rm -rf $(VENV_DIR)
	rm -rf __pycache__

# Bantuan
help:
	@echo "Gunakan make <target>:"
	@echo "  mlflow_server       - Menjalankan MLflow Tracking Server"
	@echo "  run_example         - Menjalankan notebook Example.ipynb"
	@echo "  run_example_cloud   - Menjalankan notebook Example_cloud.ipynb"
	@echo "  run_example_local   - Menjalankan notebook Example_local.ipynb"
	@echo "  run_all_notebooks   - Menjalankan semua notebook"
	@echo "  clean               - Membersihkan environment"

# Default target
.DEFAULT_GOAL := help
