---
name: pushdraft
description: Deliver a finished write-up as a shareable HTML document. Use for a report, analysis, summary, findings, spec, plan, comparison, ranking, or set of UI mocks, including when the request is mostly a research job and "HTML" is only one word in it, and whenever the user mentions "HTML" with no additional context. This is the delivery path, not a chart library, so it still applies when dataviz shapes the charts inside the document. Not for HTML that ships as part of a product.
metadata:
    harness: [claude, codex]
    platform: [darwin, linux]
    requires: "npx (pushdraft is run via npx)"
---

# HTML Communication

## When to Use

Use this skill when the user wants a plan, spec, write-up, findings, summary,
report, comparison, ranking, or set of UI mocks presented as readable HTML. It
applies when the HTML is only how the result gets delivered, so a long research
or analysis prompt that ends in "as an HTML report" belongs here too.

`dataviz` does not replace this skill. It decides how a chart looks, this skill
decides what the document is and where it goes. A report with charts needs both.

Do not use it for HTML that ships as part of a product.

## Document

Create one self-contained HTML file, capped at 512 KB.

-  Write it like a spec, not a landing page: dense, scannable, no hero,
  decorative chrome, marketing voice, or em dashes.
-  Default to true black (`#000`), white primary text, and dark gray only for
  secondary surfaces or accents.
-  Make it mobile-readable with a responsive viewport and no fixed-width layout.
-  Use semantic HTML, inline CSS, inline SVG, and HTTPS or data-URL images.
-  Build every heading, number, table, and chart into the markup before upload.
  Never generate content at runtime. The viewer ran no inline script at all on
  2026-09-12, and a report that drew itself in JavaScript arrived blank.
-  Use an inline classic script only to improve a page that already reads
  correctly without it. The sandbox blocks storage, fetch, workers, frames,
  forms, and popups.
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
