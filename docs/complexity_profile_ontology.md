# Complexity Profile Knowledge Graph Ontology

## Purpose
This document defines the initial ontology for the Complexity Profile knowledge graph. It focuses on the core node and edge types required to personalise health support based on an individual's capacity (choices) and constraints (chances).

## Modeling Principles
- Treat users as first-class entities with evolving behavioural and contextual data captured as time-bound observations.
- Represent choices (behaviours under personal control) and chances (external factors) as reusable domain concepts linked to users and higher-level facets.
- Preserve provenance and temporal context for every computed metric, observation, and relationship so that insights remain auditable.
- Store scores and assessments as nodes or edges rather than overwriting properties to keep historical versions.
- Classify attributes by sensitivity upfront so the ingestion layer and API can enforce end-to-end encryption boundaries consistently.

## Data Sensitivity & Encryption Boundaries

| Entity | Attribute(s) | Sensitivity | Required Handling |
| --- | --- | --- | --- |
| Person | primary_email, birth_date, gender_identity, consent_status, consent_scope | Personal | Encrypt at rest and in transit; redact from operational logs. |
| Consent | consent_scope, status, method, reference_uri | Personal | Encrypt; preserve immutable audit trail for decryptable copy. |
| Observation | value, metadata (if user-derived) | Sensitive | Treat as opaque ciphertext payload; only derived summaries leave secure boundary. |
| Metric | value, inputs_hash | Derived | Store plaintext for analytics, but track provenance to encrypted source observations. |
| Intervention | description, modality | Low | Plaintext acceptable; ensure references to encrypted observations remain indirect. |
| SupportResource | eligibility_rules, contact_info | Low | Plaintext acceptable. |

Guidance:
- Observations and other high-sensitivity fields should be kept encrypted end-to-end in the graph store, with decryption limited to authorised services. Graph edges may reference opaque hashes or IDs instead of decrypted payloads.
- Derived metrics that power personalisation can remain in plaintext to support querying, provided the computation pipeline keeps provenance links to encrypted raw inputs for audit.
- Configuration files in `backend/config` must avoid embedding plaintext user data; instead reference schema labels or hashed identifiers so ingestion remains encryption-agnostic.

## Core Node Types

### Person
| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| id | string | ✓ | Stable globally unique identifier (UUID or ULID). |
| external_ids | map<string,string> |  | Mapping to app, wearable, or EHR identifiers. |
| primary_email | string |  | Encrypted at rest; optional for privacy-sensitive users. |
| birth_date | date |  | Enables age-derived metrics. |
| gender_identity | string |  | Use controlled vocabulary; allow null. |
| created_at | datetime | ✓ | Graph insertion time. |
| updated_at | datetime | ✓ | Last mutation timestamp. |
| consent_status | string | ✓ | e.g., `active`, `revoked`, `limited`. |
| consent_scope | list<string> |  | Names of allowed data uses. |

### Choice
| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| id | string | ✓ | Unique identifier. |
| name | string | ✓ | Human-readable label (e.g., `Sleep Hygiene`). |
| description | string |  | Summary of the behaviour. |
| modality | string |  | Category such as `sleep`, `movement`, `nutrition`, `screen_time`. |
| measurement_unit | string |  | Expected unit (e.g., `hours`, `steps`). |
| recommended_range | range |  | Optional range for healthy behaviour. |
| created_at | datetime | ✓ | |
| updated_at | datetime | ✓ | |

### Chance
| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| id | string | ✓ | Unique identifier. |
| name | string | ✓ | e.g., `Housing Stability`, `Income Volatility`. |
| description | string |  | |
| domain | string |  | Category such as `financial`, `social_support`, `environment`. |
| measurability | string |  | e.g., `qualitative`, `quantitative`. |
| created_at | datetime | ✓ | |
| updated_at | datetime | ✓ | |

### Facet
Represents a higher-order grouping used to organise choices and chances.

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| id | string | ✓ | |
| name | string | ✓ | e.g., `Sleep`, `Mental Health`, `Financial Security`. |
| facet_type | enum | ✓ | `choice`, `chance`, `mixed`. |
| description | string |  | |
| created_at | datetime | ✓ | |
| updated_at | datetime | ✓ | |

