# DevEnv

Development Environment Setup Script

## Install as `.bash_profile`

To install the script you need to download it and save as `.bash_profile`

```bash
curl -sL https://raw.githubusercontent.com/93v/devenv/master/script.sh > $HOME/.bash_profile && source $HOME/.bash_profile
```

## Launch setup

```bash
setup --all
```

If you want to choose what to configure or install exclude the `--all` option

```bash
setup
```

## Update

```bash
selfu
```

> Note: After some experiments we have realized that we are constantly making
> the same typo while trying to update and we are typing `slefu` instead.
> That is why we have both `selfu` and `slefu` as an alias to update.
