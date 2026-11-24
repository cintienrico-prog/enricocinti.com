-- Old-style font switches inside maths ({\cal A}, {\rm d}, {\bf x}), common in
-- physics macros, which pandoc's maths converter does not understand. Rewritten to
-- \mathcal{A} etc. before the equations become MathML; likewise \mbox{\tiny N} → \text{N},
-- \mathbbm → \mathbb, and \hat\mathcal{A} → \hat{\mathcal{A}}.
local switches = { cal = "mathcal", rm = "mathrm", bf = "mathbf", it = "mathit", sf = "mathsf", tt = "mathtt" }

function Math(el)
  local t = el.text
  for old, new in pairs(switches) do
    -- {\cal A}, {\cal AB}  →  \mathcal{A}, \mathcal{AB}
    t = t:gsub("{%s*\\" .. old .. "%s+([^{}]-)%s*}", "\\" .. new .. "{%1}")
    -- \cal A (no braces): the next token only
    t = t:gsub("\\" .. old .. "%s+(\\?%a)", "\\" .. new .. "{%1}")
  end
  -- \mbox{\tiny N} (subscript labels in physics macros) → \text{N}
  t = t:gsub("\\mbox%s*{%s*\\%a+size%s+([^{}]-)}", "\\text{%1}")
  t = t:gsub("\\mbox%s*{%s*\\tiny%s+([^{}]-)}", "\\text{%1}")
  t = t:gsub("\\mbox%s*{", "\\text{")
  -- \mathbbm (bbm package) → \mathbb
  t = t:gsub("\\mathbbm%s*{", "\\mathbb{")
  -- an accent applied to \mathcal{A} without braces: \hat\mathcal{A} → \hat{\mathcal{A}}
  for _, acc in ipairs({ "hat", "tilde", "bar", "check", "vec", "dot", "ddot", "breve", "widehat", "widetilde", "overline" }) do
    t = t:gsub("\\" .. acc .. "%s*(\\math%a+%b{})", "\\" .. acc .. "{%1}")
  end
  if t ~= el.text then
    el.text = t
    return el
  end
end
