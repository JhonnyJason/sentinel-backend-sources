############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("wsimodule")
#endregion

############################################################
import * as data from "./datamodule.js"

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
            message = evnt.data
            log "#{message}"

            # separate command from potential argument            
            commandEnd = message.indexOf(" ")
            if commandEnd < 0 then command = message # no argument
            else
                command = message.substring(0, commandEnd)
                postCommand = message.substring(commandEnd).trim()

            switch command
                when "getAllData" then sendAllData(@socket)
                else throw new Error("unknown command: #{command}")

        catch err then log err
        return

    onDisconnect: (evnt) ->
        log "onDisconnect: #{@clientId}"
        try
            #TODO implment some unsubscribing  
        catch err then log err
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


############################################################
export onConnect = (socket, req) ->
    olog req.body 
    conn = new SocketConnection(socket, "#{clientIdCount}")
    clientIdCount++
    return
