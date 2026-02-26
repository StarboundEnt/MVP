# Monitoring & Alerting Setup

## Health Endpoint
1. Deploy backend with `/health` route exposed (FastAPI router or equivalent).
2. Register the URL (e.g., `https://api.starbound.health/health`) in your uptime monitor.
3. Configure checks (60s interval, 3 failure threshold) with notifications to `#oncall-starbound` Slack + PagerDuty.
4. Store last successful response payload to verify vocabulary/question mapping versions on each run.

## ingestion_rejected Logs
1. Ensure logging framework includes the structured `extra` payload from `IngestionService._log_rejection`.
2. Forward logs to central observability stack (e.g., CloudWatch Logs via Fluent Bit).
3. Create metric filter counting logs where `reason` contains `vocabulary_error` or `mapping_error`.
4. Alert when rate >5/min for 10 minutes (SNS/PagerDuty).
5. Dashboard panels: daily rejection count, top instrument/question offenders, latest reasons.

## Dashboards
- Backend API latency & error rates (APM).
- Complexity Profile backend services (API latency, graph database CPU/memory, connection pool).
- Mobile crash analytics (Sentry/Crashlytics) tied to app versions.

## Runbooks
- Link rejection alert to runbook explaining steps: inspect logs, validate vocab registry, escalate to taxonomy lead.
- Include health-check failure runbook (restart service, failover plan, communication tree).


## Example Configurations
### Pingdom HTTP Check
```hcl
# Terraform snippet
resource "pingdom_check" "starbound_api" {
  name                     = "Starbound API Health"
  type                     = "http"
  host                     = "api.starbound.health"
  url                      = "/health"
  resolution               = 1
  notifywhenbackup         = true
  sendemailnotification    = true
  sendtoemail              = ["oncall@starbound.health"]
  requestheaders           = { "Accept" = "application/json" }
}
```

### CloudWatch Metric Filter
```hcl
resource "aws_cloudwatch_log_metric_filter" "ingestion_rejected" {
  name           = "ingestion_rejected_count"
  log_group_name = "/aws/ecs/starbound-backend"
  pattern        = "{ $.reason = *ingestion_rejected* }"

  metric_transformation {
    name      = "IngestionRejected"
    namespace = "Starbound/Backend"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "ingestion_rejected_high" {
  alarm_name          = "Starbound-IngestionRejected-High"
  metric_name         = aws_cloudwatch_log_metric_filter.ingestion_rejected.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.ingestion_rejected.metric_transformation[0].namespace
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 10
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.oncall_alerts.arn]
}
```

### Datadog Log Pipeline Rule
1. Create pipeline filter: `service:starbound-backend AND message:"ingestion_rejected"`.
2. Define processing step extracting `reason`, `instrument_id`, `question_id` from JSON payload.
3. Create monitor: alert when `count(last_5m):sum:ingestion_rejected{environment:prod} > 25`.
```

