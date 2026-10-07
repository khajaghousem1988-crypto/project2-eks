FROM python:3.12-slim

# ------------------------------------------------------------
# Environment
# ------------------------------------------------------------
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    TMPDIR=/tmp

WORKDIR /app

# ------------------------------------------------------------
# Install OS security updates
# ------------------------------------------------------------
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Install Python dependencies
# ------------------------------------------------------------
COPY requirements.txt .

RUN python -m pip install --no-cache-dir --upgrade pip \
    && python -m pip install --no-cache-dir -r requirements.txt \
    && python -m pip install --no-cache-dir --upgrade \
       "msgpack>=1.2.1" \
       "setuptools>=78.1.1"

# ------------------------------------------------------------
# Remove stale vulnerable package metadata if present
# ------------------------------------------------------------
RUN find /usr/local/lib/python3.12/site-packages \
    -type d \
    \( -name "msgpack-1.1.2.dist-info" \
       -o -name "setuptools-70.3.0.dist-info" \) \
    -prune -exec rm -rf {} +

# ------------------------------------------------------------
# Copy application
# ------------------------------------------------------------
COPY . .

# ------------------------------------------------------------
# Create non-root application user
#
# Do NOT add "USER appuser" here.
# Gunicorn master starts as root so it can use the writable
# ECS /tmp mount. Gunicorn workers are dropped to appuser.
# ------------------------------------------------------------
RUN useradd --create-home \
    --shell /usr/sbin/nologin \
    appuser \
    && chown -R appuser:appuser /app

EXPOSE 5000

# ------------------------------------------------------------
# Start application
# ------------------------------------------------------------
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--threads", "2", "--timeout", "60", "--worker-tmp-dir", "/tmp", "--user", "appuser", "--group", "appuser", "app:app"]