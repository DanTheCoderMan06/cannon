opt server_output = "zapOutput/server/zap.luau"
opt client_output = "zapOutput/client/zap.luau"

-- Ragdoll
event getUp = {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    data: unknown
}

funct editRagdollState = {
    call: Async,
    args: boolean,
    rets: unknown
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

--

-- Data Replication
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

--

--Castle Replication
funct selectPlatform = {
    call: Async,
    args: Instance(Player)?,
    rets: boolean
}

funct purchaseUpgrade = {
    call: Async,
    args: string,
    rets: boolean
}
--

--Physics Replication
event enterCannon = {
	from: Client,
    type: Reliable,
    call: SingleAsync,
    data: unknown
}

event finishedPath = {
	from: Client,
    type: Reliable,
    call: SingleAsync,
    data: unknown
}

event requestLoad = {
	from: Client,
    type: Reliable,
    call: SingleAsync,
    data: unknown
}

event simulatePhysics = {
	from: Server,
    type: Reliable,
    call: SingleAsync,
    data: unknown
}
--

funct toggleCannon = {
    call: Async,
    args: unknown,
    rets: boolean
}

--Notifications Service
funct hasNotificationsEnabled = {
    call: Async,
    args: unknown,
    rets: boolean
}
--

--Lucky Block
event spawnLuckyBlock = {
	from: Server,
    type: Reliable,
    call: ManyAsync,
    data: unknown
}

event claimLuckyBlock = {
	from: Client,
    type: Reliable,
    call: SingleAsync,
    data: struct {
        id: string
    }
}

funct requestLuckyBlock =  {
    call: Async,
    args: unknown,
    rets: boolean
}
--

--Rewards 
event claimDailyReward = {
	from: Client,
    type: Reliable,
    call: SingleAsync,
    data: u8(..32)
}
--

--Auto Farm
funct toggleAutoFarm = {
    call: Async,
    args: unknown,
    rets: boolean 
}
--