-- footnote-styles.lua
-- Quarto extension to change footnote numbering systems

local footnotes = {}
local counter = 0
local style = "numeric"
local cycle_mode = "repeat"
local symbol_set = nil
local separator = ""
local start_at = 1

-- Default symbol sets for predefined styles
local SYMBOLS = { "*", "\u{2020}", "\u{2021}", "\u{00A7}", "\u{00B6}" }
-- *, †, ‡, §, ¶

-- Convert integer to Roman numerals
local function to_roman(n)
  local numerals = {
    { 1000, "m" }, { 900, "cm" }, { 500, "d" }, { 400, "cd" },
    { 100, "c" }, { 90, "xc" }, { 50, "l" }, { 40, "xl" },
    { 10, "x" }, { 9, "ix" }, { 5, "v" }, { 4, "iv" }, { 1, "i" }
  }
  local result = ""
  for _, pair in ipairs(numerals) do
    while n >= pair[1] do
      result = result .. pair[2]
      n = n - pair[1]
    end
  end
  return result
end

-- Convert integer to Excel-style alphabetic (1=a, 26=z, 27=aa, 28=ab, ...)
local function to_alpha(n)
  local result = ""
  while n > 0 do
    n = n - 1
    result = string.char(97 + (n % 26)) .. result
    n = math.floor(n / 26)
  end
  return result
end

