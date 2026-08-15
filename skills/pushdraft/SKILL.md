---
name: pushdraft
description: Use when the user asks to communicate through an HTML document, or if they mention "HTML" with no additional context.
metadata:
    harness: [claude, codex]
    platform: [darwin, linux]
    requires: "npx (pushdraft is run via npx)"
---

# HTML Communication

## When to Use

Use this skill when the user wants a plan, spec, write-up, findings, summary,
report, comparison, or set of UI mocks presented as readable HTML.

Do not use it for HTML that ships as part of a product.

## Document

Create one self-contained HTML file, capped at 512 KB.

-  Write it like a spec, not a landing page: dense, scannable, no hero,
  decorative chrome, marketing voice, or em dashes.
-  Default to true black (`#000`), white primary text, and dark gray only for
  secondary surfaces or accents.
-  Make it mobile-readable with a responsive viewport and no fixed-width layout.
-  Use semantic HTML, inline CSS, inline SVG, and HTTPS or data-URL images.
-  Use an inline classic script only when interactivity materially helps. Keep
  scripted pages useful without JavaScript; the sandbox blocks storage, fetch,
  workers, frames, forms, and popups.
-  In script-free files, give external links `target="_blank"` and
  `rel="noopener noreferrer"`. If any script exists, omit `target="_blank"`.

Never include external or module scripts, inline event handlers, `javascript:`
URLs, forms, frames, embeds, objects, applets, meta refresh, linked stylesheets,
secrets, private URLs, or local filesystem paths.

## UI Mocks

Any non-trivial UI, layout, or copy change starts here rather than in the real
components. Build several distinct static mocks, publish them, report the URL,
and stop. Wait for a pick before implementing anything.

When rendering variants:

-  Render real styled variants, not descriptions.
-  Label them `A`, `B`, `C`... for easy selection.
-  Lay them out for direct comparison.
-  Reuse the same absolute path across iterations so its Pushdraft URL stays stable.

## Publish

Shubrt has given standing permission to upload every artifact created or updated
with this skill. Upload is required, including in Auto mode. Do not ask for
separate permission or stop at the local file.

1. Write the HTML file locally.
2. Run `npx pushdraft upload <file path>`.
3. After the upload succeeds, delete that exact local HTML file.
4. Report the returned Pushdraft URL.

Re-create and upload the same absolute path to update the existing URL. Use
`npx pushdraft upload <file path> --new` only when a new draft is wanted.

Never leave a local HTML file behind after a successful upload. If the upload
fails, keep the file only to fix and retry it, then delete it after the retry
succeeds.

If validation fails, fix the markup and retry. If a scripted upload needs
authentication, ask the user to run `pushdraft auth login`, then retry without
removing the requested interactivity.

Never open a browser or claim the document is hosted before upload succeeds.
Do not verify in a browser unless the user asks.
