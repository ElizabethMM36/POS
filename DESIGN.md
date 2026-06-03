---
name: Command Center POS
colors:
  surface: '#11131b'
  surface-dim: '#11131b'
  surface-bright: '#373942'
  surface-container-lowest: '#0c0e16'
  surface-container-low: '#191b23'
  surface-container: '#1d1f27'
  surface-container-high: '#282a32'
  surface-container-highest: '#32343d'
  on-surface: '#e1e2ed'
  on-surface-variant: '#c3c6d7'
  inverse-surface: '#e1e2ed'
  inverse-on-surface: '#2e3039'
  outline: '#8d90a0'
  outline-variant: '#434655'
  surface-tint: '#b4c5ff'
  primary: '#b4c5ff'
  on-primary: '#002a78'
  primary-container: '#2563eb'
  on-primary-container: '#eeefff'
  inverse-primary: '#0053db'
  secondary: '#b7c8e1'
  on-secondary: '#213145'
  secondary-container: '#3a4a5f'
  on-secondary-container: '#a9bad3'
  tertiary: '#ffb596'
  on-tertiary: '#581e00'
  tertiary-container: '#bc4800'
  on-tertiary-container: '#ffede6'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003ea8'
  secondary-fixed: '#d3e4fe'
  secondary-fixed-dim: '#b7c8e1'
  on-secondary-fixed: '#0b1c30'
  on-secondary-fixed-variant: '#38485d'
  tertiary-fixed: '#ffdbcd'
  tertiary-fixed-dim: '#ffb596'
  on-tertiary-fixed: '#360f00'
  on-tertiary-fixed-variant: '#7d2d00'
  background: '#11131b'
  on-background: '#e1e2ed'
  surface-variant: '#32343d'
  status-available: '#22C55E'
  status-occupied: '#EF4444'
  status-reserved: '#F59E0B'
  status-alert: '#EC4899'
  surface-high: '#1E293B'
  surface-base: '#0F172A'
typography:
  display-table:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 26px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  button-lg:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  touch-min: 48px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 32px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
---

## Brand & Style

This design system is engineered for the high-velocity environment of professional hospitality. The brand personality is **utilitarian, authoritative, and dependable**, prioritizing cognitive ease over decorative elements. The target audience includes servers, bartenders, and floor managers who require split-second "glanceability" to manage table turnover and order accuracy.

The design style is **Corporate / Modern** with a focus on **Functional High-Contrast**. It utilizes a structured, grid-based layout with clear containment. Elements are defined by purposeful color-coding and robust touch targets. While the aesthetic is clean and minimal, it avoids the fragility of consumer-facing apps, opting instead for a sturdy, industrial feel that suggests reliability under pressure.

Key principles:
- **Zero Ambiguity:** Every color and shape has a specific operational meaning.
- **Physicality:** Large, stable hit areas that respond immediately to touch.
- **Visual Hierarchy:** Critical status indicators (Occupied vs. Available) dominate the visual field.

## Colors

The palette is anchored by a high-contrast logic to ensure legibility across varied restaurant lighting—from dim dining rooms to bright patios. The default mode is **Dark**, which reduces eye strain during long shifts and prevents the screen from becoming a distraction in atmospheric settings.

### Semantic Logic
- **Primary:** Used for the "happy path" actions—sending orders to the kitchen or completing a checkout.
- **Success (Green):** Indicates "Available" or "Paid" status.
- **Danger (Red):** Indicates "Occupied" or "Action Required" (e.g., voided item).
- **Warning (Amber):** Indicates "Reserved" or "Check Requested."
- **Neutral/Surface:** Uses high-value contrasts between background and surface to define functional zones without relying on heavy borders.

## Typography

**Hanken Grotesk** is the primary typeface, chosen for its sharp terminals and exceptional legibility in a digital interface. It provides a modern, precise feel that matches the "Command Center" philosophy.

**JetBrains Mono** is utilized for metadata and technical labels (like seat numbers or timestamps). The monospaced nature ensures that numerical values (prices, quantities) remain aligned and easy to scan vertically in a list.

Scaling for Mobile:
- For the Table Grid, use `display-table` to ensure table numbers are visible from a distance.
- Interactive elements must never drop below `body-md` (16px) to maintain readability during rapid movement.

## Layout & Spacing

The layout follows a **Fluid Grid** model with strict adherence to a **48px minimum touch target** for all interactive elements. This prevents "fat-finger" errors during peak service hours.

### Spacing Rhythm
- **Table Grid:** Uses a flexible column system (typically 2-3 columns on mobile) with `stack-md` (16px) gutters to clearly separate different tables.
- **Order Entry:** A split-view approach where the "Order Summary" is pinned or easily accessible. 
- **Safe Zones:** Generous `margin-mobile` ensures that edge-taps are registered accurately even when the device is held in one hand.

## Elevation & Depth

Hierarchy is established through **Tonal Layers** and **Low-Contrast Outlines** rather than heavy shadows, keeping the UI looking crisp and avoiding visual "muddiness" in dark mode.

- **Level 0 (Base):** The main canvas (Floor Plan or Menu background).
- **Level 1 (Card):** Individual tables or menu items. These use a slightly lighter surface color (`surface-high`) and a subtle 1px border for definition.
- **Level 2 (Overlay/Sheet):** Order modifiers or quantity selectors. These utilize a backdrop blur to maintain the context of the underlying order while focusing the user's attention.
- **Active State:** When a table or item is selected, it should utilize a high-contrast stroke in the `primary` or `status` color rather than a shadow.

## Shapes

The shape language uses **Rounded** (0.5rem) corners to balance professional structure with approachability. 

- **Containers:** Table cards and menu categories use the standard `rounded` (8px) corners.
- **Interactive:** Action buttons (e.g., "Pay Now") use `rounded-lg` (16px) to distinguish them from static containers.
- **Status Tags:** Pills for "VIP" or "Course 1" status should use the maximum `rounded-xl` (24px) for a distinct "tag" appearance.

## Components

### Buttons
- **Primary Action:** Large height (minimum 56px), full-width on mobile, using the `primary-color` with white/high-contrast text. 
- **Quantity Toggles:** Large "+" and "-" buttons (48x48px) flanking the numerical value.

### Table Cards
- **Available:** `status-available` border and a large centered table number.
- **Occupied:** Solid `surface-high` background with a `status-occupied` indicator strip at the top. Should display "Time Open" and "Total Amount" prominently.

### Input Fields
- **Numeric Pad:** Custom large-scale grid for price or quantity entry, avoiding the standard system keyboard to maximize speed.
- **Search:** Persistent search bar for menu items with a "Clear" (X) button for rapid re-entry.

### Lists
- **Order Summary:** Items should have a minimum height of 64px. Use `label-md` for modifiers (e.g., "No Onions") to create a clear visual distinction from the main item name.

### Chips & Tags
- Used for table statuses (e.g., "Bill Requested"). These must use the `named_colors` background with high-contrast text to ensure they are the first thing a server sees when glancing at the floor plan.