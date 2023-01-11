# Google Service account; for more, see: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/googlecloudexporter
resource "google_service_account" "metrics-writer" {
  project      = var.project_id
  account_id   = "${substr(var.demo_name, 0, 12)}-metrics-writer"
  display_name = "${substr(var.demo_name, 0, 12)}-metrics-writer"
}

resource "google_project_iam_member" "cloud-trace-iam" {
  project = var.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.metrics-writer.email}"

}
resource "google_project_iam_member" "cloud-metrics-iam" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.metrics-writer.email}"
}
