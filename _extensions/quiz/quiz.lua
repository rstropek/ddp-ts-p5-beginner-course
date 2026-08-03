--[[
  quiz.lua — Quarto *shortcode* for linking to a chapter quiz on novedu.

  Usage in a chapter:

      {{< quiz <code> [title="..."] >}}

  Renders a compact callout (like a Quarto `callout-note`) that invites the
  reader to take the chapter's quiz in the novedu chat app. The book does NOT
  reproduce the quiz's questions — they live in a YAML activity file hosted on
  the novedu server; duplicating them here would only go stale.

  <code> is the activity code a teacher minted for the quiz (for example with
  `novedu-cli codes create --module quiz --file <url>`). The shortcode builds
  the student-facing URL as

        <base>/<code>

  where <base> is read from the `novedu-base-url` metadata key (set once in
  _quarto.yml). The shortcode fetches nothing at render time, so the book
  renders offline and never breaks on a server change.

  This mirrors the `example` extension (see _extensions/example/example.lua),
  which explains the shortcode mechanics in detail. Like there, we emit a
  quarto.Callout so the card renders in BOTH the HTML site and the PDF.
--]]

local script_dir = PANDOC_SCRIPT_FILE:gsub("[^/\\]+$", "")

-- Add the extension's CSS to HTML output exactly once per document.
local css_added = false
local function ensure_css()
  if not css_added and quarto.doc.is_format("html") then
    quarto.doc.add_html_dependency({
      name = "quarto-quiz",
      version = "1.0.0",
      stylesheets = { script_dir .. "quiz.css" },
    })
    css_added = true
  end
end

-- Read the configurable novedu base URL from document metadata
-- (`novedu-base-url` in _quarto.yml). Returns nil when unset/empty so callers
-- can degrade gracefully. Trailing slashes are trimmed so we can safely
-- append "/<code>".
local function novedu_base(meta)
  local v = meta and meta["novedu-base-url"]
  if not v then return nil end
  local s = pandoc.utils.stringify(v)
  if s == "" then return nil end
  return (s:gsub("/+$", ""))
end

local function quiz(args, kwargs, meta)
  if not args[1] then
    return pandoc.Para(pandoc.Strong("[quiz: no activity code given]"))
  end
  local code = pandoc.utils.stringify(args[1])

  local base = novedu_base(meta)
  if not base then
    return pandoc.Para(pandoc.Strong("[quiz: novedu-base-url not set]"))
  end

  ensure_css()

  -- Unlike an exercise file name, an activity code (e.g. "zphawn6k0r") carries
  -- no readable name, so there is nothing to derive a title from; authors pass
  -- `title=` for a chapter-specific heading.
  local title = kwargs["title"] and pandoc.utils.stringify(kwargs["title"]) or ""
  if title == "" then title = "Check your understanding" end

  local cta = pandoc.Div(
    pandoc.Para(pandoc.Link(
      pandoc.Str("▶ Take the quiz on novedu.at"),
      base .. "/" .. code
    )),
    pandoc.Attr("", { "quiz-cta" })
  )

  return quarto.Callout({
    type = "note",
    title = "Quiz: " .. title,
    content = { cta },
  })
end

return { ["quiz"] = quiz }
