Enumerated Array module
=======================

This is a generic fixed-size array that can be indexed into with an `enum`.

```jai
Bird :: enum { DOVE; FALCON; HAWK; }
bird_counts: Enumerated_Array(Bird, int);
```

The size of the array will be set such that it can fit all possible unique `enum` values.

You can index into an `Enumerated_Array` using its `enum`, but only if you fully qualify it (due to language restrictions):
```jai
number_of_falcons := bird_counts[Bird.FALCON];
bird_counts[Bird.HAWK] += 1;
```
For very verbose enum names, though, this can become unwieldy. To help with this, `Enumerated_Array`'s backing array is contained inside of a `union`, along with a `using`'d anonymous `struct` containing members matching each `enum` name -- you can use these members to access the array element directly:
```jai
number_of_falcons := bird_counts.FALCON;
bird_counts.HAWK += 1;
```
Unlike other implementations, `Enumerated_Array` correctly handles `enum`s with more than one name corresponding to a single value, and also "sparse" `enum`s with some values omitted between other values.

If more than one `enum` name corresponds to a single value, then the values `struct` within the `union` will contain a nested `union` containing all names for that value -- so you can access that element of the array "by member name" using any of the possible `enum` names that map to that value.

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
union {
    data:     [8] int;
    values:   struct {
        /* 0 */ union { ZERO, FIRST, FIRST_AGAIN: int; }
        /* 1 */ TWO:   int;
        /* 2 */ THREE: int;
        /* 3 */ SIX:   int;
        /* 4 */ SEVEN: int;
        /* 5 */ EIGHT: int;
        /* 6 */ NINE:  int;
        /* 7 */ union { SPECIAL, LAST: int; }
    }
}
```

For more information, see the comments in [the module itself](module.jai).

For an example use of the module, see [the “skill tree” example](examples/skill_tree.jai).
