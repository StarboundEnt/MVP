# Graphiti Integration Notes (Deprecated)

Legacy note: previously the Flutter app streamed journal entries to a Graphiti ingest service. The current architecture uses the in-house Complexity Profile backend; the remaining guidance is retained for historical reference.

The legacy integration described below assumes journal entries have been tagged with Choice (behaviour) and Chance (context) labels. This keeps the
knowledge graph in sync with the local journaling pipeline without blocking the UI.

## Runtime Expectations

1. A Graphiti service is running and reachable from the client. The quickest path is the
   official Docker image: `zepai/graphiti:latest`, paired with Neo4j 5.26+.
2. The Flutter bundle includes a `.env` file with the following keys:

   ```text
   GRAPHITI_BASE_URL=https://graphiti.your-domain.com
   GRAPHITI_MESSAGES_PATH=/messages          # optional override
   GRAPHITI_SOURCE_DESCRIPTION=starbound_smart_journal_v1
   GRAPHITI_ROLE_LABEL=journaler             # label recorded with each episode
   GRAPHITI_GROUP_PREFIX=user                # prefix for group IDs (user_<id>)
   GRAPHITI_API_KEY=                          # optional bearer token
   ```

   Any unset values fall back to the defaults shown above. If `GRAPHITI_BASE_URL`
   is missing or empty the integration quietly no-ops.

## Ingestion Flow

```
SmartJournalEntry (Choice + Chance tags required)
          ↓
GraphitiService.buildPayload → JSON encode canonical data
          ↓
POST {baseUrl}{messagesPath}
```

- The payload contains the original journal text plus serialised behaviour, context,
  and outcome tags (canonical keys, display names, sentiment metadata, etc.).
- Entries without at least one behaviour and one context are skipped until the
  follow-up flow captures the missing information.
- Each user is partitioned into their own Graphiti `group_id` (e.g. `user_42`).
- Network failures are logged but never bubble up into the UI; the journal submission
  still completes instantly.

## Querying the Graph

The Flutter app does not call Graphiti search endpoints yet. Once the backend
exposes the queries we care about (e.g. recommended behaviours, context/outcome
patterns) we can add read methods alongside the existing ingest function.

## Local Testing

1. Launch Graphiti + Neo4j via Docker.
2. Point `GRAPHITI_BASE_URL` at the running service (e.g. `http://localhost:8000`).
3. Run `flutter test test/services/graphiti_service_test.dart` to verify payload
   construction.
4. Run the app, submit a journaling entry with both behaviour and context tags, and
   inspect the Graphiti API logs → the encoded payload appears under `/messages`.
