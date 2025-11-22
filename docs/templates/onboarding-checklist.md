# Developer Onboarding Checklist

**New Developer:** [Name]  
**Start Date:** YYYY-MM-DD  
**Role:** [Frontend / Backend / Full-Stack / DevOps / Other]  
**Onboarding Buddy:** [Assigned mentor name]  
**Manager:** [Manager name]

---

## Welcome to Ghost Protocol!

This checklist will guide you through your first week and ensure you have everything you need to start contributing to the Ghost Protocol project.

**Estimated Completion Time:** 1 week

---

## Day 1: Setup & Access

### Administrative Setup

- [ ] **HR Onboarding:** Complete HR paperwork and orientation
- [ ] **Email Setup:** Verify work email is functioning
- [ ] **Calendar Access:** Schedule added to team calendar
- [ ] **Team Introduction:** Introduced to team in standup/meeting

### Account & Access Setup

- [ ] **GitHub Account**
  - GitHub username: [username]
  - Added to `ghost-protocol` organization
  - Repository access granted: `ghost-protocol-monorepo`

- [ ] **Communication Tools**
  - [ ] Slack workspace joined: [workspace-url]
  - [ ] Added to channels: `#engineering`, `#general`, `#deployments`
  - [ ] Introduce yourself in `#introductions`

- [ ] **Project Management**
  - [ ] Jira/Linear account created
  - [ ] Access to project board granted
  - [ ] Familiarized with sprint workflow

- [ ] **Cloud Services**
  - [ ] AWS/GCP account (if applicable)
  - [ ] Staging environment access
  - [ ] Production read-only access

- [ ] **Monitoring & Logging**
  - [ ] Sentry account
  - [ ] Grafana/Datadog dashboard access
  - [ ] Log aggregation tool access

---

## Day 1-2: Development Environment

### Local Development Setup

- [ ] **Clone Repository**
  ```bash
  git clone git@github.com:ghost-protocol/ghost-protocol-monorepo.git
  cd ghost-protocol-monorepo
  ```

- [ ] **Install Prerequisites**
  - [ ] Node.js 18+ installed: `node --version`
  - [ ] npm 9+ installed: `npm --version`
  - [ ] Docker Desktop installed (for local database)
  - [ ] Git configured with proper user name/email

- [ ] **Install Dependencies**
  ```bash
  npm install
  cd frontend && npm install && cd ..
  cd backend && npm install && cd ..
  ```

- [ ] **Environment Variables**
  - [ ] Copy `.env.example` to `.env`
  - [ ] Request secrets from team lead (via 1Password/Vault)
  - [ ] Verify all required env vars are set

- [ ] **Database Setup**
  ```bash
  cd backend
  npm run db:create
  npm run migrate:up
  npm run seed:dev
  ```
  - [ ] Database running: `localhost:5432`
  - [ ] Test data seeded successfully

- [ ] **Start Development Servers**
  ```bash
  # Frontend
  cd frontend && npm run dev  # localhost:5000
  
  # Backend
  cd backend && npm run dev  # localhost:4000
  ```
  - [ ] Frontend accessible: http://localhost:5000
  - [ ] Backend API accessible: http://localhost:4000/api
  - [ ] Swagger docs accessible: http://localhost:4000/api/docs

- [ ] **Verify Setup**
  - [ ] Run frontend tests: `cd frontend && npm test`
  - [ ] Run backend tests: `cd backend && npm test`
  - [ ] Run linter: `npm run lint`
  - [ ] All checks pass successfully

---

## Day 2-3: Codebase Exploration

### Documentation Review

- [ ] **Read Core Documentation**
  - [ ] `README.md` - Project overview
  - [ ] `frontend/README.md` - Frontend architecture
  - [ ] `backend/README.md` - Backend architecture
  - [ ] `doc/architecture.md` - System architecture
  - [ ] `doc/roadmap.md` - Product roadmap
  - [ ] `doc/whitepaper.md` - Project vision
  - [ ] `agent-rules.md` - Development guidelines

