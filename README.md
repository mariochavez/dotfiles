# Configuration files

These dotfiles are my base configuration for the following tools.

- [Zsh](https://www.zsh.org)
- [Ghostty](https://ghostty.org/)
- [Starship](https://starship.rs)
- [fzf](https://github.com/junegunn/fzf)
- [fd](https://github.com/sharkdp/fd)
- [bat](https://github.com/sharkdp/bat)
- [eza](https://github.com/eza-community/eza)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [cask-fonts](https://github.com/Homebrew/homebrew-cask-fonts)
- [Neovim](https://neovim.io)
- [LazyVim](https://www.lazyvim.org)
- [Git](https://git-scm.com)
- [Lazygit](https://github.com/jesseduffield/lazygit)
- [Tmux](https://github.com/tmux/tmux)
- [herdr](https://herdr.dev/)
- [mise](https://mise.jdx.dev/)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [stow](https://www.gnu.org/software/stow/)

Tools that support color scheme is using a [catppuccin](https://github.com/catppuccin/catppuccin) theme.

Neovim and Lazyvim configurations are specially configured for Ruby on Rails development, but it is easy to enable
other languages features specific with extra packages from LazyVim.

Shell, Terminal, are tools were setup for my best experience working with code, but they also looks good.

![Alacritty terminal with Neovim](screen.png)

## Tools installation

If you use MacOS, please install [Homebrew](https://brew.sh) and follow the following steps. If you use Linux follow
your distribution conventions to install the tools.

```bash
brew tap homebrew/cask-fonts
brew install git lazygit ghostty starship fzf fd eza bat zoxide font-meslo-lg-nerd-font neovim tmux zsh-autosuggestions zsh-syntax-highlighting stow
```

herdr is not installed through Homebrew, use its own installer.

```bash
curl -fsSL https://herdr.dev/install.sh | sh
```

After tools installation, clone this repository to `.dotfiles` in your home directory.

```bash
git clone https://github.com/mariochavez/dotfiles .dotfiles
```

Change to the `.dotfiles` directory and use the `stow` command to configure your environment.

```bash
stow ghostty bat nvim starship tmux zsh herdr mise
```

Close your terminal and open the Ghostty terminal, you should be ready with your new setup.

## herdr plugins

`stow` only links the herdr configuration. The plugins it refers to live in
`~/.config/herdr/plugins.json`, which is outside this repository, so they have to be
installed once per machine. Until you do, the keybindings that invoke their actions
resolve to nothing.

```bash
herdr plugin install lmilojevicc/herdr-splits.nvim
herdr plugin install smarzban/herdr-file-viewer
```

Then reload the configuration:

```bash
herdr server reload-config
```

### herdr-splits

Gives one set of `ctrl+hjkl` that walks across Neovim splits and herdr panes as if they
were the same layout, with `alt+hjkl` to resize. It is the herdr equivalent of
`vim-tmux-navigator`, which does not work here: that plugin crosses edges by calling
`tmux select-pane`, and there is no tmux server inside a herdr pane.

The plugin has two halves that must both be present and agree with each other — the herdr
side installed above, and the Neovim side in `nvim/.config/nvim/lua/plugins/navigator.lua`,
which `lazy.nvim` installs on first start. The Neovim half writes
`~/.config/herdr/plugins/config/herdr-splits/herdr-splits.conf` on every `setup()` so that
the herdr-side scripts read the same keys; that file is generated and should not be edited
by hand.

Two things worth knowing:

- `ctrl+l` no longer reaches the shell as clear-screen, since herdr claims it in non-Neovim
  panes. `prefix+ctrl+l` re-sends the real keystroke.
- `alt+hjkl` needs Ghostty configured to send Option as Meta, otherwise the resize keys type
  `˙∆˚¬`. Navigation is unaffected.

### herdr-file-viewer

A git-aware read-only file browser, opened with `prefix+f` in a split or `prefix+shift+f` in
its own tab.
