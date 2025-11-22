# Operational Runbooks

This directory contains step-by-step operational procedures for Ghost Protocol infrastructure management, incident response, and disaster recovery.

## Purpose

These runbooks provide:
- **Standardized procedures** for common operational tasks
- **Incident response playbooks** for critical failures
- **Recovery procedures** for disaster scenarios
- **Preventive maintenance** guidelines

## Runbooks

| Runbook | Purpose | Severity | Last Updated |
|---------|---------|----------|--------------|
| [Node Recovery](./node-recovery.md) | Recover failed EKS nodes | High | 2025-11-16 |
| [Database Restore](./database-restore.md) | Restore RDS from backup/snapshot | Critical | 2025-11-16 |
| [Incident Response](./incident-response.md) | Handle production incidents | Critical | 2025-11-16 |
| [Rollback Procedure](./rollback-procedure.md) | Rollback failed deployments | High | 2025-11-16 |
| [Disaster Recovery](./disaster-recovery.md) | Full system recovery | Critical | 2025-11-16 |

## When to Use

### Node Recovery
**Trigger:** Node becomes NotReady, pods evicted, node drain failure
**Frequency:** As needed
**Impact:** Medium (affects pod scheduling)

### Database Restore
**Trigger:** Database corruption, accidental data deletion, ransomware
**Frequency:** Rare (emergency only)
**Impact:** Critical (service downtime during restore)

### Incident Response
**Trigger:** Production outage, security breach, data leak
**Frequency:** As needed
**Impact:** Critical (business impact)

### Rollback Procedure
**Trigger:** Failed deployment, application errors post-release
**Frequency:** Occasional
**Impact:** Medium (temporary service disruption)

### Disaster Recovery
**Trigger:** Region failure, complete infrastructure loss
**Frequency:** Very rare (emergency only)
**Impact:** Critical (full system recovery)

## Incident Severity Levels

### Critical (P0)
- Complete service outage
- Data breach/security incident
- Database corruption
- **Response Time:** Immediate (< 15 minutes)
- **Notification:** Page on-call engineer, notify management

### High (P1)
- Partial service degradation (>50% users affected)
- Performance degradation (>2x normal latency)
- Failed deployments affecting production
- **Response Time:** < 1 hour
- **Notification:** Alert on-call engineer

### Medium (P2)
- Minor service degradation (<50% users affected)
- Non-critical feature failures
- Development/staging environment issues
- **Response Time:** < 4 hours
- **Notification:** Create ticket, notify team

### Low (P3)
- Cosmetic issues
- Documentation updates
- Non-urgent maintenance
- **Response Time:** < 24 hours
- **Notification:** Create ticket

## General Principles

### 1. Communicate Early and Often
- Notify stakeholders immediately when incident detected
- Provide regular status updates (every 30 minutes for P0/P1)
- Document all actions in incident log

### 2. Preserve Evidence
- Take screenshots/logs before making changes
- Save CloudWatch Logs exports for analysis
- Document exact time of incident and actions taken

### 3. Follow the Runbook
- Don't improvise during high-pressure situations
- If runbook is unclear, escalate to senior engineer
- Update runbook after incident (lessons learned)

### 4. Test in Staging First
- Never test recovery procedures in production without validation
- Maintain staging environment that mirrors production
- Practice disaster recovery drills quarterly

### 5. Post-Incident Review
- Conduct blameless post-mortem within 48 hours
- Document root cause analysis
- Create action items to prevent recurrence
- Update runbooks based on learnings

## Emergency Contacts

### On-Call Escalation (Production Incidents)
1. **Primary On-Call:** Check PagerDuty rotation
2. **Secondary On-Call:** Escalate if primary doesn't respond in 15 min
3. **Engineering Manager:** Escalate for P0 incidents
4. **CTO:** Escalate for security incidents or prolonged outages (>2 hours)

### External Contacts
- **AWS Support:** Enterprise Support Plan (1-877-742-2121)
- **Database Team:** [Internal contact]
- **Security Team:** [Internal contact]
- **Legal Team:** [Internal contact] (for data breaches)

## Tools and Access

### Required Access
- AWS Console (admin or read-only depending on role)
- kubectl access to EKS clusters
- Terraform Cloud/Enterprise
- PagerDuty
- Slack (#incidents channel)
- GitHub (for deployment history)

### Monitoring and Alerting
- **Grafana:** https://grafana.ghost-protocol.io
- **Prometheus:** https://prometheus.ghost-protocol.io
- **CloudWatch:** AWS Console → CloudWatch
- **PagerDuty:** https://ghost-protocol.pagerduty.com

## Runbook Maintenance

### Review Schedule
- **Quarterly:** Review all runbooks for accuracy
- **Post-Incident:** Update runbook if procedure was unclear
- **Post-Change:** Update if infrastructure changes affect procedure

### Version Control
- All runbooks are version-controlled in Git
- Changes require PR review
- Tag releases when significant updates are made

## Training

### New Engineer Onboarding
1. Read all runbooks
2. Shadow senior engineer during on-call rotation
3. Practice runbooks in staging environment
4. Complete disaster recovery drill

### Ongoing Training
- Monthly incident response drills
- Quarterly disaster recovery drills
- Annual security incident simulations

## Feedback

If you encounter issues with a runbook:
1. Document the issue during the incident
2. Create a GitHub issue with label `runbook-improvement`
3. Propose changes via PR
4. Discuss in weekly ops meeting

## References

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Google SRE Handbook](https://sre.google/sre-book/table-of-contents/)
- [Incident Response Best Practices](https://response.pagerduty.com/)
