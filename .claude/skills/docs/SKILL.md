---
name: docs
description: Search and navigate documentation
argument-hint: 'search <query> | timeline [--days N] | related <path>'
---

# Documentation Search

Search .self/ documentation with full-text search, view timeline, and find related documents.

## Arguments

$ARGUMENTS

### Argument Parsing

```
Parse $ARGUMENTS:

1. Command (required):
   - "search <query>" → full-text search
   - "timeline" → chronological view
   - "related <path>" → find similar docs
   - "stats" → index statistics

2. Options:
   - "--scope <dir>" → limit search to directory
   - "--days <N>" → limit timeline to N days
   - "--channel <name>" → filter by channel
   - "--limit <N>" → max results
```

**Parse examples:**
```
"search channel inheritance"     → search for those terms
"search auth --scope domain"     → search only domain/
"timeline --days 7"              → last week's docs
"timeline --channel main"        → main channel timeline
"related domain/patterns.md"     → find similar docs
"stats"                          → show index stats
```

---

## Mode 1: Search

Full-text search across all documentation.

### Implementation

Use the Bash tool to run:

```bash
slf docs search "<query>" [--scope <dir>] [--limit <N>]
```

### Output

```markdown
**Found 5 matches:**

1. **domain/patterns.md:309**
   ```
   research-phase2 inherits [research-phase1, main]
   ```

2. **config/skills/channel/SKILL.md:16**
   ```
   **Channel inheritance**: Channels can inherit from others
   ```

[...more results]

**Usage tips:**
- Use `--scope channels` to search only channels
- Use `--scope domain` to search domain knowledge
- Add `--context 2` for surrounding lines
```

---

## Mode 2: Timeline

Show chronological view of documentation changes.

### Implementation

Use the Bash tool to run:

```bash
slf docs timeline [--days <N>] [--channel <name>] [--limit <N>]
```

### Output

```markdown
**Documentation Timeline** (last 7 days)

| Date       | Channel | Document                              |
|------------|---------|---------------------------------------|
| 2026-02-05 | main    | Reflexive Cache Pattern Complete      |
| 2026-02-03 | main    | Agent Context Refactor PR Merge       |
| 2026-02-02 | feature | Auth Implementation Session           |

**Filters applied:**
- Days: 7
- Channel: (all)
```

---

## Mode 3: Related Documents

Find documents related to a given document using term similarity.

### Implementation

Use the Bash tool to run:

```bash
slf docs related "<path-relative-to-.self/>" [--limit <N>]
```

### Output

```markdown
**Related to channels/main/2026-02-03_pattern.md:**

| Similarity | Document                   |
|------------|----------------------------|
| 85%        | domain/patterns.md         |
| 72%        | config/skills/channel/...  |
| 68%        | channels/main/2026-02-02.md|

**How to use:**
These documents share common terms and concepts. Check them for context or related decisions.
```

---

## Mode 4: Statistics

Show index statistics and health.

### Implementation

Use the Bash tool to run:

```bash
slf docs stats
```

### Output

```markdown
**Documentation Index Statistics**

- Total documents: 54
- Total lines: 10,981
- Total size: 320.7 KB
- Last indexed: 2026-02-05T12:18:38

**By directory:**
- config: 16 files
- channels: 11 files
- domain: 6 files
- prm: 5 files
- memory: 4 files

**Index is up to date**
```

---

## Auto-Indexing

The search engine automatically indexes docs on first use. You can also manually reindex:

```bash
slf docs index [--force]
```

Force reindex if you've made many changes.

---

## Integration with Other Skills

- Use `/docs search` to find past decisions before making new ones
- Use `/docs related` after `/save` to link related sessions
- Use `/docs timeline --channel <name>` to review channel history

---

## Examples

### Example 1: Research Before Deciding

```
User: "Should we use JWT or sessions for auth?"

Claude: Let me check past decisions.
[Runs /docs search "auth JWT session"]

Claude: "In .self/memory/decisions.md:42, we decided on JWT
with 15-min access tokens. Rationale was stateless auth for
microservices. Should we reuse this approach?"
```

### Example 2: Context for Code Review

```
User: "Review this PR"

Claude: Let me check related documentation.
[Runs /docs search "channel inheritance patterns"]

Claude: "This PR changes channel inheritance. According to
domain/patterns.md:309, we support multi-parent inheritance.
The code looks aligned with our pattern..."
```

### Example 3: Sprint Retrospective

```
User: "What did we accomplish this week?"

Claude:
[Runs /docs timeline --days 7]

Claude: "This week we:
- Completed auth refactor (2026-02-05)
- Merged API endpoints (2026-02-04)
- Documented pattern system (2026-02-03)

5 sessions, 3 major decisions, 12 new docs."
```

---

## Constraints

- Only searches markdown files in .self/
- Index stored in .self/.doc-search.db (SQLite)
- Similarity uses simple term frequency (not semantic embeddings)
- Auto-indexes on each search (fast for unchanged files)

---

## Error Handling

- **No results**: "No results found for: <query>"
- **Path not found**: "Document not found: <path>"
- **Invalid arguments**: Show usage hint

---

## Future Enhancements

- **Semantic search**: Add embeddings for better similarity
- **Web UI**: Browse docs in browser with pagefind
- **TUI browser**: Interactive terminal browser (requires textual)
- **Cross-repo search**: Search across multiple projects