- [ ] **Review Sprint Documentation**
  - [ ] Current sprint goals: `doc/sprints/sprint-XX/goals.md`
  - [ ] Current sprint backlog: `doc/sprints/sprint-XX/backlog.md`
  - [ ] Sprint progress: `doc/sprints/sprint-XX/progress.md`

- [ ] **Review Process Documentation**
  - [ ] CI/CD guide: `doc/ci-cd-guide.md`
  - [ ] Deployment process: `doc/deployment.md`
  - [ ] Documentation ownership: `doc/DOCUMENTATION-OWNERSHIP.md`
  - [ ] ADR process: `doc/adr/README.md`

### Codebase Walkthrough

- [ ] **Frontend Architecture** (if Frontend/Full-Stack)
  - [ ] Component structure: `frontend/src/components/`
  - [ ] Three.js modules: `frontend/src/modules/three/`
  - [ ] GSAP animations: `frontend/src/modules/gsap/`
  - [ ] State management patterns
  - [ ] Routing structure

- [ ] **Backend Architecture** (if Backend/Full-Stack)
  - [ ] Module structure: `backend/src/*/`
  - [ ] API endpoints and controllers
  - [ ] Service layer patterns
  - [ ] Database schema: `backend/prisma/schema.prisma`
  - [ ] Authentication flow

- [ ] **Shared Code**
  - [ ] Type definitions
  - [ ] Utility functions
  - [ ] Constants and configurations

---

## Day 3-4: Team Integration

### Team Meetings

- [ ] **Attend Standup** (Daily)
  - Time: [Time]
  - Format: [In-person/Remote]
  - What to share: What you did, what you'll do, any blockers

- [ ] **Sprint Planning** (Bi-weekly)
  - Understand sprint goals
  - Observe story estimation process
  - Ask questions about user stories

- [ ] **Team Retrospective** (Bi-weekly)
  - Participate in what went well / what to improve

- [ ] **Architecture Review** (As needed)
  - Observe ADR creation and approval process

### 1-on-1 Meetings

- [ ] **Onboarding Buddy Meeting**
  - Scheduled: YYYY-MM-DD
  - Topics: Codebase questions, team culture, best practices

- [ ] **Manager 1-on-1**
  - Scheduled: YYYY-MM-DD
  - Topics: Role expectations, career goals, feedback

- [ ] **Tech Lead Meeting**
  - Scheduled: YYYY-MM-DD
  - Topics: Technical architecture, current priorities

### Knowledge Transfer

- [ ] **Pair Programming Session** with [Buddy Name]
  - Topic: [Feature or module]
  - Duration: 2-4 hours
  - Date: YYYY-MM-DD

- [ ] **Code Review Walkthrough**
  - Observe code review process
  - Learn PR guidelines and standards
  - Understand approval flow

---

## Day 4-5: First Contribution

### Pick Your First Task

- [ ] **Browse Backlog**
  - Filter by: `good-first-issue` or `beginner-friendly`
  - Understand task requirements
  - Ask clarifying questions

- [ ] **Task Selected:** [Task ID and title]
  - Story points: [X]
  - Estimated effort: [Y hours]
  - Assigned: YYYY-MM-DD

### Development Workflow

- [ ] **Create Feature Branch**
  ```bash
  git checkout -b feature/[task-id]-[brief-description]
  ```

- [ ] **Make Changes**
  - Write code following style guide
  - Add tests for new functionality
  - Update documentation if needed

- [ ] **Local Testing**
  - [ ] Unit tests pass: `npm test`
  - [ ] Linter passes: `npm run lint`
  - [ ] Type checking passes: `npm run type-check`
  - [ ] Manual testing completed

- [ ] **Create Pull Request**
  - [ ] PR title follows convention: `[TYPE] Brief description (#task-id)`
  - [ ] PR description explains changes
  - [ ] Screenshots/videos attached (for UI changes)
  - [ ] Linked to task/issue
  - [ ] Requested review from team lead and buddy