### Observation
Captures a single data point related to a person, choice, or chance.

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| id | string | ✓ | |
| observation_type | enum | ✓ | `self_report`, `device_stream`, `survey`, `context_event`. |
| source_id | string | ✓ | References a `Source` node. |
| subject_type | enum | ✓ | `choice`, `chance`, `person`. |
| subject_id | string | ✓ | Identifier of the entity measured. |
| recorded_at | datetime | ✓ | Timestamp from the original system. |
| ingested_at | datetime | ✓ | Pipeline ingestion time. |
| value | any | ✓ | Numeric, categorical, or structured JSON. |
| units | string |  | Optional measurement unit. |
| confidence | float |  | 0.0–1.0 confidence or quality score. |
| metadata | map<string,any> |  | Raw payload hashes, device info, context tags. |

Subtypes such as `SleepLog`, `StressEvent`, or `IncomeChange` can be implemented via `observation_type` or separate labels if using a labelled property graph.

### Metric
Derived summary value produced by analytical pipelines.

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| id | string | ✓ | |
| metric_type | enum | ✓ | `capacity_score`, `constraint_score`, `complexity_profile`, `trend_index`. |
| computed_for | enum | ✓ | `person`, `choice`, `chance`. |
| target_id | string | ✓ | Identifier of the entity the metric describes. |
| value | number | ✓ | Scalar score (0–1 or 0–100). |
| scale | string | ✓ | Defines interpretation (e.g., `ratio`, `percent`). |
| computed_at | datetime | ✓ | Calculation datetime. |
| valid_from | datetime | ✓ | Start of the validity window. |
| valid_to | datetime |  | Optional end of validity window. |
| algorithm_version | string | ✓ | Semantic version of the model or rule. |
| inputs_hash | string |  | Hash of contributing observation IDs for audit. |

### Intervention
Represents an action or resource recommended to the user.

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| id | string | ✓ | |
| name | string | ✓ | |
| description | string |  | |
| modality | string |  | e.g., `education`, `coaching`, `financial_support`. |
| delivery_channel | string |  | `in_app`, `sms`, `phone_call`, etc. |
| effort_level | enum |  | `low`, `medium`, `high`. |
| created_at | datetime | ✓ | |
| updated_at | datetime | ✓ | |

### SupportResource
External resource or service mapped to constraints.

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| id | string | ✓ | |
| name | string | ✓ | |
| provider | string |  | Organisation delivering the resource. |
| description | string |  | |
| geographic_scope | string |  | e.g., `zip`, `city`, `state`, `national`. |
| eligibility_rules | string |  | Free-form text or link to structured criteria. |
| contact_info | map<string,string> |  | Example keys: `phone`, `url`, `email`. |
| created_at | datetime | ✓ | |
| updated_at | datetime | ✓ | |

### Source
Metadata about data origin.

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| id | string | ✓ | |
| name | string | ✓ | e.g., `Fitbit`, `Self Report`, `US Census`. |
| source_type | enum | ✓ | `device`, `survey`, `partner_api`, `manual`. |
| collection_method | string |  | |
| reliability_rating | float |  | 0–1 scale indicating relative trust. |
| schema_version | string |  | Version of ingestion schema. |
| created_at | datetime | ✓ | |
| updated_at | datetime | ✓ | |

### Consent
Tracks user permissions.

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| id | string | ✓ | |
| person_id | string | ✓ | References Person. |
| consent_scope | list<string> | ✓ | e.g., `coaching`, `research`, `partner_sharing`. |
| status | enum | ✓ | `granted`, `revoked`, `pending`. |
| captured_at | datetime | ✓ | |
| expires_at | datetime |  | |
| method | string |  | `in_app`, `paper_form`, etc. |
| reference_uri | string |  | URI to stored consent artefact. |

## Edge Types

