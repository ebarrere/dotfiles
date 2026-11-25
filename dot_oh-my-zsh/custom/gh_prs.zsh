# My open org PRs needing approval: non-draft, mergeable, checks not failing, not yet approved/changes-requested.
prs-for-review() {
  gh api graphql \
    -f q='is:pr is:open author:@me draft:false org:crexendo-cloudops org:netsapiens' \
    -f query='query($q:String!){search(query:$q,type:ISSUE,first:100){nodes{... on PullRequest{url mergeable reviewDecision commits(last:1){nodes{commit{statusCheckRollup{state}}}}}}}}' \
    --jq '.data.search.nodes[] | select(.mergeable=="MERGEABLE" and (.reviewDecision|IN("APPROVED","CHANGES_REQUESTED")|not) and (.commits.nodes[0].commit.statusCheckRollup.state|IN("FAILURE","ERROR")|not)) | .url'
}
