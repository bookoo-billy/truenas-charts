{{- define "mopidy.portal" -}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: portal
data:
  path: "/"
  {{- $port := .Values.mopidyNetwork.webPort -}}
  {{- if .Values.mopidyNetwork.hostNetwork -}}
    {{- $port = 8096 -}}
  {{- end }}
  port: {{ $port | quote }}
  protocol: http
  host: $node_ip
{{- end -}}
