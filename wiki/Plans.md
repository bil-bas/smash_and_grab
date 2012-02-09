TODO list
=========

Visuals
-------

Float fist/target over the head of targets, as well as at feet.
Invisible man shouldn't have a shadow.
Carried object should be shown in panel.
Carried object should have a background when shown next to side summary.
Shadows under vehicles.
[DONE] Shadow doesn't turn left/right

Text
----

Add index if there are more than 1 of a faction
Add index if there are more then 1 of a given unit (e.g. "Cop #1").
[DONE] range should be 2-5, not 2..5

Logic
-----

_BUG!_ If you can melee someone but not shoot them, then clicking on them assumes shooting (icon under them in melee one).

Abilities
---------
P - passive; T - toggle; S - self; R - ranged; M - melee; A - Auto.
A toggle power costs 1 action to turn on and one per turn.

THOUGHT: Perhaps you get 1 action back per turn and actually have 3 as an average.
         so 2 for minions, 3 for heroes, 4 for super-speed.
         Gives idea of having an alpha-strike and getting tired.
THOUGHT: Alternatively, could have a "special reserve" that you can use at any time to replenish
         actions and pass a whole turn to get it back (or have one per game). Some powers might
         require this to work (such as rez).


### Attack

Strength (R+): pick up AND throw a huge object, so we don't have to animate carrying.
Whirlwind (S): Attack all adjacent entities in melee.
Feint (M): Melee attack which damages enemies actions (roll 6 on d6)

### Defence

Weaker ones more likely to be passive; Invulnerability definitely a toggle :)
Resistances give 1-5 damage off.

Stealth (P): Increase effective range of attacks by 2-10 squares (stealth 2 being attacked by someone with a range of 2-7, the effective range would be 2-3).
Bulletproof (P): resistance to piercing attacks (guns and stinger's spear).
Mirrored (P): resistance to laser attacks (robot and sniper?).
Dense (P): resistance to crushing attacks (most melee and thrown objects).
Pirate (P): resistance to poison (stinger's spear)
Asbestos (P): resistance to explosive/fire attacks?
Deft (T): resistance to all ranged attacks.
Duelist (T): resistance to all melee attacks.
Invulnerable (T): resistance to all attacks.
Weave (T): resistance to opportunity fire (melee/ranged).

### Utility

Regeneration (P): gain 1-5 HP at start of turn.
Self-heal (S): Heal 1-5HP per action.
Heal (R): Heal 1-5HP to adjacent ally.
Self-rez (A): Automatically get up a turn after you are put down.



