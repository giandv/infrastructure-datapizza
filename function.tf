resource "google_storage_bucket" "bucket_async_function" {
  name     = "data-pizza-bucket"
  location = "US"
}
resource "google_storage_bucket_object" "archive_async_function" {
  name   = "index.zip"
  bucket = google_storage_bucket.bucket_async_function.name
  source = "./path/to/zip/file/which/contains/code"
}
resource "google_cloudfunctions_function" "async_function" {
  name        = "function-data-pizza"
  description = "Client FaaS"
  runtime     = "nodejs16"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket_async_function.name
  source_archive_object = google_storage_bucket_object.archive_async_function.name
  trigger_http          = true
  entry_point           = "helloGET"
}

# IAM entry for all users to invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.PROJECT_ID
  region         = var.GCP_REGION
  cloud_function = google_cloudfunctions_function.async_function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}