| Edge | From → To | Key Properties | Notes |
| --- | --- | --- | --- |
| `ENGAGES_IN` | Person → Choice | `state` (`active`, `paused`), `confidence`, `since` | Indicates a person is actively working on a behaviour. |
| `HAS_CAPACITY` | Person → Choice | `score` (0–1), `computed_at`, `metric_ref` | Capacity assessment linking to latest `Metric`. |
| `HAS_CONSTRAINT` | Person → Chance | `score` (0–1), `computed_at`, `metric_ref` | Represents the impact of an external factor on the person. |
| `BELONGS_TO` | Choice/Chance → Facet | `strength` (0–1), `assigned_at` | Enables grouping under shared themes. |
| `OBSERVED_AS` | Person → Observation | `role` (`self`, `care_team`), `collected_at` | Connects user to observation instances. |
| `MEASURES` | Observation → Choice/Chance | `weight`, `interpretation` | Clarifies what was measured. |
| `DERIVES` | Observation → Metric | `contribution_weight` | Traceability for computed metrics. |
| `RESULTED_IN` | Metric → Intervention | `reason_code`, `created_at` | Why a metric triggered a recommendation. |
| `ADDRESSES` | Intervention → Choice | `expected_effect`, `evidence_level` | Optionally link to chance for structural support. |
| `MITIGATES` | SupportResource → Chance | `effectiveness`, `geography`, `confidence` | Ties external resources to constraints. |
| `RECOMMENDS` | Intervention → Person | `status` (`proposed`, `accepted`, `completed`), `assigned_at`, `completed_at` | Tracks lifecycle of actions. |
| `SOURCED_FROM` | Observation/Metric → Source | `ingested_at`, `quality_score` | Maintains provenance. |
| `GOVERNED_BY` | Person/Observation → Consent | `valid_on` | Ensures data usage aligns with consent. |

## Controlled Vocabularies & Enumerations
- `modality` (Choice): `sleep`, `movement`, `nutrition`, `hydration`, `screen_time`, `mindfulness`, `stress_management`, `social_connection`, `medical_adherence`.
- `domain` (Chance): `financial`, `housing`, `employment`, `education`, `caregiving`, `transportation`, `social_support`, `environment`, `discrimination`, `healthcare_access`, `civic_participation`.
- `observation_type`: `self_report`, `device_stream`, `survey`, `context_event`, `coach_note`, `intake_assessment`.
- `metric_type`: `capacity_score`, `constraint_score`, `complexity_profile`, `trend_index`.
- `effort_level`: `low`, `medium`, `high`.
- Extend lists as new behaviours or determinants are added; version controlled updates should be recorded here before data ingestion changes roll out.

## Data Source Alignment
| Data Source | Graph Entities | Vocabulary Usage | Gaps / Actions |
| --- | --- | --- | --- |
| Smart journaling pipeline (Gemma-tagged entries) | `Person`, `Observation`, `Choice`, `Chance` | `observation_type=self_report`; Choice modalities now include `stress_management`, `social_connection` from tag ontology | Confirm every canonical tag maps to a single `Choice`/`Chance` id; add validation step so new tags trigger ontology review |
| Wearable hydration + movement sync | `Observation`, `Choice` | `observation_type=device_stream`; Choice modalities `hydration`, `movement`; unit property uses litres, steps, minutes | Standardise units on ingestion and add device metadata to `metadata`; ensure hydration streaks appear as separate metrics not overwritten totals |
| Intake + follow-up surveys | `Observation`, `Chance`, `Consent` | `observation_type=intake_assessment`; Chance domains `education`, `caregiving`, `transportation` added above | Build survey question-to-ontology map; capture question version in `metadata` so longitudinal comparisons stay valid |
| Coach and community health worker notes | `Observation`, `Chance` | `observation_type=coach_note`; relates to Chance domains `employment`, `housing`, `social_support` | Add lightweight text-to-tag tooling so staff notes get canonical keys; require `confidence` entry when notes capture subjective assessments |
| Support resource catalog (Action Vault, local directories) | `SupportResource`, `Intervention`, `Chance` | Chance domains `housing`, `financial`, `civic_participation`; intervention modalities `education`, `financial_support`, `coaching` | Ensure every resource references a target Chance id; add geo coverage taxonomy (zip, suburb, statewide) in `geographic_scope` to aid matching |
| Public datasets (Census, environmental feeds) | `Chance`, `Observation` | `observation_type=survey` for ACS, `context_event` for weather/air quality; Chance domains `environment`, `financial`, `healthcare_access` | Define community-level Chance ids (e.g., `neighbourhood_air_quality`); document aggregation cadence and data provenance in `Source` nodes |

