# pickYourEsModule

browse and pick your ECMAScript Modules

## Get the ES Modules

With the help of the `selectModule.sh` bash script you can pick any **ES
Module** with your favorite _selection app_, e.g. `rofi` or `dmenu`.

The path very the script looks for modules is defined by the `DIR` variable or
by the first _positional parameter_.  
If you have `rofi`, start the script and first all files which include modules
are displayed one below the other. After that in the next step all ESM exports
are displayed.

When you select an export, the script will automatically copy a string - like
the following one - into your clipboard:

`import { serve } from "https://deno.land/std/http/server.ts";`

You can import the module with the copied string immediately.

## Dependencies

To use the `selectModule.sh` script you need `xclip` or `xsel` and `rofi` or
`dmenu`.
