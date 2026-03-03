-- requires pandoc

-- HELPER: Get Visual Selection
local function get_visual_selection()
    local s_start = vim.fn.getpos("'<")
    local s_end = vim.fn.getpos("'>")
    local n_lines = math.abs(s_end[2] - s_start[2]) + 1
    local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
    if n_lines == 1 then
        lines[1] = string.sub(lines[1], s_start[3], s_end[3] - 1)
    else
        lines[1] = string.sub(lines[1], s_start[3])
        lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - 1)
    end
    return table.concat(lines, "\n")
end

-- HELPER: Create the Lua Filter for Pandoc
-- Returns the path to the temporary filter file
local function create_docx_style_filter()
    -- Word calculates size in "half-points".
    -- 24 = 12pt (Normal), 28 = 14pt, 32 = 16pt
    local filter_content = [[
        function Header(el)
          -- Convert header content to plain text to safely inject into XML
          local text = pandoc.utils.stringify(el)

          -- Construct Raw OpenXML for a Paragraph
          -- <w:p> = Paragraph
          -- <w:rPr> = Run Properties (Bold, Size)
          local xml = 
            '<w:p>' ..
              '<w:r>' ..
                '<w:rPr>' ..
                  '<w:b/>' ..               -- Bold
                  '<w:sz w:val="32"/>' ..   -- Size 16pt (32 half-points)
                  '<w:szCs w:val="32"/>' .. -- Size 16pt for complex scripts
                '</w:rPr>' ..
                '<w:t xml:space="preserve">' .. text .. '</w:t>' ..
              '</w:r>' ..
            '</w:p>'
            
          return pandoc.RawBlock('openxml', xml)
        end
    ]]

    local filter_path = vim.fn.stdpath('cache') .. "/docx_custom_header.lua"
    local f = io.open(filter_path, "w")
    if f then
        f:write(filter_content)
        f:close()
        return filter_path
    else
        print("Error: Could not create temp filter file")
        return nil
    end
end

-- 1. COMMAND: Convert WHOLE FILE to .docx
vim.api.nvim_create_user_command('MdToDocx', function()
    local filename = vim.fn.expand('%')
    if filename == '' then
        print("Buffer has no file name. Save it first.")
        return
    end
    local output_name = vim.fn.expand('%:r') .. '.docx'
    local filter_path = create_docx_style_filter() -- Generate the filter

    if not filter_path then return end

    -- Run Pandoc with the filter
    local cmd = string.format('pandoc "%s" -o "%s" --lua-filter="%s"', filename, output_name, filter_path)
    local result = os.execute(cmd)

    if result == 0 then
        print("Successfully generated: " .. output_name)
    else
        print("Error converting file.")
    end
end, {})

-- 2. COMMAND: Convert SELECTION to .docx file
vim.api.nvim_create_user_command('MdSelToDocx', function()
    local text = get_visual_selection()
    local output_name = "selection.docx"
    local filter_path = create_docx_style_filter() -- Generate the filter

    if not filter_path then return end

    -- Run Pandoc with the filter (piping text in)
    local cmd = string.format('pandoc -f markdown -o "%s" --lua-filter="%s"', output_name, filter_path)
    local handle = io.popen(cmd, 'w')
    if handle then
        handle:write(text)
        handle:close()
        print("Selection saved to " .. output_name)
    else
        print("Error: Could not run pandoc")
    end
end, { range = true })
