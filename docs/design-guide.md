# Design Guide — Ghost Protocol (Frontend) **MOBILE FIRST**

## Design philosophy
- Clean, futuristic, glass/neon aesthetic.
- Consistent 3D hologram language for brand elements.
- Accessibility and performance-first: prefer progressive enhancement.

## Color palette
### Light mode
- Void Blue glass: rgb(12, 34, 56) with translucency (use CSS variables for glass layers).
- Void White: #F7FAFC
- Accent Neon: #3DD1FF (sparingly for CTAs)
- Semantic: success #22C55E, warn #F59E0B, error #EF4444

### Dark mode
- Blue neon glass: rgba(21, 101, 192, 0.16)
- Void White: #F7FAFC (for text)
- Dark Blue Donker: #0B1220 (background)
- Accent Neon: #7CDBFF

### Tokens (example)
--color-bg: var(--dark-blue-donker);
--color-surface-glass: rgba(255,255,255,0.04);
--glass-blur: 16px;

## Typography
- Primary Display: Sohne Breit Variable  (variable font recommended). Fallback: Inter.
- UI Font: Inter Variable
- Decorative: Monument Extended.
- Scale: Base 16px; scale ratio 1.125
- Use variable fonts for weight flexibility and reduced font files.

## Iconography
- Heroicons (full set) included in repo per spec. Provide an icon registry file to map names to components.
- Use 3D glyph accents in Spline scenes for hero areas.

## Spacing & Layout
- 8px baseline grid.
- Containers: max-widths for content (720/1024/1280/1440).
- Responsive breakpoints: 640, 768, 1024, 1280, 1536.

## Components
- Design tokens → Tailwind config (or CSS variables) → HeroUI components → Application pages.
- Mandatory components:
  - Button (primary/secondary/ghost) with focus outlines, disabled state.
  - Card: 3D hologram variant and static variant.
  - Modal: accessible, focus-trap, close on ESC.
  - Toast: non-blocking notifications with ARIA alerts.
  - Wallet Connector: status, last tx, sign modal.

## 3D & Spline
- Spline scenes must be lazy-loaded and sandboxed in iframe to avoid layout jank.
- Provide low-poly fallback images for low-spec devices.
- Avoid heavy realtime JS in initial paint.

## Accessibility
- Color contrast: min 4.5:1 for normal text.
- Keyboard navigation for all interactive elements.
- ARIA roles for dynamic regions (mailbox, inbox, marketplace).

## Motion & Animation
- Prefer subtle motion. Use reduced-motion media query.
- Transition timing: 200–320ms easings.
- Use Framer Motion on selective components only.

## Design tokens / theming
- Provide `theme.json` + CSS variables.
- Dark/light toggle persisted in localStorage with system preference fallback.

## Branding assets
- Ghost primary logo SVG + 3D hologram Spline scene file.
- G3Mail logo variant with hologram asset.
- Store brand assets under `/assets/branding/` with versioned filenames.

## Developer handoff
- Document component props and accessibility constraints in Storybook.
- Each component must include visual regression tests.

## File naming conventions
- `*.module.css` or CSS-in-JS using styled-system or tailwind.
- Components: PascalCase; files match component names.