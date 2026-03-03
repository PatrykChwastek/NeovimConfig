require('commands.md_to_docx')

vim.keymap.set("n", "<leader>mp", function()
  -- Step 1: Get full HTML clipboard
  local html = vim.fn.system([[
powershell -command "Add-Type -AssemblyName System.Windows.Forms; [Windows.Forms.Clipboard]::GetText('Html')"
  ]])

  if html == nil or html == "" then
    print("No HTML content in clipboard")
    return
  end

  -- Step 2: Extract first <a href="...">TEXT</a>
  local url, link_text = html:match('<a href="([^"]+)".->(.-)</a>')
  if not url or not link_text then
    print("No link found in clipboard HTML")
    return
  end

  -- Step 3: Optionally append immediately following text in <span>
  local span_text = html:match('</a><span.->(.-)</span>')
  if span_text then
    link_text = link_text .. span_text
  end

  -- Step 4: Convert to Markdown
  local markdown = string.format("[%s](%s)", link_text, url)

  -- Step 5: Insert at cursor
  vim.api.nvim_put({markdown}, "c", true, true)
end, { desc = "Paste Word/Teams link as Markdown" })
