// Whether we're demoing a skill tree where different levels of the same skill
// can have differing costs (true) or whether all levels of a given skill have
// the same cost (false).
SKILL_LEVELS_CAN_HAVE_DIFFERENT_COSTS :: true;

Currency :: enum { CASH; SKULLS; }
Currencies :: #type Enumerated_Array(Currency, int);

Skill_Kind :: enum {
    TRIGGER_FINGER;
    BADASS;
}
Skill_Definition :: struct {
    name: string;
    description: string;

#if SKILL_LEVELS_CAN_HAVE_DIFFERENT_COSTS {
    levels: [] Currencies;
} else {
    levels: int;
    cost: Currencies;
}

    level_up: (level: int);
    unlocks: [] Skill_Kind;
    initially_unlocked: bool;
}

#if SKILL_LEVELS_CAN_HAVE_DIFFERENT_COSTS {

SKILL_DEFINITIONS :: Enumerated_Array(Skill_Kind, Skill_Definition).{
    TRIGGER_FINGER=.{ name="Trigger Finger",
        description="Shoot 10\% faster per level.",
        levels=.[
            .{ CASH=15 },
            .{ CASH=30 },
            .{ CASH=45 },
        ],
        level_up=(level: int) { using state.stats;
            attack_speed_multiplier += .1;
        },
        unlocks=.[ .BADASS ],
        initially_unlocked=true,
    },
    BADASS=.{ name="Badass",
        description="Deal 10\% more damage per level.",
        levels=.[
            .{ CASH=15 },
        ],
        level_up=(level: int) { using state.stats;
            damage_multiplier += .1;
        }
    }
};

} else {

SKILL_DEFINITIONS :: Enumerated_Array(Skill_Kind, Skill_Definition).{
    TRIGGER_FINGER=.{ name="Trigger Finger",
        description="Shoot 10\% faster per level.",
        levels=3,
        cost=.{ CASH=15 },
        level_up=(level: int) { using state.stats;
            attack_speed_multiplier += .1;
        },
        unlocks=.[ .BADASS ],
        initially_unlocked=true,
    },
    BADASS=.{ name="Badass",
        description="Deal 10\% more damage per level.",
        levels=1,
        cost=.{ CASH=15 },
        level_up=(level: int) { using state.stats;
            damage_multiplier += .1;
        }
    }
};

}

// Compile-time skill definition checks
#run { for SKILL_DEFINITIONS {
    assert(!!it.level_up,
        "You forgot to include a level_up() procedure for %!",
        it_index
    );
}}

// Always check the result of an invocation of this before invoking level_up()
can_level_up :: (skill_kind: Skill_Kind) -> bool {
    // Can't level up if it's not unlocked
    if state.skill_levels[skill_kind] == -1 then return false;

    def := SKILL_DEFINITIONS[skill_kind];

    // Can't level up if it's already max level
#if SKILL_LEVELS_CAN_HAVE_DIFFERENT_COSTS {
    if state.skill_levels[skill_kind] == def.levels.count then return false;
} else {
    if state.skill_levels[skill_kind] == def.levels then return false;
}

    // Can't level up if you don't have the currencies necessary
#if SKILL_LEVELS_CAN_HAVE_DIFFERENT_COSTS {
    cost := def.levels[state.skill_levels[skill_kind]]; // No +1 because levels is zero-indexed
    for state.currencies if it < cost[it_index] then return false;
} else {
    for state.currencies if it < def.cost[it_index] then return false;
}

    return true;
}

// Always check can_level_up() before invoking this
level_up :: (skill_kind: Skill_Kind) {
    def := SKILL_DEFINITIONS[skill_kind];

#if SKILL_LEVELS_CAN_HAVE_DIFFERENT_COSTS {
    for def.levels[state.skill_levels[skill_kind]] state.currencies[it_index] -= it; // No +1 because levels is zero-indexed
} else {
    for def.cost state.currencies[it_index] -= it;
}

    if state.skill_levels[skill_kind] == 0 then for def.unlocks state.skill_levels[it] = max(state.skill_levels[it], 0);

    state.skill_levels[skill_kind] += 1;
    def.level_up(state.skill_levels[skill_kind]);
}


// Global game state
state: struct {
    // -1 = locked, 0 = unlocked but unleveled, 1+ = unlocked and leveled
    skill_levels: Enumerated_Array(Skill_Kind, int);
    currencies: Currencies;
    stats: struct {
        attack_speed_multiplier: float = 1.0;
        damage_multiplier:       float = 1.0;
    }
}

init :: () { using state;
    for SKILL_DEFINITIONS skill_levels[it_index] = ifx it.initially_unlocked then 0 else -1;
}

give :: (currency: Currency, amount: int) { state.currencies[currency] += amount; }
take :: (currency: Currency, amount: int) { state.currencies[currency] -= amount; }

#run { (#import "Compiler").set_build_options_dc(.{do_output=false});

    init();
    assert(!can_level_up(.TRIGGER_FINGER));
    assert(!can_level_up(.BADASS));

    give(.CASH, 100);
    assert( can_level_up(.TRIGGER_FINGER));
    assert(!can_level_up(.BADASS));

    if can_level_up(.TRIGGER_FINGER) then level_up(.TRIGGER_FINGER);

    assert( can_level_up(.TRIGGER_FINGER));
    assert( can_level_up(.BADASS));

}

#import "Basic";
#import,file "../module.jai"; // Enumerated_Array