- [ ] **Address Review Feedback**
  - [ ] Respond to all comments
  - [ ] Make requested changes
  - [ ] Re-request review

- [ ] **Merge PR**
  - [ ] Approved by 2+ reviewers
  - [ ] CI/CD pipeline passes
  - [ ] Merged to `main` branch

---

## Week 1: Reflection & Feedback

### Onboarding Feedback

- [ ] **Complete Onboarding Survey**
  - What went well?
  - What was confusing?
  - What could be improved?
  - Any blockers or challenges?

- [ ] **Schedule Week 1 Retrospective**
  - With onboarding buddy
  - With manager
  - Discuss first week experience

### Knowledge Check

- [ ] **Can you answer these questions?**
  - [ ] What are the three core products of Ghost Protocol?
  - [ ] What is the tech stack (frontend and backend)?
  - [ ] How do you run the app locally?
  - [ ] What is the sprint cadence (duration and schedule)?
  - [ ] What is the code review process?
  - [ ] How do you deploy to staging/production?
  - [ ] What is an ADR and when to create one?

---

## Week 2+: Continued Learning

### Advanced Topics

- [ ] **Deep Dive into Your Focus Area**
  - [ ] Frontend: Three.js, GSAP animations, state management
  - [ ] Backend: Database optimization, API design, authentication
  - [ ] DevOps: CI/CD pipeline, monitoring, deployment

- [ ] **Review ADRs**
  - [ ] Read all ADRs in `doc/adr/`
  - [ ] Understand major architectural decisions

- [ ] **Explore Blockchain Integration** (if applicable)
  - [ ] Multi-chain wallet architecture
  - [ ] Transaction intent execution
  - [ ] Smart contract interactions

### Ownership & Impact

- [ ] **Claim Module Ownership**
  - [ ] Discuss with tech lead
  - [ ] Become point person for [module name]
  - [ ] Document your expertise

- [ ] **Contribute to Documentation**
  - [ ] Fix outdated docs you encountered
  - [ ] Add missing examples
  - [ ] Improve onboarding checklist

- [ ] **Mentor Future New Hires**
  - [ ] Volunteer to be onboarding buddy
  - [ ] Share your onboarding experience

---

## Resources & Links

### Documentation

- **Repository:** https://github.com/ghost-protocol/ghost-protocol-monorepo
- **Figma Designs:** [Link]
- **API Documentation:** http://localhost:4000/api/docs (local)
- **Wiki/Notion:** [Link]

### Team Contacts

| Role | Name | Slack | Email |
|------|------|-------|-------|
| Tech Lead | [Name] | @handle | [email] |
| Product Manager | [Name] | @handle | [email] |
| DevOps Lead | [Name] | @handle | [email] |
| Frontend Lead | [Name] | @handle | [email] |
| Backend Lead | [Name] | @handle | [email] |
| Onboarding Buddy | [Name] | @handle | [email] |

### Emergency Contacts

- **Production Outage:** [On-call rotation / PagerDuty]
- **Security Issue:** [Security team email]
- **HR Issues:** [HR contact]

---

## Checklist Completion

- [ ] All Day 1 items completed
- [ ] All Day 1-2 items completed
- [ ] All Day 2-3 items completed
- [ ] All Day 3-4 items completed
- [ ] All Day 4-5 items completed
- [ ] Week 1 reflection completed
- [ ] First PR merged successfully

**Onboarding Completion Date:** YYYY-MM-DD

**Sign-off:**
- **New Developer:** [Name] - Date
- **Onboarding Buddy:** [Name] - Date
- **Manager:** [Name] - Date

---

## Welcome to the Team!

You're now fully onboarded and ready to contribute to Ghost Protocol. If you have any questions or need help, don't hesitate to reach out to your buddy, team lead, or anyone on the team.

**Let's build something amazing together!**

---

**Maintained by:** Tech Lead + HR  
**Last Updated:** November 10, 2025  
**Next Review:** February 10, 2026
