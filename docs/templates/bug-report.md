# Bug Report: [Brief Description]

**Date Reported:** YYYY-MM-DD  
**Reporter:** [Your Name]  
**Severity:** [Critical | High | Medium | Low]  
**Status:** [New | In Progress | Resolved | Closed]  
**Assigned To:** [Developer Name or Unassigned]

---

## Bug Summary

[One-sentence description of the bug]

---

## Environment

| Field | Value |
|-------|-------|
| **Browser** | [Chrome 120 / Firefox 121 / Safari 17] |
| **OS** | [Windows 11 / macOS 14 / Ubuntu 22.04] |
| **Device** | [Desktop / Mobile / Tablet] |
| **App Version** | [v1.2.3] |
| **Environment** | [Production / Staging / Local Development] |
| **URL** | [URL where bug occurs] |

**Additional Context:**
- Node.js Version: [18.x]
- Database: [PostgreSQL 15.x]
- Other relevant software versions

---

## Severity Classification

### Critical
- Application crashes or becomes unusable
- Data loss or corruption
- Security vulnerability
- Production outage affecting all users

### High
- Major feature is broken
- Affects large number of users
- No workaround available
- Significant performance degradation

### Medium
- Feature works but with issues
- Affects some users
- Workaround exists
- Minor performance impact

### Low
- Cosmetic issues
- Minor usability issues
- Affects very few users
- Easy workaround available

**Selected Severity:** [Explain why this severity level was chosen]

---

## Steps to Reproduce

1. [First step]
2. [Second step]
3. [Third step]
4. [... continue]

**Frequency:** [Always | Often (>50%) | Sometimes (<50%) | Rarely]

**First Noticed:** [Date or version when you first noticed this bug]

---

## Expected Behavior

[Describe what should happen]

---

## Actual Behavior

[Describe what actually happens]

---

## Screenshots / Videos

[Attach or link to screenshots, screen recordings, or GIFs demonstrating the bug]

**Screenshot 1:** [Description]
![Screenshot](url-to-screenshot)

**Video:** [Link to Loom/video]

---

## Error Messages

### Console Errors

```
[Paste exact error message from browser console or terminal]
```

### Stack Trace

```
[Paste full stack trace if available]
```

### Network Errors (if applicable)

**Failed Request:**
```
Request URL: [URL]
Status Code: [500 Internal Server Error]
Response:
{
  "error": "Internal Server Error",
  "message": "[error message]"
}
```

---

## Logs

### Frontend Logs

```
[Paste relevant frontend logs]
```

### Backend Logs

```
[Paste relevant backend logs with timestamps]
```

### Database Logs (if applicable)

```
[Paste relevant database query logs]
```

---

## Impact Analysis

### User Impact

- **Number of Users Affected:** [Estimate or exact number]
- **User Types Affected:** [All users / Logged-in users / Admins / etc.]
- **Business Impact:** [Revenue loss / User churn / Support tickets / etc.]

### Technical Impact

- **Affected Components:**
  - [ ] Frontend (Next.js)
  - [ ] Backend API (NestJS)
  - [ ] Database (PostgreSQL)
  - [ ] Blockchain Integration
  - [ ] Third-party Services

- **Related Features:**
  - [Feature 1]
  - [Feature 2]

---

## Root Cause (For Developers)

**Hypothesis:** [Initial theory about what's causing the bug]

**Investigation Notes:**
- [Note 1]
- [Note 2]

**Confirmed Root Cause:** [Fill in after investigation]

**Related Code:**
- File: `[path/to/file.ts]`
- Line: [123]
- Function: `[functionName]`

---

## Workaround (If Available)

### Temporary Solution

[Describe temporary workaround users can use while bug is being fixed]

**Steps:**
1. [Step 1]
2. [Step 2]

**Limitations:** [What doesn't work with this workaround]

---

## Proposed Fix

### Solution Approach

[Describe how you plan to fix this bug]

**Files to Modify:**
- `[path/to/file1.ts]` - [What changes]
- `[path/to/file2.ts]` - [What changes]

**Testing Plan:**
- [ ] Unit tests added/modified
- [ ] Integration tests added
- [ ] Manual testing scenarios

**Estimated Effort:** [Story points or hours]

---

## Related Issues

- **Related Bug:** [Link to related GitHub issue]
- **Duplicate of:** [Link if this is a duplicate]
- **Blocks:** [Issues blocked by this bug]
- **Blocked by:** [Issues blocking this fix]

---

## Regression Testing

### Areas to Test After Fix

- [ ] [Test area 1]
- [ ] [Test area 2]
- [ ] [Test area 3]

### Automated Tests to Add

- [ ] Unit test: `[test name]`
- [ ] Integration test: `[test name]`
- [ ] E2E test: `[test name]`

---

## Additional Notes

[Any other relevant information about this bug]

---

## Resolution (To Be Filled After Fix)

**Fixed In:** [Version number or PR link]

**Fix Description:** [Brief description of the fix]

**Verified By:** [QA tester name]

**Date Resolved:** YYYY-MM-DD

**Prevention Measures:** [What was done to prevent similar bugs in the future]

---

## Checklist

- [ ] Bug is reproducible
- [ ] Environment details provided
- [ ] Screenshots/videos attached
- [ ] Error messages included
- [ ] Impact analysis completed
- [ ] Severity correctly classified
- [ ] Assigned to appropriate developer
- [ ] Related issues linked

---

**Reported by:** [Your Name]  
**Last Updated:** YYYY-MM-DD
