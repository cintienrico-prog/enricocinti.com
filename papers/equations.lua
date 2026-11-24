-- Equation numbers for the HTML version. Pandoc keeps \label{...} inside display
-- maths but does not number equations, so references come out as "[eq:x]".
-- This numbers every display equation that has a \label, in order, gives it that
-- id, and turns \ref / \eqref to it into the number.
-- Limitation: unlabelled numbered equations are not counted, so numbers can differ
-- from the PDF when a paper mixes the two (use LaTeXML for such a paper).
local numbers, n = {}, 0

local function number_equations(el)
  if el.mathtype ~= "DisplayMath" then return nil end
  local label = el.text:match("\\label%s*{([^}]*)}")
  if not label then return nil end
  n = n + 1
  numbers[label] = n
  el.text = el.text:gsub("\\label%s*{[^}]*}", "")
  return pandoc.Span(
    { el, pandoc.Span({ pandoc.Str("(" .. n .. ")") }, { class = "eqno" }) },
    { id = label, class = "equation" })
end

local function resolve(el)
  local ref = el.attributes["reference"]
  local num = ref and numbers[ref]
  if not num then return nil end
  local text = el.attributes["reference-type"] == "eqref" and "(" .. num .. ")" or tostring(num)
  el.content = { pandoc.Str(text) }
  return el
end

function Pandoc(doc)
  doc = doc:walk({ Math = number_equations })
  return doc:walk({ Link = resolve })
end
