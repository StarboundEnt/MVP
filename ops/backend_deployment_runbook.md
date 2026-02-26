# Backend Deployment Runbook

This guide walks through deploying the Starbound backend (ingestion services + Complexity Profile API) to production using real environment credentials.

## Prerequisites
- Access to production Kubernetes cluster (or hosting environment) with permissions to deploy.
- Secrets stored in your secret manager (e.g., AWS Secrets Manager, GCP Secret Manager) under the key `starbound/backend/prod`.
- CI runner or local machine with Docker, kubectl (or equivalent), and access to the private container registry.
- Latest code with passing tests (`python3 -m unittest ...`).

## 1. Prepare Release Candidate
1. `git checkout main` and `git pull` to ensure you have the latest code.
1a. Run `./ops/scripts/prepare_backend_release.sh` to execute automated preflight checks.
2. Run backend tests:
   ```bash
   python3 -m unittest backend.tests.test_vocabulary_registry \
       backend.tests.test_question_mapper \
       backend.tests.test_ingestion_service \
       backend.tests.test_http_graph_writer \
        backend.tests.test_feedback_repository \
        backend.tests.test_feedback_router \
        backend.tests.test_remote_profile_store \
        backend.tests.test_health
   ```
3. Review `backend/config/graph_vocab.json` and `backend/config/question_mapping.json` for expected versions. Update metadata version if necessary before tagging release.
4. Create release tag (`vX.Y.Z`) once code is approved.

## 2. Build & Push Container Image
Update environment variables before running the script:
```bash
export STARBOUND_IMAGE_TAG=vX.Y.Z
export CONTAINER_REGISTRY=registry.your-cloud.com/starbound
```
Build and push:
```bash
./ops/scripts/build_backend_image.sh
```
(This script builds the Docker image and pushes it to the registry. Ensure you are authenticated.)

## 3. Retrieve Production Secrets
Pull secrets into a deployment file:
```bash
aws secretsmanager get-secret-value \
  --secret-id starbound/backend/prod \
  --query SecretString --output text > /tmp/backend_env.json
python3 ops/scripts/json_to_env.py /tmp/backend_env.json > /tmp/backend_env.env
```
Convert JSON to Kubernetes secret or environment file as required. Never commit secrets back into the repo.
Create/update Kubernetes secret (example):
```bash
kubectl create secret generic starbound-backend-env \
  --from-env-file=/tmp/backend_env.env \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Required environment keys
- `COMPLEXITY_API_BASE_URL`: Base URL for the production Complexity Profile backend.
- `COMPLEXITY_API_INGEST_PATH`: Path for single payload ingestion (default `/ingest`).
- `COMPLEXITY_API_BATCH_PATH`: Path for batch ingestion (default `/ingest/batch`).
- `COMPLEXITY_API_PROFILE_PATH`: Template path for profile retrieval (default `/users/{id}/complexity-profile`).
- `COMPLEXITY_API_KEY`: Bearer token used for ingestion and profile requests.
- `COMPLEXITY_API_TIMEOUT`: Optional request timeout in seconds (default `10`).
- Set `COMPLEXITY_API_USE_LOCAL_STORE=1` only for local debugging; omit it in production so the service proxies to the remote backend.


## 4. Deploy to Production
For Kubernetes using Helm:
```bash
helm upgrade --install starbound-backend ops/helm/backend \
  --set image.repository=$CONTAINER_REGISTRY/backend \
  --set image.tag=$STARBOUND_IMAGE_TAG \
  --set-file envSecrets=/tmp/backend_env.json
```
Alternatively, apply the templated manifest in `ops/deploy/backend.yaml.template` after substituting registry/tag values.

## 5. Post-Deployment Verification
1. Wait for pods to become ready (`kubectl get pods`).
2. Hit the health endpoint:
   ```bash
   ./ops/scripts/run_health_check.sh https://api.starbound.health/health
   ```
   Confirm vocab summary and question mapping versions match expectations.
3. Submit a synthetic journaling response using `python3 backend/scripts/simulate_ingest.py onboarding_survey_v1 q_sleep_schedule 4` and confirm it returns `Status: accepted`.
4. Check logs for `ingestion_rejected` entries; there should be none unless intentionally triggered.

## 6. Monitoring & Rollback
- Confirm uptime monitor sees `/health` success.
- If issues arise, roll back via `helm rollback starbound-backend <revision>` or re-deploy previous tag.
- Record deployment details in the launch log (date, tag, operator, outcome).

## Appendices
- `ops/monitoring_setup.md` for alert configuration.
- `docs/mvp_launch_checklist.md` for overall readiness tracking.
