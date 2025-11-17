############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("bugsnitchmodule")
#endregion


############################################################
import fs from "fs"
import Slimbot from "slimbot"
import * as c from "./configmodule.js"

############################################################
bot = null
chatId = null
hostname = ""

############################################################
setReady = null
ready = new Promise (rslv) -> setReady = rslv

############################################################
knownReports = new Set()

############################################################
export initialize = () ->
    log "initialize"
    
    token = c.telegramToken
    chatId = c.snitchChatId
    name = c.name

    # use name as hostname if we have a name in the config
    if name then hostname = name
    else hostname = fs.readFileSync("/etc/hostname", "utf8")

    hostname = hostname.replaceAll("\n", "")
    hostname = hostname.replaceAll(" ", "")

    bot = new Slimbot(token)
    setReady()
    return

############################################################
export send = (message) ->
    log "send"
    await ready
    try bot.sendMessage(chatId, "#{hostname}: #{message}")
    catch err then log err
    return

export report = (message) ->
    log "report"
    if knownReports.has(message) then return

    knownReports.add(message)
    console.error(message)
    send(message)
    return