-- Generate the display symbol for footnote number n
local function get_symbol(n)
  if style == "numeric" then
    return tostring(n)
  elseif style == "numeric-02" then
    return string.format("%02d", n)
  elseif style == "numeric-03" then
    return string.format("%03d", n)
  elseif style == "alpha-lower" then
    return to_alpha(n)
  elseif style == "alpha-upper" then
    return string.upper(to_alpha(n))
  elseif style == "roman-lower" then
    return to_roman(n)
  elseif style == "roman-upper" then
    return string.upper(to_roman(n))
  elseif style == "asterisk" then
    return string.rep("*", n)
  elseif style == "symbols" or style == "custom" then
    local symbols = symbol_set or SYMBOLS
    if cycle_mode == "restart" then
      local idx = ((n - 1) % #symbols) + 1
      return symbols[idx]
    else
      -- repeat mode: cycle through symbols, doubling up each round
      local round = math.floor((n - 1) / #symbols) + 1
      local idx = ((n - 1) % #symbols) + 1
      return string.rep(symbols[idx], round)
    end
  else
    return tostring(n)
  end
end

-- HTML-escape a string
local function html_escape(s)
  s = s:gsub("&", "&amp;")
  s = s:gsub("<", "&lt;")
  s = s:gsub(">", "&gt;")
  s = s:gsub('"', "&quot;")
  return s
end

-- CSS-escape a string for use in content: "..."
local function css_escape(s)
  s = s:gsub("\\", "\\\\")
  s = s:gsub('"', '\\"')
  return s
end

-- Read extension configuration from document metadata
local function read_config(meta)
  local ext_config = nil

  -- Check extensions.footnote-styles namespace
  if meta.extensions then
    ext_config = meta.extensions["footnote-styles"]
  end

  if not ext_config then
    return false
  end

  -- Read style
  if ext_config.style then
    style = pandoc.utils.stringify(ext_config.style)
  end

  -- Read cycle mode
  if ext_config.cycle then
    cycle_mode = pandoc.utils.stringify(ext_config.cycle)
  end

  -- Read separator (HTML only)
  if ext_config.separator then
    separator = pandoc.utils.stringify(ext_config.separator)
  end

  -- Read start-at
  if ext_config["start-at"] then
    local v = tonumber(pandoc.utils.stringify(ext_config["start-at"]))
    if v then start_at = math.max(1, math.floor(v)) end
  end

  -- Read custom symbols (overrides style)
  if ext_config.custom then
    symbol_set = {}
    for _, v in ipairs(ext_config.custom) do
      table.insert(symbol_set, pandoc.utils.stringify(v))
    end
    style = "custom"
  end

  return true
end

------------------------------------------------------------------------
-- HTML
------------------------------------------------------------------------

local function inject_html_css()
  local sep_css = '""'
  if separator ~= "" then
    sep_css = '"' .. css_escape(separator) .. '"'
  end

  -- Use CSS Grid on <ol> with display:contents on <li> so that all
  -- ::before markers share a single auto-sized column—the grid
  -- automatically sizes to the widest marker, no width calc needed.
  local css = string.format([[
.footnotes ol {
  display: grid;
  grid-template-columns: auto 1fr;
  column-gap: 0.4em;
  padding-left: 0;
  list-style-type: none;
}
.footnotes li {
  display: contents;
}
.footnotes li::before {
  content: attr(data-marker) %s;
  text-align: right;
  white-space: pre;
}
.footnotes li > div > p:first-child,
.tippy-content > div > p:first-child {
  margin-top: 0;
}
.footnotes li > div > p:last-child,
.tippy-content > div > p:last-child {
  margin-bottom: 0;
}
]], sep_css)

  quarto.doc.include_text("in-header", "<style>" .. css .. "</style>")
end

local function html_filters()
  return {
    {
      Meta = function(meta)
        local has_config = read_config(meta)
        if not has_config then
          style = nil
        elseif style == "numeric" and start_at == 1 then
          style = nil
        end
        return meta
      end
    },
    {
      Note = function(el)
        if style == nil then
          return el
        end

        counter = counter + 1
        local n = counter + start_at - 1
        local sym = get_symbol(n)
        local escaped_sym = html_escape(sym)

        table.insert(footnotes, {
          n = n,
          symbol = sym,
          content = el.content
        })

        local ref_html = string.format(
          '<a href="#fn%d" class="footnote-ref" id="fnref%d" role="doc-noteref"><sup>%s</sup></a>',
          n, n, escaped_sym
        )
        return pandoc.RawInline('html', ref_html)
      end
    },
    {
      Pandoc = function(doc)
        if style == nil or #footnotes == 0 then
          return doc
        end

        inject_html_css()

        local parts = {}
        table.insert(parts, '<section id="footnotes" class="footnotes footnotes-end-of-document" role="doc-endnotes">')
        table.insert(parts, '<hr />')
        table.insert(parts, '<ol>')

        for _, fn in ipairs(footnotes) do
          local escaped_sym = html_escape(fn.symbol)
          local body_html = pandoc.write(pandoc.Pandoc(fn.content), 'html')

          local backlink = string.format(
            ' <a href="#fnref%d" class="footnote-back" role="doc-backlink">\u{21A9}\u{FE0E}</a>',
            fn.n
          )

          local last_p_end = body_html:match(".*()</p>")
          if last_p_end then
            body_html = body_html:sub(1, last_p_end - 1) .. backlink .. body_html:sub(last_p_end)
          else
            body_html = body_html .. backlink
          end

          table.insert(parts, string.format(
            '<li id="fn%d" data-marker="%s"><div>%s</div></li>',
            fn.n, escaped_sym, body_html
          ))
        end

        table.insert(parts, '</ol>')
        table.insert(parts, '</section>')

        local section_html = table.concat(parts, '\n')
        table.insert(doc.blocks, pandoc.RawBlock('html', section_html))

        return doc
      end
    }
  }
end

------------------------------------------------------------------------
-- LaTeX / PDF
------------------------------------------------------------------------

-- Escape a string for use inside a LaTeX command definition
local function latex_escape(s)
  -- For symbols used in \ifcase, most Unicode chars work with xelatex/lualatex
  -- Only need to escape TeX-special chars that could appear in custom symbols
  s = s:gsub("\\", "\\textbackslash{}")
  s = s:gsub("#", "\\#")
  s = s:gsub("%%", "\\%%")
  s = s:gsub("{", "\\{")
  s = s:gsub("}", "\\}")
  s = s:gsub("~", "\\textasciitilde{}")
  s = s:gsub("%^", "\\textasciicircum{}")
  return s
end

local function generate_latex_preamble()
  -- Simple styles that map directly to LaTeX counter formats
  if style == "alpha-lower" then
    return "\\renewcommand{\\thefootnote}{\\alph{footnote}}"
  elseif style == "alpha-upper" then
    return "\\renewcommand{\\thefootnote}{\\Alph{footnote}}"
  elseif style == "roman-lower" then
    return "\\renewcommand{\\thefootnote}{\\roman{footnote}}"
  elseif style == "roman-upper" then
    return "\\renewcommand{\\thefootnote}{\\Roman{footnote}}"

  -- Zero-padded numerics
  elseif style == "numeric-02" then
    return [[
\makeatletter
\renewcommand{\thefootnote}{\two@digits{\value{footnote}}}
\makeatother]]

  elseif style == "numeric-03" then
    return [[
\makeatletter
\newcommand{\@fnthreedigits}[1]{\ifnum#1<100 0\fi\two@digits{#1}}
\renewcommand{\thefootnote}{\@fnthreedigits{\value{footnote}}}
\makeatother]]

  -- Styles that need a generated \ifcase lookup
  elseif style == "symbols" or style == "custom" or style == "asterisk" then
    -- Generate \ifcase entries using get_symbol()—reuses the same
    -- cycling logic as HTML so output is consistent across formats
    local max_n = 50
    local entries = {}
    for n = 1, max_n do
      table.insert(entries, "  \\or " .. latex_escape(get_symbol(n)))
    end
    return string.format([[
\makeatletter
\newcommand{\@fnscustomsymbol}[1]{%%
  \ifcase\value{#1}%%
%s%%
  \else ?\fi
}
\renewcommand{\thefootnote}{\@fnscustomsymbol{footnote}}
\makeatother]], table.concat(entries, "%%\n"))
  end

  return nil
end

local function latex_filters()
  return {
    {
      Meta = function(meta)
        local has_config = read_config(meta)
        if not has_config then return meta end

        local parts = {}
        if style ~= "numeric" then
          local preamble = generate_latex_preamble()
          if preamble then table.insert(parts, preamble) end
        end
        if #parts > 0 then
          quarto.doc.include_text("in-header", table.concat(parts, "\n"))
        end
        if start_at > 1 then
          quarto.doc.include_text("before-body",
            string.format("\\setcounter{footnote}{%d}", start_at - 1))
        end
        return meta
      end
    }
  }
end

------------------------------------------------------------------------
-- Typst
------------------------------------------------------------------------

local function generate_typst_preamble()
  local offset = start_at - 1
  -- sep is concatenated directly, never passed through string.format,
  -- so the literal % in "40%" is safe
  local sep = '\n#set footnote.entry(separator: line(length: 40%, stroke: 0.5pt))'

  -- Simple letter/roman styles: use built-in pattern or numbering() with offset
  local simple = {
    ["alpha-lower"] = "a", ["alpha-upper"] = "A",
    ["roman-lower"] = "i", ["roman-upper"] = "I",
  }
  if simple[style] then
    local pat = simple[style]
    if offset == 0 then
      return '#set footnote(numbering: "' .. pat .. '")' .. sep
    else
      return string.format(
        '#set footnote(numbering: n => numbering("%s", n + %d))', pat, offset
      ) .. sep
    end

  -- Numeric with offset only
  elseif style == "numeric" then
    if offset == 0 then return nil end
    return string.format(
      '#set footnote(numbering: n => str(n + %d))', offset
    ) .. sep

  -- Zero-padded numerics
  elseif style == "numeric-02" then
    return string.format([[
#set footnote(numbering: n => {
  let s = str(n + %d)
  if s.len() < 2 { "0" + s } else { s }
})]], offset) .. sep

  elseif style == "numeric-03" then
    return string.format([[
#set footnote(numbering: n => {
  let s = str(n + %d)
  while s.len() < 3 { s = "0" + s }
  s
})]], offset) .. sep

  -- Asterisk
  elseif style == "asterisk" then
    if offset == 0 then
      return '#set footnote(numbering: n => "*" * n)' .. sep
    else
      return string.format(
        '#set footnote(numbering: n => "*" * (n + %d))', offset
      ) .. sep
    end

  -- Symbols/custom
  elseif style == "symbols" or style == "custom" then
    -- Use Typst's built-in "*" only when everything matches its behaviour exactly
    if style == "symbols" and cycle_mode == "repeat" and symbol_set == nil and offset == 0 then
      return '#set footnote(numbering: "*")' .. sep
    end

    local symbols = symbol_set or SYMBOLS
    local sym_strs = {}
    for _, s in ipairs(symbols) do
      table.insert(sym_strs, '"' .. s .. '"')
    end
    local sym_array = "(" .. table.concat(sym_strs, ", ") .. ")"

    if cycle_mode == "restart" then
      return string.format([[
#set footnote(numbering: n => {
  let syms = %s
  let n = n + %d
  syms.at(calc.rem(n - 1, syms.len()))
})]], sym_array, offset) .. sep
    else
      return string.format([[
#set footnote(numbering: n => {
  let syms = %s
  let n = n + %d
  let idx = calc.rem(n - 1, syms.len())
  let rnd = int((n - 1) / syms.len()) + 1
  syms.at(idx) * rnd
})]], sym_array, offset) .. sep
    end
  end

  return nil
end

local function typst_filters()
  return {
    {
      Meta = function(meta)
        local has_config = read_config(meta)
        if not has_config then return meta end
        if style == "numeric" and start_at == 1 then return meta end

        local preamble = generate_typst_preamble()
        if preamble then
          quarto.doc.include_text("in-header", preamble)
        end
        return meta
      end
    }
  }
end

------------------------------------------------------------------------
-- Format dispatch
------------------------------------------------------------------------

if quarto.doc.is_format("html") then
  return html_filters()
elseif quarto.doc.is_format("pdf") then
  return latex_filters()
elseif quarto.doc.is_format("typst") then
  return typst_filters()
else
  return {}
end
