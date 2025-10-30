# --- Stage 1: The Builder ---
# This stage installs build-time dependencies and Python packages
FROM python:3.13-slim AS builder

WORKDIR /app

# Install build-time system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Install Python dependencies into a virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir -r requirements.txt


# --- Stage 2: The Final Image ---
# This stage builds the final, lightweight image for production
FROM python:3.13-slim

WORKDIR /app

# Install *runtime* system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Copy the virtual environment from the builder stage
COPY --from=builder /opt/venv /opt/venv

# Set the venv path
ENV PATH="/opt/venv/bin:$PATH"

# Copy the rest of the project files
COPY . .

# --- This is the key section for handling secrets ---

# 1. Declare ARGs that will be passed from the 'docker build' command.
ARG SECRET_KEY
ARG DJANGO_SETTINGS_MODULE="my_finance_backend.settings.production"
ARG DEBUG="False"

# New individual database credentials
ARG DB_NAME
ARG DB_USER
ARG DB_PASSWORD
ARG DB_HOST
ARG DB_PORT="5432"

# 2. Set the ENV variables from the ARGs.
ENV SECRET_KEY=${SECRET_KEY}
ENV DJANGO_SETTINGS_MODULE=${DJANGO_SETTINGS_MODULE}
ENV DEBUG=${DEBUG}

# Set environment variables for the new database configuration
ENV DB_NAME=${DB_NAME}
ENV DB_USER=${DB_USER}
ENV DB_PASSWORD=${DB_PASSWORD}
ENV DB_HOST=${DB_HOST}
ENV DB_PORT=${DB_PORT}

ENV PYTHONUNBUFFERED=1

# --- End of key section ---

# Run collectstatic (this build step requires the ENV vars above to be set)
RUN python manage.py collectstatic --noinput

# Expose the port
EXPOSE 8000

# Set the correct CMD (using exec form)
CMD ["gunicorn", "my_finance_backend.wsgi:application", "--bind", "0.0.0.0:8000"]
