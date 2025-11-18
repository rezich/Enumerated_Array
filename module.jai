// @NOTE: This module has NOT been EXHAUSTIVELY tested -- there MAY be bugs.

// A generic fixed-size array that can be indexed into with an enum.
//
//      Bird :: enum { DOVE; FALCON; HAWK; }
//      bird_counts: Enumerated_Array(Bird, int);
//
// The size of the array will be set such that it can fit all possible unique
// values of the provided enum.
//
// You can index into an Enumerated_Array using its enum, but only if you fully
// qualify it (due to language restrictions):
//
//      number_of_falcons := bird_counts[Bird.FALCON];
//      bird_counts[Bird.HAWK] += 1;
//
// For very verbose enum names, though, this can become unwieldy. To help with
// this, Enumerated_Array's backing array is #placed "onto" a using'd anonymous
// struct containing members matching each enum name -- allowing you to access
// the array elements more concisely:
//
//      number_of_falcons := bird_counts.FALCON;
//      bird_counts.HAWK += 1;
//
// Unlike other implementations, Enumerated_Array correctly handles enums with
// more than one name corresponding to a single value, as well as enums that
// have "holes" between named values, and enums whose lowest named value is
// nonzero.
//
// If more than one enum name corresponds to a single value, then the (using'd)
// values struct will contain a nested union containing all names for that value
// -- so you can access that element of the array "by member name" using any of
// the possible names that map to that value.


// Example/Tests -- set false to true below and compile this file to run
#if false #run { (#import "Compiler").set_build_options_dc(.{do_output=false});
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
    stuff: Enumerated_Array(Thing, int);
    // The interface you will use to interact with stuff will look like this:
    //     count :: 8;
    //         
    //     using values: struct {
    //         /* 0 */ union { ZERO, FIRST, FIRST_AGAIN: int; }
    //         /* 1 */ TWO:   int;
    //         /* 2 */ THREE: int;
    //         /* 3 */ SIX:   int;
    //         /* 4 */ SEVEN: int;
    //         /* 5 */ EIGHT: int;
    //         /* 6 */ NINE:  int;
    //         /* 7 */ union { SPECIAL, LAST: int; }
    //     }
    //     #place values;
    //     data: [8] int;

    // Assignment inside of a for-loop
    for * stuff it.*                            = 1;
    for 0..stuff.count-1 assert(stuff.data[it] == 1);

    // Assignment using subscripted qualified enum
    stuff[Thing.TWO]      = 22;
    assert(stuff.data[1] == 22);

    // Assignment using member
    stuff.SEVEN           = 7777777;
    assert(stuff.data[4] == 7777777);

    // Assignment using subscripted enum from an array of said enum
    NICE_THINGS :: Thing.[ .SIX, .NINE ];
    for NICE_THINGS stuff[it] = 69;
    assert(stuff.data[3]     == 69);
    assert(stuff.data[6]     == 69);

    // Assignment using member, with multiple members unioned to the same value
    stuff.SPECIAL         = 420420;
    assert(stuff.LAST    == 420420);
    assert(stuff.data[7] == 420420);

    // Ditto
    stuff.FIRST_AGAIN     = 108;
    assert(stuff.ZERO    == 108);
    assert(stuff.data[0] == 108);

    for stuff log("% %", it_index, it);
    log("---");

    // Assignment using a values literal
    other_stuff := Enumerated_Array(Thing, float).{
        FIRST  =.1,
        TWO    =.2,
        SEVEN  =.7,
        SPECIAL=.420,
    };
    for other_stuff log("% %", it_index, it);
    log("---");

    // Assignment using an data literal
    more_stuff := Enumerated_Array(Thing, string).{data=.[
        "Hello", "Sailor", "This", "Is", "Just", "A", "Test", "Goodbye"
    ]};
    for more_stuff log("% %", it_index, it);
    log("---");

    // Offset test
    even_more_stuff := Enumerated_Array(enum { FOO :: 47; BAR :: 48; }, int).{
        FOO=100,
        BAR=10000
    };
    for even_more_stuff log("% %", it_index, it);
    log("---");

    // Empty enum test
    Empty :: enum {}
    nothing: Enumerated_Array(Empty, int);
    for nothing assert(false, "This should not assert.");
    log("---");

    // Non-s64 enum test
    Elf_Type :: enum u16 {
        NONE   :: 0x00;
        REL    :: 0x01;
        EXEC   :: 0x02;
        DYN    :: 0x03;
        CORE   :: 0x04;
        LOOS   :: 0xFE00;
        HIOS   :: 0xFEFF;
        LOPROC :: 0xFF00;
        HIPROC :: 0xFFFF;
    }
    elves := Enumerated_Array(Elf_Type, string).{data=.[
        "Hermey", "Buddy", "Legolas", "Drizzt", "Dobby", "Ernie", "Tyrande", "Tanis", "Puck"
    ]};
    for elves log("% %", it_index, it);
    log("---");

    // Just for fun
    Currency :: enum { OLD_COINS; BUCKS; SIMOLEANS; }
    Loot_Bag :: Enumerated_Array(Currency, int);
    my_sack_of_loot := Loot_Bag.{
        OLD_COINS =  69,
        BUCKS     = 420,
        SIMOLEANS = 108,
    };
    CURRENCY_TO_GOLD_EXCHANGE_RATES :: Enumerated_Array(Currency, float).{
        OLD_COINS = 0.5 ,
        BUCKS     = 1   ,
        SIMOLEANS = 4.25
    };
    gold_value_of_my_sack_of_loot := 0;
    for my_sack_of_loot
        gold_value_of_my_sack_of_loot += xx (cast(float) it * CURRENCY_TO_GOLD_EXCHANGE_RATES[it_index]);
    assert(gold_value_of_my_sack_of_loot == 913);
}


