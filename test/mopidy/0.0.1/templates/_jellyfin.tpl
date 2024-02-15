{{- define "mopidy.workload" -}}
workload:
  mopidy:
    enabled: true
    primary: true
    type: Deployment
    podSpec:
      hostNetwork: {{ .Values.mopidyNetwork.hostNetwork }}
      containers:
        mopidy:
          enabled: true
          primary: true
          imageSelector: image
          securityContext:
            runAsUser: {{ .Values.mopidyRunAs.user }}
            runAsGroup: {{ .Values.mopidyRunAs.group }}
          env:
            {{ with .Values.mopidyConfig.publishedServerUrl }}
            JELLYFIN_PublishedServerUrl: {{ . | quote }}
            {{ end }}
          {{ with .Values.mopidyConfig.additionalEnvs }}
          envList:
            {{ range $env := . }}
            - name: {{ $env.name }}
              values: {{ $env.value }}
            {{ end }}
          {{ end }}
          probes:
            liveness:
              enabled: true
              type: http
              port: 8096
              path: /health
            readiness:
              enabled: true
              type: http
              port: 8096
              path: /health
            startup:
              enabled: true
              type: http
              port: 8096
              path: /health
      initContainers:
      {{- include "ix.v1.common.app.permissions" (dict "containerName" "01-permissions"
                                                        "UID" .Values.mopidyRunAs.user
                                                        "GID" .Values.mopidyRunAs.group
                                                        "mode" "check"
                                                        "type" "init") | nindent 8 }}

{{/* Service */}}
service:
  mopidy:
    enabled: true
    primary: true
    type: NodePort
    targetSelector: mopidy
    ports:
      webui:
        enabled: true
        primary: true
        port: {{ .Values.mopidyNetwork.webPort }}
        nodePort: {{ .Values.mopidyNetwork.webPort }}
        targetPort: 8096
        targetSelector: mopidy

{{/* Persistence */}}
persistence:
  config:
    enabled: true
    type: {{ .Values.mopidyStorage.config.type }}
    datasetName: {{ .Values.mopidyStorage.config.datasetName | default "" }}
    hostPath: {{ .Values.mopidyStorage.config.hostPath | default "" }}
    targetSelector:
      mopidy:
        mopidy:
          mountPath: /config
        01-permissions:
          mountPath: /mnt/directories/config
  cache:
    enabled: true
    type: {{ .Values.mopidyStorage.cache.type }}
    datasetName: {{ .Values.mopidyStorage.cache.datasetName | default "" }}
    hostPath: {{ .Values.mopidyStorage.cache.hostPath | default "" }}
    targetSelector:
      mopidy:
        mopidy:
          mountPath: /cache
        01-permissions:
          mountPath: /mnt/directories/cache
  transcode:
    enabled: true
    type: {{ .Values.mopidyStorage.transcodes.type }}
    datasetName: {{ .Values.mopidyStorage.transcodes.datasetName | default "" }}
    hostPath: {{ .Values.mopidyStorage.transcodes.hostPath | default "" }}
    medium: {{ .Values.mopidyStorage.transcodes.medium | default "" }}
    {{/* Size of the emptyDir */}}
    size: {{ .Values.mopidyStorage.transcodes.size | default "" }}
    targetSelector:
      mopidy:
        mopidy:
          mountPath: /config/transcodes
        {{ if ne .Values.mopidyStorage.transcodes.type "emptyDir" }}
        01-permissions:
          mountPath: /mnt/directories/transcodes
        {{ end }}
  tmp:
    enabled: true
    type: emptyDir
    targetSelector:
      mopidy:
        mopidy:
          mountPath: /tmp
  {{- range $idx, $storage := .Values.mopidyStorage.additionalStorages }}
  {{ printf "mopidy-%v" (int $idx) }}:
    {{- $size := "" -}}
    {{- if $storage.size -}}
      {{- $size = (printf "%vGi" $storage.size) -}}
    {{- end }}
    enabled: true
    type: {{ $storage.type }}
    datasetName: {{ $storage.datasetName | default "" }}
    hostPath: {{ $storage.hostPath | default "" }}
    server: {{ $storage.server | default "" }}
    share: {{ $storage.share | default "" }}
    domain: {{ $storage.domain | default "" }}
    username: {{ $storage.username | default "" }}
    password: {{ $storage.password | default "" }}
    size: {{ $size }}
    {{- if eq $storage.type "smb-pv-pvc" }}
    mountOptions:
      - key: noperm
    {{- end }}
    targetSelector:
      mopidy:
        mopidy:
          mountPath: {{ $storage.mountPath }}
        01-permissions:
          mountPath: /mnt/directories{{ $storage.mountPath }}
  {{- end }}
{{ with .Values.mopidyGPU }}
scaleGPU:
  {{ range $key, $value := . }}
  - gpu:
      {{ $key }}: {{ $value }}
    targetSelector:
      mopidy:
        - mopidy
  {{ end }}
{{ end }}
{{- end -}}
