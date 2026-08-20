local laptop = "desc:Samsung Display Corp. ATNA60KA02-0"

hl.monitor({
    output = laptop,
    mode = "3200x2000@120",
    position = "0x0",
    scale = 1.60,
})

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

for workspace = 1, 10 do
    hl.workspace_rule({
        workspace = tostring(workspace),
        monitor = laptop,
        default = workspace == 1,
        persistent = true,
    })
end
