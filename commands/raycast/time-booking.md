Use [raycast-notes](raycast-notes) and [notion](notion) to run the workflow below. Perform the work now. Do not only describe what you would do.

## Goal

Transfer completed todos from the Raycast Notes "Kochan" and "Agency" to the Notion database "📥 Zeiten".

Use only this Notion database and data source:

- Database ID: `245ea8ba-093f-4e0c-883b-63be00fe343d`
- Data source ID: `5b97cc2d-8352-415d-8c79-032ef8942a6a`

Access the database directly with these IDs. Do not search for another database. Do not stop if a search for "Zeiten" returns no results.

## Read the Raycast Notes

Use [raycast-notes](raycast-notes) to find these two notes:

- The note whose title is exactly "Kochan" or ends with "Kochan"
- The note whose title is exactly "Agency" or ends with "Agency"

Their titles may contain prefixes, emojis, or separators. Examples include:

- `💻 | Kochan`
- `🪴 | Agency`

Read both notes in full with Read Note.

## Process completed todos only

Process only todos whose completed status in [raycast-notes](raycast-notes) is `true`, meaning the checkbox is checked.

These forms count as completed:

```text
[x] Task
[X] Task
- [x] Task
- [X] Task
* [x] Task
* [X] Task
```

Never process open todos such as:

```text
[ ] Task
[] Task
- [ ] Task
- [] Task
* [ ] Task
* [] Task
```

Ignore regular text, headings, links, and all other content.

## Preserve todo hierarchy in the title

When a completed todo is nested below another todo, prepend the titles of all its ancestor todos. Join each level with ` – `.

Use this format:

```text
Parent – Child
Parent – Child – Grandchild
```

An ancestor does not need to be completed to provide context. Import only the completed todo itself.

For example:

```text
[ ] pushdraft
    [x] Image upload
    [ ] System für Agenten Verhalten
    [x] data upload
```

Create these titles:

```text
pushdraft – Image upload
pushdraft – data upload
```

Remove checkbox markers, list markers, and excess whitespace from every title component.

## Create the Notion entries

Create exactly one entry for each completed todo in the database with ID `245ea8ba-093f-4e0c-883b-63be00fe343d` and data source ID `5b97cc2d-8352-415d-8c79-032ef8942a6a`.

Set only these four properties:

- `Titel`: the cleaned todo title, including its complete ancestor hierarchy
- `Datum`: today's date in the `Europe/Berlin` time zone
- `Typ`: `Task > Kochan` for the Kochan note, or `Task > Agency` for the Agency note
- `Quelle`: `API`

Use these values with the exact spelling and capitalization shown above.

Do not set or change any other properties, including:

- `Dauer (Min)`
- `Verbucht`
- `Externe ID`
- `Details`
- `Buchungstitel`
- `Dauer (Std)`
- `Projekt`
- `Generiert`
- `Abrechenbar`
- `Kommentar`
- `Erstellt am`

## Prevent duplicates

Before creating an entry, check whether the database already contains an entry with exactly the same values for all three of these properties:

- `Titel`
- `Typ`
- `Quelle`

Do not include `Datum` in the duplicate check.

If an identical entry already exists:

- Do not create another entry.
- Count the todo as a duplicate and as successfully processed.
- Try to remove it from its original Raycast Note.

## Remove processed todos from Raycast

Remove a completed todo only after one of these conditions is confirmed:

- Its Notion entry was created successfully.
- An identical Notion entry already existed.

Remove only the processed todo's own line. Follow all of these rules:

- Never remove an open todo.
- Never remove regular text or headings.
- For a nested todo, remove only its own line.
- Keep an incomplete ancestor todo.
- Preserve the order, formatting, and all remaining content in the note.
- If the Notion operation fails, do not remove the todo.
- If [raycast-notes](raycast-notes) does not offer a confirmed edit, update, or delete operation, do not remove anything.
- Never claim that a todo was removed unless the removal succeeded and the tool confirmed it.

## Final report

After processing both notes, report:

- The Kochan note that was found
- The Agency note that was found
- The database ID used
- Number of completed todos found
- Number of new Notion entries created
- Number of duplicates found
- Number of failed entries
- Number of todos removed from Raycast
- Every todo that was not removed, with the reason it remained
