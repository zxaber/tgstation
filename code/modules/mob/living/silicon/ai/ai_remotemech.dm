/**This is a mob to handle allowing an AI player to remote control a mech via an AI beacon. It is created when the AI player starts
remote controlling a mech, and is destroyed when it stops.*/
/mob/living/silicon/ai/ai_remotemech
	can_be_carded = FALSE
	var/mob/living/silicon/ai/parent_ai

/mob/living/silicon/ai/ai_remotemech/Initialize
	name = "[parent_ai] remote beacon"
	real_name = "[parent_ai] remote beacon"

