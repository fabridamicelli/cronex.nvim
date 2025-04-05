USERNAME="fabridamicelli"
REPOSITORY="cronex.nvim"
RESULT=$(
    gh api repos/$USERNAME/$REPOSITORY/traffic/clones |
        jq -r '.clones | group_by(.timestamp | split("T")[0]) | map({date: .[0].timestamp | split("T")[0], count: (map(.count) | add)}) | .[0:-1] | .[] | @json'
)
echo "${RESULT}" >>downloads.jsonl
