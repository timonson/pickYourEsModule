const file = Deno.args[0]

import(file)
  .then(module => {
    const modulesString = Object.entries(module)
      .reduce((acc, [key, value]) => {
        acc += key === "default" ? `${value.name} (default)\n` : `${key}\n`
        return acc
      }, "")
      .trim()
    console.log(modulesString)
  })
  .catch(err => {
    console.log(err)
  })