Enumerated_Array :: struct(
    ENUM: Type, // The enum type
    T:    Type, // The value type
    USE_INDEX_LOOKUP_TABLE := true // Whether or not to use a lookup table when
    // indexing into the array. If true (default), a constant array sized to fit
    // the highest value in ENUM will be generated, to provide speedy lookups.
    //
    // For very large, very sparse ENUMs, you might want to set this to false
    // instead.
    //
    // If ENUM is zero-indexed and contiguous, then this setting is ignored, as
    // no lookup table is required, and ENUM itself can be used to directly
    // index into the array.
) #modify {
    info := (cast(*Type_Info_Enum) ENUM);
    if info.type != .ENUM then return false,
        "Enumerated_Array's ENUM must be an enum.";
    if info.enum_type_flags & .FLAGS then return false,
        "Enumerated_Array's ENUM must be an enum (not an enum_flags).";
    return true;
} {
    // Main interface:
    //     count:  Constant integer representing the number of elements in data.
    //             This is the same as the number of unique values in ENUM.
    //      data:  Fixed-size array of T, sized to fit all unique ENUM values.
    //   (values:) Anonymous struct containing T members and/or unions
    //             containing only T members -- one member corresponding with
    //             each ENUM name. data is #placed "onto" this struct, providing
    //             an alternate way of accessing the same T values. The struct
    //             is also using'd, so you don't need to qualify access to it
    //             with "values."

    // Common array convention: "count"
    #if IS_CONTIGUOUS
        then count :: #run type_info(ENUM).values.count;
        else count :: VALUE_MAPPINGS.count;

    // Alternate way to access data: a member for each ENUM value
    #if count then using values: struct { #insert -> string { builder: String_Builder;
        #if IS_CONTIGUOUS {
            for type_info(ENUM).names print(*builder, "%1%2",
                it, ifx it_index < count-1 then ", "
            );
            append(*builder, ": T;\n");
        } else for mapping: VALUE_MAPPINGS {
            if mapping.names.count > 1 then append(*builder,  "union {\n");
            for mapping.names print(*builder, "%1%2",
                it, ifx it_index < mapping.names.count-1 then ", "
            );
            append(*builder, ": T;\n");
            if mapping.names.count > 1 then append(*builder,  "}\n");
        }
        return builder_to_string(*builder);
    }}

    // Common array convention: "data"
    #if count then #place values;
    data: [count] T;


    // Internal interface:
    //    IS_CONTIGUOUS: True if all ENUM values are contiguous; false
    //                   otherwise. Only used at compile time.
    //     INDEX_OFFSET: First value of ENUM. Used to optimize contiguous ENUM
    //                   values when the first value is nonzero. Used at runtime
    //                   if nonzero.
    //    Value_Mapping: struct mapping the internal type of ENUM to an array of
    //                   names. Only exists if ENUM's values are not contiguous.
    //                   Used in VALUE_MAPPINGS (below). Only used at compile
    //                   time.
    //   VALUE_MAPPINGS: Constant fixed-size array containing one Value_Mapping 
    //                   for each unique value in ENUM. Only exists if ENUM's
    //                   values are not contiguous. Used at compile time to
    //                   build the values struct. Used at runtime to linear-
    //                   search index into data, only if USE_INDEX_LOOKUP_TABLE
    //                   is false (which it is *not* by default).
    //   INDEX_MAPPINGS: Constant fixed-size array sized to fit the highest
    //                   ENUM value. Only exists if ENUM's values are not
    //                   contiguous *and* USE_INDEX_LOOKUP_TABLE is true (which
    //                   it is by default). May become very large for incredibly
    //                   spare ENUMs. Used at runtime.

    IS_CONTIGUOUS :: #run -> bool {
        values := type_info(ENUM).values;
        for 0..values.count-2 if values[it+1] != values[it]+1 then return false;
        return true;
    }
    INDEX_OFFSET :: #run -> s64 {
        using _ := type_info(ENUM);
        return ifx count then values[0];
    }

    #if !IS_CONTIGUOUS {
        Value_Mapping :: struct {
            VALUE_TYPE :: #run,stallable -> Type {
                return (cast(*Type) *(cast(*Type_Info) type_info(ENUM).internal_type)).*;
            };
            value: VALUE_TYPE;
            names: [] string;
        }
        VALUE_MAPPINGS :: #run,stallable -> [] Value_Mapping {
            mappings: [..] Value_Mapping;
            names, values := type_info(ENUM).names, type_info(ENUM).values;
            for values {
                value := cast(Value_Mapping.VALUE_TYPE) it;
                mapping_exists := false;
                for mapping: mappings if mapping.value == value { mapping_exists = true; break; }
                if mapping_exists then continue;
                mapping_names: [..] string;
                for names if values[it_index] == value then array_add(*mapping_names, it);
                array_add(*mappings, .{ value, mapping_names });
            }
            quick_sort(mappings, (a,b) => a.value-b.value);
            return mappings;
        }
        #if USE_INDEX_LOOKUP_TABLE then INDEX_MAPPINGS :: #run,stallable -> [] int {
            COUNT :: #run enum_highest_value(ENUM)+1;
            mappings: [COUNT] int;
            for 0..COUNT-1 mappings[it] = -1;
            for VALUE_MAPPINGS mappings[it.value] = it_index;
            return mappings;
        }
    }
}

