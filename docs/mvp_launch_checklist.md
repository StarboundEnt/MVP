# MVP Launch Readiness Checklist

## Purpose
Consolidates the engineering, product, compliance, and operational steps that must be completed before launching the Starbound MVP.

## 1. Technical Readiness
- [ ] Backend ingestion service deployed with vocabulary registry + question mapping configs (see backend/config).
- [ ] Complexity Profile API (`GET /users/{id}/complexity-profile`) wired to graph database and covered by integration tests.
- [ ] Smart journaling pipeline pointing at the production Complexity Profile backend cluster with health monitoring enabled.
- [ ] Flutter app passes `flutter analyze`, `flutter test`, integration and golden tests.
- [ ] Mobile builds produced for iOS TestFlight and Android internal track; smoke tests executed on target devices.
- [ ] Secure HTTP client wired to production payload transformer + request signer configuration (E2EE-ready contract frozen).
- [ ] Application secrets (.env, API keys) rotated and stored in secure secret manager (e.g., AWS Secrets Manager) with least privilege IAM roles.

## 2. Data Governance
- [ ] Consent flows verified against Privacy Policy and captured in graph `Consent` nodes.
- [ ] Data retention schedule agreed; data pipelines enforce deletion/archival policies.
- [ ] Security review complete: encryption at rest, network transport (TLS), audit logging, access controls.
- [ ] Device key manager seeded for enrolled users; key rotation + recovery procedures documented and linked to consent revocation flow.
- [ ] DPIA / PIA completed for handling sensitive health and chance data.

## 3. Monitoring & Operations
- [ ] Health endpoint (`/health`) integrated into uptime monitoring with alerts.
- [ ] `ingestion_rejected` logs exported to monitoring platform with alert thresholds for sustained failures (>5/min).
- [ ] Observability dashboards (APM, logs, metrics) configured for mobile app, backend API, and graph ingestion jobs.
- [ ] On-call rotation defined with runbooks for major failure scenarios (ingestion failures, Complexity Profile backend outage, model scoring errors).

## 4. Product & UX
- [ ] Content review of nudges, follow-up questions, and resources ensures cultural appropriateness and Australian localisation.
- [ ] Accessibility verification (WCAG AA) completed on mobile app.
- [ ] Beta feedback from pilot cohort triaged; critical issues fixed or documented for post-launch.

## 5. Compliance & Legal
- [ ] Terms of Service and Privacy Policy published within app and website.
- [ ] Consent records stored with immutable audit trail and export capability.
- [ ] Incident response plan documented and rehearsed (tabletop exercise).

## 6. Go-Live Process
- [ ] Final go/no-go meeting including engineering, product, compliance.
- [ ] Production deployment walkthrough rehearsed (dry run with staging environment).
- [ ] Launch-day checklist assigned: comms, social posts, stakeholder updates.
- [ ] Post-launch monitoring period staffed (first 72 hours).

## Appendix
- Vocabulary registry: `backend/config/graph_vocab.json`
- Question mapping config: `backend/config/question_mapping.json`
- Ingestion service tests: `backend/tests/test_ingestion_service.py`
- Health endpoint: `backend/api/health.py`
- E2EE flow overview: `docs/e2ee_launch_overview.md`

Update this checklist as items are completed to maintain visibility into launch readiness.


### Execution Notes
- **Backend deployment**: Prepare IaC/CI job pointing to the production Complexity Profile backend (API + graph store); run smoke tests via `GET /health` and sample journaling ingest before marking item complete.
- **Mobile store builds**: Generate release notes, bump version numbers in `pubspec.yaml`, run `flutter build ipa` and `flutter build appbundle`, upload to TestFlight/Internal Track, capture device screenshots for review.
- **Consent/legal**: Review final Privacy Policy + Terms of Service with counsel; ensure consent copy in app matches legal text; export sample consent logs for audit.
- **Monitoring linkage**: After deploying `/health`, register endpoint in your monitoring tool (e.g., Pingdom/New Relic) with 1-minute polling and alert to on-call channel. Create log pipeline filter for `ingestion_rejected` tag with threshold alerts.
- **Go/no-go review**: Schedule meeting with engineering, product, compliance 48h prior to launch; share filled checklist, deployment plan, rollback procedures.