### Filled Vocabulary Gaps
- Added Choice modalities `stress_management`, `social_connection`, `medical_adherence` to capture journaling tags and medication adherence data.
- Added Chance domains `education`, `caregiving`, `transportation`, `civic_participation` for survey and resource catalogs.
- Added Observation types `coach_note` and `intake_assessment` to distinguish professional notes from self-reporting.
- Action item: keep ingestion schemas aligned with these enums; any new controlled term must be registered before it appears in production payloads.


## Temporal & Versioning Guidelines
- Store all edges with `since`, `until` timestamps when relationships change over time.
- Never overwrite metrics; create new `Metric` nodes and connect via `DERIVES` and `HAS_CAPACITY`/`HAS_CONSTRAINT` edges to keep history.
- Observations should include both `recorded_at` (origin timestamp) and `ingested_at` (pipeline timestamp) to support latency analysis.
- Use `algorithm_version` on metrics and `inputs_hash` to make recalculations reproducible.

## Privacy & Security Considerations
- Encrypt sensitive properties (e.g., income, discrimination experiences) at the application layer before storage where required by policy.
- Use `Consent` nodes and `GOVERNED_BY` edges to enforce purpose-based access control.
- Include `confidence` or `quality_score` on observations and metrics so downstream services can apply guardrails.

## Ingestion Validation Guardrails
- **Vocabulary registry**: Maintain a single JSON/YAML file (e.g., `config/graph_vocab.json`) listing allowed `choice.modality`, `chance.domain`, `observation_type`, etc. The ingestion service loads it at start-up and rejects payloads with unknown values.
- **Schema contracts**: Define pydantic/dataclass schemas per ingestion channel (journaling, wearables, surveys) enforcing required fields like `subject_id`, `recorded_at`, and `source_id`.
- **ID resolution**: For every incoming canonical tag, resolve to the graph node ID via a lookup table; if multiple matches occur, raise an error so taxonomy admins can disambiguate.
- **Temporal sanity checks**: Reject observations whose `recorded_at` is more than 30 days in the future or older than system retention policy unless flagged for backfill.
- **Unit normalisation**: Convert raw units (ounces, miles) to canonical units (litres, kilometres) before persistence; store the original in `metadata.original_unit` for traceability.
- **Consent enforcement**: Before writing, confirm the user’s latest `Consent` node allows the ingestion `purpose`—if not, drop or quarantine the record.
- **Quality thresholds**: Require `confidence` ≥ configurable minimum for AI-derived labels; lower scores route to review instead of automatic upsert.
- **Audit logging**: Log every rejection with cause and payload hash so data ops can monitor drift and update the ontology registry when changes are intentional.


## Question-to-Ontology Mapping Template
| Instrument | Question ID | Prompt (plain language) | Response Type | Maps To | Notes |
| --- | --- | --- | --- | --- | --- |
| onboarding_survey_v1 | q_sleep_schedule | "How regular is your sleep schedule?" | Likert (1-5) | `Choice:sleep_hygiene` | Convert scale to capacity indicators; store raw value in observation `value` |
| onboarding_survey_v1 | q_housing_security | "Do you feel secure in your current housing for the next 6 months?" | Multiple choice | `Chance:housing_stability` | Map options to constraint score tiers (e.g., secure → 0.2, unstable → 0.8) |
| daily_journal | followup_hydration | "How many cups of water did you drink today?" | Numeric | `Choice:daily_hydration` | Convert cups to litres before persistence |
| coach_checkin_v1 | note_caregiving | "List any caregiving responsibilities affecting health goals." | Free text | `Chance:caregiving_load` | Use NLP tagging with manual review queue for low confidence |
| monthly_reflection | q_support_network | "Who supports you when things get tough?" | Free text | `Chance:social_support` | Capture qualitative themes + note if no support is mentioned |

**Template usage**:
1. Add a row per question or follow-up that generates data destined for the graph.
2. `Maps To` must reference an existing node ID or controlled vocabulary entry; if not, create one before the instrument ships.
3. Include transformation rules (scoring, unit conversion) in `Notes` so ingestion code can stay in sync with survey design.
4. Version instruments (e.g., `onboarding_survey_v2`) when questions change; keep retired rows for audit trail.


## Prototype Query: GET /users/{id}/complexity-profile

