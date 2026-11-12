# functions
Functions used in multiple bash scripts


# Log Level Breakdown

### 0 — SILENT

* **When to use:** Non-interactive or automated executions (e.g., Cron jobs, automated scripts, quiet CI/CD steps) where stdout/stderr must remain completely silent unless explicitly redirected.
* **Target Audience:** None (suppresses all output).

### 1 — CRITICAL

* **When to use:** Fatal errors that cause immediate process termination or catastrophic system failure. The application or script cannot recover and must abort.
* **Examples:** Database connection completely lost on startup, disk out of space, missing mandatory environment variables, core dependency missing.
* **Target Audience:** On-call engineers, automated paging/alerting systems (OpsGenie, PagerDuty).

### 2 — ERROR

* **When to use:** Operational failures where a specific task, request, or transaction failed, but the overall application remains running and stable.
* **Examples:** A specific third-party API request timed out after retries, a file import failed due to corruption, an unhandled exception occurred during a single request.
* **Target Audience:** System administrators and developers monitoring application health.

### 3 — WARN (Warning)

* **When to use:** Unexpected conditions, non-fatal anomalies, or performance issues that do not stop execution now, but might indicate an impending problem or sub-optimal behavior.
* **Examples:** High memory threshold exceeded, attempting a fallback mechanism, usage of a deprecated function/API, retrying a transient network connection.
* **Target Audience:** Developers and Ops analyzing trend metrics or bug reports.

### 4 — NOTICE

* **When to use:** Normal, but *significant* system state changes or operational milestones. Higher priority than standard routine logging, but strictly non-error.
* **Examples:** Service started or shut down cleanly, configuration reloaded, user elevated permissions/password changed, database migration completed.
* **Target Audience:** System administrators, security auditing tools.

### 5 — INFO (Information)

* **When to use:** Routine, expected operational events detailing normal application flow. Used to trace steady-state behavior in production without cluttering logs.
* **Examples:** User logged in, scheduled task execution started/finished, HTTP endpoint hit with status 200, record created successfully.
* **Target Audience:** Anyone monitoring general usage patterns or user activity.

### 6 — DEBUG

* **When to use:** Fine-grained diagnostic information required strictly for troubleshooting and local development. Usually disabled in production due to high volume and potential exposure of sensitive data.
* **Examples:** Full API payload dumps, entry/exit points of functions, SQL queries being executed, inner loop variable states.
* **Target Audience:** Software developers debugging specific code paths.
