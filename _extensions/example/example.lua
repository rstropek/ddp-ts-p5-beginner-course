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

  In the PDF the callout carries two extra things a printed page needs: a QR
  code and the address in readable type. See the "print-friendly links" section
  below.
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

-- ── print-friendly links (PDF only) ─────────────────────────────────────────
--
-- On screen the callout's button is clickable, so nobody ever reads the address
-- behind it. On paper that button is dead: a printed handout leaves the reader
-- with nothing but the ink on the page. For PDF output the callout therefore
-- also carries a QR code (for a phone) and the full address in print (for a
-- keyboard).
--
-- The block below is shared with the other link extensions — the same code sits
-- in _extensions/example/example.lua, _extensions/quiz/quiz.lua, and
-- _extensions/tutor/tutor.lua. Change one, change the others. The LaTeX half
-- guards itself with \ifdefined, so it is harmless when several extensions add
-- it to the same document.

local PRINT_LINK_HEADER = [[
\ifdefined\ddplinkrow\else
  \usepackage{iftex}
  \usepackage{qrcode}   % draws QR codes in pure TeX — no external tool needed
  \usepackage{needspace} % keeps a compact link card away from a page boundary
  \newsavebox{\ddpqrbox}
  \newlength{\ddpqrsize}\setlength{\ddpqrsize}{3cm}
  % A monospace face for printed addresses. Inconsolata's zero is slashed, so a
  % reader cannot mistake 0 for O, and 1, l, and I stay apart too. Only this one
  % macro switches to it; code listings keep the book's usual typewriter font.
  \ifPDFTeX
    \newcommand{\ddpurlfont}{\fontencoding{T1}\fontfamily{zi4}\selectfont}
  \else
    \usepackage{fontspec}
    \newfontfamily{\ddpurlfont}{inconsolata}
  \fi
  % A long address has to wrap. The Lua side decides where: \allowbreak at the
  % places a reader can follow, \ddpurlbrk everywhere else, whose penalty makes
  % TeX break there only when nothing else fits. No hyphen is ever inserted, so
  % what stands on the page is exactly what you type.
  \newcommand{\ddpurlbrk}{\penalty700\relax}
  % One row inside the callout: QR code on the left, caption and address right.
  \newcommand{\ddplinkrow}[1]{%
    % \nopagebreak keeps the row with the call-to-action above it: a callout
    % that breaks between the two would leave an orphaned QR code on the next
    % page.
    \par\nopagebreak\smallskip\noindent
    \begin{minipage}[c]{\ddpqrsize}\usebox{\ddpqrbox}\end{minipage}%
    \hfill
    \begin{minipage}[c]{\dimexpr\linewidth-\ddpqrsize-1em\relax}%
      \raggedright\footnotesize
      Scan the code, or type this address into your browser:\par
      \smallskip
      {\ddpurlfont\small #1\par}%
    \end{minipage}%
    \par\smallskip}
\fi
]]

-- Characters that LaTeX would otherwise read as markup.
local LATEX_ESCAPE = {
  ["\\"] = "\\textbackslash{}", ["{"] = "\\{",  ["}"] = "\\}",
  ["$"]  = "\\$",               ["&"] = "\\&",  ["#"] = "\\#",
  ["%"]  = "\\%",               ["_"] = "\\_",
  ["~"]  = "\\textasciitilde{}", ["^"] = "\\textasciicircum{}",
}

-- Where a long address may wrap. A wrap must never change what the reader
-- types, which rules out the obvious choices:
--   * break AFTER "/", "?", "&" or "=" — a line ending in one of those is
--     plainly part of the address;
--   * break BEFORE "-", "." and friends — a line ending in a hyphen looks like
--     a hyphenation the printer added, and the reader drops it;
--   * never break inside "://", because a line ending in "https:/" reads as a
--     single slash.
-- Anywhere else a break is allowed but expensive (see \ddpurlbrk), so TeX takes
-- one only when nothing else fits. Such a break adds no character at all and so
-- cannot be misread.
local BREAK_AFTER = { ["/"] = true, ["?"] = true, ["&"] = true, ["="] = true }
local BREAK_BEFORE = {
  ["-"] = true, ["."] = true, ["_"] = true, ["~"] = true, [":"] = true,
  [","] = true, ["+"] = true, ["#"] = true, ["%"] = true,
}

-- Turn a URL into LaTeX that is safe to typeset and wraps at readable places.
local function typeset_url(url)
  local out, last = {}, #url
  for i = 1, last do
    local c, next_c = url:sub(i, i), url:sub(i + 1, i + 1)
    out[#out + 1] = LATEX_ESCAPE[c] or c
    if i == last or (c == "/" and next_c == "/") then
      -- nothing: the end of the address, or the middle of "://"
    elseif BREAK_AFTER[c] or BREAK_BEFORE[next_c] then
      out[#out + 1] = "\\allowbreak "
    else
      out[#out + 1] = "\\ddpurlbrk "
    end
  end
  return table.concat(out)
end

-- Add the LaTeX definitions above to the preamble, at most once per document.
local header_added = false
local function ensure_print_link_header()
  if not header_added then
    quarto.doc.include_text("in-header", PRINT_LINK_HEADER)
    header_added = true
  end
end

-- The QR code plus the printed address, as a block for the callout's body.
-- Returns nil for every format other than PDF: on the web the button already
-- takes the reader there, and a printed address would only add clutter.
--
-- `level` is the QR error-correction level: "L" holds the most data (use it for
-- long addresses), "M" survives more smudges (fine for short ones).
--
-- \qrcode reads its argument verbatim, so the raw URL is written straight into
-- the LaTeX — it must not be escaped. Building it inside an \lrbox keeps that
-- verbatim reading intact and lets \ddplinkrow place the finished box.
local function print_link_block(url, level)
  if not quarto.doc.is_format("pdf") then return nil end
  ensure_print_link_header()
  return pandoc.RawBlock("latex", table.concat({
    "\\begin{lrbox}{\\ddpqrbox}\\qrcode*[height=\\ddpqrsize,level=", level, "]{",
    url, "}\\end{lrbox}\n",
    "\\ddplinkrow{", typeset_url(url), "}",
  }))
end

-- Quarto renders callouts as breakable tcolorboxes in PDF output. A compact
-- QR card that lands exactly at the bottom of a page can leave XeLaTeX's color
-- state unbalanced after the page break, which makes later body text invisible.
-- Reserve a little more room than the tallest link card needs so the complete
-- card moves to the next page instead of touching or crossing the boundary.
local function keep_print_card_together(callout)
  if quarto.doc.is_format("pdf") then
    return pandoc.Blocks({
      pandoc.RawBlock("latex", "\\Needspace{5.5cm}"),
      callout,
    })
  end
  return callout
end

-- The label of a callout's call-to-action link. The ▶ character has no glyph in
-- the PDF's text font and would silently vanish there, so the PDF gets LaTeX's
-- own triangle instead.
local function cta_label(text)
  if quarto.doc.is_format("pdf") then
    return { pandoc.RawInline("latex", "$\\blacktriangleright$~"), pandoc.Str(text) }
  end
  return { pandoc.Str("▶ " .. text) }
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

  local url = playground_url(base, given)

  -- The call-to-action link, wrapped in a Div we can target from CSS to render
  -- it as a button (HTML only — the PDF shows it as a normal callout link).
  local cta = pandoc.Div(
    pandoc.Para(pandoc.Link(
      cta_label("Open in the playground"),
      url
    )),
    pandoc.Attr("", { "playground-cta" })
  )

  -- In print the button is dead, so the PDF also gets a QR code and the address
  -- in readable type. A playground address carries the exercise's own URL as a
  -- query parameter and so runs long: level "L" keeps the code's squares big
  -- enough for a phone camera.
  local content = { cta }
  content[#content + 1] = print_link_block(url, "L")

  -- quarto.Callout emits Quarto's native callout node, so it renders as a
  -- titled, bordered card in BOTH HTML and PDF. (Emitting a raw callout-classed
  -- Div does NOT work from a shortcode: the callout filter has already run by
  -- the time a shortcode expands.) `collapse` is left unset so the card is a
  -- plain, non-collapsible box like the tips elsewhere in the book.
  return keep_print_card_together(quarto.Callout({
    type = "tip",
    title = "Exercise: " .. title,
    content = content,
  }))
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
