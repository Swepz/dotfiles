function claude --description 'claude with directory trust preseeded'
    python3 -c '
import json, os, sys, tempfile

path = os.path.expanduser("~/.claude.json")
cwd = sys.argv[1]
with open(path) as fh:
    config = json.load(fh)
project = config.setdefault("projects", {}).setdefault(cwd, {})
if project.get("hasTrustDialogAccepted") is not True:
    project["hasTrustDialogAccepted"] = True
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), suffix=".tmp")
    with os.fdopen(fd, "w") as fh:
        json.dump(config, fh, indent=2)
    os.replace(tmp, path)
' (pwd)
    command claude --dangerously-skip-permissions $argv
end
