return {
	cloudSky = 10000,
	cloudSkyLerp = 2000,
	nightSky = 20000,
	nightSkyLerp = 3000,

	-- Lighting transition based on altitude
	DAY_CLOCK_TIME = 14, -- Normal daytime
	NIGHT_CLOCK_TIME = 0, -- Absolute night time (can be 0 or 24)
	NIGHT_TRANSITION_START_ALTITUDE = 10500, -- Altitude to start transitioning to night
	NIGHT_TRANSITION_END_ALTITUDE = 12000, -- Altitude where it's fully night

	attachToAttachments = {
		--[[
		"HatAttachment",
		"LeftGripAttachment",
		"RightGripAttachment",
		"RightFootAttachment",
		"LeftFootAttachment",--]]
		"RootAttachment",
	},
}
