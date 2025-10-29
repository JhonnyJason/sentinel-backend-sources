############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("wsimodule")
#endregion

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
        try
            progress = 0
            bytes = null
            success = false
            processingStart = performance.now()

            message = evnt.data
            log "#{message}"
            bytes = message.length

            msgObj = disectMessage(message) # message: command authCode argument
            olog msgObj
            progress = 1

            access.checkSocket(msgObj.authCode, @socket)
            progress = 2
            
            switch messageObject.command
                when "getAllData" then sendAllData(@socket)
                else throw new Error("unknown command: #{messageObject.command}")
            
            progress = 3
            success = true
        catch err then log err
        
        processingTime = performance.now() - processingStart
        usage = { success, progress, bytes, processingTime }
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
    catch err then log err
    return

disectMessage = (message) ->
    log "disectMessage"
    tokens = message.split(" ")
    
    if tokens.length < 1 then throw new Error("Unexpected message.split result!")
    
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
    return

############################################################
export onConnect = (socket, req) ->
    olog req.body
    conn = new SocketConnection(socket, "#{clientIdCount}")
    clientIdCount++
    return
