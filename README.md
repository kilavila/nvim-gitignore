# nvim-gitignore

Fast way to generate gitignore files for your new projects!<br>
This plugin uses curl to make HTTP requests to GitHub's api: `https://api.github.com/gitignore/templates`

## Features
- List gitignore templates from GitHub's list of templates
- Select a template from a list which will create the file for you

## Installation
With [lazy.nvim](https://github.com/folke/lazy.nvim)
```
{ "kilavila/nvim-gitignore" }
```

Press enter to select a template or escape to close the window.

## Commands
```
:Gitignore
```
