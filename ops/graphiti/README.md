# Local Graphiti Stack

This directory contains a Docker Compose setup that launches Graphiti alongside
Neo4j so you can ingest and inspect journal data locally.

## 1. Configure Secrets

```bash
cp ops/graphiti/.env.graphiti.example ops/graphiti/.env.graphiti
```

Edit `.env.graphiti` and set at least:

- `OPENAI_API_KEY` – Graphiti relies on a structured-output LLM (OpenAI by default).
- `NEO4J_USER` / `NEO4J_PASSWORD` – Defaults work with the compose file. Adjust if
  you already run Neo4j elsewhere.

Any optional provider keys are passed straight through to the container.

## 2. Start the Stack

```bash
cd ops/graphiti
docker compose up -d
```

Services exposed locally:

- Graphiti API: `http://localhost:8000` (Swagger docs at `/docs`)
- Neo4j Browser: `http://localhost:7474`

The first startup builds indices and may take ~30 seconds.

## 3. Point the Flutter App at Graphiti

Ensure the app’s `.env` contains:

```
GRAPHITI_BASE_URL=http://localhost:8000
```

Hot-reload the app. Any new journal entry with behaviour + context tags will POST
payloads to `http://localhost:8000/messages`.

## 4. Validate Ingestion

1. Watch the Graphiti container logs:
   ```bash
   docker compose logs -f graphiti
   ```
2. Submit a journal entry in the app.
3. Check Neo4j Browser (`neo4j` / `graphiti`) and run:
   ```cypher
   MATCH (e:Episodic)-[:EVIDENCE]->(b:Entity)
   RETURN e, b
   LIMIT 10;
   ```
   You should see the new episode nodes and linked entities.

## 5. Tear Down

```bash
docker compose down
```

Add `-v` if you want to wipe the persisted Neo4j data:

```bash
docker compose down -v
```

## Troubleshooting

- **401 errors:** Set `GRAPHITI_API_KEY` in the Flutter `.env` and configure the
  Graphiti service to expect the same bearer token.
- **LLM rate limits:** Lower `SEMAPHORE_LIMIT` inside `.env.graphiti` or switch to
  a higher-throughput provider via extra keys.
- **Port conflicts:** Update the exposed ports in `docker-compose.yml` and mirror
  the change in the Flutter `.env`.

Refer to the upstream docs for advanced tuning: <https://github.com/getzep/graphiti>.
