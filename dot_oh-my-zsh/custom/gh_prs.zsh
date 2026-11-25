# My open org PRs blocked only on approval: non-draft, merge BLOCKED, checks not failing, no changes requested.
ghprs() {
  local q='is:pr is:open author:@me draft:false org:crexendo-cloudops org:netsapiens' json i
  for i in {1..5}; do
    # mergeStateStatus is computed lazily; UNKNOWN resolves after the first request.
    json=$(gh api graphql -H 'Accept: application/vnd.github.merge-info-preview+json' -f q="$q" \
      -f query='query($q:String!){search(query:$q,type:ISSUE,first:100){nodes{... on PullRequest{url mergeStateStatus reviewDecision commits(last:1){nodes{commit{statusCheckRollup{state}}}}}}}}') || return
    print -r -- "$json" | jq -e '.data.search.nodes|any(.mergeStateStatus=="UNKNOWN")' >/dev/null || break
    sleep 2
  done
  print -r -- "$json" | jq -r '.data.search.nodes[] | select(.mergeStateStatus=="BLOCKED" and .reviewDecision!="CHANGES_REQUESTED" and (.commits.nodes[0].commit.statusCheckRollup.state|IN("FAILURE","ERROR")|not)) | .url'
}
