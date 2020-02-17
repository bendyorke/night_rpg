// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"
import {Socket} from "phoenix"
import LiveSocket from "phoenix_live_view"

const decimalToHex = dec =>  ('0' + dec.toString(16)).substr(-2)

const generateId = length => {
  const base = new Uint8Array(length / 2)
  window.crypto.getRandomValues(base)
  return Array.from(base, decimalToHex).join('')
}

const uuid = generateId(20)

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken, uuid}});
liveSocket.connect()
