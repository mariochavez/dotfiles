-- Seamless ctrl+hjkl navigation between nvim splits and herdr panes.
-- Replaces vim-tmux-navigator, which shelled out to `tmux select-pane` and so
-- did nothing inside a herdr pane. The herdr side of this pair lives in
-- ~/.config/herdr/config.toml (keys.command -> herdr-splits.nav-*).

-- Floating windows have no position in Neovim's layout tree, so a directional
-- `wincmd` from one always "succeeds" and always lands in the same normal
-- window. herdr-splits reads that as "moved within Neovim" and returns before
-- it ever tries to cross into herdr, which strands you inside the snacks
-- explorer. These are the picker's window filetypes (zindex 33, so the plugin
-- classes them as embedded sidebars rather than true floats).
local picker_filetypes = {
  "snacks_picker_list",
  "snacks_picker_input",
  "snacks_picker_preview",
  "snacks_layout_box",
}

-- Screen rect of a window, in (row, col) terms.
local function rect(winid)
  local pos = vim.api.nvim_win_get_position(winid)
  return {
    top = pos[1],
    left = pos[2],
    bottom = pos[1] + vim.api.nvim_win_get_height(winid),
    right = pos[2] + vim.api.nvim_win_get_width(winid),
  }
end

-- Is `other` positioned in `direction` relative to `from`?
local function lies_toward(from, other, direction)
  if direction == "left" then
    return other.right <= from.left
  elseif direction == "right" then
    return other.left >= from.right
  elseif direction == "up" then
    return other.bottom <= from.top
  else
    return other.top >= from.bottom
  end
end

-- Distance used to pick the nearest candidate window.
local function gap(from, other, direction)
  if direction == "left" then
    return from.left - other.right
  elseif direction == "right" then
    return other.left - from.right
  elseif direction == "up" then
    return from.top - other.bottom
  else
    return other.top - from.bottom
  end
end

-- From a picker float: move to the nearest normal window in `direction` if one
-- exists, otherwise hand off to herdr. This restores both halves of the move --
-- explorer -> editor stays inside nvim, explorer -> herdr crosses the boundary.
local function navigate_from_picker(direction)
  local from = rect(0)
  local best, best_gap

  -- snacks_layout_box is a *non-floating* window owned by the picker, so it
  -- passes a plain is-not-a-float test; focusing it just bounces straight back
  -- to the list. Candidates must exclude every window the picker owns.
  local is_picker_win = {}
  for _, ft in ipairs(picker_filetypes) do
    is_picker_win[ft] = true
  end

  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local ft = vim.bo[vim.api.nvim_win_get_buf(winid)].filetype
    if
      winid ~= vim.api.nvim_get_current_win()
      and vim.api.nvim_win_get_config(winid).relative == ""
      and not is_picker_win[ft]
    then
      local other = rect(winid)
      if lies_toward(from, other, direction) then
        local d = gap(from, other, direction)
        if not best_gap or d < best_gap then
          best, best_gap = winid, d
        end
      end
    end
  end

  if best then
    vim.api.nvim_set_current_win(best)
  else
    require("herdr-splits.herdr").focus_pane(direction)
  end
end

return {
  {
    "lmilojevicc/herdr-splits.nvim",
    cond = vim.env.HERDR_ENV == "1",
    event = "VeryLazy",
    opts = {
      at_edge = "wrap",
      -- Only consulted for resizing and at_edge="split", not for navigation.
      ignored_filetypes = vim.list_extend({
        "dadbod-ui",
        "dbout",
        "aerial",
        "Outline",
        "Trouble",
        "quickfix",
        "snacks_dashboard",
      }, picker_filetypes),
    },
    keys = {
      { "<C-h>", function() require("herdr-splits").move_cursor_left() end, desc = "Navigate left" },
      { "<C-j>", function() require("herdr-splits").move_cursor_down() end, desc = "Navigate down" },
      { "<C-k>", function() require("herdr-splits").move_cursor_up() end, desc = "Navigate up" },
      { "<C-l>", function() require("herdr-splits").move_cursor_right() end, desc = "Navigate right" },
      { "<M-h>", function() require("herdr-splits").resize_left() end, desc = "Resize left" },
      { "<M-j>", function() require("herdr-splits").resize_down() end, desc = "Resize down" },
      { "<M-k>", function() require("herdr-splits").resize_up() end, desc = "Resize up" },
      { "<M-l>", function() require("herdr-splits").resize_right() end, desc = "Resize right" },
    },
    init = function()
      local directions = { ["<C-h>"] = "left", ["<C-j>"] = "down", ["<C-k>"] = "up", ["<C-l>"] = "right" }

      local function apply(buf)
        local ft = vim.bo[buf].filetype
        for key, direction in pairs(directions) do
          -- snacks owns <C-j>/<C-k> in the input window as list_down/list_up --
          -- the only way to move the selection while typing a filter, so leave
          -- them alone there. In the list window plain j/k already do that job.
          local snacks_owns = ft == "snacks_picker_input" and (key == "<C-j>" or key == "<C-k>")
          if not snacks_owns then
            vim.keymap.set({ "n", "i" }, key, function()
              navigate_from_picker(direction)
            end, { buffer = buf, desc = "Navigate " .. direction })
          end
        end
      end

      local group = vim.api.nvim_create_augroup("herdr_splits_picker_nav", { clear = true })
      -- snacks installs its own buffer-local maps after FileType fires, so
      -- re-assert on entry as well; the maps are idempotent.
      vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "WinEnter" }, {
        group = group,
        callback = function(event)
          local buf = event.buf or vim.api.nvim_get_current_buf()
          if vim.tbl_contains(picker_filetypes, vim.bo[buf].filetype) then
            apply(buf)
          end
        end,
      })
    end,
  },
}
