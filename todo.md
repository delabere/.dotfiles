# For work configurion
## neovim
- when navigating to a service on a fresh nvim boot, it opens up in the classinc vim file navigation and I then have to first navigate into a go file, and then re-open the nav to get nvimtree and then I can navigate the directory properly
  - Try using the CD version of the monzo service helper

- when using grep telescope pickers in the monorepo, I get the full filepaths which truncate to only the first chars which is often not enough to see the filenames of what I'm looking at eg:
` src/github.com/monzo/wearedev/service.pot-invariant-maintainer/handler/han`
👆 I don't need `src/github.com/monzo/wearedev/` so I'd like to trim this out