for_expansion :: (
    array: *Enumerated_Array,
    body:  Code,     // No remove
    flags: For_Flags // .REVERSE, .POINTER
) #expand {
    for <= cast(bool)(flags & .REVERSE) index: 0..array.count-1 {
        #if array.IS_CONTIGUOUS && array.INDEX_OFFSET == 0 then // Direct index
            `it_index := cast(array.ENUM) index;
        else #if array.IS_CONTIGUOUS then                       // Offset index
            `it_index := cast(array.ENUM) (index + array.INDEX_OFFSET);
        else                                                    // Lookup table
            `it_index := cast(array.ENUM) array.VALUE_MAPPINGS[index].value;

        `it := #ifx flags & .POINTER
            then *array.data[index]
            else  array.data[index]
        ;

        #insert(remove=#assert false "This for_expansion does not support remove.") body;
    }
}

operator *[] :: (
    using array: *Enumerated_Array,
    index:       array.ENUM
) -> *array.T {
    actual_index := -1;

    #if IS_CONTIGUOUS && INDEX_OFFSET == 0 then       // Direct index
        actual_index = xx index;
    else #if IS_CONTIGUOUS then                       // Offset index
        actual_index = xx index - INDEX_OFFSET;
    else #if USE_INDEX_LOOKUP_TABLE then              // Lookup table
        actual_index = ifx index < INDEX_MAPPINGS.count then INDEX_MAPPINGS[index] else -1;
    else for VALUE_MAPPINGS if it.value == xx index { // Linear search
        actual_index = it_index; break; 
    }

    assert(actual_index != -1,
        "Invalid enum index % in %",
        index, type_of(array.*)
    );

    return *data[actual_index];
}

// Helper procedure -- only makes sense if T can be summed
sum :: (
    using array: Enumerated_Array
) -> array.T {
    total: T;
    for data total += it;
    return total;
}

#scope_file //======================================================================================

#import "Basic";
#import "Sort";
