{{/* label */}}
{{- define "labels" }}
{{- if eq .Values.type "service" }}
app.kubernetes.io/appName: {{ .Values.global.appName }}
app.kubernetes.io/serviceName: {{ .Values.name }}
app.kubernetes.io/instance: {{ .Values.global.instance }}
app.kubernetes.io/kind: service
{{- else if eq .Values.type "frontend" }}
app.kubernetes.io/appName: {{ .Values.global.appName }}
app.kubernetes.io/serviceName: {{ .Values.name }}
app.kubernetes.io/instance: {{ .Values.global.instance }}
app.kubernetes.io/kind: frontend
{{- else if eq .Values.type "job" }}
pp.kubernetes.io/appName: {{ .Values.global.appName }}
app.kubernetes.io/serviceName: {{ .Values.name }}
app.kubernetes.io/instance: {{ .Values.global.instance }}
app.kubernetes.io/kind: job
{{- end }}
{{ end -}}


{{/* fullname */}}
{{- define "fullname" -}}
{{- printf "%s-%s-%s" .Values.global.appName .Values.name .Values.global.instance | trunc 50 | trimSuffix "-" -}}
{{- end -}}


{{/* annotation-ingress */}}
{{- define "annotation-ingress" -}}
kubernetes.io/ingress.class: nginx
kubernetes.io/tls-acme: "true"
{{- end -}}


{{/* configmap-volume */}}
{{- define "configmap.file.volume" -}}
{{- if .Values.configmap.file -}}
{{ $fullname := (include "fullname" .) }}
- name: configmap-file
  configMap:
    name: {{ printf "%s-%s" $fullname "file" }}
{{- end }}
{{- end -}}



{{/* secret-volume */}}
{{- define "secret.store.volume" -}}
{{- if .Values.secrets }}
{{ $fullname := (include "fullname" .) }}
- name: secrets-store-inline
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: {{ printf "%s-%s" $fullname "secret-store" }}
{{- end }}
{{- end -}}


{{- define "volumes" }}
{{- include "configmap.file.volume" . }}
{{- include "secret.store.volume" . }}
{{- end }}


{{- define "configmap.file.mount" -}}
{{- if .Values.configmap.file -}}
{{ $fullname := (include "fullname" .) }}
{{- range $file := .Values.configmap.file }}
- name: configmap-file
  mountPath: {{ printf "%s/%s" $file.mountpath $file.name }}
  subPath: {{ $file.name }}
  readOnly: true
{{- end }}
{{- end }}
{{- end -}}


{{- define "secret.store.mount" -}}
{{- if .Values.secrets -}}
{{ $fullname := (include "fullname" .) }}
- name: secrets-store-inline
  mountPath: "/mnt/secrets"
  readOnly: true
{{- end }}
{{- end -}}


{{- define "mounts" }}
{{- include "secret.store.mount" . }}
{{- include "configmap.file.mount" . }}
{{- end }}



