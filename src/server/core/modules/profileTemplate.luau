return {
	money = 0,
	floors = 1,
	cannon = 0,
	highscore = 0,
	towerStatus = 0, -- 0 PUBLIC 1 FRIENDS 2 PRIVATE
	boughtLevels = 0,
	boughtFloors = 0,

	cannons = {},
	lastClaimed = os.time(),
	daysPlayed = 0,
	daysClaimed = {},
	lastEntered = 0,

	notificationQueue = {},
	firstTimeRewards = true,
	distanceIncreased = false,

	invitedPlayers = {},
	notificationsOn = false,

	hasVIPOn = false,
	vipTimeStart = 0,
}
