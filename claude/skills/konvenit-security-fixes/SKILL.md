---
name: security-fixes
description: Automated dependency security fixes for Konvenit projects. Creates a pull request with dependency updates for Dependabot alerts. Use when the user asks to fix Dependabot issues, update dependencies for security, create a security fix PR, or mentions a Jira ticket for security updates. Triggers on phrases like "fix dependabot issues", "security dependency updates", "create security PR for MP-1234", "fix security vulnerabilities in dependencies".
---

# Security Fixes - Automated Dependency Updates

Automates the process of fixing Dependabot security alerts by updating dependencies and creating a properly named pull request linked to a Jira ticket.

## Workflow

### 1. Get Jira Ticket Number

Ask the user for the Jira ticket number if not provided:
```
What's the Jira ticket number for this security fix? (e.g., MP-1234)
```

### 2. Create Branch and Update Dependencies

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
6. Create a pull request titled: `<TICKET-NUMBER> security fix`

### 3. Verify Changes

After running the script, review:
- Check which dependencies were updated
- Verify tests are passing
- Confirm Dependabot alerts are resolved

### 4. Output

Provide the user with:
- Branch name
- Commit hash
- PR link (if available)
- List of updated dependencies
- Any errors encountered

## Example Usage

**User**: "Please fix the Dependabot issues for ticket MP-1234"

**Response**:
1. Run `scripts/fix_security_deps.sh MP-1234`
2. Report results:
   ```
   ✅ Created branch: MP-1234-security-fix
   ✅ Updated dependencies:
      - nokogiri: 1.13.0 → 1.13.10
      - rack: 2.2.3 → 2.2.8
   ✅ Committed: MP-1234 security fix (commit: abc123)
   ✅ Pushed to remote
   ✅ Pull request created: [link]
   ```

## Error Handling

If the script encounters errors:
- **Merge conflicts**: Report to user and suggest manual resolution
- **No updates available**: Inform user dependencies are up to date
- **Test failures**: Report which tests failed and ask for guidance
- **Git errors**: Show error message and suggest next steps
