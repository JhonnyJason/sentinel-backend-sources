############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("wsimodule")
#endregion

############################################################
import * as bs from "./bugsnitch.js"

############################################################
import * as data from "./datamodule.js"
import * as access from "./accessmodule.js"

############################################################
clientIdCount = 0

############################################################
class SocketConnection
    constructor: (@socket, @clientId) ->
        # preseve that "this" is this class
        self = this
        @socket.onmessage = (evnt) -> self.onMessage(evnt)
        @socket.onclose = (evnt) -> self.onDisconnect(evnt)
        log "#{@clientId} connected!"

    onMessage: (evnt) ->
        log "onMessage"
        processingStart = performance.now()
        try result = processMessage(evnt.data, @socket)        
        catch err then bs.report("Soccket.onMessage: "+err.message)
        processingTime = performance.now() - processingStart

        if result? then usage = result
        else usage = { 
            success: false, 
            error: "fatal",  
            bytes: evnt.data.length
        }

        usage.processingTime = processingTime
        noteUsage(usage)
        return

    onDisconnect: (evnt) ->
        log "onDisconnect: #{@clientId}"
        try
            #TODO implment some unsubscribing  
        catch err then log err
        return
    
    noteUsage: (usage) ->
        log "noteUsage: #{@clientId}"
        #TODO identify abusive behaviour
        olog usage
        return

    close: ->
        log "closeSocket for: #{@clientId}"
        @socket.close()
        return
    
############################################################
sendAllData = (socket) -> 
    log "sendAllData"
    try
        data = JSON.stringify(data.getAllData())
        olog data
        socket.send(data)
    catch err then bs.report("Command.sendAllData: "+err.message)
    return

disectMessage = (message) ->
    log "disectMessage"
    tokens = message.split(" ")
        
    command = tokens[0]
    authCode = ""
    argument = ""

    if tokens.length >= 2 then authCode = tokens[1]

    if tokens.length == 3 then argument = tokens[2]
    if tokens.length > 3 then argument = tokens.splice(2).join(" ")

    return {command, authCode, argument}

############################################################
noteUsage = (usage, socket) ->
    log "noteUsage"
    ## TODO implement
    return

############################################################
processMessage = (message, sock) ->
    log "processMessage"
    olog { message }
    result = Object.create(null)
    result.success = false
    result.bytes = message.length

    msgObj = disectMessage(message) # message: command authCode argument
    olog msgObj

    result.error = "Unauthorized!"
    if !access.hasAccess(msgObj.authCode) then return result
    
    result.error = "unknown command: #{msgObj.command}"
    switch msgObj.command
        when "getAllData" then sendAllData(sock)
        else return result
            
    result.success = true
    result.error = null
    return result

############################################################
export onConnect = (socket, req) ->
    olog req.body
    conn = new SocketConnection(socket, "#{clientIdCount}")
    clientIdCount++
    return
