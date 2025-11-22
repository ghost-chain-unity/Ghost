# Agent Rules — Ghost Protocol Development Guide

**Last Updated:** November 10, 2025  
**Purpose:** Comprehensive guide for agents working on Ghost Protocol  
**Scope:** Project structure, concepts, development guidelines, and workflows

---

## 🧠 CoT World Class Framework (Phase 0.2.1 - Team Assembly)

**Purpose:** Define systematic deep thinking protocol and collaboration model for 3 specialized Replit agents operating at professional world-class developer level.

**Framework Version:** 1.0  
**Effective Date:** November 10, 2025  
**Review Cycle:** Monthly or after major milestones

---

### I. Deep Thinking Neural Protocol

Before planning or executing ANY task, agents MUST follow this tri-level analysis framework:

#### Level 1: Context Scan (2-5 minutes)

**Mandatory Checks:**
```yaml
Current State:
  - What exists? (Read replit.md, check codebase)
  - What's in progress? (Check workflows, recent commits)
  - What's blocked? (Identify dependencies)

User Intent:
  - What is the REAL problem? (Beyond stated request)
  - What are implicit requirements? (Performance, security, UX)
  - What does success look like? (Clear acceptance criteria)

Project Context:
  - How does this fit Ghost Protocol vision? (ChainGhost/G3Mail/Ghonity)
  - Which product affected? (ChainGhost unified/G3Mail/Ghonity community)
  - What's the flywheel impact? (Does it strengthen ecosystem?)
```

**Output:** Context Brief (3-5 bullet points)

#### Level 2: Systems Impact Analysis (5-10 minutes)

**Mandatory Analysis:**
```yaml
Architectural Dependencies:
  - Frontend impact? (UI components, state, routing)
  - Backend impact? (APIs, database, services)
  - Blockchain impact? (Smart contracts, RPC, indexer)
  - Cross-layer touchpoints? (API contracts, data flow)

Integration Points:
  - What services/modules interact?
  - What data flows change?
  - What interfaces need updates?
  - What shared state is affected?

Performance Implications:
  - Database query impact (N+1, indexes needed?)
  - API latency concerns (pagination, caching)
  - Frontend bundle size (code splitting, lazy loading)
  - Blockchain gas costs (contract optimization)

Security Considerations:
  - Authentication/authorization changes?
  - Data exposure risks (PII, wallet addresses)?
  - Input validation requirements?
  - Rate limiting needs?
```

**Output:** Systems Impact Map (dependency graph + risk assessment)

#### Level 3: Failure Mode Stress Test (5-8 minutes)

**Mandatory Edge Case Enumeration:**
```yaml
What Could Go Wrong:
  - Empty states (no data, no transactions)
  - Error states (network failure, timeout, invalid input)
  - Boundary conditions (max length, overflow, underflow)
  - Race conditions (concurrent updates, stale data)
  - Backward compatibility (breaking changes, migrations)

Rollback Strategy:
  - Can this be reverted? (Database migrations, contract upgrades)
  - What's the blast radius? (Affected users, data integrity)
  - How to detect issues? (Monitoring, alerts, health checks)
  - What's the recovery process? (Rollback steps, data repair)

User Experience Degradation:
  - Loading states (skeleton screens, progress indicators)
  - Offline support (graceful degradation, error messages)
  - Mobile considerations (touch targets, viewport, performance)
  - Accessibility (keyboard nav, screen readers, color contrast)
```

**Output:** Failure Mode Matrix (edge cases + mitigation strategies)

---

#### Thought Templates (Reusable Patterns)

**Template 1: New Feature Analysis**
```markdown
## Feature: [Name]

### Context Scan
- **Current State:** [What exists]
- **User Need:** [Problem being solved]
- **Success Criteria:** [Definition of done]

### Systems Impact
- **Frontend:** [Components, state, routing]
- **Backend:** [APIs, database, services]
- **Blockchain:** [Contracts, indexer, RPC]
- **Cross-Layer:** [Touchpoints, data flow]

### Failure Modes
- **Edge Cases:** [List 5+ scenarios]
- **Mitigation:** [How to handle each]
- **Rollback:** [Recovery strategy]

### Decision Record
- **Assumptions:** [Explicit list]
- **Trade-offs:** [What we're choosing vs alternatives]
- **Unknowns:** [What needs validation]
```

**Template 2: Bug Fix Analysis**
```markdown
## Bug: [Description]

### Root Cause Analysis
- **Symptom:** [What user sees]
- **Root Cause:** [Underlying issue]
- **Why It Happened:** [Missing check, race condition, etc.]

### Impact Assessment
- **Severity:** [Critical/High/Medium/Low]
- **Affected Users:** [Scope]
- **Data Integrity:** [Is data corrupted?]

### Fix Strategy
- **Immediate Fix:** [Quick patch]
- **Long-term Fix:** [Proper solution]
- **Regression Prevention:** [How to avoid repeat]

### Testing Plan
- **Unit Tests:** [What to test]
- **Integration Tests:** [End-to-end scenarios]
- **Manual QA:** [User flow verification]
```

---

#### Time-Boxed Thinking Cycles

**Divergence Phase (Explore):** 60% of thinking time
- Generate multiple solution approaches
- List all edge cases
- Identify all dependencies
- Document all assumptions

**Convergence Phase (Decide):** 40% of thinking time
- Evaluate approaches against criteria (complexity, performance, maintainability)
- Select best solution with explicit reasoning
- Document trade-offs
- Create action plan

**Rule:** No implementation until convergence phase completes.

---

### II. Agent Specialization & Role Charters

#### Agent Frontend (React/Next.js Expert)

**Primary Responsibilities:**
```yaml
Core Domain:
  - React 18+ components (functional, hooks)
  - Next.js 14+ architecture (App Router, SSR, SSG)
  - 3D graphics (Three.js, @react-three/fiber and spline)
  - UI/UX implementation (Tailwind, HERO UI)
  - Animation (GSAP, Framer Motion)
  - State management (Context, Zustand)
  - Frontend build optimization

Quality Gates:
  - Component Storybook documentation
  - Accessibility compliance (WCAG 2.1 AA)
  - Mobile responsiveness (tested on 3+ viewports)
  - Performance budget (Lighthouse score >90)
  - Zero console errors/warnings
```

**Shared Understanding Checkpoints:**
```yaml
With Backend:
  - API contracts (endpoints, payloads, error codes)
  - Authentication flow (JWT, session management)
  - Real-time updates (WebSocket, polling strategy)

With Blockchain:
  - Wallet connection flow (MetaMask, WalletConnect)
  - Transaction signing UX (pending, confirmed, failed states)
  - Multi-chain display (network switching, balance aggregation)
```

**Cross-Domain Touchpoints:**
```yaml
Must Coordinate On:
  - API response formats (ensure frontend can parse)
  - Error handling strategy (error codes, user messages)
  - Loading/success/error states (consistent patterns)
  - Data validation (client-side mirrors backend)
```

---

#### Agent Backend (Node.js/NestJS Expert)

**Primary Responsibilities:**
```yaml
Core Domain:
  - NestJS 10+ architecture (modules, controllers, services)
  - PostgreSQL + Prisma ORM (schema, migrations, queries)
  - RESTful API design (versioning, pagination, filtering)
  - Authentication (JWT, session, rate limiting)
  - Database optimization (indexes, query plans, caching)
  - AI/ML integration (LLM APIs hugging face, embeddings, vector search)
  - Microservices coordination (when scaling)

Quality Gates:
  - OpenAPI/Swagger documentation
  - Unit test coverage >80%
  - Integration tests for critical paths
  - Database migration safety (reversible, tested)
  - API response time <200ms (p95)
  - Security audit pass (OWASP Top 10)
```

**Shared Understanding Checkpoints:**
```yaml
With Frontend:
  - API contracts (versioned, documented)
  - Authentication tokens (format, expiration, refresh)
  - Real-time updates (SSE, WebSocket protocols)

With Blockchain:
  - Transaction indexer data format
  - Wallet address validation
  - Event parsing requirements
```

**Cross-Domain Touchpoints:**
```yaml
Must Coordinate On:
  - Database schema changes (migration coordination)
  - API versioning (backward compatibility)
  - Error handling (consistent codes, messages)
  - Performance SLAs (latency budgets, caching strategy)
```

---

#### Agent Blockchain (Solidity/ERC-4337 Expert)

**Primary Responsibilities:**
```yaml
Core Domain:
  - Solidity smart contracts (upgradeable patterns)
  - ERC-4337 account abstraction (bundler, paymaster)
  - Multi-chain integration (Ethereum, BSC, Polygon, Arbitrum, Base)
  - RPC provider management (Alchemy, Infura, fallbacks)
  - Transaction indexer (event parsing, data normalization)
  - Gas optimization (contract optimization, batching)
  - Security audits (reentrancy, overflow, access control)

Quality Gates:
  - Contract test coverage >95%
  - Formal verification (critical contracts)
  - Third-party audit (before mainnet)
  - Gas profiling (optimize hot paths)
  - Testnet deployment validation
  - Upgrade/rollback plan documented
```

**Shared Understanding Checkpoints:**
```yaml
With Backend:
  - Event schema (what backend needs to index)
  - Transaction data format (parsing requirements)
  - RPC call patterns (rate limits, caching)

With Frontend:
  - Wallet interaction flow (signing, broadcasting)
  - Transaction status updates (pending, confirmed, failed)
  - Error messages (user-friendly translations)
```

**Cross-Domain Touchpoints:**
```yaml
Must Coordinate On:
  - Contract ABI changes (versioning, backward compatibility)
  - Event emission (what data to log on-chain)
  - Gas estimation (frontend display, backend calculation)
  - Multi-chain support (network IDs, RPC endpoints)
```

---

### III. Collaboration Model

#### Synchronized Scoping Reviews

**Before Starting ANY Task:**
```yaml
Step 1: Individual Analysis (15-30 minutes)
  - Each agent: Run Deep Thinking Neural Protocol
  - Output: Context Brief, Systems Impact Map, Failure Mode Matrix

Step 2: Scoping Review (15-20 minutes)
  - All agents: Share analysis results
  - Identify: Cross-domain dependencies
  - Agree: Handoff points and interfaces
  - Document: Shared assumptions

Step 3: Plan Approval (5 minutes)
  - Frontend: Confirms UI/UX feasibility
  - Backend: Confirms API contract
  - Blockchain: Confirms on-chain requirements
  - Consensus: Proceed or iterate
```

**Output:** Scoping Document (shared in task comments)

---

#### Structured Handoffs

**Phase 1: Plan Brief (Backend → Frontend)**
```yaml
What Backend Provides:
  - API endpoint specification (method, path, auth)
  - Request/response schema (TypeScript types)
  - Error codes and messages
  - Rate limits and pagination
  - Authentication requirements

What Frontend Confirms:
  - Schema matches UI needs
  - Error handling is clear
  - Loading states are defined
  - Edge cases are covered
```

