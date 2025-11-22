## Description

<!-- Provide a brief description of the changes in this PR -->

## Type of Change

<!-- Mark the relevant option with an "x" -->

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Refactoring (no functional changes)
- [ ] Performance improvement
- [ ] Security patch

## Related Issues

<!-- Link to related issues (if any) -->

Closes #
Related to #

## Checklist

### Code Quality

- [ ] My code follows the project's style guidelines (ESLint/Prettier pass)
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] My changes generate no new warnings or errors
- [ ] No emoji in code (Hero Icons used instead)

### Testing

- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Integration tests pass (if applicable)
- [ ] Test coverage meets requirements:
  - [ ] Backend: >80% coverage
  - [ ] Frontend: >70% coverage
  - [ ] Smart Contracts: >95% coverage

### Documentation

- [ ] I have updated the documentation accordingly
- [ ] I have added/updated comments in the code
- [ ] I have created/updated ADR (if architectural decision)
- [ ] I have updated `CHANGELOG.md` (if user-facing change)

### Dependencies

- [ ] Dependencies installed in correct package directory (NOT in root)
- [ ] No new security vulnerabilities introduced (Snyk/Dependabot check)
- [ ] All dependencies are necessary and justified

### Smart Contracts (if applicable)

- [ ] Gas optimization performed
- [ ] Security best practices followed (reentrancy, overflow, access control)
- [ ] Slither static analysis passed
- [ ] Test coverage >95%
- [ ] Security review requested

### Database Changes (if applicable)

- [ ] Migration created (Prisma/TypeORM)
- [ ] Migration tested (up and down)
- [ ] Migration documented
- [ ] Backward compatible or rollback plan documented

## Screenshots (if applicable)

<!-- Add screenshots for UI changes -->

## Performance Impact

<!-- Describe any performance impact (positive or negative) -->

- [ ] No performance impact
- [ ] Performance improved
- [ ] Performance degraded (justification required)

## Breaking Changes

<!-- List any breaking changes and migration path -->

None / [List breaking changes]

## Deployment Notes

<!-- Any special deployment considerations? -->

- [ ] No special deployment steps required
- [ ] Requires database migration
- [ ] Requires environment variable changes
- [ ] Requires infrastructure changes

## Reviewer Notes

<!-- Any specific areas you want reviewers to focus on? -->

## Post-Deployment Verification

<!-- How to verify this change works in production -->

- [ ] Verify [specific functionality]
- [ ] Check [specific metric]
- [ ] Monitor [specific logs/alerts]
