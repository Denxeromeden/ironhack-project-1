FROM python:3.12.15-slim-trixie@sha256:16bf2b5c59a08523519d3c8589deca849285dee1d62a3653e124c3dba340f15e AS base

RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

ENV REDIS_HOST=redis
ENV REDIS_PORT=6379

FROM base AS final

COPY . .

EXPOSE 80

CMD ["gunicorn", "app:app", "-b", "0.0.0.0:80", "--log-file", "-", "--access-logfile", "-", "--workers", "4", "--keep-alive", "0"]