**Phase 2: Design Spec (Frontend → Backend)**
```yaml
What Frontend Provides:
  - User flow diagrams
  - Component hierarchy
  - State management approach
  - API call patterns (when, how often)
  - Real-time update needs

What Backend Confirms:
  - Can support API call patterns
  - Caching strategy is feasible
  - Performance budget is realistic
  - WebSocket/SSE requirements clear
```

**Phase 3: Implementation Notes (Blockchain → Backend)**
```yaml
What Blockchain Provides:
  - Contract ABI and addresses
  - Event emission specification
  - RPC call requirements
  - Gas estimation formulas
  - Network-specific quirks

What Backend Confirms:
  - Can parse events correctly
  - RPC call rate limits understood
  - Data normalization approach agreed
  - Multi-chain indexing strategy clear
```

---

#### Shared Knowledge Artifacts

**Mandatory Documentation:**
```yaml
Architecture Decision Records (ADRs) — REQUIRED:
  - ⚠️ MANDATORY for ALL architectural decisions
  - Location: doc/adr/
  - Format: Markdown (use template.md)
  - When: BEFORE any architectural implementation
  - Includes: Context, Drivers, Options, Decision, Consequences, Pros/Cons, Links, Notes, Review Date
  - Review: MUST be architect-approved before proceeding
  - See Section IV for detailed mandatory policy

API Documentation:
  - Location: backend/openapi.yaml
  - Format: OpenAPI 3.0
  - When: Before implementing endpoints
  - Includes: All endpoints, schemas, examples

Contract Documentation:
  - Location: contracts/docs/
  - Format: NatSpec + Markdown
  - When: Before deploying contracts
  - Includes: Function specs, events, security notes

Component Documentation:
  - Location: frontend/src/components/ (Storybook)
  - Format: MDX
  - When: Before component implementation
  - Includes: Props, examples, accessibility notes
```

---

#### Conflict Resolution Protocol

**When Disagreement Occurs:**
```yaml
Step 1: State Positions (5 minutes each)
  - Each agent: Explain reasoning
  - Document: Assumptions and constraints
  - Clarify: Misunderstandings

Step 2: Evaluate Trade-offs (10 minutes)
  - List: Pros and cons of each approach
  - Assess: Against project goals (performance, maintainability, timeline)
  - Identify: Non-negotiables vs nice-to-haves

Step 3: Decision via Framework (5 minutes)
  - Apply: Decision Matrix (see Section V)
  - Document: Decision Record (ADR)
  - Commit: All agents align

Step 4: Escalation (If Unresolved)
  - Trigger: After 30 minutes of discussion
  - To: Architect agent (for strategic decisions)
  - With: Complete decision record + analysis
```

**Decision Record Template:**
```markdown
## Decision: [Title]
**Date:** [YYYY-MM-DD]
**Participants:** [Agent Frontend, Agent Backend, Agent Blockchain]

### Context
[What decision needs to be made and why]

### Options Considered
1. [Option A]: [Pros/Cons]
2. [Option B]: [Pros/Cons]
3. [Option C]: [Pros/Cons]

### Decision
[Chosen option and reasoning]

### Consequences
- **Positive:** [Benefits]
- **Negative:** [Trade-offs]
- **Risks:** [What to monitor]

### Review Date
[When to revisit this decision]
```

---

### IV. Quality Standards

#### Layered Code Review Checklist

**Frontend Checklist:**
```yaml
Functionality:
  - [ ] Component renders correctly (all states)
  - [ ] Props validation (TypeScript types)
  - [ ] Event handlers work (click, submit, keyboard)
  - [ ] Error boundaries catch errors
  - [ ] Loading states display correctly

Performance:
  - [ ] No unnecessary re-renders (React.memo, useMemo)
  - [ ] Images optimized (WebP, lazy loading)
  - [ ] Code splitting (dynamic imports)
  - [ ] Bundle size within budget (<250KB per page)
  - [ ] Lighthouse score >90 (desktop), >80 (mobile)

Accessibility:
  - [ ] Keyboard navigation works
  - [ ] Focus indicators visible
  - [ ] ARIA labels present
  - [ ] Color contrast >4.5:1
  - [ ] Screen reader tested

Security:
  - [ ] XSS prevention (sanitize user input)
  - [ ] CSRF tokens (for forms)
  - [ ] No secrets in code (use env vars)
  - [ ] Content Security Policy headers

Documentation:
  - [ ] Storybook story created
  - [ ] Props documented (JSDoc)
  - [ ] Usage examples provided
  - [ ] Edge cases noted
```

**Backend Checklist:**
```yaml
Functionality:
  - [ ] All endpoints work (happy path + error cases)
  - [ ] Input validation (DTO classes)
  - [ ] Error handling (try/catch, custom exceptions)
  - [ ] Logging (info, warn, error levels)
  - [ ] Health checks work (/health, /health/ready)

Performance:
  - [ ] Database queries optimized (indexes, no N+1)
  - [ ] Response time <200ms (p95)
  - [ ] Pagination implemented (large datasets)
  - [ ] Caching used (Redis for hot data)
  - [ ] Rate limiting configured

Security:
  - [ ] Authentication required (JWT validation)
  - [ ] Authorization checked (role/permission)
  - [ ] Input sanitization (prevent SQL injection)
  - [ ] Rate limiting (per user, per endpoint)
  - [ ] Secrets in environment variables

Testing:
  - [ ] Unit tests (>80% coverage)
  - [ ] Integration tests (critical paths)
  - [ ] E2E tests (main user flows)
  - [ ] Load tests (expected traffic + 2x)

Documentation:
  - [ ] OpenAPI spec updated
  - [ ] README includes setup steps
  - [ ] Migration documented (if schema change)
  - [ ] ⚠️ ADR MANDATORY (if ANY architectural decision - see Section IV)
  - [ ] ADR architect-approved before proceeding
```

**Blockchain Checklist:**
```yaml
Functionality:
  - [ ] All contract functions work (unit tests)
  - [ ] Events emitted correctly (indexed params)
  - [ ] Access control enforced (onlyOwner, etc.)
  - [ ] Upgradeable pattern works (proxy + implementation)
  - [ ] Multi-chain compatibility (if applicable)

Security:
  - [ ] Reentrancy protection (checks-effects-interactions)
  - [ ] Overflow/underflow protection (SafeMath or Solidity 0.8+)
  - [ ] Access control (who can call what)
  - [ ] Front-running mitigation (commit-reveal, MEV protection)
  - [ ] Third-party audit (before mainnet)

Gas Optimization:
  - [ ] Storage minimized (use events for logs)
  - [ ] Loops avoided (or bounded)
  - [ ] External calls batched
  - [ ] Gas profiling done (forge test --gas-report)
  - [ ] Below gas limit (block limit - buffer)

Testing:
  - [ ] Unit tests (>95% coverage)
  - [ ] Fuzz testing (Echidna/Foundry)
  - [ ] Integration tests (multi-contract flows)
  - [ ] Testnet deployment validated
  - [ ] Mainnet simulation (fork testing)

Documentation:
  - [ ] NatSpec comments (functions, events, params)
  - [ ] Contract diagram (architecture)
  - [ ] Deployment guide (networks, addresses)
  - [ ] Upgrade/rollback plan
  - [ ] Security considerations documented
```

---

#### Mandatory Automated Tests

**Test Pyramid:**
```yaml
Unit Tests (70% of tests):
  - What: Individual functions, pure logic
  - Tools: Jest (frontend/backend), Foundry (contracts)
  - Coverage: >80% (backend), >70% (frontend), >95% (contracts)
  - Run: On every commit (pre-commit hook)

Integration Tests (20% of tests):
  - What: Multiple components, API flows
  - Tools: Jest + Supertest (backend), React Testing Library (frontend)
  - Coverage: All critical user paths
  - Run: On every PR (CI pipeline)

End-to-End Tests (10% of tests):
  - What: Full user journeys across layers
  - Tools: Playwright (web), Hardhat (contracts)
  - Coverage: Main user flows (signup, transaction, story creation)
  - Run: Before deployment (staging validation)
```

**Test Standards:**
```yaml
Every Test Must Have:
  - [ ] Descriptive name (what it tests)
  - [ ] Arrange-Act-Assert structure
  - [ ] Isolated setup (no shared state)
  - [ ] Cleanup (teardown hooks)
  - [ ] Fast execution (<1s per unit test)

Test Data:
  - [ ] Use factories (not hardcoded data)
  - [ ] Reset between tests
  - [ ] No real API calls (mock external services)
  - [ ] No real blockchain txs (use fork/mock)
```

---

#### Documentation Artifacts

**Architecture Decision Records (ADRs) — MANDATORY:**
```yaml
⚠️ MANDATORY POLICY:
  - ADRs are REQUIRED for ALL architectural decisions
  - Cannot proceed with implementation until ADR is approved
  - ADR must be reviewed by architect agent before marking task complete
  - Skipping ADR for architectural decisions is a critical process violation

When to Create (All Cases MANDATORY):
  - ✅ REQUIRED: Choosing or changing frameworks/libraries
  - ✅ REQUIRED: Any major architecture changes
  - ✅ REQUIRED: Database schema design or migrations
  - ✅ REQUIRED: Adding new services or modules
  - ✅ REQUIRED: Changing authentication/authorization strategy
  - ✅ REQUIRED: Selecting third-party APIs or services
  - ✅ REQUIRED: Changing deployment or infrastructure
  - ✅ REQUIRED: API design patterns or breaking changes
  - ✅ REQUIRED: State management approach changes
  - ✅ REQUIRED: Performance optimization strategies
  - ✅ REQUIRED: Security implementation decisions

When NOT to Create (Optional):
  - ❌ Minor bug fixes (no architectural impact)
  - ❌ UI/UX tweaks (no system changes)
  - ❌ Code refactoring (same behavior)
  - ❌ Documentation updates

Template: doc/adr/template.md (MUST follow structure exactly)
Location: doc/adr/ADR-YYYYMMDD-title.md
Naming: ADR-[Date]-[short-kebab-case-title].md

Required Sections (from template.md):
  1. Context and Problem Statement
  2. Decision Drivers
  3. Considered Options (ALL alternatives analyzed)
  4. Decision Outcome (clear chosen option + justification)
  5. Positive Consequences
  6. Negative Consequences
  7. Pros and Cons of the Options
  8. Links (related docs/ADRs)
  9. Notes (implementation details, future considerations)
  10. Review Date and Next Review

Quality Standards:
  - ✅ ALL alternatives must be documented with pros/cons
  - ✅ Trade-offs must be explicit and honest
  - ✅ Consequences (positive AND negative) must be listed
  - ✅ Review date must be set (when to revisit decision)
  - ✅ Implementation details and metrics included
  - ✅ Security implications documented
  - ✅ Performance impact analyzed

Review Process:
  1. Create ADR draft (status: Proposed)
  2. Call architect agent for review
  3. Address feedback and iterate
  4. Change status to Accepted
  5. Reference ADR in implementation PRs
  6. Update ADR table in doc/adr/README.md
```

