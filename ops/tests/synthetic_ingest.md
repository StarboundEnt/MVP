# Synthetic Ingestion Test

Use this script after deploying to production to verify ingestion is functioning.

```bash
python3 backend/scripts/simulate_ingest.py   onboarding_survey_v1 q_sleep_schedule 4
```

Expected output:
- `Status: accepted`
- Payload printed with choice modality and observation type.

Repeat for chance question:
```bash
python3 backend/scripts/simulate_ingest.py   onboarding_survey_v1 q_housing_security unstable
```

If `Status: rejected`, inspect `reason` and check backend logs for `ingestion_rejected` entries.
