vim:ft=markdown
[https://github.com/catinacanoe/xioxide](https://github.com/catinacanoe/xioxide)
`xioxide`, a `cd` wrapper script written by canoe, but it's extensible. In the sense that you can use it to organize and access any data that is naturally organized in a tree.
Inspired by `zoxide` [https://github.com/ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide)

# dependencies

  Needs `fzf` for interactive mode, see [this section](#search-pattern) for more info on what that is.

# installation

  You need to export the variable `XIOXIDE_PATH` into your environment. It should contain the path to where the repository/this script is stored. For example in your ~/.profile: `export XIOXIDE_PATH="~/repos/xioxide"`

  Then, set an `alias xioxide="source ~/path/to/xioxide/main.sh"`. The following documentation assumes you have set a similar alias.

# configuration

  By default config is located at `$XDG_CONFIG_HOME/xioxide/default.conf`

## files and folders style

   Config should be formatted like this:
   ```
   r ~/repos/
       n nix-dots/
       x xioxide/
           m main.sh
       p pw/
   # xioxide ignores empty lines

   # like that one

   rn ~/Downloads/rightnow/
   tm ~/Documents/tomorrow/

   t /
       m mnt/
       e etc/
   c ~/.config/
       x xioxide/
           d default.conf
   ```
   Basically, `xioxide` just uses this config to create names for concatenations of these strings, so the name `cxd` would refer to `~/.config/xioxide/default.conf`, and just `c` would refer to `~/.config/`. So `xioxide nvim "" cxd` would open `~/.config/xioxide/default.conf` with `nvim`, and `xioxide cd "" c` would `cd` to `~/.config/`
   See [the arguments section](#arguments) for more info on what all of the args mean.
   Note that the names of the entries in the config don't have to be one char long, but having longer ones can lead to conflicts. In cases of ambiguity like this, `xioxide` will prefer the one defined earlier, so `tm` would refer to `~/Documents/tomorrow/` and not `/mnt/`, and `rn` would refer to `~/repos/nix-dots/` and not `~/Documents/rightnow/`

   Note:
   - Indent size can be any number of *spaces* as long as it is kept consistent
   - It is best practise to use trailing slashes in a config like this so that it is easy to filter for files vs folders
   - No inline comments `r ~/repos/ # like this` are allowed, so you can use the `#` character in the config freely except at the start of a line

## not just files and folders :)

   This is where the aformentioned extensibility part comes in. You do not have to use `xioxide` just for folders and files, you can use it with any set of strings that is naturally organized as a tree. For example:
   ```
   g google.com/
       i images/
       s search/
   ```
   With this config, `xioxide firefox '' '' '' gi` would open `google.com/images/` in firefox

## extra info for understanding

   Behind the scenes: You can look into the `.parsed` files, but what `xioxide` does is convert these human readable trees into more machine readable files by concatenating the entries like this:
   ```
   g google.com/
   gi google.com/images/
   gs google.com/search/
   ```
   Then, it just searches the first column for your search pattern

# usage: help

  `xioxide help`
   print out this help page

# usage: reload

   `xioxide reload [config_name]`
   Parse the configuration file `$XDG_CONFIG_HOME/xioxide/*.conf` into a more machine readable format, at `$XDG_CONFIG_HOME/xioxide/*.parsed`. `xioxide` only reads the `.parsed` file at runtime so you need to run this in order to apply changes in the config.

   Running `xioxide reload` with no arguments will parse every file in `$XDG_CONFIG_HOME/xioxide/` that matches `*.conf`. The resulting files will have the extension `.parsed` instead. If you want to reload only a specific config, pass its stem name as a second argument. So, to parse `$XDG_CONFIG_HOME/xioxide/myconf.conf`, run `xioxide reload myconf`.

# usage: normal
  `xioxide <processing_cmd> <filter_cmd> <current_cmd> <config> <searchpattern> [--no-passthrough]`

## flags
   Any flag should be passed as the 6th argument
   - `--no-passthrough` just means that if a match is not found for the search pattern, exit right away instead of passing the search pattern straight to the `<processing_cmd>`

## arguments

   1. The program to run on the output (determined by everything else). Commonly `cd` or `$EDITOR`, but can be `echo` if you want do something custom with the output. Defaults to `echo` if left empty.

   2. The filter program to run the list of items through before searching it. For example use `grep '/$'` to only match folders or `grep -v '/$'` to only match files, if your config is similar to the one shown in [the configuration section](#configuration) (ie it has trailing slashes). If left empty, defaults to `cat` which doesn't filter at all

   3. The command to get the currently open item (used for relative patterns, see [search patterns section](#search-pattern)). If you are using `xioxide` as a `cd` replacement, this should probably be `pwd`. Defaults to `echo` if left empty.

   4. The stem name of the configuration file to use (defaults to `default` if left empty). So if you want to use the configuration `$XDG_CONFIG_HOME/xioxide/my.conf`, pass `my` as this argument.

   5. The search pattern to search through the filtered list and select final output. More on the search pattern and how it is parsed [later](#search-pattern)

## search pattern

   This section describes how the search pattern is parsed and used to select final output.

   Predots:
   If the pattern contains dot characters (`.`) at the beginning, these are called predots. They signify the current item (like `cd ./dir`). If there is only one dot, `xioxide` will essentially just replace it with the current item's name. So, if there is an item `abc ~/alpha/bet/c/` and that is the current directory, the search pattern `.d` is equivalent to `abcd`. If there are multiple dots, `xioxide` starts going up the item tree (like `cd ../other`). So, in the same scenario, the pattern `..z` is the same as `abz`, and `...e` is equivalent to `ae`. However, `....a` would not be valid, as there is no item with the name `''`. In this case xioxide will just pass the string through to the runner command.

   Letters:
   Outlined previously, the letters in the string are the main part of the search pattern. So, however the predots narrowed down our search, `xioxide` will just look through the item list and find all of the items whose names begin with the provided letters.

   Postdots:
   This is what we call the dot(s) at the end of the string (if there are multiple, the behaviour is the same as if there was just one). If there are no postdots, `xioxide` just uses the item at the top of the narrowed down list (most likely the one that matched our predots and letters perfectly). If there are postdots, `xioxide` allows the user to select the item to use from the narrowed down list using `fzf`.
   
   Example: you have defined `m /mnt/` and `mz /mnt/0/` in your config file, and are currently in the `/mnt/` directory. If you run `xioxide cd '' pwd '' .z` (the two empty strings mean: not filtering, using default config) `xioxide` will run `pwd` and get `/mnt` as output. Then it will look through your config and see that the first matching item is `m`, then it will append `z` and get `mz`. The behaviour from here is the same as if you ran `xioxide` with `mz` as the search pattern and not `.z`, so `xioxide` will cd into /mnt/0/.

   Note:
   - If you are using `xioxide` as a cd replacement, and your `<current_cmd>` (third arg) is `pwd`, relative patterns won't seem to work right in the home directory. This is because `pwd` prints `/home/username` while you might use `~` in your config, and they won't match. To fix this, you can use `sed 's|~|/home/username|'` in your filtering command.

   Else:
   If `xioxide` was not able to find a match for the pattern at all, then it just passes the search pattern straight to the processing command defined in the first arg. If you do not want this behavior, pass --no-pasthrough as your 6th argument.

# roadmap

  Just features I plan to eventually implement

## better installation instructions

   currently they aren't very descriptive

## add aliases
   so that commonly accesed items can be sed replaced in