**API Documentation:**
```yaml
What to Document:
  - All endpoints (method, path, auth)
  - Request/response schemas (with examples)
  - Error codes and messages
  - Rate limits and pagination
  - Authentication requirements

Format: OpenAPI 3.0 (backend/openapi.yaml)
Tools: Swagger UI (auto-generated docs)
Update: Before implementing new endpoints
Review: On every API change PR
```

**Changelog:**
```yaml
Every Release Must Have:
  - Version number (semantic versioning)
  - Release date
  - Added features
  - Changed behavior
  - Deprecated items
  - Removed items
  - Fixed bugs
  - Security fixes

Format: CHANGELOG.md (Keep a Changelog format)
Update: On every merge to main
Review: Before production deployment
```

---

#### Performance & Security Benchmarks

**Frontend Performance SLAs:**
```yaml
Lighthouse Scores (Desktop):
  - Performance: >90
  - Accessibility: >95
  - Best Practices: >90
  - SEO: >90

Core Web Vitals:
  - LCP (Largest Contentful Paint): <2.5s
  - FID (First Input Delay): <100ms
  - CLS (Cumulative Layout Shift): <0.1

Bundle Size:
  - Initial load: <250KB gzipped
  - Route chunks: <100KB each
  - Images: WebP/AVIF, lazy loaded
```

**Backend Performance SLAs:**
```yaml
API Response Times (p95):
  - Simple queries (user profile): <100ms
  - Complex queries (feed generation): <500ms
  - Data mutations (create/update): <200ms
  - Search queries: <300ms

Database Performance:
  - Query time: <50ms (p95)
  - Connection pool: >50 available
  - Cache hit rate: >80% (hot data)

Throughput:
  - Requests per second: >1000 (per instance)
  - Concurrent users: >10000
  - Error rate: <0.1%
```

**Blockchain Performance:**
```yaml
Gas Costs:
  - Simple transfers: <50k gas
  - Swaps: <150k gas
  - Complex operations: <500k gas

Indexer Performance:
  - Block processing latency: <5s
  - Event parsing accuracy: 100%
  - Reorg handling: Automatic (up to 64 blocks)
  - Sync speed: >100 blocks/second (historical)
```

**Security Benchmarks:**
```yaml
OWASP Top 10:
  - [ ] No SQL injection
  - [ ] No XSS vulnerabilities
  - [ ] No CSRF attacks
  - [ ] Authentication enforced
  - [ ] Authorization checked
  - [ ] Secrets not exposed
  - [ ] Rate limiting configured
  - [ ] Input validation present
  - [ ] Security headers set
  - [ ] Logging and monitoring active

Smart Contract Security:
  - [ ] No reentrancy vulnerabilities
  - [ ] No overflow/underflow
  - [ ] Access control enforced
  - [ ] Front-running mitigated
  - [ ] Third-party audit passed
```

---

### V. Decision Making Framework

#### Risk-Tier Matrix

**How to Assess Risk:**
```yaml
Impact Dimensions:
  1. User Experience (0-10)
     - 0: No user-facing change
     - 5: Minor UX improvement
     - 10: Critical user flow affected

  2. System Stability (0-10)
     - 0: Isolated change
     - 5: Touches multiple modules
     - 10: Core infrastructure change

  3. Security (0-10)
     - 0: No security implications
     - 5: Authentication/authorization related
     - 10: Handling sensitive data or funds

  4. Reversibility (0-10)
     - 0: Easily reversible (feature flag, config)
     - 5: Requires migration (backward compatible)
     - 10: Not reversible (blockchain, data loss)

Risk Score = (UX + Stability + Security + Reversibility) / 4
```

**Risk Tiers:**
```yaml
Low Risk (0-3):
  - Examples: Copy changes, styling tweaks, documentation
  - Decision: Single agent can proceed
  - Review: Standard code review
  - Testing: Unit tests sufficient
  - Deployment: Direct to main (after CI passes)

Medium Risk (4-6):
  - Examples: New components, API endpoints, database queries
  - Decision: Agent + one peer review
  - Review: Deep code review + systems impact check
  - Testing: Unit + integration tests
  - Deployment: Staging → Production (after QA)

High Risk (7-8):
  - Examples: Architecture changes, schema migrations, multi-chain support
  - Decision: All 3 agents consensus
  - Review: Code review + architect review + decision record
  - Testing: Unit + integration + E2E tests
  - Deployment: Staging → Canary → Production (gradual rollout)

Critical Risk (9-10):
  - Examples: Smart contract deployment, core authentication changes, data migrations
  - Decision: All 3 agents + architect + user approval
  - Review: Multiple rounds + external audit (contracts)
  - Testing: Comprehensive test suite + load testing + security audit
  - Deployment: Testnet → Mainnet fork test → Mainnet (with rollback plan)
```

---

#### Escalation Triggers

**When to Escalate to Architect:**
```yaml
Automatic Escalation:
  - Risk score >7 (high/critical risk)
  - Agent conflict unresolved after 30 minutes
  - Breaking API/contract changes required
  - Performance degradation >20% observed
  - Security vulnerability discovered
  - Architectural pattern doesn't exist

Manual Escalation:
  - Uncertain about design approach
  - Multiple valid solutions, need strategic guidance
  - Cross-product implications unclear
  - Technical debt trade-off decision
  - Timeline/scope negotiation needed
```

**Escalation Process:**
```yaml
Step 1: Prepare Escalation Brief (15 minutes)
  - Problem statement (what needs decision)
  - Context (why it matters)
  - Analysis done (what was explored)
  - Options (with pros/cons)
  - Recommendation (agent perspective)

Step 2: Request Architect Review
  - Tool: architect tool with responsibility="plan" or "evaluate_task"
  - Include: All relevant files
  - Specify: Question or guidance needed

Step 3: Implement Architect Feedback
  - Document: Decision record (ADR)
  - Share: With all agents
  - Execute: According to decision
```

---

#### Validation Loops

**Proof-of-Concept (PoC) Phase:**
```yaml
When to Use:
  - High risk changes (score >7)
  - New technology/pattern
  - Performance-critical features
  - Complex algorithms

Process:
  1. Build minimal PoC (time-boxed: 2-4 hours)
  2. Validate assumptions (does it work?)
  3. Measure performance (benchmarks)
  4. Document findings (what learned)
  5. Decide: Proceed, pivot, or abandon

Success Criteria:
  - Proves feasibility
  - Meets performance requirements
  - Acceptable complexity
  - Aligns with architecture
```

**Internal QA Phase:**
```yaml
When to Use:
  - Before any deployment (staging/production)
  - After medium/high risk changes
  - Before major feature releases

Process:
  1. Deploy to staging environment
  2. Run automated test suite (unit + integration + E2E)
  3. Manual QA (exploratory testing)
  4. Performance testing (load, stress)
  5. Security scan (dependency check, OWASP)
  6. Document findings (bugs, issues, improvements)

Pass Criteria:
  - All automated tests pass
  - No critical/high bugs found
  - Performance SLAs met
  - Security scan clean
```

**Stakeholder Sign-off Phase:**
```yaml
When to Use:
  - Critical risk changes (score >9)
  - User-facing feature releases
  - API contract changes (breaking)
  - Smart contract deployments

Process:
  1. Prepare demo (working prototype)
  2. Document changes (release notes)
  3. Present to stakeholders (user/product owner)
  4. Gather feedback (usability, requirements)
  5. Iterate if needed
  6. Get explicit approval

Required Approvals:
  - User confirmation (for user stories)
  - Product owner (for features)
  - Security team (for contracts/auth)
  - Architect (for architecture changes)
```

---

#### Rollback & Mitigation Readiness

**Before ANY Deployment:**
```yaml
Rollback Plan Required:
  - [ ] Rollback trigger defined (what constitutes failure)
  - [ ] Rollback procedure documented (step-by-step)
  - [ ] Rollback tested (in staging)
  - [ ] Rollback owner assigned (who executes)
  - [ ] Rollback time estimated (how long to revert)

Monitoring Plan Required:
  - [ ] Key metrics identified (what to watch)
  - [ ] Alerts configured (when to trigger)
  - [ ] Dashboards created (visualization)
  - [ ] On-call assigned (who responds)
  - [ ] Escalation path defined (who to notify)

Data Integrity Plan:
  - [ ] Database backup taken (before migration)
  - [ ] Backup restoration tested
  - [ ] Data validation queries prepared
  - [ ] Corruption detection automated
  - [ ] Recovery procedure documented
```

**Incident Response Protocol:**
```yaml
Severity 1 (Critical - Production Down):
  - Response time: Immediate
  - Action: Rollback immediately
  - Notification: All agents + architect + user
  - Post-mortem: Required within 24h

Severity 2 (High - Degraded Performance):
  - Response time: <15 minutes
  - Action: Investigate, mitigate, or rollback
  - Notification: Agent team + architect
  - Post-mortem: Required within 48h

Severity 3 (Medium - Minor Issues):
  - Response time: <1 hour
  - Action: Document, fix in next release
  - Notification: Agent team
  - Post-mortem: Optional

Severity 4 (Low - Cosmetic):
  - Response time: <1 day
  - Action: Add to backlog
  - Notification: Agent team (async)
  - Post-mortem: Not required
```

---

### VI. Implementation Checklist

**Before Starting Phase 0.2.2 (Documentation Setup):**
```yaml
All Agents Must:
  - [ ] Read this entire CoT World Class Framework
  - [ ] Understand their role charter (Section II)
  - [ ] Review collaboration model (Section III)
  - [ ] Familiarize with quality standards (Section IV)
  - [ ] Know decision framework (Section V)
  - [ ] Practice Deep Thinking Neural Protocol on a sample task
  - [ ] Acknowledge understanding (comment in task)

Agent Frontend:
  - [ ] Review frontend architecture (Section: Frontend Architecture)
  - [ ] Set up Storybook environment
  - [ ] Configure ESLint + Prettier
  - [ ] Install accessibility testing tools (axe-core)

Agent Backend:
  - [ ] Review backend architecture (Section: Backend Architecture)
  - [ ] Set up NestJS development environment
  - [ ] Configure Prisma migrations
  - [ ] Install API testing tools (Supertest)

Agent Blockchain:
  - [ ] Review blockchain layer (Section: Blockchain Layer)
  - [ ] Set up Hardhat/Foundry environment
  - [ ] Configure testnet RPC endpoints
  - [ ] Install security tools (Slither, Mythril)
```

---

