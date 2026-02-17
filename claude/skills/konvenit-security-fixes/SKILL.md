---
name: konvenit-security-fixes
description: Automated dependency security fixes for Konvenit projects with full Jira integration and Dependabot verification. Creates a pull request with dependency updates for Dependabot alerts, manages Jira ticket status, verifies alerts are resolved, and links PR to ticket. Use when the user asks to fix Dependabot issues, update dependencies for security, create a security fix PR, or mentions a Jira ticket for security updates. Triggers on phrases like "fix dependabot issues", "security dependency updates", "create security PR for MP-1234", "fix security vulnerabilities in dependencies".
---

# Security Fixes - Automated Dependency Updates with Jira Integration

Automates the complete workflow of fixing Dependabot security alerts including Jira ticket management, dependency updates, Dependabot verification, and pull request creation.

## Workflow

please follow these steps in order to ensure a smooth and effective security fix process.

### 1. Get Jira Ticket Number

Check if there is an open  and unassigned Jira ticket with the title "### <APPLICATION>> ### Fix Security Alerts". If not provided,
Ask the user for the Jira ticket number if not provided:
The application name can be determined from the git remote URL, so you can also ask for that if the user does not provide a ticket number. For example: auftragsbuch, katalysator, miceplace, reaktor, ratefinder2, etc.
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
2. Bump Ruby gems to patch versions (if Gemfile exists) - this needs to run bundle that the version updates the Gemfile.lock
3. Run `bundle update --patch` to update Ruby gems
4. Run `yarn upgrade` to update JavaScript packages (if package.json exists)
5. Run tests to ensure updates do not break the build, only on Gems not Apps because they run to long
6. Commit changes with message: `<TICKET-NUMBER> security fix`
7. Push the branch to remote

### 4. Verify Dependabot Alerts Are Fixed

**IMPORTANT**: After updating dependencies, verify that Dependabot alerts are actually resolved:

```bash
# Determine the application name from git remote
APPLICATION=$(git remote get-url origin | sed 's/.*github.com[:/]konvenit\/\(.*\)\.git/\1/')

# Check Dependabot alerts page
echo "Checking: https://github.com/konvenit/${APPLICATION}/security/dependabot"
```

Use `web_fetch` to check the Dependabot security page:
```
https://github.com/konvenit/<APPLICATION>/security/dependabot
```

**What to verify:**
- Are there still open alerts?
- Which alerts were fixed by the updates?
- Are there any remaining alerts that need different action?

**Report to user:**
- ✅ "All Dependabot alerts resolved" (if no alerts remain)
- ⚠️ "X alerts resolved, Y alerts still open" (if some remain)
- List any remaining alerts with severity and package name

**If alerts remain**: Ask user whether to:
- Continue with PR (partial fix)
- Investigate further updates
- Create separate ticket for remaining issues

### 5. Create Pull Request

Only proceed with PR creation if:
- At least some alerts were fixed, OR
- User confirms to proceed

Use GitHub CLI to create PR:

```bash
gh pr create --title "<TICKET-NUMBER> security fix" --body "[PR body with Jira link]"
```

The Pullrequest will include:
- Title: `<TICKET-NUMBER> security fix`
- Body: Including link to Jira ticket and Dependabot verification results
- Get the Pullrequest URL from the output

### 6. Link Pullrequest to Jira and Update Status

After Pullrequest is created:
- **Post Pullrequest link as comment to Jira ticket** using Atlassian tools
- **Move ticket status to "In Codereview"**
- **Assign Pullrequest to reviewer**

### 7. Report Complete Results

Provide comprehensive summary to user:
- Branch name
- Commit hash
- Dependabot verification results (alerts fixed vs remaining)
- Pullrequest link
- List of updated dependencies
- Jira ticket status confirmation
- Any warnings or next steps

## Example Usage

**User**: "Please fix the Dependabot issues for ticket MP-1234"

**Claude Response**:
1. Assign MP-1234 to user and move to "In Arbeit"
2. Run `scripts/fix_security_deps.sh MP-1234`
3. **Verify Dependabot alerts at https://github.com/konvenit/mice-portal/security/dependabot**
4. Report verification results
5. Create Pullrequest (if alerts were fixed)
6. Post Pullrequest link to Jira ticket
7. Assign Pullrequest link to Jira ticket
8. Move ticket to "In Codereview"
9. Final report:
   ```
   ✅ Jira MP-1234: Assigned to you, status → In Arbeit
   ✅ Created branch: MP-1234-security-fix
   ✅ Updated dependencies:
      - nokogiri: 1.13.0 → 1.13.10
      - rack: 2.2.3 → 2.2.8
   ✅ Committed: MP-1234 security fix (commit: abc123)
   ✅ Dependabot verification:
      - 3 critical alerts resolved ✅
      - 0 alerts remaining
      - All security issues fixed!
   ✅ Pullrequest created: https://github.com/konvenit/mice-portal/pull/123
   ✅ Pullrequest assigned to reviewer
   ✅ Jira MP-1234: Added Pullrequest comment, status → In Codereview
   ```

## Complete Workflow Steps

1. **Start**: Get Jira ticket number
2. **Jira Update 1**: Assign to user + status → "In Arbeit"
3. **Git Operations**: Branch, update deps, commit, push
4. **Verification**: Check Dependabot alerts page to confirm fixes
5. **Decision Point**: Proceed with PR based on verification results
6. **PR Creation**: Create PR with Jira link and verification results in description
7. **Jira Update 2**: Comment with PR link + status → "In Codereview"
8. **Report**: Summarize all actions including Dependabot verification

## Dependabot Verification Details

### How to Check
- Use `web_fetch` on `https://github.com/konvenit/<APPLICATION>/security/dependabot`
- Parse the page to identify:
  - Total alerts (before updates)
  - Resolved alerts (after updates)
  - Remaining open alerts
  - Severity levels (Critical, High, Moderate, Low)

### What to Report
```
Dependabot Verification Results:
✅ Fixed: 3 alerts
   - nokogiri: Critical SQL injection vulnerability
   - rack: High HTTP request smuggling
   - rails: Moderate XSS vulnerability

⚠️ Remaining: 1 alert
   - devise: Low information disclosure (requires major version update)

Recommendation: Proceed with PR for fixed alerts, create separate ticket for devise update.
```

### PR Description Template with Verification
```markdown
Security dependency updates for https://miceportal.atlassian.net/browse/MP-1234

## Dependabot Verification
✅ **3 critical/high alerts resolved**
⚠️ 1 low-severity alert remains (requires major version update)

See: https://github.com/konvenit/<APPLICATION>/security/dependabot

## Changes
- Updated Ruby gems (patch versions)
  - nokogiri: 1.13.0 → 1.13.10 (fixes CVE-2023-XXXX)
  - rack: 2.2.3 → 2.2.8 (fixes CVE-2023-YYYY)
- Updated JavaScript packages

```

## Error Handling

If the script encounters errors:
- **Jira access issues**: Report error and continue with git operations
- **Dependabot page inaccessible**: Report error, suggest manual verification
- **No updates available**: Verify Dependabot page to confirm no fixes needed
- **Alerts still open after updates**: Report which alerts remain and why
- **Merge conflicts**: Report to user and suggest manual resolution
- **Test failures**: Report which tests failed and ask for guidance
- **Git errors**: Show error message and suggest next steps
- **PR creation failed**: Provide manual PR creation link

## Integration with Other Skills

This skill integrates with:
- **mice-jira-tickets**: For Jira ticket management operations
- **Atlassian**: For direct Jira API access (ticket updates, comments)
- **web_fetch**: To verify Dependabot alerts are resolved
