--[[
  tutor.lua — Quarto *shortcode* for linking to a part's AI tutor on novedu.

  Usage in a chapter (inside its opening "AI tutor" section):

      {{< tutor <key> [title="..."] >}}

  Renders a compact callout (like a Quarto `callout-tip`) that invites the
  reader to open the AI tutor for the current book part in the novedu chat
  app. Every chapter opens with an `## AI tutor` section: prose that says what
  the situation in that chapter is, then this box. The box's body text is fixed
  here, in one place, because the standing rules of a tutor are the same in
  every chapter — editing this file updates them all. The tutor's behavior
  itself lives in a YAML activity file (e.g.
  0010-introduction/introduction-tutor.yaml); the book only links to it.

  <key> is the tutor's key in the activity registry, `ddp-activities.yaml`
  (e.g. `tutor-introduction`), NOT an activity code. The generated lock file
  ddp-activities.lock.yaml maps every key to the code novedu minted for it and
  is merged into the document metadata as `activity-codes` (metadata-files in
  _quarto.yml), so the shortcode resolves

        <base>/<activity-codes[key]>

  where <base> is read from the `novedu-base-url` metadata key (set once in
  _quarto.yml). The shortcode fetches nothing at render time, so the book
  renders offline and never breaks on a server change.

  Adding a tutor therefore means: add one entry to ddp-activities.yaml, run
  `novedu-cli codes sync ddp-activities.yaml`, commit registry + lock file, and
  reference the key here. A key with no entry in the lock file is a hard render
  error, never a dead link.

  This mirrors the `quiz` extension (see _extensions/quiz/quiz.lua), which in
  turn mirrors the `example` extension. Like there, we emit a quarto.Callout so
  the card renders in BOTH the HTML site and the PDF.
--]]

local script_dir = PANDOC_SCRIPT_FILE:gsub("[^/\\]+$", "")

-- Add the extension's CSS to HTML output exactly once per document.
local css_added = false
local function ensure_css()
  if not css_added and quarto.doc.is_format("html") then
    quarto.doc.add_html_dependency({
      name = "quarto-tutor",
      version = "1.0.0",
      stylesheets = { script_dir .. "tutor.css" },
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

-- Resolve a registry key to the activity code novedu minted for it, using the
-- `activity-codes` map that ddp-activities.lock.yaml contributes to the document
-- metadata (metadata-files in _quarto.yml).
--
-- An unresolvable key ABORTS the render instead of rendering a marker: the whole
-- point of keys is that a chapter can never link to a code that is not there, and
-- a bold marker in a 200-page PDF is easy to miss. `error(msg, 0)` drops the Lua
-- position prefix so the reader sees just the instruction.
local function activity_code(meta, key)
  local map = meta and meta["activity-codes"]
  if not map then
    error(
      "tutor shortcode: no `activity-codes` metadata. Check that _quarto.yml lists "
        .. "ddp-activities.lock.yaml under metadata-files, and that the file exists "
        .. "(regenerate it with: novedu-cli codes sync ddp-activities.yaml).",
      0
    )
  end
  local entry = map[key]
  if not entry then
    error(
      "tutor shortcode: unknown activity key '" .. key .. "'. Add it to "
        .. "ddp-activities.yaml, run `novedu-cli codes sync ddp-activities.yaml`, "
        .. "and commit the regenerated ddp-activities.lock.yaml.",
      0
    )
  end
  return pandoc.utils.stringify(entry)
end

-- The one line every tutor box carries. Each chapter opens with an "AI tutor"
-- section whose prose says what the situation in that chapter is, so this text
-- only states the standing rules of a tutor, the ones that hold in every
-- chapter. It is defined once here rather than in 20+ .qmd files. An
-- exercise-AI box overrides it with `text=` (and usually `cta=`), because those
-- boxes link a code generator, not a tutor.
local BODY_TEXT = "Hints and questions instead of finished programs, "
  .. "in English or German."
local CTA_TEXT = "Ask your AI tutor on novedu.at"

local function tutor(args, kwargs, meta)
  if not args[1] then
    return pandoc.Para(pandoc.Strong("[tutor: no activity key given]"))
  end
  local key = pandoc.utils.stringify(args[1])

  local base = novedu_base(meta)
  if not base then
    return pandoc.Para(pandoc.Strong("[tutor: novedu-base-url not set]"))
  end

  local code = activity_code(meta, key)

  ensure_css()

  local title = kwargs["title"] and pandoc.utils.stringify(kwargs["title"]) or ""
  if title == "" then title = "Your AI tutor" end

  -- `text=` swaps the body text (an exercise-AI box describes a code
  -- generator, not a tutor); `text=""` is treated as "use the default", so
  -- there is always a body. `cta=` swaps the button label the same way.
  local body = kwargs["text"] and pandoc.utils.stringify(kwargs["text"]) or ""
  if body == "" then body = BODY_TEXT end
  local cta_text = kwargs["cta"] and pandoc.utils.stringify(kwargs["cta"]) or ""
  if cta_text == "" then cta_text = CTA_TEXT end

  local url = base .. "/" .. code

  local cta = pandoc.Div(
    pandoc.Para(pandoc.Link(
      cta_label(cta_text),
      url
    )),
    pandoc.Attr("", { "tutor-cta" })
  )

  -- In print the button is dead, so the PDF also gets a QR code and the address
  -- in readable type. A tutor address is short (base plus a ten-character code),
  -- so level "M" costs no room and survives a smudged printout.
  local content = { pandoc.Para(pandoc.Str(body)), cta }
  content[#content + 1] = print_link_block(url, "M")

  return keep_print_card_together(quarto.Callout({
    type = "tip",
    title = title,
    content = content,
  }))
end

return { ["tutor"] = tutor }
