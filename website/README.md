# MHX Ternary Ibex Documentation Website

This directory contains the Astro-based documentation website for the MHX Ternary RISC-V Core project.

## 🚀 Features

- **Beautiful Design**: Professional, responsive design with light/dark mode support
- **Real-time Data**: Automatically pulls CI status, test results, and performance metrics
- **Interactive Components**: Live metrics, progress bars, and status indicators
- **Comprehensive Documentation**: Complete ISA reference, integration guides, and security analysis
- **Automatic Deployment**: Deploys to GitHub Pages on every commit to main

## 🏗️ Structure

```
website/
├── src/
│   ├── components/       # Reusable UI components
│   │   ├── Header.astro
│   │   ├── Footer.astro
│   │   ├── Sidebar.astro
│   │   ├── StatCard.astro
│   │   ├── TestStatus.astro
│   │   └── ProgressBar.astro
│   ├── layouts/          # Page layouts
│   │   ├── BaseLayout.astro
│   │   └── DocsLayout.astro
│   ├── pages/            # Site pages (file-based routing)
│   │   ├── index.astro          # Dashboard
│   │   ├── architecture.astro   # Architecture overview
│   │   ├── verification.astro   # Test status & coverage
│   │   └── docs/
│   │       ├── index.astro
│   │       ├── quick-start.astro
│   │       ├── instruction-set.astro
│   │       ├── integration.astro
│   │       └── security.astro
│   └── data/             # Generated data (JSON)
├── public/               # Static assets
│   ├── images/          # Images (floorplan, diagrams)
│   └── data/            # Public JSON data
├── scripts/             # Build scripts
│   └── generate-site-data.mjs
└── package.json
```

## 🛠️ Development

### Prerequisites

- Node.js 20+
- npm or pnpm

### Install Dependencies

```bash
cd website
npm install
```

### Generate Site Data

```bash
npm run generate-data
```

This script:
- Reads CI artifacts and test results
- Loads performance metrics from `ci/performance_baseline.json`
- Copies markdown documentation from `doc/` directory
- Copies floorplan and other images
- Generates JSON files for the site to consume

### Run Development Server

```bash
npm run dev
```

Visit http://localhost:4321 to see the site.

### Build for Production

```bash
npm run build
```

The built site will be in `dist/` directory.

## 📊 Data Flow

The website automatically pulls data from various sources:

```
GitHub CI/CD
    ↓
Artifacts (test results, coverage, performance)
    ↓
generate-site-data.mjs
    ↓
src/data/*.json
    ↓
Astro Pages
    ↓
Static HTML (dist/)
    ↓
GitHub Pages
```

### Data Sources

| Data Type | Source | Generated File |
|-----------|--------|----------------|
| Build info | GitHub Actions env | `build-info.json` |
| CI status | CI artifacts | `ci-status.json` |
| Performance | `ci/performance_baseline.json` | `performance.json` |
| Test results | CI artifacts | `verification.json` |
| Documentation | `doc/*.md`, `*.md` | `docs-content.json` |
| Images | `docs/images/`, `build/floorplan/` | `public/images/` |

## 🎨 Theming

The site uses Tailwind CSS with custom color schemes:

- **Primary**: Blue tones (core branding)
- **Accent**: Green tones (ternary operations)
- **Neural**: Yellow tones (neural unit)

Dark mode is supported and automatically switches based on user preference.

## 🚀 Deployment

The site is automatically deployed to GitHub Pages via the `.github/workflows/deploy-website.yml` workflow:

1. **Collect Data**: Gathers CI artifacts and metrics
2. **Build**: Runs Astro build with collected data
3. **Deploy**: Publishes to GitHub Pages

### Manual Deployment

```bash
npm run build
# Upload dist/ to your hosting provider
```

## 📝 Adding Content

### New Documentation Page

1. Create `src/pages/docs/your-page.astro`
2. Use the `DocsLayout` layout
3. Add link in `Sidebar.astro`

Example:

```astro
---
import DocsLayout from '../../layouts/DocsLayout.astro';
---

<DocsLayout title="Your Page Title">
  <div class="prose dark:prose-invert max-w-none">
    <h1>Your Content</h1>
    <!-- Your markdown or HTML -->
  </div>
</DocsLayout>
```

### New Metric Card

Use the `StatCard` component:

```astro
<StatCard
  title="Your Metric"
  value="42"
  subtitle="Description"
  icon="chart"
  status="success"
  trend="up"
  trendValue="+10%"
/>
```

## 🧪 Testing

```bash
# Check TypeScript
npx astro check

# Preview production build
npm run preview
```

## 📄 License

Same as parent project (Apache 2.0)