**Framework Effectiveness Metrics (Review Monthly):**
```yaml
Quality Metrics:
  - Bug escape rate (<5% to production)
  - Code review iterations (average <3)
  - Test coverage (>80% backend, >70% frontend, >95% contracts)
  - Documentation completeness (100% for public APIs)

Velocity Metrics:
  - Planning time (should decrease as patterns emerge)
  - Implementation time (should stabilize)
  - Review time (should decrease with clear standards)
  - Rework time (should decrease with better analysis)

Collaboration Metrics:
  - Agent conflict frequency (should decrease)
  - Handoff clarity (measured by questions asked)
  - Cross-domain bug rate (should decrease)
  - Decision record quality (peer-rated)

Outcome Metrics:
  - User-reported bugs (should decrease)
  - Performance SLA compliance (should increase)
  - Security incidents (target: zero)
  - Deployment success rate (target: >95%)
```

---

**End of CoT World Class Framework**

This framework is a living document. All agents should propose improvements based on real-world experience. Schedule monthly review to refine processes, templates, and standards.

---

## 🔒 Operational & Security Rules (MANDATORY)

**Source:** Integrated from doc/agent-rules.md  
**Status:** CRITICAL - Must be followed by ALL contributors

### Rule 1: NEVER INSTALL DEPENDENCIES IN ROOT

**CRITICAL RULE:**
```yaml
FORBIDDEN:
  ❌ npm install <package> at root level
  ❌ Root package.json with dependencies or devDependencies
  ❌ package-lock.json at root level
  ❌ node_modules/ at root level

REQUIRED:
  ✅ All package installations inside workspace folders (packages/*)
  ✅ cd frontend && npm install <package>
  ✅ cd backend && npm install <package>
  ✅ Each package has its own package.json, package-lock.json, node_modules
  ✅ Root package.json ONLY for workspace definitions and scripts
```

**Enforcement:**
- Per-package lockfiles (each workspace maintains its own)
- CI must run ONLY package-local installs and tests
- CI must NOT run `npm install` at repo root
- Build will FAIL if root dependencies detected

### Rule 2: NO EMOJI IN CODE (ONLY HEROICONS)

**CRITICAL RULE:**
```yaml
FORBIDDEN:
  ❌ Emoji in string literals, comments, variable names
  ❌ Emoji in UI components, buttons, alerts
  ❌ Emoji in console logs, error messages
  ❌ Emoji in documentation within code files

REQUIRED:
  ✅ Use Hero Icons for all visual indicators
  ✅ Use SVG icons from icon libraries
  ✅ Use descriptive text instead of emoji
  ✅ ESLint configured to block emoji usage

EXCEPTION:
  ⚠️ User-generated content only (runtime data, not code)
```

### Rule 3: Security-First Development

**MANDATORY Security Practices:**
```yaml
Code Security:
  - Snyk/Dependabot alerts: REQUIRED
  - All PRs must pass security check
  - Secrets NEVER committed (use Vault / KMS)
  - Third-party audit for smart contracts (before mainnet)
  - Security reviewer required for infra and contracts PRs

Authentication & Authorization:
  - JWT validation on all protected endpoints
  - Role-based access control (RBAC)
  - Rate limiting on all public endpoints
  - Input validation with Zod/class-validator
  - SQL injection prevention (parameterized queries)
  - XSS prevention (sanitize user input)

Data Privacy:
  - PII encrypted at rest
  - No PII in logs (use log masking)
  - GDPR compliance (data deletion endpoints)
  - Audit logs for sensitive operations
```

### Rule 4: Commit & Code Review Standards

**Commit Message Format:** Conventional Commits (REQUIRED)
```bash
feat: Add ChainGhost narrative generation API
fix: Resolve wallet balance calculation bug
refactor: Improve indexer performance
docs: Update API documentation
test: Add integration tests for social graph
chore: Update dependencies
security: Patch XSS vulnerability in comment system
```

**Code Review Requirements:**
```yaml
All PRs Must Have:
  - At least 1 code reviewer approval
  - Security reviewer approval (for infra, contracts, auth)
  - All CI checks passing (tests, linting, security scan)
  - No merge conflicts
  - Updated documentation (if applicable)
  - ADR created (for architectural changes)

Security-Critical PRs:
  - Infrastructure changes: 1 code + 1 security reviewer
  - Smart contracts: 1 code + 1 security + 1 architect reviewer
  - Authentication/authorization: 1 security reviewer mandatory
```

### Rule 5: Infrastructure as Code (MANDATORY)

**REQUIRED:**
```yaml
Infrastructure:
  - Terraform for infrastructure provisioning
  - Helm charts for Kubernetes manifests
  - No manual infrastructure changes
  - All infrastructure versioned in Git
  - Environment parity (dev, staging, prod)

Forbidden:
  - Manual server configuration
  - Unversioned infrastructure
  - Snowflake servers (each must be reproducible)
  - Direct production access (use IaC + CI/CD)
```

### Rule 6: LLM Usage & Audit Policy

**MANDATORY for AI-Generated Content:**
```yaml
LLM Usage:
  - All prompts and outputs stored in append-only audit logs
  - Sensitive outputs redacted before logging
  - Store seeds, prompts, model versions for reproducibility
  - Content safety filter before user-facing output
  - Human-in-the-loop for sensitive operations

Storage:
  - Logs location: backend/logs/llm-audit/
  - Retention: 90 days minimum
  - Format: JSON with timestamp, user_id, prompt, output (redacted)
```

### Rule 7: Operational Excellence

**Runbooks (REQUIRED):**
```yaml
Critical Flows Must Have Runbooks:
  - Node recovery procedure
  - Database restore procedure
  - Incident response playbook
  - Rollback procedure (per service)
  - Disaster recovery plan

Location: infra/runbooks/
Format: Markdown with step-by-step instructions
Review: Quarterly or after incidents
```

**Monitoring & Alerts:**
```yaml
Required Monitoring:
  - Service health checks (every 30s)
  - Error rate alerts (>2% triggers PagerDuty)
  - Performance alerts (p95 > SLA triggers Slack)
  - Security alerts (failed auth, unusual patterns)
  - Business metrics (transaction volume, user signups)
```

### Rule 8: Testing Standards (MANDATORY)

**Before Merging to Main:**
```yaml
Required Tests:
  - Unit tests (>80% coverage backend, >70% frontend, >95% contracts)
  - Integration tests for chain, indexer, marketplace flows
  - E2E tests for critical user journeys
  - Security tests (OWASP Top 10)
  - Performance tests (load tests for APIs)

Contract-Specific:
  - Fuzz testing (Echidna/Foundry)
  - Formal verification (critical contracts)
  - Gas profiling (optimization required)
  - Testnet deployment validation
```

### Rule 9: Release Process (GATED)

**Deployment Checklist:**
```yaml
Pre-Release:
  - [ ] All tests passing (unit, integration, E2E)
  - [ ] Security scan passed (Snyk, Dependabot)
  - [ ] Performance benchmarks met
  - [ ] Documentation updated (changelog, API docs)
  - [ ] Database migrations tested (staging)
  - [ ] Rollback plan documented
  - [ ] Feature flags configured (gradual rollout)

Release Artifacts:
  - [ ] Changelog (semantic versioning)
  - [ ] SBOM (Software Bill of Materials)
  - [ ] Audit report (security scan results)
  - [ ] Release notes (user-facing changes)

Post-Release:
  - [ ] Monitor error rates (24h)
  - [ ] Monitor performance metrics (24h)
  - [ ] Verify feature flag rollout (5% → 25% → 100%)
  - [ ] Update status page
```

### Rule 10: Continuous Improvement

**Adopt CoT World Class:**
```yaml
Decision Documentation:
  - Document reasoning for complex decisions in design docs
  - Use RFC-style proposals for major changes
  - Create ADRs for architectural decisions
  - Post-mortems for incidents (within 48h)

Learning:
  - Monthly retrospectives
  - Quarterly architecture reviews
  - Security training (bi-annual)
  - Performance optimization reviews
```

---

**ENFORCEMENT:**
- ⚠️ Violations of these rules will cause build failures
- ⚠️ Security violations require immediate fix + incident review
- ⚠️ Repeated violations trigger process review
- ✅ Compliance is checked automatically in CI/CD pipeline

---

## ⚠️ CURRENT IMPLEMENTATION STATUS

### ✅ IMPLEMENTED (Working Code)
- **Frontend:** Next.js 14 app running on port 5000
  - React 18 with Hot Module Replacement
  - Three.js visualization (NetworkVisualizer component)
  - Design tokens and basic styling
  - Single demo page (visual.jsx)

### 📋 PLANNED (Documentation Only)
- **Backend:** Microservices architecture (no code yet)
- **Infrastructure:** Kubernetes setup (no manifests yet)
- **Blockchain:** Smart contracts (placeholder only)
- **Database:** PostgreSQL/TimescaleDB/Redis (not configured)

