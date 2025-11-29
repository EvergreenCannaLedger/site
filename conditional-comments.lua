-- conditional-comments.lua
function RawBlock(el)
  -- Only include comment box on blog posts or dashboard
  if el.format == "html" and el.text:match("<!-- commento -->") then
    local path = quarto.doc.input_file or ""
    if path:match("^posts/") or path:match("dashboards.qmd$") then
      return el
    else
      return {}
    end
  end
  return el
end
