---
name: security-fixes
description: Automated dependency security fixes for Konvenit projects with full Jira integration. Creates a pull request with dependency updates for Dependabot alerts, manages Jira ticket status, and links PR to ticket. Use when the user asks to fix Dependabot issues, update dependencies for security, create a security fix PR, or mentions a Jira ticket for security updates. Triggers on phrases like "fix dependabot issues", "security dependency updates", "create security PR for MP-1234", "fix security vulnerabilities in dependencies".
---

# Security Fixes - Automated Dependency Updates with Jira Integration

Automates the complete workflow of fixing Dependabot security alerts including Jira ticket management, dependency updates, and pull request creation.

## Workflow

### 1. Get Jira Ticket Number

Ask the user for the Jira ticket number if not provided:
```
What's the Jira ticket number for this security fix? (e.g., MP-1234)
```

### 2. Update Jira Ticket Status

Use the `mice-jira-tickets` skill or Atlassian tools to:
- **Assign the ticket to the current user**
- **Move ticket status to "In Arbeit"** (In Progress)

### 3. Create Branch and Update Dependencies

Run the automated script:

```bash
scripts/fix_security_deps.sh <TICKET-NUMBER>
```

The script will:
1. Create a new branch: `<TICKET-NUMBER>-security-fix` from the latest master
2. Run `bundle update --patch` to update Ruby gems
3. Run `yarn upgrade` to update JavaScript packages (if package.json exists)
4. Commit changes with message: `<TICKET-NUMBER> security fix`
5. Push the branch to remote
6. Create a pull request with:
   - Title: `<TICKET-NUMBER> security fix`
   - Body: Including link to Jira ticket
7. Get the PR URL from the output

### 4. Link PR to Jira and Update Status

After PR is created:
- **Post PR link as comment to Jira ticket** using Atlassian tools
- **Move ticket status to "In Codereview"**

### 5. Verify and Report

After running the automation, provide the user with:
- Branch name
- Commit hash
- PR link
- List of updated dependencies
- Jira ticket status confirmation
- Any errors encountered

## Example Usage

**User**: "Please fix the Dependabot issues for ticket MP-1234"

**Claude Response**:
1. Assign MP-1234 to user and move to "In Arbeit"
2. Run `scripts/fix_security_deps.sh MP-1234`
3. Post PR link to Jira ticket
4. Move ticket to "In Codereview"
5. Report results:
   ```
   ✅ Jira MP-1234: Assigned to you, status → In Arbeit
   ✅ Created branch: MP-1234-security-fix
   ✅ Updated dependencies:
      - nokogiri: 1.13.0 → 1.13.10
      - rack: 2.2.3 → 2.2.8
   ✅ Committed: MP-1234 security fix (commit: abc123)
   ✅ PR created: https://github.com/org/repo/pull/123
   ✅ Jira MP-1234: Added PR comment, status → In Codereview
   ```

## Complete Workflow Steps

1. **Start**: Get Jira ticket number
2. **Jira Update 1**: Assign to user + status → "In Arbeit"
3. **Git Operations**: Branch, update deps, commit, push
4. **PR Creation**: Create PR with Jira link in description
5. **Jira Update 2**: Comment with PR link + status → "In Codereview"
6. **Report**: Summarize all actions taken

## Jira Integration Details

### Ticket Transitions
- **Start** → "In Arbeit" (when starting work)
- **In Arbeit** → "In Codereview" (when PR is created)

### PR Description Template
```markdown
Security dependency updates for [MP-1234](https://konvenit.atlassian.net/browse/MP-1234)

## Changes
- Updated Ruby gems (patch versions)
- Updated JavaScript packages

## Testing
- [ ] All tests passing
- [ ] Dependabot alerts resolved
- [ ] No breaking changes detected

Jira: MP-1234
```

### Jira Comment Template
```
Pull Request created: [PR Title|PR_URL]

Security dependencies updated automatically.
```

## Error Handling

If the script encounters errors:
- **Jira access issues**: Report error and continue with git operations
- **Merge conflicts**: Report to user and suggest manual resolution
- **No updates available**: Inform user dependencies are up to date
- **Test failures**: Report which tests failed and ask for guidance
- **Git errors**: Show error message and suggest next steps
- **PR creation failed**: Provide manual PR creation link

## Integration with Other Skills

This skill integrates with:
- **mice-jira-tickets**: For Jira ticket management operations
- **Atlassian**: For direct Jira API access (ticket updates, comments)
