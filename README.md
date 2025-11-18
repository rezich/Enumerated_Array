Enumerated Array module
=======================

A generic fixed-size array that can be indexed into with an `enum`.

```jai
Bird :: enum { DOVE; FALCON; HAWK; }
bird_counts: Enumerated_Array(Bird, int);
```

The size of the array will be set such that it can fit all possible unique
values of the provided `enum`.

You can index into an `Enumerated_Array` using its `enum`, but only if you fully
qualify it (due to language restrictions):
```jai
number_of_falcons := bird_counts[Bird.FALCON];
bird_counts[Bird.HAWK] += 1;
```
For very verbose `enum` names, though, this can become unwieldy. To help with
this, `Enumerated_Array`'s backing array is `#place`d "onto" a `using`'d anonymous
`struct` containing members matching each `enum` name -- allowing you to access
the array elements more concisely:
```jai
number_of_falcons := bird_counts.FALCON;
bird_counts.HAWK += 1;
```
Unlike other implementations, `Enumerated_Array` correctly handles `enum`s with
more than one name corresponding to a single value, as well as `enum`s that
have "holes" between named values, and `enum`s whose lowest named value is
nonzero.

If more than one `enum` name corresponds to a single value, then the (`using`'d)
values `struct` will contain a nested `union` containing all names for that value
-- so you can access that element of the array "by member name" using any of
the possible names that map to that value.

For example, given the following `enum`:
```jai
Thing :: enum {
    ZERO;
    FIRST       :: ZERO;
    TWO         :: 2;
    SIX         :: 6;
    SEVEN;
    THREE       :: 3;
    SPECIAL     :: 420;
    EIGHT       :: 8;
    NINE;
    LAST        :: SPECIAL;
    FIRST_AGAIN :: FIRST;
}
```
The contents of an `Enumerated_Array` using this `enum`, e.g. `Enumerated_Array(Thing, int)` will look like this:
```jai
count :: 8;
using values: struct {
    /* 0 */ union { ZERO, FIRST, FIRST_AGAIN: int; }
    /* 1 */ TWO:   int;
    /* 2 */ THREE: int;
    /* 3 */ SIX:   int;
    /* 4 */ SEVEN: int;
    /* 5 */ EIGHT: int;
    /* 6 */ NINE:  int;
    /* 7 */ union { SPECIAL, LAST: int; }
}
#place values;
data: [8] int;
```

A use-case for `Enumerated_Array` that many may find useful is for defining a constant “table” of constant data that is indexed into with an `enum`:
```jai
Powerup_Kind :: enum {
    DOUBLE_DAMAGE;
    HASTE;
    INVISIBILITY;
}
Powerup_Definition :: struct {
    name: string;
    color: RGB;
    on_collect: (*Hero);
}
POWERUP_DEFINITIONS :: Enumerated_Array(Powerup_Kind, Powerup_Definition).{

    DOUBLE_DAMAGE=.{ name="Double Damage",
        color=.{0,0,1},
        on_collect=(using hero: *Hero) {
            stats.damage *= 2;
        }
    },

    HASTE=.{ name="Haste",
        color=.{1,0,0},
        on_collect=(using hero: *Hero) {
            stats.move_speed = MOVE_SPEED_MAX;
        }
    },

    INVISIBILITY=.{ name="Invisibility",
        color=.{1,1,0},
        on_collect=(using hero: *Hero) {
            is_invisible = true;
        }
    },

};
```
In some other languages, one may be tempted to reach for some kind of hash table for this sort of lookup, even though it's a table of constant data. Here, though, `Enumerated_Array` is a natural fit for just such a situation.

For more information, see the comments in [the module itself](module.jai).

For an example use of the module, see [the “skill tree” example](examples/skill_tree.jai).
