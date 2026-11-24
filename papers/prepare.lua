-- Prepares a paper's main.tex for TeX4ht (run by render.sh with texlua, on a copy
-- of the source: the paper itself and its PDF are never touched).
--   texlua prepare.lua main.tex
-- Each rewrite below fixes a construct that compiles fine in LaTeX but comes out
-- wrong, or stops the run, in TeX4ht's MathML. papers/example/main.tex has one of
-- each, so a change here can be checked against it.

local file = assert(arg[1], "usage: texlua prepare.lua main.tex")
local f = assert(io.open(file)); local tex = f:read("a"); f:close()

local split = tex:find("\\begin{document}", 1, true)
assert(split, file .. ": no \\begin{document}")
local preamble, body = tex:sub(1, split - 1), tex:sub(split)

-- Preamble macros that contain a _ (\newcommand{\GN}{G_{\tn N}}) are read before
-- TeX4ht starts, so the _ never becomes a MathML subscript. They go to
-- paper-macros.tex, which paper.cfg reads again once TeX4ht is on.
local again = {}
for line in preamble:gmatch("[^\n]+") do
  local code = line:gsub("%%.*", "")
  if code:match("^%s*\\newcommand") or code:match("^%s*\\renewcommand") or code:match("^%s*\\def") then
    if code:find("_", 1, true) then
      again[#again + 1] = (code:gsub("\\newcommand", "\\renewcommand"))
    end
  end
end
local m = assert(io.open("paper-macros.tex", "w")); m:write(table.concat(again, "\n"), "\n"); m:close()

-- Shorthands for environments (\newcommand{\beq}{\begin{eqnarray}}): written out,
-- because TeX4ht reads such environments looking for a literal \end{...}.
local function expand(name, env)
  if env:match("^\\begin{") or env:match("^\\end{") then
    body = body:gsub("\\" .. name .. "(%A)", function(after) return env .. after end)
  end
end
for name, env in preamble:gmatch("\\newcommand{?\\(%a+)}?{(\\%a+{[%a*]+})}") do expand(name, env) end
for name, env in preamble:gmatch("\\def\\(%a+){(\\%a+{[%a*]+})}") do expand(name, env) end

-- eqnarray (deprecated, still common in physics) breaks TeX4ht's MathML in recent
-- versions; amsmath's align takes the same rows (a &=& b too), numbered alike.
body = body:gsub("\\(begin){eqnarray(%*?)}", "\\%1{align%2}"):gsub("\\(end){eqnarray(%*?)}", "\\%1{align%2}")
if not preamble:find("amsmath", 1, true) then
  preamble = preamble:gsub("(\\documentclass[^\n]*\n)", "%1\\usepackage{amsmath}\n", 1)
end

-- An accent on a bare macro (\hat\cA) needs braces for TeX4ht: \hat{\cA}.
for _, accent in ipairs({ "hat", "tilde", "bar", "vec", "dot", "ddot", "check", "breve", "acute",
  "grave", "mathring", "widehat", "widetilde", "overline", "underline" }) do
  body = body:gsub("\\" .. accent .. "\\(%a+)", "\\" .. accent .. "{\\%1}")
end

-- A sub- or superscript that is a bare macro (\sigma^\Psi) needs braces too:
-- \sigma^{\Psi}. Not when the macro takes a braced argument (_\mathrm{x}).
body = body:gsub("([_^])\\(%a+)([^%a{])", "%1{\\%2}%3")

local out = assert(io.open(file, "w")); out:write(preamble, body); out:close()
