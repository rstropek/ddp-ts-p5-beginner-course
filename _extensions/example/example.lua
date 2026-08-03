--[[
  example.lua — Quarto *shortcodes* for linking to the TypeScript playground.

  This extension contributes two shortcodes:

    {{< example <exercise-yaml-url> >}}
        Renders a compact callout (like a Quarto `callout-tip`) that invites the
        reader to open the exercise in the web playground. The book does NOT
        reproduce the exercise's description, starter code, or sample solution —
        that content lives in the playground; duplicating it here would only go
        stale. The callout title is derived from the exercise file name (e.g.
        `olympic_rings.yaml` -> "Olympic Rings"); pass `title=` to override it.

    {{< playground <exercise-yaml-url> [text="..."] >}}
        An inline link into the playground, for use in prose.

  Both build the playground URL as

        <base>/playground?exerciseUrl=<exercise-yaml-url>

  where <base> is read from the `playground-base-url` metadata key (set once in
  _quarto.yml). The server's FQDN may change — editing that one line updates
  every link. Neither shortcode fetches anything at render time, so the book
  renders offline and never breaks on a change to a remote exercise file.

  How a shortcode works: Quarto loads this file (because _extension.yml lists it
  under contributes.shortcodes) and calls the registered function with
  (args, kwargs, meta) whenever it meets the tag. The function returns Pandoc
  elements, which Quarto renders to whatever the target format is. Emitting a Div
  with a `callout-tip` class reuses Quarto's own callout machinery, so we get a
  titled, bordered card for free in BOTH the HTML site and the PDF handout.
--]]

local script_dir = PANDOC_SCRIPT_FILE:gsub("[^/\\]+$", "")

-- Add the extension's CSS to HTML output exactly once per document.
local css_added = false
local function ensure_css()
  if not css_added and quarto.doc.is_format("html") then
    quarto.doc.add_html_dependency({
      name = "quarto-example",
      version = "1.0.0",
      stylesheets = { script_dir .. "example.css" },
    })
    css_added = true
  end
end

-- ── helpers ────────────────────────────────────────────────────────────────

-- Read the configurable playground base URL from document metadata
-- (`playground-base-url` in _quarto.yml). Returns nil when unset/empty so
-- callers can degrade gracefully. Trailing slashes are trimmed so we can safely
-- append "/playground?...".
local function playground_base(meta)
  local v = meta and meta["playground-base-url"]
  if not v then return nil end
  local s = pandoc.utils.stringify(v)
  if s == "" then return nil end
  return (s:gsub("/+$", ""))
end

-- Build the "open this exercise in the playground" URL, e.g.
--   <base>/playground?exerciseUrl=<raw yaml url>. The exercise URL is appended
-- as-is (matching how the playground server expects it).
local function playground_url(base, exercise_url)
  return base .. "/playground?exerciseUrl=" .. exercise_url
end

-- Derive a human-readable exercise name from its file reference, e.g.
--   ".../olympic_rings.yaml"      -> "Olympic Rings"
--   ".../soccer-field-basics.yaml"-> "Soccer Field Basics"
-- Used as the callout title unless the author passes an explicit `title=`.
local function derive_title(ref)
  local name = ref:gsub("[?#].*$", "")     -- drop any query/fragment
  name = name:gsub("/+$", "")              -- drop trailing slashes
  name = name:match("([^/]+)$") or name    -- keep the last path segment
  name = name:gsub("%.%w+$", "")           -- drop the extension
  name = name:gsub("[-_]+", " ")           -- separators -> spaces
  name = name:gsub("^%s*(.-)%s*$", "%1")   -- trim
  name = name:gsub("(%a)([%w']*)", function(first, rest) -- Title Case
    return first:upper() .. rest:lower()
  end)
  if name == "" then return "Exercise" end
  return name
end

-- ── the `example` shortcode ─────────────────────────────────────────────────

local function example(args, kwargs, meta)
  if not args[1] then
    return pandoc.Para(pandoc.Strong("[example: no exercise url given]"))
  end
  local given = pandoc.utils.stringify(args[1])

  local base = playground_base(meta)
  if not base then
    return pandoc.Para(pandoc.Strong("[example: playground-base-url not set]"))
  end

  ensure_css()

  local title = kwargs["title"] and pandoc.utils.stringify(kwargs["title"]) or ""
  if title == "" then title = derive_title(given) end

  -- The call-to-action link, wrapped in a Div we can target from CSS to render
  -- it as a button (HTML only — the PDF shows it as a normal callout link).
  local cta = pandoc.Div(
    pandoc.Para(pandoc.Link(
      pandoc.Str("▶ Open in the playground"),
      playground_url(base, given)
    )),
    pandoc.Attr("", { "playground-cta" })
  )

  -- quarto.Callout emits Quarto's native callout node, so it renders as a
  -- titled, bordered card in BOTH HTML and PDF. (Emitting a raw callout-classed
  -- Div does NOT work from a shortcode: the callout filter has already run by
  -- the time a shortcode expands.) `collapse` is left unset so the card is a
  -- plain, non-collapsible box like the tips elsewhere in the book.
  return quarto.Callout({
    type = "tip",
    title = "Exercise: " .. title,
    content = { cta },
  })
end

-- ── the `playground` shortcode ──────────────────────────────────────────────
--
-- An inline link into the playground for a single exercise, for use in prose:
--
--     Try it yourself in {{< playground .../shapes.yaml text="the Shapes exercise" >}}.
--
-- The first argument is the exercise's YAML URL; `text=` overrides the link
-- label (default: "the playground").
local function playground(args, kwargs, meta)
  if not args[1] then
    return pandoc.Strong("[playground: no exercise url given]")
  end
  local exercise_url = pandoc.utils.stringify(args[1])

  local base = playground_base(meta)
  if not base then
    return pandoc.Strong("[playground: playground-base-url not set]")
  end

  local label = kwargs["text"] and pandoc.utils.stringify(kwargs["text"]) or ""
  if label == "" then label = "the playground" end

  return pandoc.Link(pandoc.Str(label), playground_url(base, exercise_url))
end

return { ["example"] = example, ["playground"] = playground }
