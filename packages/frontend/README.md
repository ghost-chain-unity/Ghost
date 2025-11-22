# Frontend Applications

Frontend applications for Ghost Protocol ecosystem.

## Applications

### web
Main web application - ChainGhost (unified wallet + journey) + Ghonity (community ecosystem).
- **Tech Stack:** Next.js 14, React 18, Three.js
- **UI Library:** Hero UI, Tailwind CSS
- **3D Graphics:** @react-three/fiber, Spline
- **Animation:** GSAP, Framer Motion
- **Port:** 5000 (development)
- **Status:** ✅ Partially Implemented

### admin
Admin dashboard + SuperAccount features.
- **Tech Stack:** Next.js 14, React 18
- **Features:** 3D NFT generator, analytics, user management
- **Port:** 5001 (development)
- **Status:** 📋 Planned (not implemented)

### components
Shared design system and component library.
- **Tech Stack:** React 18, Storybook
- **Components:** Design tokens, Hero UI wrappers, 3D components
- **Status:** 📋 Planned (not implemented)

## Installation

Each app has its own `package.json`. Install dependencies per-app using pnpm:

```bash
cd web && pnpm install
cd admin && pnpm install
cd components && pnpm install
```

## Development

```bash
# Start web app (main app)
cd web && pnpm run dev         # http://0.0.0.0:5000

# Start admin app
cd admin && pnpm run dev       # http://0.0.0.0:5001

# Start Storybook (components)
cd components && pnpm run storybook
```

## Build

```bash
# Production build
cd web && pnpm run build
cd admin && pnpm run build
```

## Testing

```bash
# Run tests
pnpm test

# Run E2E tests
pnpm run test:e2e
```

## Design System

Follow the design guide in `docs/design-guide.md`:
- **Colors:** Void Blue glass, Neon accents
- **Typography:** Sohne Breit Variable, Inter
- **Icons:** Hero Icons only (NO EMOJI)
- **Spacing:** 8px baseline grid
- **Breakpoints:** 640, 768, 1024, 1280, 1536

## Performance

- Lighthouse score >90 (desktop), >80 (mobile)
- Bundle size <250KB per page
- LCP <2.5s
- Code splitting and lazy loading

---

**Last Updated:** November 15, 2025
