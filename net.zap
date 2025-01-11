opt server_output = "zapOutput/server/zap.luau"
opt client_output = "zapOutput/client/zap.luau"

event getUp = {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    data: unknown
}

event editRagdollState = {
    from: Client,
    type: Reliable,
    call: ManyAsync,
    data: boolean
}

event replicateRagdollState = {
	from: Server,
    type: Reliable,
    call: ManyAsync,
    data: unknown
}

event applyForceLocally = {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    data: unknown
}

event replicateNewMotors = {
	from: Server,
    type: Reliable,
    call: ManyAsync,
    data: Instance(Motor6D)[]
}

event dataChanged = {
	from: Server,
    type: Reliable,
    call: SingleAsync,
    data: unknown
}

funct changePrivacy = {
    call: Async,
    args: unknown,
    rets: boolean
}

funct selectPlatform = {
    call: Async,
    args: Instance(Player)?,
    rets: boolean
}

