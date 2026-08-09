-- ---------------------------------------------------------------------------
-- emoji-pdf.lua — PDF-only emoji substitution.
--
-- The PDF build (xelatex + Latin Modern) has no emoji glyphs and DROPS them
-- SILENTLY: `selected === "🪨"` would print as `selected === ""` — wrong code
-- in the printed book. The HTML build renders emoji fine.
--
-- So for PDF output only, this filter replaces each known emoji with a plain
-- word, in prose (Str) and in code (Code, CodeBlock) alike. The substitution
-- is consistent across a chapter, so printed listings stay valid programs.
-- Chapters that rely on emoji add a PDF-only callout telling the reader that
-- the printed book shows words where the screen shows symbols (see
-- 0030-conditions/0070-rock-paper-scissors.qmd).
--
-- Same idea as the ▶ -> \blacktriangleright substitution in the shortcode
-- extensions (_extensions/*/*.lua), just for content instead of callout labels.
--
-- When a new chapter introduces a new emoji, add it to the table below —
-- longer sequences (emoji + variation selector U+FE0F) must come first so
-- they match before their shorter prefix does.
-- ---------------------------------------------------------------------------

if not quarto.doc.is_format("pdf") then
  return {}
end

local substitutions = {
  { "✂️", "scissors" },     -- U+2702 U+FE0F
  { "✂", "scissors" },      -- U+2702 without variation selector
  { "🪨", "rock" },          -- U+1FAA8
  { "📃", "paper" },         -- U+1F4C3
  { "\u{FE0F}", "" },        -- stray variation selector: invisible, drop it
}

local function substitute(text)
  local changed = false
  for _, pair in ipairs(substitutions) do
    local count
    text, count = text:gsub(pair[1], pair[2])
    if count > 0 then
      changed = true
    end
  end
  if changed then
    return text
  end
  return nil
end

return {
  {
    Str = function(el)
      local text = substitute(el.text)
      if text then
        return pandoc.Str(text)
      end
    end,
    Code = function(el)
      local text = substitute(el.text)
      if text then
        el.text = text
        return el
      end
    end,
    CodeBlock = function(el)
      local text = substitute(el.text)
      if text then
        el.text = text
        return el
      end
    end,
  },
}
