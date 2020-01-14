# pickYourEsModule

browse and pick your ECMAScript Modules - only for Linux users for now.

![](./2019-10-03T15:08:08+02:00_1307x518.gif)

This script fits perfectly to [Deno](https://deno.land/). For example, you can
pick one of the Deno Standard Modules and then import it directly with the URL
which has been copied into your clipboard.

## Quick Start

If you want to use this script to browse through all the Deno Standard ES
Modules run `./selectModule.sh <path>` where `<path>` is the location of the
Deno Standard Modules
[repository](https://github.com/denoland/deno/tree/master/std/) on your device.

## Usage

With the help of the `selectModule.sh` Bash script you can pick any **ES
Module** with your favorite _selection app_, e.g. `rofi` or `dmenu`.

The `DIR` variable or the first _positional parameter_ defines the path where
the script looks for ES modules.  
If you have `rofi` installed, start the `selectModule.sh` script and all files
which include ES modules are displayed one below the other.  
After you selected a file, the Bash script calls the JavaScript script
`getEsModules.js` to display all ESM exports.

When you select an export, the script will automatically copy a string - like
the following one - into your clipboard:

`import { serve } from "https://deno.land/std/http/server.ts";`

You can import the module with the copied string immediately.

## Dependencies

`pickYourEsModule` consists of the two files `selectModule.sh` and
`getEsModules.js` which have to be in the same directory.

Furthermore it depends on `xclip` or `xsel` and `rofi` or `dmenu`.