**Purpose**: Drive the API endpoint that summarises a person’s current capacity, constraints, and supporting resources from the graph.

**Response shape (conceptual)**:
```json
{
  "user": {"id": "user-123", "consent_status": "active"},
  "choices": [{
    "id": "sleep_hygiene",
    "name": "Sleep Hygiene",
    "modality": "sleep",
    "capacity_score": 0.68,
    "last_updated": "2024-06-14T09:00:00Z"
  }],
  "constraints": [{
    "id": "housing_stability",
    "name": "Housing Stability",
    "domain": "housing",
    "constraint_score": 0.82,
    "last_updated": "2024-06-13T22:00:00Z"
  }],
  "recommended_resources": [{
    "intervention_id": "int-42",
    "resource_id": "rent-assist-nyc",
    "name": "City Rental Assistance",
    "status": "proposed"
  }],
  "profile_metric": {
    "id": "metric-991",
    "value": 0.41,
    "computed_at": "2024-06-14T10:00:00Z",
    "algorithm_version": "cp-1.2.0"
  }
}
```

### Cypher prototype (Neo4j)
```cypher
MATCH (p:Person {id: $userId})
OPTIONAL MATCH (p)-[:ENGAGES_IN]->(choice:Choice)
OPTIONAL MATCH (p)-[cap:HAS_CAPACITY]->(choice)
OPTIONAL MATCH (choice)-[:BELONGS_TO]->(choiceFacet:Facet)
OPTIONAL MATCH (p)-[constraintRel:HAS_CONSTRAINT]->(chance:Chance)
OPTIONAL MATCH (chance)-[:BELONGS_TO]->(chanceFacet:Facet)
OPTIONAL MATCH (metric:Metric {metric_type: 'complexity_profile', target_id: p.id})
OPTIONAL MATCH (p)<-[recRel:RECOMMENDS {status: 'proposed'}]-(intervention:Intervention)
OPTIONAL MATCH (intervention)-[:ADDRESSES]->(choice)
OPTIONAL MATCH (intervention)-[:MITIGATES]->(chance)
OPTIONAL MATCH (intervention)-[:LINKS_TO]->(resource:SupportResource)
WITH p, metric,
     collect(DISTINCT {
       id: choice.id,
       name: choice.name,
       modality: choice.modality,
       facet: choiceFacet.name,
       capacity_score: cap.score,
       capacity_metric: cap.metric_ref,
       last_updated: cap.computed_at
     }) AS choices,
     collect(DISTINCT {
       id: chance.id,
       name: chance.name,
       domain: chance.domain,
       facet: chanceFacet.name,
       constraint_score: constraintRel.score,
       constraint_metric: constraintRel.metric_ref,
       last_updated: constraintRel.computed_at
     }) AS constraints,
     collect(DISTINCT {
       intervention_id: intervention.id,
       resource_id: resource.id,
       name: coalesce(resource.name, intervention.name),
       status: recRel.status,
       reason: recRel.reason_code
     }) AS recommendedResources
RETURN {
  user: { id: p.id, consent_status: p.consent_status },
  profile_metric: CASE WHEN metric IS NULL THEN NULL ELSE {
    id: metric.id, value: metric.value, computed_at: metric.computed_at, algorithm_version: metric.algorithm_version
  } END,
  choices: [c IN choices WHERE c.id IS NOT NULL],
  constraints: [c IN constraints WHERE c.id IS NOT NULL],
  recommended_resources: [r IN recommendedResources WHERE r.intervention_id IS NOT NULL]
} AS complexityProfile;
```

