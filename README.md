`xioxide`, a cd wrap_per scri_pt wri_tten by c_anoe [](insert gh link)

# installation

  You need to export the variable `XIOXIDE_PATH` into your environment. It should contain the path to where the repository/this script is stored. For example in your ~/.profile: `export XIOXIDE_PATH="~/repos/xioxide"`

  Then, set an `alias xioxide="source ~/path/to/xioxide/main.sh"`. The following documentation assumes you have set a similar alias.

# configuration

  default config is located at `$XDG_CONFIG_HOME/xioxide/default.conf`
  and should be formatted like this:
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
  Basically, xioxide just uses this config to create names for concatenations of these strings, so the name `cxd` would refer to `~/.config/xioxide/default.conf`, and just `c` would refer to `~/.config/`. So `xioxide nvim "" cxd` would open ~/.config/xioxide/default.conf with nvim, and `xioxide cd "" c` would cd to ~/.config/
  See [the arguments section](#arguments) for more info on what all of the args mean.
  Note that the names of the entries in the config don't have to be one char long, but having longer ones can lead to conflicts. In cases of ambiguity like this, xioxide will prefer the one defined earlier, so `tm` would refer to `~/Documents/tomorrow/` and not `/mnt/`, and `rn` would refer to `~/repos/nix-dots/` and not `~/Documents/rightnow/`

  Note:
  - It is best practise to use trailing slashes in a config like this so that it is easy to filter for files vs folders
  - No inline comments `r ~/repos/ # like this` are allowed, so you can use the `#` character in the config freely except at the start of a line

  But, you do not have to use xioxide for folders and files, you can use it to alias any set of data that is organized as a tree:
  ```
  g google.com/
      i images/
      s search/
  ```
  With this config, `xioxide firefox "" gi` would open `google.com/images/` in firefox

  Behind the scenes. You can look into the `.parsed` files, but what xioxide does is convert these human readable trees into more machine readable files by concatenating the entries like this:
  ```
  g google.com/
  gi google.com/images/
  gs google.com/search/
  ```
  Then, it just searches the first column for your search pattern

# usage: help `xioxide help`

   print out this help page

# usage: reload `xioxide reload arg`

   Parse the configuration file `$XDG_CONFIG_HOME/xioxide/default.conf` into a more quickly readable format, at `$XDG_CONFIG_HOME/xioxide/default.parsed`. Xioxide only reads the `.parsed` file at runtime so you need to run this in order to apply changes in the config.
   If you have multiple configs, select which one to reload using a second argument. For example if you also have `$XDG_CONFIG_HOME/xioxide/other.conf"` run `xioxide reload other` to parse that config into `other.parsed`.

# usage: normal `xioxide <processing_cmd> <filter_cmd> <current_cmd> <config> <searchpattern>` [--no-passthrough]

## flags
   Any flag should be passed as the 6th argument
   - `--no-passthrough` this just means that if a match is not found for the search pattern, exit right away instead of passing the search pattern straight to the `<processing_cmd>`

## arguments

   1. The program to run on the output (determined by everything else). Commonly `cd` or `$EDITOR`, but can be `echo` if you want do something custom with the output. Defaults to `echo` if left empty.

   2. The filter program to run the list of items through before searching it. For example use `grep '/$'` to only match folders or `grep -v '/$'` to only match files, if your config is similar to the one shown in [the configuration section](#configuration) (ie it has trailing slashes). If left empty, defaults to `cat` which doesn't filter at all

   3. The command to get the currently open item (used for relative patterns, see [search patterns section](#search-pattern)). If you are using xioxide as a cd replacement, this should probably be `pwd`. Defaults to `echo` if left empty.

   4. The stem name of the configuration file to use (defaults to `default` if left empty). So if you want to use the configuration `$XDG_CONFIG_HOME/xioxide/my.conf`, pass `my` as this argument.

   5. The search pattern to search through the filtered list and select final output. More on the search pattern and how it is parsed [later](#search-pattern)

## search pattern

   This section describes how the search pattern is parsed and used to select final output.
   
   Absolute pattern:
   If the pattern does not start with `.` xioxide will just search through the list of filtered items, and use the first match (passing it to the command specified in the first argument)

   Relative pattern:
   If the pattern starts with `.` xioxide will determine the current item using the command in your third argument. Then, it will try to find an item in the filtered list that matches the output of the command (can be partial match ie `ca` matches `cat`). If it finds a match, it will take the name of the first matching item (as defined in conf), append the rest of your search pattern (whatever was after the '.'), and search the filtered list using the newly generated search pattern (same behaviour as an absolute pattern). If it does not find a match (current item is not defined in config) it will exit with an error.
   Example: you have defined `m /mnt/` and `mz /mnt/0/` in your config file, and are currently in the `/mnt/` directory. If you run `xioxide cd '' pwd '' .z` (the two empty strings mean: not filtering, using default config) `xioxide` will run `pwd` and get `/mnt` as output. Then it will look through your config and see that the first matching item is `m`, then it will apped `z` and get `mz`. The behaviour from here is the same as if you ran xioxide with `mz` as the search pattern and not `.z`, so xioxide will cd into /mnt/0/.
   Note:
   - If you are using xioxide as a cd replacement, and your `<current_cmd>` (third arg) is `pwd`, relative patterns won't seem to work right in the home directory. This is because `pwd` prints `/home/username` while you might use `~` in your config, and they won't match. To fix this, you can use `sed 's|~|/home/username|'` in your filtering command.

   Else:
   If xioxide was not able to find a match for the pattern at all, then it just passes the search pattern straight to the processing command defined in the first arg. If you do not want this behavior, pass --no-pasthrough as your 6th argument.

   Interactive:
   If you pass `''` (empty string) or `.` as your search pattern, xioxide will run in interactive mode. In this mode it will filter your config, and allow you to select which item to use with fzf. If you pass just `.`, in addition to filtering the config according to `<filter_cmd>` xioxide will only include items that match the current item, as defined by `<current_cmd>` in the fzf menu.
