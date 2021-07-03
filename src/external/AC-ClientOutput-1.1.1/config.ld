---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

---
-- LDoc configuration.
--

title = "AC-ClientOutput documentation"
description = "Library for formatting outputs to clients for AssaultCube Lua servers"
project = "AC-ClientOutput"

file = {
  "src/AC-ClientOutput",
  exclude = {
    "src/AC-ClientOutput/ClientOutput/FontConfig"
  }
}
package = "AC-ClientOutput"
dir = "docs"

wrap = true
