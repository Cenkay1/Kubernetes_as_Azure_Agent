{{/*
Chart full name
*/}}
{{- define "azure-devops-agent.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "azure-devops-agent.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: azure-devops-agents
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{/*
Secret name
*/}}
{{- define "azure-devops-agent.secretName" -}}
{{ include "azure-devops-agent.fullname" . }}-auth
{{- end }}

{{/*
TriggerAuthentication name
*/}}
{{- define "azure-devops-agent.triggerAuthName" -}}
{{ include "azure-devops-agent.fullname" . }}-trigger-auth
{{- end }}
