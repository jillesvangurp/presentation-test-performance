# FORMATION – Reveal.js Deck

A ready-to-run Reveal.js deck with a first pass at a brand theme.
To use your real brand colors, replace `img/screenshot.jpg` with a capture of your site and tweak `css/theme/formation.css`.

## Quick start

```bash
bunx serve .
```

And then open [http://localhost:3000](the slides)

Or just open `index.html` in a browser. Reveal.js loads via the CDN.

## Use your assets

- Replace `img/logo.svg` with your actual SVG logo (same filename).
- Replace `img/screenshot.jpg` with your website screenshot.

## Customize the theme
Edit `css/theme/formation.css` and tune these variables:
```
--color-bg
--color-fg
--color-accent
--color-muted
--color-link
```

## Structure
```
formation-deck/
  index.html
  css/
    theme/
      formation.css
  img/
    logo.svg
    screenshot.jpg
```
