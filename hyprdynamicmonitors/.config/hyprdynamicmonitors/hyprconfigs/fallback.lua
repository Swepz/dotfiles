{{- range .Monitors }}
{{- if eq .Description "" }}
hl.monitor({ output = "{{ .Name }}", disabled = true })
{{- end }}
{{- end }}

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})
