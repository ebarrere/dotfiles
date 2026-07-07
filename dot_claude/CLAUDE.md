<!-- # NOTE TO SELF: add something about updating readme -->

# General rules for clarity

The below rules should be followed everywhere, superceding all others, except where explicitly overridden in a more specific rules file.

## Prefer brevity in general

When creating Pull Requests, Jira tickets and adding comments (to any location including, but not limited to GitHub, Jira, Confluence, etc), always be extremely, painfully concise. Brevity is clarity, and giving more context than necessary only confuses things.  In general, do not explain the _why_, except with a single sentence.

The exception to this policy is dedicated documents (Confluence Pages, GitHub docs/.md files specific to the issue or event), where deeper reasoning to explain the decision can be added. When in doubt, keep it brief.

### Code comments

Comments in any code (executable or declarative) should be limited to cases where the context is not obvious, or where the comment genuinely adds clarity; for example, when using a non-standard pattern or library to work around a problem. In the case when a comment is needed, keep it extremely brief, and prefer pointing to an external source (e.g. Jira issue, Confluence page, GitHub document) to provide greater context.

## Jira formatting and Project setup

#### Summary and description

The title/summary of a ticket should _only ever_ contain the initial symptom (should not include any diagnosis), and should be as brief as possible. This will generally be the state that was reported by the user.

The description should also be very brief in general — the initial state before most/any diagnosis has been performed.

#### Comments
Comments should be extremely brief, and should be added for major troubleshooting/diagnosis milestones, in the order that they occurred. When closing a ticket, make sure to note any more robust (non-implemented) solutions that can be used in case the issue re-occurs. When a durable fix is added to a comment, make sure it is bold, or in its own section in order to stand out.

Any commands in comments should be runable **from a user's workstation**, meaning "ssh $USER@$SERVER" or "`kubectl` --context $CONTEXT" should be included as necessary.

#### SRE space

The SRE (Site Reliability Engineering) space/project should be used unless otherwise specified.

#### Issue types and tagging

The two most common issue types are "Bug" (type id 10916) and Task (type id 10883). "Bug" type should be used for anything affecting a user-facing service, or manifesting in a user-facing issue _from the perspective of_ the SRE team **OR** _any other user_. e.g. "AWX backups failing", "Lago invoice download fails", "Some user service affected", etc. "Task" type should be used for most everything else.

We use Epics and Assignment to define what work will be actioned, and review the backlog weekly on Monday. Issues with no Epic or Assignee are deferred until the next meeting. Therefore, everything we are working on should be assigned an Epic and an Asignee.

"Keep the lights on" (SRE-353) can be tagged as the epic for all "Bug"s, and any "Task"s that don't fit another current Epic. When in doubt, ask or search the list to find the best candidate.
