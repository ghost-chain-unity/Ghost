# Security Policy

## Supported Versions

We release security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to: **security@ghostprotocol.io**

You should receive a response within 48 hours. If for some reason you do not, please follow up via email to ensure we received your original message.

### What to Include

Please include the following information:

1. **Type of vulnerability** (e.g., SQL injection, XSS, authentication bypass)
2. **Full path** to the source file(s) related to the vulnerability
3. **Location** of the affected code (tag/branch/commit or direct URL)
4. **Step-by-step instructions** to reproduce the issue
5. **Proof-of-concept or exploit code** (if possible)
6. **Impact** of the issue, including how an attacker might exploit it

### Response Timeline

- **Initial Response:** Within 48 hours
- **Status Update:** Within 7 days
- **Fix Timeline:** 
  - Critical: 1-3 days
  - High: 7 days
  - Medium: 30 days
  - Low: 90 days

## Security Measures

### Automated Scanning

We use the following tools to continuously scan our codebase:

- **Snyk:** Dependency vulnerability scanning (daily)
- **CodeQL:** Static application security testing (on every PR)
- **Dependabot:** Automated dependency updates (weekly)
- **Slither:** Smart contract static analysis (on every contract PR)

### Third-Party Audits

All smart contracts undergo third-party security audits before mainnet deployment:

- **Audit Firms:** Trail of Bits, OpenZeppelin, Certora
- **Audit Scope:** All production smart contracts
- **Re-audit:** After any critical changes

### Bug Bounty Program

We run a bug bounty program through:

- **Platform:** Immunefi / HackerOne
- **Scope:** Smart contracts, backend APIs, frontend
- **Rewards:** Up to $50,000 for critical vulnerabilities

Details: [Coming Soon]

## Security Best Practices

### For Contributors

1. **Never commit secrets** (API keys, private keys, passwords)
   - Use environment variables
   - Add secrets to `.env.local` (gitignored)
   - Use GitHub Secrets for CI/CD

2. **Run security scans locally**
   ```bash
   # Frontend security check
   cd packages/frontend/web
   pnpm audit
   
   # Backend security check
   cd packages/backend/api-gateway
   pnpm audit
   
   # Contract security check
   cd packages/contracts/chaing-token
   pnpx hardhat check
   ```

3. **Follow secure coding guidelines**
   - Input validation (Zod, class-validator)
   - SQL injection prevention (Prisma, parameterized queries)
   - XSS prevention (React auto-escaping, DOMPurify)
   - Authentication (JWT with refresh tokens)
   - Authorization (RBAC, permission checks)

4. **Smart contract security**
   - Reentrancy protection (checks-effects-interactions)
   - Overflow/underflow protection (Solidity 0.8+)
   - Access control (OpenZeppelin AccessControl)
   - Formal verification (for critical contracts)
   - Test coverage >95%

### For Users

1. **Keep dependencies updated**
   ```bash
   pnpm update --latest
   ```

2. **Review Dependabot PRs promptly**
   - Security updates: Merge within 24h
   - Non-security: Review within 7 days

3. **Monitor security alerts**
   - GitHub Security tab
   - Snyk dashboard
   - Email notifications

## Disclosure Policy

- We follow **Coordinated Vulnerability Disclosure**
- We will publicly disclose vulnerabilities after:
  1. Fix is deployed to production
  2. 90 days have passed since initial report (whichever comes first)
- Credit will be given to researchers (unless they prefer to remain anonymous)

## Contact

- **Security Email:** security@ghostprotocol.io
- **PGP Key:** [Coming Soon]
- **Bug Bounty:** [Coming Soon]

## Acknowledgments

We thank the following security researchers for responsibly disclosing vulnerabilities:

- [List will be updated as vulnerabilities are disclosed]

---

**Last Updated:** November 15, 2025  
**Next Review:** December 15, 2025
