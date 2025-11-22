# Sprint Planning

This directory tracks sprint goals, progress, and deliverables for the Ghost Protocol project.

## Sprint Cycle

- **Duration:** 2 weeks (10 working days)
- **Planning:** First Monday of sprint
- **Retrospective:** Last Friday of sprint
- **Demo:** Last Friday after retrospective

## Current Sprint

**Sprint 1** (November 10 - November 23, 2025)
- Status: In Progress
- Goal: Complete Phase 0 (Planning & Setup)

## Sprint Structure

Each sprint directory contains:

```
sprints/
├── sprint-01/
│   ├── README.md              # Sprint overview
│   ├── goals.md               # Sprint goals and success criteria
│   ├── backlog.md             # Stories planned for sprint
│   ├── progress.md            # Daily progress updates
│   └── demo.md                # Demo script and outcomes
└── sprint-02/
    └── ...
```

## Sprint Template

### goals.md
```markdown
# Sprint [N] Goals

**Sprint:** [Start Date] - [End Date]
**Theme:** [Sprint theme or focus area]

## Primary Goals

1. [Goal 1]
2. [Goal 2]
3. [Goal 3]

## Success Criteria

- [ ] [Measurable criterion 1]
- [ ] [Measurable criterion 2]
- [ ] [Measurable criterion 3]

## Key Metrics

- Story points committed: [X]
- Story points completed: [Y]
- Velocity: [Z]
```

### backlog.md
```markdown
# Sprint [N] Backlog

## Committed Stories

| ID | Story | Points | Assignee | Status |
|----|-------|--------|----------|--------|
| GH-001 | As a user, I want... | 5 | @dev1 | In Progress |
| GH-002 | As a user, I want... | 3 | @dev2 | Done |

## In Progress

[Stories currently being worked on]

## Done

[Completed stories]

## Blocked

[Stories with blockers]
```

### progress.md
```markdown
# Sprint [N] Progress

## Week 1

### Day 1 (Monday)
- [Update 1]
- [Update 2]

### Day 2 (Tuesday)
- [Update 1]
- [Update 2]

## Week 2

[Continue...]
```

## Sprint Planning Process

1. **Review Previous Sprint**
   - Velocity from last sprint
   - Incomplete stories
   - Lessons learned

2. **Refine Backlog**
   - Groom top stories
   - Estimate with planning poker
   - Clarify acceptance criteria

3. **Set Sprint Goal**
   - What's the focus?
   - What will we demo?

4. **Commit to Stories**
   - Based on team velocity
   - Leave buffer for unexpected work

5. **Assign Tasks**
   - Break stories into tasks
   - Assign owners
   - Identify dependencies

## Definition of Done

A story is considered "Done" when:
- [ ] Code implemented and merged
- [ ] Unit tests written (>80% coverage)
- [ ] Integration tests pass
- [ ] Code reviewed by at least 1 peer
- [ ] Documentation updated
- [ ] Deployed to staging
- [ ] Acceptance criteria met
- [ ] Product owner approves

## Velocity Tracking

| Sprint | Committed | Completed | Velocity | Carry Over |
|--------|-----------|-----------|----------|------------|
| 1 | 30 | TBD | TBD | TBD |
| 2 | - | - | - | - |

## Best Practices

1. **Don't overcommit** - Use 80% of theoretical capacity
2. **Include buffer** - Account for meetings, reviews, debugging
3. **Break down large stories** - Keep stories <8 points
4. **Update daily** - Keep progress.md current
5. **Address blockers immediately** - Don't let them linger
6. **Celebrate wins** - Acknowledge completed work

## Sprint Ceremonies

### Sprint Planning (2 hours)
- Review backlog
- Estimate stories
- Commit to sprint goal
- Break down tasks

### Daily Standup (15 minutes)
- What did you do yesterday?
- What will you do today?
- Any blockers?

### Sprint Review/Demo (1 hour)
- Demo completed work
- Get feedback
- Update product backlog

### Sprint Retrospective (1 hour)
- What went well?
- What could improve?
- Action items for next sprint

---

**Maintained by:** Ghost Protocol Development Team
