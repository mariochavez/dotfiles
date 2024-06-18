# Configuration files

These dotfiles are my base configuration for the following tools.

- [Zsh](https://www.zsh.org)
- [Alacritty](https://alacritty.org)
- [Starship](https://starship.rs)
- [fzf](https://github.com/junegunn/fzf)
- [fd](https://github.com/sharkdp/fd)
- [bat](https://github.com/sharkdp/bat)
- [eza](https://github.com/eza-community/eza)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [cask-fonts](https://github.com/Homebrew/homebrew-cask-fonts)
- [Neovim](https://neovim.io)
- [LazyVim](https://www.lazyvim.org)
- [Tmux](https://github.com/tmux/tmux)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [stow](https://www.gnu.org/software/stow/)

Tools that support color scheme is using a [catppuccin](https://github.com/catppuccin/catppuccin) theme.

Neovim and Lazyvim configurations are specially configured for Ruby on Rails development, but it is easy to enable
other languages features specific with extra packages from LazyVim.

Shell, Terminal, are tools were setup for my best experience working with code, but they also looks good.

## Tools installation

If you use MacOS, please install [Homebrew](https://brew.sh) and follow the following steps. If you use Linux follow
your distribution conventions to install the tools.

```bash
brew tap homebrew/cask-fonts
brew install git alacritty starship fzf fd eza bat zoxide font-meslo-lg-nerd-font neovim tmux zsh-autosuggestions zsh-syntax-highlighting stow
```

After tools installation, clone this repository to `.dotfiles` in your home directory.

```bash
git clone https://github.com/mariochavez/dotfiles .dotfiles
```

Change to the `.dotfiles` directory and use the `stow` command to configure your environment.

```bash
stow alacritty bat nvim starship tmux zsh
```

Close your terminal and open the Alacritty terminal, you should be ready with your new setup.