### Gremlin prototype (TinkerPop)
```gremlin
g.V().hasLabel('Person').has('id', userId)
.project('user', 'profile_metric', 'choices', 'constraints', 'recommended_resources')
.by(valueMap('id','consent_status').by(unfold()))
.by(__.out('DERIVES').has('metric_type','complexity_profile').order().by('computed_at', decr).limit(1)
     .valueMap('id','value','computed_at','algorithm_version').by(unfold()).fold())
.by(__.out('ENGAGES_IN').as('choice')
     .optional(__.inE('HAS_CAPACITY').has('person_id', userId).as('capEdge'))
     .project('id','name','modality','facets','capacity_score','last_updated')
       .by(select('choice').values('id'))
       .by(select('choice').values('name'))
       .by(select('choice').values('modality'))
       .by(select('choice').out('BELONGS_TO').values('name').fold())
       .by(select('capEdge').values('score'))
       .by(select('capEdge').values('computed_at'))
     .fold())
.by(__.outE('HAS_CONSTRAINT').as('rel').inV().as('chance')
     .project('id','name','domain','facets','constraint_score','last_updated')
       .by(select('chance').values('id'))
       .by(select('chance').values('name'))
       .by(select('chance').values('domain'))
       .by(select('chance').out('BELONGS_TO').values('name').fold())
       .by(select('rel').values('score'))
       .by(select('rel').values('computed_at'))
     .fold())
.by(__.inE('RECOMMENDS').has('status','proposed').as('rel').outV().as('intervention')
     .project('intervention_id','resource_id','name','status','reason')
       .by(select('intervention').values('id'))
       .by(select('intervention').out('LINKS_TO').values('id').fold())
       .by(select('intervention').coalesce(out('LINKS_TO').values('name'), values('name')))
       .by(select('rel').values('status'))
       .by(select('rel').values('reason_code'))
     .fold());
```

**Implementation notes**:
- Filter null IDs before serialising to keep arrays clean.
- Optional `asOf` parameters can be supported by adding `WHERE cap.computed_at <= $asOf` clauses (or equivalent) for historical views.
- Wrap queries in backend service functions and back them with unit tests that stub graph responses.


## Backend Implementation Checklist
- [ ] Build vocabulary registry loader and expose health check endpoint showing last refresh.
- [ ] Implement ingestion validators per channel (journaling, wearables, surveys) using the schema rules above.
- [ ] Create question mapping config file and wire it into survey/journal pipelines.
- [ ] Add consent check middleware before persistence and emit structured rejection logs.
- [ ] Integrate `GET /users/{id}/complexity-profile` query with service tests covering happy path and missing data cases.
- [ ] Set up nightly job to recompute Complexity Profile metrics and refresh recommendations.

**Open questions**
- How do we version interventions and resources when external providers change availability?
- What is the retention policy for rejected payload logs and manual review queues?
- Should coaches see constraint scores directly or only high-level recommendations?


## Next Steps
1. Implement ingestion-time validators that reject payloads using unregistered Choice modalities, Chance domains, or observation types.
2. Document the survey and journaling question-to-ontology mapping so new instruments can be added without ad hoc tag creation.
3. Load a small pilot dataset into the graph and run Cypher/Gremlin queries to confirm the aligned vocabularies produce the expected Complexity Profile outputs.

## Example User Journey (Plain Language)

1. Aisha signs up for personalised support. The system creates a **Person** profile with her consent choices recorded in a **Consent** entry so coaches know how her data may be used.
2. During onboarding she shares that she wants to improve sleep and hydration. These become links from Aisha to the **Choice** concepts `Sleep Hygiene` and `Daily Hydration`, grouped under the `Sleep` and `Nutrition` **Facets**.
3. A community health worker notes that Aisha works the night shift and currently rents a temporary apartment. Those circumstances connect her to the **Chance** factors `Irregular Work Schedule` and `Housing Stability`, also grouped under contextual **Facets** like `Employment` and `Housing`.
4. Each morning Aisha records sleep duration in the app and her wearable syncs hydration data. Every entry is stored as an **Observation** that points back to the relevant choice so the graph keeps a time stamped history instead of overwriting values.
5. Weekly analytic jobs review the fresh observations. They produce **Metric** scores: a `capacity_score` for `Sleep Hygiene` (how ready she is to change) and a `constraint_score` for `Housing Stability` (how much it limits her). These metrics stay linked to the observations that fed them.
6. Because the housing constraint score is high, the system surfaces a city-funded rental assistance program. That resource lives in the graph as a **SupportResource** connected to the housing chance. An **Intervention** recommendation links both to Aisha and to the sleep choice, clarifying that addressing housing stability should improve her sleep efforts.
7. Aisha accepts the recommendation and later reports back that she received support. The intervention edge updates to `completed`, creating a clear, auditable trail of what was suggested, why, and what happened.

This narrative shows how the ontology traces the relationships among a person’s choices, contextual chances, time-based observations, computed insights, and tailored support—all in terms a coach or user can follow.