**👉 Key Point:** This guide describes both current implementation AND planned architecture. Sections are clearly marked with status indicators.

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Directory Structure](#directory-structure)
3. [Frontend Architecture](#frontend-architecture) ✅ IMPLEMENTED
4. [Backend Architecture](#backend-architecture) 📋 PLANNED
5. [Infrastructure & DevOps](#infrastructure--devops) 📋 PLANNED
6. [Blockchain Layer](#blockchain-layer) 📋 PLANNED
7. [Development Workflows](#development-workflows) ✅ IMPLEMENTED
8. [Coding Guidelines](#coding-guidelines)
9. [Common Tasks Reference](#common-tasks-reference) ✅ IMPLEMENTED

---

## Project Overview

### What is Ghost Protocol?
Ghost Protocol adalah **super-app Web3** yang menyatukan tiga produk dalam satu ekosistem terpadu:

```
┌─────────────────────────────────────────────┐
│          GHOST PROTOCOL ECOSYSTEM           │
├─────────────────────────────────────────────┤
│                                             │
│  1. ChainGhost                              │
│     → Unified Execution + Journey Layer     │
│     → One-click cross-chain transactions    │
│     → Auto-generated narrative visualization│
│     → Intent-based architecture             │
│     (Wallet operations + Story in ONE exp)  │
│                                             │
│  2. G3Mail (Ghost Web3 Mail)                │
│     → Decentralized Communication Product   │
│     → Encrypted messaging                   │
│     → On-chain message pointers             │
│     → Client-side decryption                │
│                                             │
│  3. Ghonity                                 │
│     → Community Ecosystem                   │
│     → Follow wallets, discover alpha        │
│     → Social graph & reputation             │
│     → Copy-trade strategies                 │
│                                             │
└─────────────────────────────────────────────┘
```

### Core Philosophy (Flywheel Effect)
```
ACTION (ChainGhost) → NARRATIVE (ChainGhost Story) → COMMUNITY (Ghonity)
        ↓                      ↓                            ↓
     "I DO"              "I BECOME"                     "WE ARE"
     
     More Action ← Community Discovery ← Shared Narratives
```

### Tech Stack at a Glance

**✅ Currently Used:**
- **Frontend:** Next.js 14.0.4, React 18.x, Three.js 0.152.2
- **3D Graphics:** @react-three/fiber, @react-three/drei
- **Animation:** GSAP 3.12.2
- **Runtime:** Node.js 20

**📋 Planned (Not Yet Implemented):**
- **Backend:** Node.js/NestJS, Go (optional for performance)
- **Database:** PostgreSQL, TimescaleDB, Redis, Elasticsearch, Vector DB
- **Blockchain:** Multi-chain RPC, ERC-4337, Smart Contract Wallets
- **Infrastructure:** Kubernetes, Prometheus, Grafana

---

## 🚀 Quick Start for Agents

### First Time Setup
```bash
# 1. The project is already set up with Node.js 20
# 2. Frontend dependencies are already installed
# 3. Workflow "frontend" is configured and running

# To verify:
cd frontend && npm run dev
# Should show: "✓ Ready in X ms" on port 5000
```

### Essential Files to Know
- **`replit.md`** - Current project state, always check this first
- **`agent-work.md`** - Complete documentation (all 14 source files)
- **`agent-rules.md`** - This file (you're reading it)
- **`frontend/package.json`** - Frontend dependencies and scripts
- **`frontend/next.config.js`** - Next.js configuration

### Critical Rules
1. **Frontend MUST use port 5000** (Replit requirement)
2. **Backend should use port 4000** (when implemented)
3. **Always test changes** before marking task complete
4. **Update replit.md** when making significant changes
5. **Never commit secrets** - use environment variables

---

## 📦 Dependency & Package Management Rules

### ⚠️ CRITICAL: NO ROOT DEPENDENCIES

**MANDATORY RULE: All runtime dependencies MUST be installed in their respective workspace folders, NEVER in root.**

```yaml
❌ WRONG - Never do this:
  npm install @heroui/react          # At root level
  npm install tailwindcss            # At root level
  Root package.json has dependencies # ❌ FORBIDDEN

✅ CORRECT - Always do this:
  cd frontend && npm install @heroui/react    # In frontend/
  cd backend && npm install nestjs            # In backend/
  Only workspace-specific dependencies        # ✅ REQUIRED
```

### Root package.json Purpose

**Root package.json should ONLY contain:**
```json
{
  "name": "ghost-protocol-workspace",
  "version": "1.0.0",
  "private": true,
  "workspaces": ["frontend", "backend"],
  "scripts": {
    "frontend": "cd frontend && npm run dev",
    "backend": "cd backend && npm run dev",
    "install:frontend": "cd frontend && npm install",
    "install:backend": "cd backend && npm install"
  }
}
```

**Root package.json should NEVER contain:**
- ❌ `dependencies` field (runtime packages)
- ❌ `devDependencies` field (build tools)
- ❌ `package-lock.json` at root level

### Workspace-Specific Dependencies

**Frontend Dependencies (`frontend/package.json`):**
```json
{
  "dependencies": {
    "next": "14.0.4",
    "react": "^19.0.0",
    "@heroui/react": "^2.8.5",
    "framer-motion": "^12.23.24",
    "next-themes": "^0.4.6"
  },
  "devDependencies": {
    "tailwindcss": "^3.4.0",
    "postcss": "^8.4.35",
    "autoprefixer": "^10.4.22"
  }
}
```

**Backend Dependencies (`backend/package.json`):**
```json
{
  "dependencies": {
    "@nestjs/core": "^10.x.x",
    "@nestjs/common": "^10.x.x",
    "prisma": "^5.x.x"
  },
  "devDependencies": {
    "@types/node": "^20.x.x",
    "typescript": "^5.x.x"
  }
}
```

### Installation Commands

**Always navigate to the correct workspace first:**

```bash
# Frontend dependencies
cd frontend
npm install <package-name>
npm install @heroui/react

# Backend dependencies  
cd backend
npm install <package-name>
npm install @nestjs/core

# NEVER run npm install at root level (unless installing workspace structure)
```

### Version Conflict Resolution

**When multiple workspaces need the same dependency with different versions:**

1. **Assess compatibility:** Check if one version can satisfy both workspaces
2. **Pin versions:** Use exact versions (`2.8.5` not `^2.8.5`) if needed
3. **Document decision:** Add comment in package.json explaining version choice
4. **Test thoroughly:** Ensure compatibility across all workspaces

**Example:**
```json
// frontend/package.json
{
  "dependencies": {
    // Using @heroui/react 2.8.5 for compatibility with Tailwind v3
    // DO NOT upgrade to 3.x until Tailwind v4 migration is complete
    "@heroui/react": "2.8.5"
  }
}
```

### Dependency Conflict Prevention

**Before installing any dependency, ALWAYS:**

1. ✅ Check if workspace folder exists (`frontend/`, `backend/`)
2. ✅ Navigate to correct workspace (`cd frontend`)
3. ✅ Verify package.json exists in workspace
4. ✅ Run installation command (`npm install <package>`)
5. ✅ Verify package-lock.json updated in workspace (not root)
6. ✅ Restart workflow if needed

**After installation:**
```bash
# Verify installation location
ls frontend/node_modules/<package-name>  # Should exist
ls node_modules/<package-name>           # Should NOT exist

# If accidentally installed at root:
rm -rf node_modules package-lock.json    # Clean root
cd frontend && npm install               # Reinstall in workspace
```

### Lockfile Management

**Package lockfiles location:**
- ✅ `frontend/package-lock.json` - Frontend lockfile
- ✅ `backend/package-lock.json` - Backend lockfile  
- ❌ `package-lock.json` at root - Should NOT exist

**If root lockfile exists (conflict state):**
```bash
# Clean up root lockfile
rm package-lock.json

# Regenerate workspace lockfiles
cd frontend && npm install
cd ../backend && npm install
```

### Common Mistakes & Solutions

**Mistake 1: Installing at root by accident**
```bash
# Wrong
npm install @heroui/react

# Solution
rm -rf node_modules package-lock.json
cd frontend && npm install @heroui/react
```

**Mistake 2: Version mismatch between root and workspace**
```bash
# Problem: Root has Tailwind 4, Frontend has Tailwind 3
# Solution: Remove from root, keep only in frontend
rm package-lock.json
# Edit root package.json to remove all dependencies
cd frontend && npm install
```

**Mistake 3: Forgetting to restart workflow after installation**
```bash
# After installing dependencies
cd frontend && npm install <package>
# MUST restart the workflow to pick up changes
# Use Replit UI or restart command
```

### Enforcement Checklist

**Before merging any code:**
- [ ] Root package.json has NO `dependencies` field
- [ ] Root package.json has NO `devDependencies` field
- [ ] Root package.json has ONLY `scripts` and `workspaces`
- [ ] No `node_modules` folder at root level
- [ ] No `package-lock.json` at root level
- [ ] All dependencies in correct workspace folders
- [ ] Workflow runs without errors after clean install

**Violation consequences:**
- ⚠️ Build failures due to version conflicts
- ⚠️ Unexpected behavior from wrong dependency versions
- ⚠️ Difficult debugging when deps are in wrong location
- ⚠️ Wasted time cleaning up dependency mess

---

## 🚫 Code Quality & Linting Rules

### ESLint Configuration

**MANDATORY: All frontend code MUST pass ESLint checks before committing.**

```bash
# Run ESLint
cd frontend && npm run lint

# Auto-fix issues where possible
cd frontend && npm run lint:fix
```

### Emoji & Emoticon Blocking

**CRITICAL RULE: Emoji and emoticons are STRICTLY FORBIDDEN in all source code.**

**Rationale:**
- ✅ Maintain professional codebase standards
- ✅ Ensure consistent rendering across all environments
- ✅ Avoid encoding issues and platform-specific display problems
- ✅ Improve code readability and searchability
- ✅ Prevent confusion between visual indicators and actual code logic

**What is Blocked:**
```javascript
// ❌ FORBIDDEN - Emoji in string literals
const message = "Hello 🌍 World";

// ❌ FORBIDDEN - Emoji in template strings
const greeting = `Welcome 👋 to Ghost Protocol`;

// ❌ FORBIDDEN - Emoji in comments (will be blocked)
// This is cool 🚀

// ✅ ALLOWED - Text descriptions
const message = "Hello World";
const greeting = "Welcome to Ghost Protocol";
```

**Alternative Solutions:**
```javascript
// ✅ CORRECT - Use icon components for UI
import { RocketIcon } from '@/components/icons';
<RocketIcon className="text-primary" />

// ✅ CORRECT - Use image assets
<img src="/icons/rocket.svg" alt="Rocket" />

// ✅ CORRECT - Use unicode entity in JSX
<span>&#128640;</span> // Renders as 🚀

// ✅ CORRECT - Use Hero UI icons
import { Icon } from '@heroui/react';
<Icon name="rocket" />
```

### ESLint Setup (Frontend)

**Location:** `frontend/.eslintrc.json`

**Rules Enforced:**
1. **no-restricted-syntax**: Blocks emoji unicode ranges
   - Emoticons: `\u{1F300}-\u{1F9FF}`
   - Symbols: `\u{2600}-\u{26FF}`
   - Dingbats: `\u{2700}-\u{27BF}`
   - Extended: `\u{1F000}-\u{1FAFF}`

2. **no-irregular-whitespace**: Prevents invisible characters

**Coverage:**
- ✅ String literals
- ✅ Template strings
- ✅ Comments (via irregular whitespace check)
- ⚠️ JSX text (limited detection - use code review)

**Configuration Files:**
```
frontend/
├── .eslintrc.json      # ESLint rules config
├── .eslintignore       # Files to ignore
└── package.json        # lint & lint:fix scripts
```

### Pre-Commit Checklist

**Before committing any code:**
- [ ] Run `npm run lint` in workspace folder
- [ ] Fix all ESLint errors (no emoji, no irregular whitespace)
- [ ] Verify no emoji in comments or strings
- [ ] Use icon components for visual indicators
- [ ] Test code renders correctly in browser

**Enforcement:**
- 🔴 **Blocking:** Code with emoji will FAIL lint check
- 🔴 **CI/CD:** Linting runs on build pipeline (future)
- 🟡 **Warning:** Manual review for JSX text emoji
- ✅ **Auto-fix:** Some issues fixable with `npm run lint:fix`

### Common Violations & Fixes

**Violation 1: Emoji in success message**
```javascript
// ❌ WRONG
console.log('Transaction complete ✅');

// ✅ CORRECT
console.log('Transaction complete');
// Or use logger with semantic levels
logger.success('Transaction complete');
```

**Violation 2: Emoji in component text**
```javascript
// ❌ WRONG
<button>Save 💾</button>

// ✅ CORRECT
import { SaveIcon } from '@/components/icons';
<button><SaveIcon /> Save</button>
```

**Violation 3: Emoji in error handling**
```javascript
// ❌ WRONG
throw new Error('Failed to load data 😢');

// ✅ CORRECT
throw new Error('Failed to load data: Network timeout');
```

### Exception Cases

**When emoji might be acceptable (with justification):**
1. **User-generated content**: Displaying user input containing emoji (runtime data)
2. **Test fixtures**: Mock data for testing user content handling
3. **Documentation examples**: Showing what NOT to do (in markdown, not code)
4. **External API responses**: Data from third-party services

**How to handle exceptions:**
```javascript
// Store user content with emoji (OK - it's data, not code)
const userPost = await fetchUserContent(); // May contain emoji

// Test data for emoji handling (use separate test files)
// tests/fixtures/user-content.json
{
  "post": "User said: Hello 🌍"
}
```

---

## Directory Structure

### Current Project Layout
```
ghost-protocol/
├── frontend/                    # Next.js web app (ChainGhost, Ghonity)
│   ├── pages/                   # Next.js pages
│   │   ├── _app.js             # App wrapper
│   │   └── visual.jsx          # 3D visualization demo
│   ├── src/
│   │   └── components/         # React components
│   │       └── NetworkVisualizer.jsx  # Three.js component
│   ├── styles/                 # CSS modules & global styles
│   │   ├── globals.css
│   │   └── Visual.module.css
│   ├── design-tokens.json      # Design system tokens
│   ├── package.json            # Dependencies
│   ├── next.config.js          # Next.js config
│   └── README.md
│
├── backend/                     # Node.js/NestJS API (placeholder)
│   ├── package.json
│   └── README.md
│
├── contracts/                   # Smart contracts (Hardhat)
│   ├── hardhat.config.js
│   └── README.md
│
├── infra/                       # Kubernetes manifests
│   └── README.md
│
├── doc/                         # Technical documentation
│   ├── whitepaper.md           # Project whitepaper
│   ├── architecture.md         # System architecture
│   ├── roadmap.md              # Development roadmap
│   ├── structure.md            # Data models & APIs
│   └── deployment.md           # Security & deployment
│
├── agent-work.md               # Complete project documentation (14 files merged)
├── agent-rules.md              # This file - agent development guide
├── replit.md                   # Replit project state & preferences
├── .gitignore                  # Git ignore rules
├── .replit                     # Replit configuration
│
└── Product Concept Docs:
    ├── README.md               # Ecosystem overview
    ├── CryptoGhost.md         # ChainGhost concept
    ├── CryptoStory.md         # ChainGhost journey concept
    └── Ghonity.md             # Ghonity community ecosystem concept
```

### File Location Rules

**When working on frontend:**
- **Pages:** Always place in `frontend/pages/`
- **Components:** Always place in `frontend/src/components/`
- **Styles:** CSS modules in `frontend/styles/`, component-specific styles co-located
- **Assets:** Images/media in `frontend/public/`

**When working on backend:**
- **Services:** `backend/src/services/` (Indexer, AI Engine, Social Graph)
- **Controllers:** `backend/src/controllers/`
- **Models:** `backend/src/models/`
- **Config:** `backend/src/config/`

**When working on contracts:**
- **Contracts:** `contracts/contracts/`
- **Tests:** `contracts/test/`
- **Scripts:** `contracts/scripts/`
- **Artifacts:** `contracts/artifacts/` (gitignored)

**Documentation:**
- **Technical docs:** `doc/` directory
- **Product concepts:** Root level (CryptoGhost.md, etc.)
- **Agent docs:** Root level (agent-work.md, agent-rules.md)
- **Project state:** `replit.md` (always keep updated)

---

## Frontend Architecture ✅ IMPLEMENTED

### Overview
**Status:** ✅ Working and running on port 5000

Frontend terdiri dari dua aplikasi utama:
1. **Web App** (Next.js) - ChainGhost & Ghonity ✅ **ACTIVE**
2. **Mobile/Extension** (React Native) - ChainGhost wallet 📋 **PLANNED**

### Current Implementation: Next.js Web App

**Actual Files in Project:**
```
frontend/
├── pages/
│   ├── _app.js              ✅ EXISTS - App wrapper
│   └── visual.jsx           ✅ EXISTS - 3D visualization demo
│
├── src/components/
│   └── NetworkVisualizer.jsx  ✅ EXISTS - Three.js component
│
├── styles/
│   ├── globals.css          ✅ EXISTS - Global styles
│   └── Visual.module.css    ✅ EXISTS - Visual page styles
│
├── design-tokens.json       ✅ EXISTS - Design system
├── package.json             ✅ EXISTS - Dependencies
├── next.config.js           ✅ EXISTS - Next.js config
└── README.md                ✅ EXISTS - Frontend docs
```

**Missing (To Be Created):**
- `frontend/public/` - Static assets directory
- `frontend/pages/index.jsx` - Home page
- `frontend/src/components/chainghost/` - ChainGhost components
- `frontend/src/components/ghonity/` - Ghonity components
- `frontend/src/lib/api/` - API client utilities

**Technology Stack:**
```json
{
  "framework": "Next.js 14.0.4",
  "ui_library": "React 18.x",
  "3d_graphics": "Three.js 0.152.2",
  "3d_react": "@react-three/fiber 8.13.0",
  "3d_helpers": "@react-three/drei 9.45.0",
  "animation": "GSAP 3.12.2"
}
```

**Port Configuration:**
- **Development:** Port 5000 (0.0.0.0)
- **Production:** Port 5000 (0.0.0.0)
- **Why 5000?** Replit requirement for webview proxy

**Configuration Files:**

`frontend/next.config.js`:
```javascript
const nextConfig = {
  reactStrictMode: true,
  webpack: (config) => {
    config.externals.push({
      'utf-8-validate': 'commonjs utf-8-validate',
      'bufferutil': 'commonjs bufferutil',
    })
    return config
  },
}
```

`frontend/package.json` scripts:
```json
{
  "dev": "next dev -H 0.0.0.0 -p 5000",
  "build": "next build",
  "start": "next start -H 0.0.0.0 -p 5000"
}
```

### Frontend Components

**NetworkVisualizer.jsx** - Three.js 3D visualization:
- Uses `@react-three/fiber` for React-Three integration
- `OrbitControls` for camera control
- Custom shaders for visual effects
- Real-time node graph rendering

**Design System:**
- Tokens defined in `frontend/design-tokens.json`
- Brand: Ghost (confident, calm, minimal, technical)
- Recommended: Tailwind CSS + Radix UI for components

### Frontend Development Rules

1. **Always use functional components with hooks**
2. **Maintain component structure:**
   ```
   frontend/src/components/
   ├── shared/           # Shared components across products
   ├── chainghost/       # ChainGhost-specific components
   └── ghonity/          # Ghonity-specific components
   ```

3. **Styling approach:**
   - Use CSS Modules for component-specific styles
   - Use `globals.css` for app-wide styles
   - Reference design-tokens.json for consistency

4. **State management (when implemented):**
   - Use React Context for global state
   - Consider Zustand/Jotai for complex state
   - Redux if absolutely necessary

5. **API calls:**
   - Create `frontend/src/lib/api/` for API clients
   - Use axios or fetch with proper error handling
   - Implement retry logic for critical calls

---

### How to Add a New Frontend Page (Step-by-Step)

**Example: Adding a ChainGhost profile page**

1. **Create the page file:**
   ```bash
   touch frontend/pages/chainghost.jsx
   ```

2. **Add basic page structure:**
   ```javascript
   // frontend/pages/chainghost.jsx
   export default function ChainGhostPage() {
     return (
       <div>
         <h1>ChainGhost - Your Unified Wallet & Journey</h1>
         <p>Coming soon...</p>
       </div>
     )
   }
   ```

3. **Add styles (optional):**
   ```bash
   touch frontend/styles/ChainGhost.module.css
   ```

4. **Import styles in page:**
   ```javascript
   import styles from '../styles/ChainGhost.module.css'
   ```

5. **Test locally:**
   - Navigate to `https://[replit-url]/chainghost`
   - Check browser console for errors
   - Verify HMR (Hot Module Replacement) works

6. **Update replit.md:**
   - Add to "Recent Changes" section

---

## Backend Architecture 📋 PLANNED

**⚠️ STATUS: NOT YET IMPLEMENTED - Documentation Only**

### Overview
Backend will use **microservices architecture** dengan beberapa service utama:

```
┌─────────────────────────────────────────────┐
│            API GATEWAY (Port 4000)          │
│  - Authentication                           │
│  - Request routing                          │
│  - Rate limiting                            │
└─────────────────────────────────────────────┘
              ↓
    ┌─────────┴─────────┐
    ↓                   ↓
┌─────────┐      ┌──────────────┐
│ INDEXER │      │  AI ENGINE   │
│ SERVICE │      │   SERVICE    │
│         │      │              │
│ - Multi │      │ - Story gen  │
│  chain  │      │ - Smart      │
│  watch  │      │   routing    │
│ - Event │      │ - Discovery  │
│  parse  │      │              │
└─────────┘      └──────────────┘
    ↓                   ↓
┌─────────────────────────────────┐
│      SOCIAL GRAPH SERVICE       │
│  - Follow relationships         │
│  - Reputation scoring           │
│  - Network analysis             │
└─────────────────────────────────┘
```

### Backend Services (To Be Implemented)

#### 1. API Gateway
**Location:** `backend/src/gateway/`  
**Responsibilities:**
- Route requests to appropriate services
- Authentication & authorization (Privy/Dynamic)
- Rate limiting & API key validation
- Response aggregation

**Port:** 4000 (localhost)

#### 2. Indexer Service
**Location:** `backend/src/indexer/`  
**Responsibilities:**
- Monitor multiple blockchain networks
- Parse and normalize transaction events
- Store time-series data in TimescaleDB
- Emit events for AI Engine and Social Graph

**Key Functions:**
- `watchChain(chainId)` - Monitor blockchain
- `parseTransaction(txHash)` - Parse tx data
- `storeEvent(event)` - Save to database
- `emitUpdate(walletId)` - Notify other services

#### 3. AI Engine Service
**Location:** `backend/src/ai/`  
**Responsibilities:**
- Generate ChainGhost narratives from transaction data
- Smart routing for ChainGhost (find optimal paths)
- Discovery algorithms for Ghonity
- Build embeddings for similarity search

**Key Functions:**
- `generateStory(walletId)` - Create ChainGhost narrative
- `findOptimalRoute(intent)` - Route finding
- `recommendWallets(userId)` - Discovery

#### 4. Social Graph Service
**Location:** `backend/src/social/`  
**Responsibilities:**
- Manage follow relationships
- Calculate reputation scores
- Generate social feeds
- Provide discovery APIs

**Key Functions:**
- `followWallet(follower, followee)` - Create follow
- `getFeed(userId)` - Generate personalized feed
- `calculateReputation(walletId)` - Score wallet

### Data Layer

```
┌──────────────────────────────────────────┐
│           DATABASE LAYER                 │
├──────────────────────────────────────────┤
│                                          │
│  PostgreSQL                              │
│  - Users, Wallets, Follows               │
│  - ChainGhost narratives, Badges         │
│  - Authentication sessions               │
│                                          │
│  TimescaleDB (PostgreSQL extension)      │
│  - Transaction events (time-series)      │
│  - Performance metrics                   │
│  - Historical data                       │
│                                          │
│  Redis                                   │
│  - Session cache                         │
│  - Real-time feeds                       │
│  - Job queues                            │
│                                          │
│  Elasticsearch                           │
│  - Wallet search                         │
│  - Transaction search                    │
│  - Discovery queries                     │
│                                          │
│  Vector DB (Pinecone/Milvus/Weaviate)    │
│  - Wallet embeddings                     │
│  - Similarity search                     │
│  - AI discovery features                 │
│                                          │
└──────────────────────────────────────────┘
```

### Backend Development Rules

1. **Service Structure:**
   ```
   backend/src/<service-name>/
   ├── controllers/      # HTTP handlers
   ├── services/         # Business logic
   ├── models/           # Data models
   ├── utils/            # Helper functions
   └── tests/            # Unit & integration tests
   ```

2. **API Design:**
   - Use RESTful conventions
   - Version APIs: `/api/v1/`
   - Return consistent error format
   - Implement pagination for lists

3. **Database Access:**
   - Use TypeORM or Prisma for PostgreSQL
   - Implement repository pattern
   - Always use transactions for multi-table operations
   - Index frequently queried fields

4. **Error Handling:**
   - Create custom error classes
   - Log errors with context
   - Return user-friendly messages
   - Never expose internal errors to client

5. **Security:**
   - Validate all inputs
   - Sanitize user data
   - Use parameterized queries (prevent SQL injection)
   - Implement rate limiting
   - Store API keys in environment variables

---

### When to Implement Backend
**Prerequisites before starting backend:**
1. ✅ Frontend is stable and tested
2. ⬜ Database schemas defined
3. ⬜ API contracts documented
4. ⬜ Authentication strategy chosen (Privy/Dynamic)

**Implementation Order:**
1. Start with API Gateway (port 4000)
2. Add basic authentication
3. Implement Indexer service
4. Add AI Engine service
5. Build Social Graph service

---

## Infrastructure & DevOps 📋 PLANNED

**⚠️ STATUS: NOT YET IMPLEMENTED - Documentation Only**

### Current Infrastructure Status
**Status:** Placeholder only (manifests in `infra/`)

### Planned Infrastructure

**Container Orchestration:**
- Kubernetes for service deployment
- Helm charts for configuration management
- Namespaces: dev, staging, production

**Monitoring & Observability:**
```yaml
Prometheus:
  - Metrics collection from all services
  - Custom metrics for blockchain events
  - Alert rules for anomalies

Grafana:
  - Real-time dashboards
  - Service health visualization
  - Performance metrics

Logging:
  - Centralized logging (ELK stack or similar)
  - Structured JSON logs
  - Log retention policy
```

**CI/CD Pipeline:**
```yaml
GitHub Actions:
  - Automated testing on PR
  - Build Docker images
  - Deploy to Kubernetes
  - Run security scans

Stages:
  1. Lint & Test
  2. Build artifacts
  3. Deploy to dev
  4. Integration tests
  5. Deploy to staging
  6. Manual approval
  7. Deploy to production
```

### Infrastructure Development Rules

1. **Kubernetes Manifests:**
   ```
   infra/k8s/
   ├── base/             # Base configurations
   ├── dev/              # Dev environment
   ├── staging/          # Staging environment
   └── production/       # Production environment
   ```

2. **Environment Variables:**
   - Never commit secrets to Git
   - Use Kubernetes Secrets
   - Document required env vars in README

3. **Resource Limits:**
   - Always set resource requests/limits
   - Monitor actual usage and adjust
   - Plan for autoscaling

4. **Deployment Strategy:**
   - Use rolling updates
   - Implement health checks
   - Have rollback plan
   - Test in staging first

---

## Blockchain Layer 📋 PLANNED

**⚠️ STATUS: NOT YET IMPLEMENTED - Documentation Only**

### Overview
Blockchain layer will handle semua interaksi on-chain untuk ChainGhost.

### Architecture

```
┌─────────────────────────────────────────┐
│      BLOCKCHAIN INTERACTION LAYER       │
├─────────────────────────────────────────┤
│                                         │
│  Multi-Chain RPC Nodes                  │
│  ├── Ethereum                           │
│  ├── BSC (Binance Smart Chain)          │
│  ├── Polygon                            │
│  ├── Arbitrum                           │
│  └── [Future chains]                    │
│                                         │
│  Account Abstraction (ERC-4337)         │
│  ├── Bundler nodes                      │
│  ├── Paymaster contracts                │
│  └── Entry point contracts              │
│                                         │
│  Intent Solver Network                  │
│  ├── Route optimization                 │
│  ├── Gas estimation                     │
│  └── MEV protection                     │
│                                         │
│  Smart Contract Wallets                 │
│  ├── UUPS/Transparent proxy pattern     │
│  ├── Social recovery                    │
│  └── Multi-sig support                  │
│                                         │
└─────────────────────────────────────────┘
```

### Smart Contracts

**Location:** `contracts/contracts/`

**Contract Structure (To Be Implemented):**
```
contracts/contracts/
├── wallet/
│   ├── GhostWallet.sol         # Main wallet contract
│   ├── GhostWalletFactory.sol  # Factory for deployment
│   └── modules/                # Wallet modules
│       ├── RecoveryModule.sol
│       └── SessionModule.sol
│
├── intent/
│   ├── IntentEngine.sol        # Intent processing
│   └── IntentSolver.sol        # Route solving
│
├── paymaster/
│   └── GhostPaymaster.sol      # Gas abstraction
│
└── interfaces/
    └── [Interface definitions]
```

### Smart Contract Development Rules

1. **Development Environment:**
   - Use Hardhat for development
   - Write comprehensive tests (>90% coverage)
   - Use OpenZeppelin contracts for standards
   - Implement upgradeable pattern (UUPS or Transparent)

2. **Security Practices:**
   ```
   MUST DO:
   - Run Slither static analysis
   - Run Mythril symbolic execution
   - Implement reentrancy guards
   - Use SafeMath (pre-Solidity 0.8)
   - Emit events for all state changes
   
   MUST NOT:
   - Deploy without audit (mainnet)
   - Use delegatecall without extreme caution
   - Store secrets on-chain
   - Ignore compiler warnings
   ```

3. **Testing Strategy:**
   - Unit tests for each function
   - Integration tests for workflows
   - Fuzz testing for edge cases
   - Gas optimization tests
   - Upgrade scenario tests

4. **Deployment Process:**
   ```
   1. Test on local Hardhat network
   2. Deploy to testnets (Goerli, Mumbai, etc.)
   3. Run end-to-end tests on testnet
   4. Third-party security audit
   5. Bug bounty program
   6. Mainnet deployment (gradual rollout)
   ```

---

## Development Workflows ✅ IMPLEMENTED

### Current Active Workflows

**Frontend Workflow:** ✅ **RUNNING**
```yaml
Name: frontend
Command: cd frontend && npm run dev
Port: 5000
Output: webview
Status: Active
```

**How to Access:**
- Click "Webview" button in Replit
- Or use the preview URL shown in Replit

### Running the Project

**✅ Frontend (WORKING NOW):**
```bash
# Frontend is already running via workflow
# To manually start:
cd frontend
npm run dev          # Development server on port 5000

# To rebuild:
npm run build        # Production build
npm run start        # Start production server
```

**Important:** Frontend MUST bind to `0.0.0.0:5000` for Replit proxy to work.

**📋 Backend (TO BE IMPLEMENTED):**
```bash
# When you implement backend, follow this pattern:
cd backend
npm install
npm run dev          # Should run on port 4000 (localhost)
```

**📋 Smart Contracts (TO BE IMPLEMENTED):**
```bash
# When you implement contracts, follow this pattern:
cd contracts
npm install
npx hardhat compile  # Compile contracts
npx hardhat test     # Run tests
npx hardhat node     # Start local node (port 8545)
```

### Development Commands Reference

**Frontend:**
```bash
npm run dev          # Start dev server
npm run build        # Production build
npm run start        # Start production server
npm run lint         # Run ESLint (when configured)
```

**Backend:**
```bash
npm run dev          # Start with nodemon
npm run build        # Compile TypeScript
npm run start        # Start production
npm test             # Run tests
```

**Contracts:**
```bash
npx hardhat compile  # Compile contracts
npx hardhat test     # Run tests
npx hardhat clean    # Clean artifacts
npx hardhat deploy   # Deploy (with deploy script)
```

### Git Workflow

**Branch Strategy:**
```
main                 # Production-ready code
├── develop          # Integration branch
│   ├── feature/*    # New features
│   ├── fix/*        # Bug fixes
│   └── refactor/*   # Code improvements
```

**Commit Convention:**
```
feat: Add ChainGhost narrative generation API
fix: Resolve wallet balance calculation bug
refactor: Improve indexer performance
docs: Update API documentation
test: Add integration tests for social graph
chore: Update dependencies
```

---

## Coding Guidelines

### General Principles

1. **Code Quality:**
   - Write self-documenting code
   - Add comments for complex logic only
   - Keep functions small and focused
   - Use meaningful variable names
   - Avoid premature optimization

2. **Project Organization:**
   - One concern per file
   - Group related files together
   - Use index files for clean imports
   - Maintain consistent file naming

3. **Error Handling:**
   ```javascript
   // Good
   try {
     const result = await riskyOperation()
     return { success: true, data: result }
   } catch (error) {
     logger.error('Operation failed', { error, context })
     return { success: false, error: error.message }
   }
   
   // Bad
   const result = await riskyOperation() // No error handling
   ```

4. **Async/Await:**
   ```javascript
   // Good - Sequential when needed
   const user = await getUser(id)
   const wallet = await getWallet(user.walletId)
   
   // Good - Parallel when possible
   const [user, settings] = await Promise.all([
     getUser(id),
     getSettings(id)
   ])
   
   // Bad - Unnecessary sequential
   const user = await getUser(id)
   const settings = await getSettings(id) // Could be parallel
   ```

5. **Emoji/Emoticon Usage Policy:**
   
   **CRITICAL RULE: NO EMOJIS IN CODE**
   
   ```javascript
   // ❌ BAD - Never use emojis in code
   const status = "✅ Success"
   console.log("🚀 Starting server...")
   const errorMessage = "❌ Failed to load"
   
   // ✅ GOOD - Use plain text in code
   const status = "Success"
   console.log("Starting server...")
   const errorMessage = "Failed to load"
   
   // ❌ BAD - Emojis in variable names or comments
   const rocket_emoji = "🚀"  // Don't do this
   // 🔥 This is a hot function  // Don't do this
   
   // ✅ GOOD - Descriptive names and comments
   const launchIcon = "rocket"
   // This function handles high-priority tasks
   ```
   
   **Frontend: Use Icons and SVG Only**
   
   ```jsx
   // ❌ BAD - Emoji in UI components
   const Button = () => <button>Click me! 👆</button>
   const Alert = () => <div>⚠️ Warning message</div>
   
   // ✅ GOOD - Use icon libraries or SVG
   import { ClickIcon } from '@/icons'
   import { AlertIcon } from '@heroicons/react'
   
   const Button = () => (
     <button>
       <ClickIcon className="w-4 h-4" />
       Click me!
     </button>
   )
   
   const Alert = () => (
     <div className="flex items-center gap-2">
       <AlertIcon className="w-5 h-5 text-yellow-500" />
       <span>Warning message</span>
     </div>
   )
   
   // ✅ GOOD - Custom SVG icons
   const CheckIcon = () => (
     <svg viewBox="0 0 24 24" fill="currentColor">
       <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/>
     </svg>
   )
   ```
   
   **Exception: User-Facing Content Only**
   
   Emojis are ONLY allowed in user-visible text content:
   
   ```jsx
   // ✅ ALLOWED - User input/content that users write
   const userComment = "Great project! 🚀"  // User-generated content
   const userBio = "Crypto enthusiast 💎🙌"   // User profile text
   
   // ✅ ALLOWED - Marketing/content copy (with caution)
   const welcomeMessage = "Welcome to Ghost Protocol 👻"  // If part of brand
   
   // ❌ STILL NOT ALLOWED - Developer-written UI text
   const buttonText = "Submit 🚀"  // Use icon component instead
   const errorText = "Error ❌"     // Use icon component instead
   ```
   
   **Why This Rule Exists:**
   1. **Consistency:** Icons are theme-aware and scalable
   2. **Accessibility:** Screen readers handle icons better than emojis
   3. **Professionalism:** Code should be clean and maintainable
   4. **Rendering:** Emojis render differently across platforms
   5. **Performance:** SVG icons are optimized and cacheable
   
   **Recommended Icon Libraries:**
   - Hero Icons (already using Hero UI)
   - Lucide Icons
   - Phosphor Icons
   - Custom SVG sprite sheets

### TypeScript Guidelines (Backend)

```typescript
// Use interfaces for data structures
interface User {
  id: string
  walletAddress: string
  createdAt: Date
}

// Use types for unions and intersections
type WalletStatus = 'active' | 'suspended' | 'deleted'

// Avoid 'any', use 'unknown' if type is truly unknown
function processData(data: unknown) {
  if (typeof data === 'string') {
    // Now TypeScript knows it's a string
  }
}

// Use generics for reusable types
interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: string
}
```

### React Guidelines (Frontend)

```javascript
// Prefer functional components
const MyComponent = ({ title, onAction }) => {
  const [state, setState] = useState(initialState)
  
  useEffect(() => {
    // Side effects here
    return () => {
      // Cleanup
    }
  }, [dependencies])
  
  return <div>{title}</div>
}

// Use custom hooks for reusable logic
const useWalletBalance = (address) => {
  const [balance, setBalance] = useState(null)
  
  useEffect(() => {
    fetchBalance(address).then(setBalance)
  }, [address])
  
  return balance
}

// Memoize expensive computations
const expensiveValue = useMemo(() => {
  return computeExpensiveValue(a, b)
}, [a, b])
```

### Solidity Guidelines (Smart Contracts)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/...";

/// @title GhostWallet
/// @notice Smart contract wallet with account abstraction
/// @dev Implements ERC-4337 standard
contract GhostWallet is Initializable, UUPSUpgradeable {
    
    /// @notice Emitted when wallet executes transaction
    /// @param target The destination address
    /// @param value The amount of ETH sent
    event TransactionExecuted(address indexed target, uint256 value);
    
    /// @notice Execute a transaction
    /// @param target Destination address
    /// @param value Amount to send
    /// @param data Transaction data
    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyOwner returns (bytes memory) {
        // Implementation
        emit TransactionExecuted(target, value);
    }
}
```

---

## Common Tasks Reference ✅ IMPLEMENTED

### ✅ Task 1: Check Current Project State

**ALWAYS START HERE:**
```bash
# 1. Read the current state
# - Check replit.md for latest status
# - Check agent-work.md for complete docs
# - Check this file for development rules

# 2. Verify frontend is running
# - Check webview output
# - Look for "✓ Ready" message in logs

# 3. Check for errors
# - Use refresh_all_logs tool
# - Check browser console
```

### ✅ Task 2: Add a New Frontend Page

**Example: Adding homepage**
```bash
# 1. Create the page
cat > frontend/pages/index.jsx << 'EOF'
export default function HomePage() {
  return (
    <div>
      <h1>Ghost Protocol</h1>
      <p>Welcome to the crypto super-app</p>
    </div>
  )
}
EOF

# 2. Test by navigating to https://[replit-url]/
# 3. Update replit.md with change
```

### ✅ Task 3: Add a New Component

**Example: Adding a card component**
```bash
# 1. Create component directory if needed
mkdir -p frontend/src/components/shared

# 2. Create component file
cat > frontend/src/components/shared/Card.jsx << 'EOF'
export default function Card({ title, children }) {
  return (
    <div className="card">
      <h3>{title}</h3>
      {children}
    </div>
  )
}
EOF

# 3. Create style file
touch frontend/src/components/shared/Card.module.css

# 4. Use in page
# import Card from '../src/components/shared/Card'
```

### ✅ Task 4: Install New Frontend Dependency

```bash
cd frontend
npm install <package-name>

# Example:
npm install axios
npm install tailwindcss

# Restart workflow after installing
# Use restart_workflow tool
```

### ✅ Task 5: Debug Frontend Issues

**Step-by-step debugging:**
```bash
# 1. Check logs
# - Use refresh_all_logs tool
# - Read /tmp/logs/frontend_*.log

# 2. Check browser console
# - Look for JavaScript errors
# - Check network tab for failed requests

# 3. Check Next.js compilation
# - Look for "Compiled successfully" or error messages
# - Check for missing imports

# 4. Common fixes:
# - Delete .next folder: rm -rf frontend/.next
# - Reinstall dependencies: rm -rf frontend/node_modules && npm install
# - Restart workflow
```

### ✅ Task 6: Update Documentation

**After making changes:**
```bash
# 1. Update replit.md
# - Add to "Recent Changes" section
# - Update "Current State" if needed

# 2. If major architectural change:
# - Update agent-work.md
# - Update this file (agent-rules.md)
```

### 📋 Task 7: Add Backend Endpoint (WHEN IMPLEMENTED)

**Not yet available - backend doesn't exist yet**
```bash
# This is for future reference
# Steps will be similar to:
# 1. Create controller
# 2. Define route
# 3. Implement business logic
# 4. Add tests
```

### 📋 Task 8: Add Smart Contract (WHEN IMPLEMENTED)

**Not yet available - contracts not set up yet**
```bash
# This is for future reference
# Steps will be similar to:
# 1. Create contract file
# 2. Write tests
# 3. Compile
# 4. Deploy to testnet
```

### Debugging Tips

**Frontend Issues:**
```bash
# Check browser console
# Check Next.js dev server logs
# Use React DevTools
# Check network tab for API calls

# Common issues:
# - Port conflict: Change to different port
# - Build errors: Delete .next/ and rebuild
# - Module not found: npm install again
```

**Backend Issues:**
```bash
# Check server logs
# Use debugger or console.log
# Test API with Postman/curl
# Check database connections

# Common issues:
# - Port in use: kill process or use different port
# - Database connection: verify credentials
# - CORS errors: check CORS configuration
```

**Blockchain Issues:**
```bash
# Check transaction hash on block explorer
# Verify contract deployment
# Check gas limits
# Test on testnet first

# Common issues:
# - Gas estimation: increase gas limit
# - Revert without reason: add error messages
# - Nonce issues: reset account nonce
```

---

## Important Notes for Agents

### When Working on This Project:

1. **Always check replit.md first** for current project state
2. **Refer to agent-work.md** for complete documentation
3. **Follow the directory structure** - don't create files in wrong locations
4. **Update replit.md** when making significant changes
5. **Test changes** before considering task complete
6. **Keep frontend on port 5000** - this is mandatory for Replit
7. **Backend should use port 4000** (localhost) when implemented
8. **Never commit secrets or API keys**
9. **Document major decisions** in appropriate markdown files

### Quick Reference for Agent Decisions

**"Where should I put this file?"**
- Frontend component → `frontend/src/components/`
- Frontend page → `frontend/pages/`
- Backend service → `backend/src/services/`
- Smart contract → `contracts/contracts/`
- Documentation → `doc/` or root for agent docs

**"What port should I use?"**
- Frontend: 5000 (0.0.0.0)
- Backend: 4000 (localhost)
- Hardhat node: 8545 (localhost)

**"How do I test my changes?"**
- Frontend: Check webview, browser console
- Backend: Use Postman/curl, check logs
- Contracts: `npx hardhat test`

**"Should I create this file?"**
- Code files: Yes, if needed for functionality
- Documentation: Only if explicitly requested
- Config files: Yes, if required for setup
- Test files: Yes, always write tests

### Emergency Fixes

**If frontend won't start:**
```bash
cd frontend
rm -rf .next node_modules package-lock.json
npm install
npm run dev
```

**If workflow is broken:**
- Check logs: Use refresh_all_logs tool
- Restart workflow: Use restart_workflow tool
- Reconfigure: Use workflows_set_run_config_tool

**If port conflict:**
- Frontend MUST be 5000 for Replit
- Backend can use 4000 or 3000
- Never use port 80 or 443

---

## Documentation Maintenance

### Files to Keep Updated

**replit.md:**
- Current project state
- Recent changes log
- User preferences
- Development status

**agent-work.md:**
- Already complete, don't modify unless major changes
- Consolidates all 14 source documentation files

**This file (agent-rules.md):**
- Update when adding new patterns
- Update when project structure changes
- Update with lessons learned

---

## Version History

**v1.1.0** (November 11, 2025)
- Added Emoji/Emoticon Usage Policy
- NO EMOJIS IN CODE rule (critical)
- Frontend must use icons/SVG only
- Exception: User-facing content only
- Added recommended icon libraries

**v1.0.0** (November 9, 2025)
- Initial creation
- Frontend setup complete
- Backend placeholder
- Comprehensive guidelines established

---

**End of Agent Rules Documentation**

For complete project information, always refer to:
- `agent-work.md` - Full documentation
- `replit.md` - Current state
- `doc/` - Technical specs
