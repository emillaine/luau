// This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
#include "Luau/TypeInfer.h"
#include "Luau/Type.h"

#include "Fixture.h"

#include "ScopedFlags.h"
#include "doctest.h"

using namespace Luau;

LUAU_FASTFLAG(LuauCheckFunctionStatementTypes)
LUAU_FASTFLAG(DebugLuauForceOldSolver)
LUAU_FASTFLAG(LuauNewTypePathErrorMessages)

TEST_SUITE_BEGIN("IntersectionTypes");

TEST_CASE_FIXTURE(Fixture, "select_correct_union_fn")
{
    CheckResult result = check(R"(
        type A = (number) -> (string)
        type B = (string) -> (number)

        function foo(f: A & B)
            return f(10), f("a")
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("(((number) -> string) & ((string) -> number)) -> (string, number)", toString(requireType("foo")));
}

TEST_CASE_FIXTURE(Fixture, "table_combines")
{
    CheckResult result = check(R"(
        type A={a:number}
        type B={b:string}

        const c:A & B = {a=10, b="s"}
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "table_combines_missing")
{
    CheckResult result = check(R"(
        type A={a:number}
        type B={b:string}

        const c:A & B = {a=10}
    )");

    REQUIRE(result.errors.size() == 1);
}

TEST_CASE_FIXTURE(Fixture, "impossible_type")
{
    CheckResult result = check(R"(
        const c:number&string = 10
    )");

    REQUIRE(result.errors.size() == 1);
}

TEST_CASE_FIXTURE(Fixture, "table_extra_ok")
{
    CheckResult result = check(R"(
        type A={a:number}
        type B={b:string}

        function f(t: A & B): A
            return t
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "fx_intersection_as_argument")
{
    CheckResult result = check(R"(
        type A = (number) -> (string)
        type B = (string) -> (number)
        type C = (A) -> (number)

        function foo(f: A & B, g: C)
            return g(f)
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "fx_union_as_argument_fails")
{
    CheckResult result = check(R"(
        type A = (number) -> (string)
        type B = (string) -> (number)
        type C = (A) -> (number)

        function foo(f: A | B, g: C)
            return g(f)
        end
    )");

    REQUIRE(!result.errors.empty());
}

TEST_CASE_FIXTURE(Fixture, "argument_is_intersection")
{
    CheckResult result = check(R"(
        type A = (number | boolean) -> number

        function foo(f: A)
            f(5)
            f(true)
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "should_still_pick_an_overload_whose_arguments_are_unions")
{
    CheckResult result = check(R"(
        type A = (number) -> string
        type B = (string) -> number

        function foo(f: A & B)
            return f(1), f("five")
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("(((number) -> string) & ((string) -> number)) -> (string, number)", toString(requireType("foo")));
}

TEST_CASE_FIXTURE(Fixture, "propagates_name")
{
    const std::string code = R"(
        type A={a:number}
        type B={b:string}

        function f(t: A & B)
            return t
        end
    )";

    const std::string expected = R"(
        type A={a:number}
        type B={b:string}

        function f(t: A & B): A&B
            return t
        end
    )";

    CHECK_EQ(expected, decorateWithTypes(code));
}

TEST_CASE_FIXTURE(Fixture, "index_on_an_intersection_type_with_property_guaranteed_to_exist")
{
    CheckResult result = check(R"(
        type A = {x: {y: number}}
        type B = {x: {y: number}}

        function f(t: A & B)
            return t.x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    if (!FFlag::DebugLuauForceOldSolver)
        CHECK("(A & B) -> { y: number }" == toString(requireType("f")));
    else
        CHECK("(A & B) -> { y: number } & { y: number }" == toString(requireType("f")));
}

TEST_CASE_FIXTURE(Fixture, "index_on_an_intersection_type_works_at_arbitrary_depth")
{
    CheckResult result = check(R"(
        type A = {x: {y: {z: {thing: string}}}}
        type B = {x: {y: {z: {thing: string}}}}

        function f(t: A & B)
            return t.x.y.z.thing
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    if (!FFlag::DebugLuauForceOldSolver)
        CHECK_EQ("(A & B) -> string", toString(requireType("f")));
    else
        CHECK_EQ("(A & B) -> string & string", toString(requireType("f")));
}

TEST_CASE_FIXTURE(Fixture, "index_on_an_intersection_type_with_mixed_types")
{
    CheckResult result = check(R"(
        type A = {x: number}
        type B = {x: string}

        function f(t: A & B)
            return t.x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    if (!FFlag::DebugLuauForceOldSolver)
        CHECK_EQ("(A & B) -> never", toString(requireType("f")));
    else
        CHECK_EQ("(A & B) -> number & string", toString(requireType("f")));
}

TEST_CASE_FIXTURE(Fixture, "index_on_an_intersection_type_with_one_part_missing_the_property")
{
    CheckResult result = check(R"(
        type A = {x: number}
        type B = {}

        function f(t: A & B)
            return t.x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("(A & B) -> number", toString(requireType("f")));
}

TEST_CASE_FIXTURE(Fixture, "index_on_an_intersection_type_with_one_property_of_type_any")
{
    CheckResult result = check(R"(
        type A = {y: number}
        type B = {x: any}

        function f(t: A & B)
            return t.x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("(A & B) -> any", toString(requireType("f")));
}

TEST_CASE_FIXTURE(Fixture, "index_on_an_intersection_type_with_all_parts_missing_the_property")
{
    CheckResult result = check(R"(
        type A = {}
        type B = {}

        function f(t: A & B)
            const x = t.x
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    UnknownProperty* up = get<UnknownProperty>(result.errors[0]);
    REQUIRE_MESSAGE(up, result.errors[0].data);
    CHECK_EQ(up->key, "x");
}

TEST_CASE_FIXTURE(Fixture, "table_intersection_write")
{
    CheckResult result = check(R"(
        type X = { x: number }
        type XY = X & { y: number }

        function f(t: XY)
            t.x = 10
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    result = check(R"(
        type X = {}
        type XY = X & { x: number, y: number }

        function f(t: XY)
            t.x = 10
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    result = check(R"(
        type X = { x: number }
        type Y = { y: number }
        type XY = X & Y

        function f(t: XY)
            t.x = 10
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    result = check(R"(
        type A = { x: {y: number} }
        type B = { x: {y: number} }

        function f(t: A & B)
            t.x = { y = 4 }
            t.x.y = 40
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "table_intersection_write_sealed")
{
    CheckResult result = check(R"(
        type X = { x: number }
        type Y = { y: number }
        type XY = X & Y

        function f(t: XY)
            t.z = 10
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    auto e = toString(result.errors[0]);
    CHECK_EQ("Cannot add property 'z' to table 'X & Y'", e);
}

TEST_CASE_FIXTURE(Fixture, "table_intersection_write_sealed_indirect")
{
    ScopedFastFlag _{FFlag::LuauCheckFunctionStatementTypes, true};

    CheckResult result = check(R"(
        type X = { x: (number) -> number }
        type Y = { y: (string) -> string }

        type XY = X & Y

        function f(t: XY)
            function t.z(a:number) return a * 10 end
            function t:y(a:number) return a * 10 end
            function t:w(a:number) return a * 10 end
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(4, result);
    if (!FFlag::DebugLuauForceOldSolver)
    {
        CHECK_EQ(toString(result.errors[0]), "Cannot add property 'z' to table 'X & Y'");
        auto err1 = get<TypeMismatch>(result.errors[1]);
        REQUIRE(err1);
        CHECK_EQ("number", toString(err1->givenType));
        CHECK_EQ("string", toString(err1->wantedType));
        auto err2 = get<TypeMismatch>(result.errors[2]);
        REQUIRE(err2);
        CHECK_EQ("(string, number) -> string", toString(err2->givenType));
        CHECK_EQ("(string) -> string", toString(err2->wantedType));
        CHECK_EQ(toString(result.errors[3]), "Cannot add property 'w' to table 'X & Y'");
    }
    else
    {
        const std::string expected = "Expected this to be\n\t"
                                     "'(string) -> string'"
                                     "\nbut got\n\t"
                                     "'(string, number) -> string'"
                                     "\ncaused by:\n"
                                     "  Argument count mismatch. Function expects 2 arguments, but only 1 is specified";

        CHECK_EQ(expected, toString(result.errors[0]));
        CHECK_EQ(toString(result.errors[1]), "Cannot add property 'z' to table 'X & Y'");
        CHECK_EQ(toString(result.errors[2]), "Expected this to be 'string', but got 'number'");
        CHECK_EQ(toString(result.errors[3]), "Cannot add property 'w' to table 'X & Y'");
    }
}

TEST_CASE_FIXTURE(Fixture, "table_write_sealed_indirect")
{
    DOES_NOT_PASS_NEW_SOLVER_GUARD();
    // After normalization, previous 'table_intersection_write_sealed_indirect' is identical to this one
    CheckResult result = check(R"(
    type XY = { x: (number) -> number, y: (string) -> string }

    const xy : XY = {
        x = function(a: number) return -a end,
        y = function(a: string) return a .. "b" end
    }
    function xy.z(a:number) return a * 10 end
    function xy:y(a:number) return a * 10 end
    function xy:w(a:number) return a * 10 end
    )");

    LUAU_REQUIRE_ERROR_COUNT(4, result);
    const std::string expected = "Expected this to be\n\t"
                                 "'(string) -> string'"
                                 "\nbut got\n\t"
                                 "'(string, number) -> string'"
                                 "\ncaused by:\n"
                                 "  Argument count mismatch. Function expects 2 arguments, but only 1 is specified";
    CHECK_EQ(expected, toString(result.errors[0]));

    CHECK_EQ(toString(result.errors[1]), "Cannot add property 'z' to table 'XY'");
    CHECK_EQ(toString(result.errors[2]), "Expected this to be 'string', but got 'number'");
    CHECK_EQ(toString(result.errors[3]), "Cannot add property 'w' to table 'XY'");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_intersection_setmetatable")
{
    CheckResult result = check(R"(
        function f(t: {} & {})
            setmetatable(t, {})
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "error_detailed_intersection_part")
{
    CheckResult result = check(R"(
type X = { x: number }
type Y = { y: number }
type Z = { z: number }
type XYZ = X & Y & Z
const a: XYZ = 3
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    if (!FFlag::DebugLuauForceOldSolver)
    {
        const std::string expected = FFlag::LuauNewTypePathErrorMessages
                                         ? "Expected this to be 'X & Y & Z', but got 'number'; \n"
                                           "this is because \n\t"
                                           " * `number` is not a subtype of `X`\n\t"
                                           " * `number` is not a subtype of `Y`\n\t"
                                           " * `number` is not a subtype of `Z`"
                                         : "Expected this to be 'X & Y & Z', but got 'number'; \n"
                                           "this is because \n\t"
                                           " * the 1st component of the intersection is `X`, and `number` is not a subtype of `X`\n\t"
                                           " * the 2nd component of the intersection is `Y`, and `number` is not a subtype of `Y`\n\t"
                                           " * the 3rd component of the intersection is `Z`, and `number` is not a subtype of `Z`";
        CHECK_EQ(expected, toString(result.errors[0]));
    }
    else
    {
        const std::string expected = R"(Expected this to be 'X & Y & Z', but got 'number'
caused by:
  Not all intersection parts are compatible.
Expected this to be 'X', but got 'number')";

        CHECK_EQ(expected, toString(result.errors[0]));
    }
}

TEST_CASE_FIXTURE(Fixture, "error_detailed_intersection_all")
{
    CheckResult result = check(R"(
type X = { x: number }
type Y = { y: number }
type Z = { z: number }
type XYZ = X & Y & Z

function f(a: XYZ): number
    return a
end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    if (!FFlag::DebugLuauForceOldSolver)
    {
        const std::string expected = FFlag::LuauNewTypePathErrorMessages
                                         ? "Expected this to be 'number', but got 'X & Y & Z'; \n"
                                           "this is because \n\t"
                                           " * `X` is not a subtype of `number`\n\t"
                                           " * `Y` is not a subtype of `number`\n\t"
                                           " * `Z` is not a subtype of `number`"
                                         : "Expected this to be 'number', but got 'X & Y & Z'; \n"
                                           "this is because \n\t"
                                           " * the 1st component of the intersection is `X`, which is not a subtype of `number`\n\t"
                                           " * the 2nd component of the intersection is `Y`, which is not a subtype of `number`\n\t"
                                           " * the 3rd component of the intersection is `Z`, which is not a subtype of `number`";
        CHECK_EQ(expected, toString(result.errors[0]));
    }
    else
        CHECK_EQ(toString(result.errors[0]), R"(Expected this to be 'number', but got 'X & Y & Z'; none of the intersection parts are compatible)");
}

TEST_CASE_FIXTURE(Fixture, "overload_is_not_a_function")
{
    check(R"(
--!nonstrict
function _(...):((typeof(not _))&(typeof(not _)))&((typeof(not _))&(typeof(not _)))
_(...)(setfenv,_,not _,"")[_] = null
end
do end
_(...)(...,setfenv,_):_G()
)");
}

TEST_CASE_FIXTURE(Fixture, "no_stack_overflow_from_flattenintersection")
{
    CheckResult result = check(R"(
        const l0,l0 = null, null
        repeat
        type t0 = ((any)|((any)&((any)|((any)&((any)|(any))))))&(t0)
        function _(l0):(t0)&(t0)
            while null do
            end
        end
        until _(_)(_)._
    )");

    LUAU_REQUIRE_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "intersect_bool_and_false")
{
    CheckResult result = check(R"(
        function f(x: boolean & false)
            const y : false = x -- OK
            const z : true = x  -- Not OK
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    if (!FFlag::DebugLuauForceOldSolver)
    {
        const std::string expected = FFlag::LuauNewTypePathErrorMessages
                                         ? "Expected this to be 'true', but got 'boolean & false'; \n"
                                           "this is because \n\t"
                                           " * `boolean` is not a subtype of `true`\n\t"
                                           " * `false` is not a subtype of `true`"
                                         : "Expected this to be 'true', but got 'boolean & false'; \n"
                                           "this is because \n\t"
                                           " * the 1st component of the intersection is `boolean`, which is not a subtype of `true`\n\t"
                                           " * the 2nd component of the intersection is `false`, which is not a subtype of `true`";
        CHECK_EQ(expected, toString(result.errors[0]));
    }
    else
        CHECK_EQ(toString(result.errors[0]), "Expected this to be 'true', but got 'boolean & false'; none of the intersection parts are compatible");
}

TEST_CASE_FIXTURE(Fixture, "intersect_false_and_bool_and_false")
{
    CheckResult result = check(R"(
        function f(x: false & (boolean & false))
            const y : false = x -- OK
            const z : true = x  -- Not OK
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    // TODO: odd stringification of `false & (boolean & false)`.)
    if (!FFlag::DebugLuauForceOldSolver)
    {
        const std::string expected = FFlag::LuauNewTypePathErrorMessages
                                         ? "Expected this to be 'true', but got 'boolean & false & false'; \n"
                                           "this is because \n\t"
                                           " * `boolean` is not a subtype of `true`\n\t"
                                           " * `false` is not a subtype of `true`"
                                         : "Expected this to be 'true', but got 'boolean & false & false'; \n"
                                           "this is because \n\t"
                                           " * the 1st component of the intersection is `false`, which is not a subtype of `true`\n\t"
                                           " * the 2nd component of the intersection is `boolean`, which is not a subtype of `true`\n\t"
                                           " * the 3rd component of the intersection is `false`, which is not a subtype of `true`";
        CHECK_EQ(expected, toString(result.errors[0]));
    }
    else
        CHECK_EQ(
            toString(result.errors[0]), "Expected this to be 'true', but got 'boolean & false & false'; none of the intersection parts are compatible"
        );
}

TEST_CASE_FIXTURE(Fixture, "intersect_saturate_overloaded_functions")
{
    CheckResult result = check(R"(
        function foo(x: ((number?) -> number?) & ((string?) -> string?))
            const y : (null) -> null = x -- Not OK (fixed in DCR)
            const z : (number) -> number = x -- Not OK
        end
    )");

    if (!FFlag::DebugLuauForceOldSolver)
    {
        // clang-format off
        const std::string expected1 = FFlag::LuauNewTypePathErrorMessages
            ?
                "Expected this to be\n"
                "\t'(null) -> null'\n"
                "but got\n"
                "\t'((number?) -> number?) & ((string?) -> string?)'; \n"
                "this is because \n"
                "\t * Expected the return type to be `null`, but got `number`\n"
                "\t * Expected the return type to be `null`, but got `string`"
            :
                "Expected this to be\n"
                "\t'(null) -> null'\n"
                "but got\n"
                "\t'((number?) -> number?) & ((string?) -> string?)'; \n"
                "this is because \n"
                "\t * in the 1st component of the intersection, the function returns the 1st entry in the type pack which has the 1st component of the union as `number` and it returns the 1st entry in the type pack is `null`, and `number` is not a subtype of `null`\n"
                "\t * in the 2nd component of the intersection, the function returns the 1st entry in the type pack which has the 1st component of the union as `string` and it returns the 1st entry in the type pack is `null`, and `string` is not a subtype of `null`"
        ;
        const std::string expected2 = FFlag::LuauNewTypePathErrorMessages
            ?
                "Expected this to be\n"
                "\t'(number) -> number'\n"
                "but got\n"
                "\t'((number?) -> number?) & ((string?) -> string?)'; \n"
                "this is because \n"
                "\t * Expected the 1st parameter to be a supertype of `number`, but got `string?`\n"
                "\t * Expected the return type to be `number`, but got `null`\n"
                "\t * Expected the return type to be `number`, but got `string`"
            :
                "Expected this to be\n"
                "	'(number) -> number'\n"
                "but got\n"
                "	'((number?) -> number?) & ((string?) -> string?)';\n"
                "this is because\n"
                "	 * in the 1st component of the intersection, the function returns the 1st entry in the type pack which has the 2nd component of the union as `null` and it returns the 1st entry in the type pack is `number`, and `null` is not a subtype of `number`\n"
                "	 * in the 2nd component of the intersection, the function returns the 1st entry in the type pack which has the 1st component of the union as `string` and it returns the 1st entry in the type pack is `number`, and `string` is not a subtype of `number`\n"
                "	 * in the 2nd component of the intersection, the function returns the 1st entry in the type pack which has the 2nd component of the union as `null` and it returns the 1st entry in the type pack is `number`, and `null` is not a subtype of `number`\n"
                "	 * in the 2nd component of the intersection, the function takes the 1st entry in the type pack which is `string?` and it takes the 1st entry in the type pack is `number`, and `string?` is not a supertype of `number`"
        ;
        // clang-format on

        CHECK_LONG_STRINGS_EQ(expected1, toString(result.errors.at(0)));
        CHECK_LONG_STRINGS_EQ(expected2, toString(result.errors.at(1)));
    }
    else
    {
        LUAU_REQUIRE_ERROR_COUNT(1, result);
        const std::string expected = R"(Expected this to be
	'(number) -> number'
but got
	'((number?) -> number?) & ((string?) -> string?)'; none of the intersection parts are compatible)";
        CHECK_EQ(expected, toString(result.errors[0]));
    }
}

TEST_CASE_FIXTURE(Fixture, "union_saturate_overloaded_functions")
{
    // CLI-116474 Semantic subtyping of assignments needs to decide how to interpret intersections of functions
    DOES_NOT_PASS_NEW_SOLVER_GUARD();

    CheckResult result = check(R"(
        function f(x: ((number) -> number) & ((string) -> string))
            const y : ((number | string) -> (number | string)) = x -- OK
            const z : ((number | boolean) -> (number | boolean)) = x -- Not OK
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    const std::string expected = "Expected this to be\n\t"
                                 "'(boolean | number) -> boolean | number'"
                                 "\nbut got\n\t"
                                 "'((number) -> number) & ((string) -> string)'"
                                 "; none of the intersection parts are compatible";
    CHECK_EQ(expected, toString(result.errors[0]));
}

TEST_CASE_FIXTURE(Fixture, "intersection_of_tables")
{
    CheckResult result = check(R"(
        function f(x: { p : number?, q : string? } & { p : number?, q : number?, r : number? })
            const y : { p : number?, q : null, r : number? } = x -- OK
            const z : { p : null } = x -- Not OK
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    if (!FFlag::DebugLuauForceOldSolver)
    {
        const std::string expected =
            FFlag::LuauNewTypePathErrorMessages
                ? "Expected this to be\n\t'{ p: null }'\nbut got\n\t'{ p: number?, q: number?, r: number? } & { p: number?, q: string? }'"
                  "; \n"
                  "Expected property `p` to be exactly `null`, but got `number`"
                : "Expected this to be\n\t'{ p: null }'\nbut got\n\t'{ p: number?, q: number?, r: number? } & { p: number?, q: string? }'"
                  "; \nthis is because \n\t"
                  " * in the 1st component of the intersection, accessing `p` has the 1st component of the union as `number` and "
                  "accessing `p` results in `null`, and `number` is not exactly `null`\n\t"
                  " * in the 2nd component of the intersection, accessing `p` has the 1st component of the union as `number` and "
                  "accessing `p` results in `null`, and `number` is not exactly `null`";
        CHECK_EQ(expected, toString(result.errors[0]));
    }
    else
    {
        const std::string expected =
            R"(Expected this to be '{ p: null }', but got '{ p: number?, q: number?, r: number? } & { p: number?, q: string? }'; none of the intersection parts are compatible)";
        CHECK_EQ(expected, toString(result.errors[0]));
    }
}

TEST_CASE_FIXTURE(Fixture, "intersection_of_tables_with_top_properties")
{
    CheckResult result = check(R"(
        function f(x : { p : number?, q : any } & { p : unknown, q : string? })
            const y : { p : number?, q : string? } = x -- OK
            const z : { p : string?, q : number? } = x -- Not OK
        end
    )");

    if (!FFlag::DebugLuauForceOldSolver)
    {
        // clang-format off
        const std::string expected = FFlag::LuauNewTypePathErrorMessages
            ?
                "Expected this to be\n"
                "\t'{ p: string?, q: number? }'\n"
                "but got\n"
                "\t'{ p: number?, q: any } & { p: unknown, q: string? }'; \n"
                "this is because \n"
                "\t * Expected property `p` to be exactly `string?`, but got `number`\n"
                "\t * Expected property `p` to be exactly `string?`, but got `unknown`\n"
                "\t * Expected property `p` to be exactly `string`, but got `number?`\n"
                "\t * Expected property `q` to be exactly `number?`, but got `any`\n"
                "\t * Expected property `q` to be exactly `number?`, but got `string`\n"
                "\t * Expected property `q` to be exactly `number`, but got `string?`"
            :
                "Expected this to be\n"
                "\t'{ p: string?, q: number? }'\n"
                "but got\n"
                "\t'{ p: number?, q: any } & { p: unknown, q: string? }'; \n"
                "this is because \n"
                "\t* in the 1st component of the intersection, accessing `p` has the 1st component of the union as `number` and accessing `p` results in `string?`, and `number` is not exactly `string?`\n"
                "\t* in the 1st component of the intersection, accessing `p` results in `number?` and accessing `p` has the 1st component of the union as `string`, and `number?` is not exactly `string`\n"
                "\t* in the 1st component of the intersection, accessing `q` results in `any` and accessing `q` results in `number?`, and `any` is not exactly `number?`\n"
                "\t* in the 2nd component of the intersection, accessing `p` results in `unknown` and accessing `p` results in `string?`, and `unknown` is not exactly `string?`\n"
                "\t* in the 2nd component of the intersection, accessing `q` has the 1st component of the union as `string` and accessing `q` results in `number?`, and `string` is not exactly `number?`\n"
                "\t* in the 2nd component of the intersection, accessing `q` results in `string?` and accessing `q` has the 1st component of the union as `number`, and `string?` is not exactly `number`"
        ;
        // clang-format on

        CHECK_LONG_STRINGS_EQ(expected, toString(result.errors.at(0)));
    }
    else
    {
        LUAU_REQUIRE_ERROR_COUNT(1, result);
        const std::string expected = R"(Expected this to be
	'{ p: string?, q: number? }'
but got
	'{ p: number?, q: any } & { p: unknown, q: string? }'; none of the intersection parts are compatible)";
        CHECK_EQ(expected, toString(result.errors[0]));
    }
}

TEST_CASE_FIXTURE(Fixture, "intersection_of_tables_with_never_properties")
{
    CheckResult result = check(R"(
        function f(x : { p : number?, q : never } & { p : never, q : string? })
            const y : { p : never, q : never } = x -- OK
            const z : never = x -- OK
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "overloaded_functions_returning_intersections")
{
    CheckResult result = check(R"(
        function f(x : ((number?) -> ({ p : number } & { q : number })) & ((string?) -> ({ p : number } & { r : number })))
            const y : (null) -> { p : number, q : number, r : number} = x -- OK
            const z : (number?) -> { p : number, q : number, r : number} = x -- Not OK
        end
    )");

    if (!FFlag::DebugLuauForceOldSolver)
    {
        LUAU_REQUIRE_ERROR_COUNT(2, result);
        const std::string expected1 =
            FFlag::LuauNewTypePathErrorMessages
                ? "Expected this to be\n\t"
                  "'(null) -> { p: number, q: number, r: number }'"
                  "\nbut got\n\t"
                  "'((number?) -> { p: number } & { q: number }) & ((string?) -> { p: number } & { r: number })'"
                  "; \nthis is because \n\t"
                  " * Expected the return type to be `{ p: number, q: number, r: number }`, but got `{ p: number }`\n\t"
                  " * Expected the return type to be `{ p: number, q: number, r: number }`, but got `{ q: number }`\n\t"
                  " * Expected the return type to be `{ p: number, q: number, r: number }`, but got `{ r: number }`"
                : "Expected this to be\n"
                  "	'(null) -> { p: number, q: number, r: number }'\n"
                  "but got\n"
                  "	'((number?) -> { p: number } & { q: number }) & ((string?) -> { p: number } & { r: number })'; \n"
                  "this is because \n"
                  "	 * in the 1st component of the intersection, the function returns the 1st entry in the type pack which has the 1st component of "
                  "the intersection as `{ p: number }` and it returns the 1st entry in the type pack is `{ p: number, q: number, r: number }`, and "
                  "`{ p: number }` is not a subtype of `{ p: number, q: number, r: number }`\n"
                  "	 * in the 1st component of the intersection, the function returns the 1st entry in the type pack which has the 2nd component of "
                  "the intersection as `{ q: number }` and it returns the 1st entry in the type pack is `{ p: number, q: number, r: number }`, and "
                  "`{ q: number }` is not a subtype of `{ p: number, q: number, r: number }`\n"
                  "	 * in the 2nd component of the intersection, the function returns the 1st entry in the type pack which has the 1st component of "
                  "the intersection as `{ p: number }` and it returns the 1st entry in the type pack is `{ p: number, q: number, r: number }`, and "
                  "`{ p: number }` is not a subtype of `{ p: number, q: number, r: number }`\n"
                  "	 * in the 2nd component of the intersection, the function returns the 1st entry in the type pack which has the 2nd component of "
                  "the intersection as `{ r: number }` and it returns the 1st entry in the type pack is `{ p: number, q: number, r: number }`, and "
                  "`{ r: number }` is not a subtype of `{ p: number, q: number, r: number }`";
        const std::string expected2 =
            FFlag::LuauNewTypePathErrorMessages
                ? "Expected this to be\n\t"
                  "'(number?) -> { p: number, q: number, r: number }'"
                  "\nbut got\n\t"
                  "'((number?) -> { p: number } & { q: number }) & ((string?) -> { p: number } & { r: number })'"
                  "; \nthis is because \n\t"
                  " * Expected the 1st parameter to be a supertype of `number`, but got `string?`\n\t"
                  " * Expected the return type to be `{ p: number, q: number, r: number }`, but got `{ p: number }`\n\t"
                  " * Expected the return type to be `{ p: number, q: number, r: number }`, but got `{ q: number }`\n\t"
                  " * Expected the return type to be `{ p: number, q: number, r: number }`, but got `{ r: number }`"
                : "Expected this to be\n"
                  "\t'(number?) -> { p: number, q: number, r: number }'\n"
                  "but got\n"
                  "\t'((number?) -> { p: number } & { q: number }) & ((string?) -> { p: number } & { r: number })'; \n"
                  "this is because \n"
                  "\t* in the 1st component of the intersection, the function returns the 1st entry in the type pack which has the 1st component of "
                  "the intersection as `{ p: number }` and it returns the 1st entry in the type pack is `{ p: number, q: number, r: number }`, and "
                  "`{ p: number }` is not a subtype of `{ p: number, q: number, r: number }`\n"
                  "\t* in the 1st component of the intersection, the function returns the 1st entry in the type pack which has the 2nd component of "
                  "the intersection as `{ q: number }` and it returns the 1st entry in the type pack is `{ p: number, q: number, r: number }`, and "
                  "`{ q: number }` is not a subtype of `{ p: number, q: number, r: number }`\n"
                  "\t* in the 2nd component of the intersection, the function returns the 1st entry in the type pack which has the 1st component of "
                  "the intersection as `{ p: number }` and it returns the 1st entry in the type pack is `{ p: number, q: number, r: number }`, and "
                  "`{ p: number }` is not a subtype of `{ p: number, q: number, r: number }`\n"
                  "\t* in the 2nd component of the intersection, the function returns the 1st entry in the type pack which has the 2nd component of "
                  "the intersection as `{ r: number }` and it returns the 1st entry in the type pack is `{ p: number, q: number, r: number }`, and "
                  "`{ r: number }` is not a subtype of `{ p: number, q: number, r: number }`\n"
                  "\t* in the 2nd component of the intersection, the function takes the 1st entry in the type pack which is `string?` and it takes "
                  "the 1st entry in the type pack has the 1st component of the union as `number`, and `string?` is not a supertype of `number`";

        CHECK_LONG_STRINGS_EQ(expected1, toString(result.errors.at(0)));
        CHECK_LONG_STRINGS_EQ(expected2, toString(result.errors.at(1)));
    }
    else
    {
        LUAU_REQUIRE_ERROR_COUNT(1, result);
        CHECK_EQ(
            R"(Expected this to be
	'(number?) -> { p: number, q: number, r: number }'
but got
	'((number?) -> { p: number } & { q: number }) & ((string?) -> { p: number } & { r: number })'; none of the intersection parts are compatible)",
            toString(result.errors[0])
        );
    }
}

TEST_CASE_FIXTURE(Fixture, "overloaded_functions_mentioning_generic")
{
    CheckResult result = check(R"(
        function f<a>()
            function g(x : ((number?) -> (a | number)) & ((string?) -> (a | string)))
                const y : (null) -> a = x -- OK
                const z : (number?) -> a = x -- Not OK
            end
        end
    )");
    if (!FFlag::DebugLuauForceOldSolver)
    {
        LUAU_REQUIRE_ERROR_COUNT(0, result);
    }
    else
    {
        LUAU_REQUIRE_ERROR_COUNT(1, result);
        const std::string expected = R"(Expected this to be
	'(number?) -> a'
but got
	'((number?) -> a | number) & ((string?) -> a | string)'; none of the intersection parts are compatible)";
        CHECK_EQ(expected, toString(result.errors[0]));
    }
}

TEST_CASE_FIXTURE(Fixture, "overloaded_functions_mentioning_generics")
{
    CheckResult result = check(R"(
        function f<a,b,c>()
            function g(x : ((a?) -> (a | b)) & ((c?) -> (b | c)))
                const y : (null) -> ((a & c) | b) = x -- OK
                const z : (a?) -> ((a & c) | b) = x -- Not OK
            end
        end
    )");


    if (!FFlag::DebugLuauForceOldSolver)
    {
        LUAU_REQUIRE_NO_ERRORS(result);
    }
    else
    {
        LUAU_REQUIRE_ERROR_COUNT(1, result);
        const std::string expected = R"(Expected this to be
	'(a?) -> (a & c) | b'
but got
	'((a?) -> a | b) & ((c?) -> b | c)'; none of the intersection parts are compatible)";
        CHECK_EQ(expected, toString(result.errors[0]));
    }
}

TEST_CASE_FIXTURE(Fixture, "overloaded_functions_mentioning_generic_packs")
{
    CheckResult result = check(R"(
        function f<a...,b...>()
            function g(x : ((number?, a...) -> (number?, b...)) & ((string?, a...) -> (string?, b...)))
                const y : ((null, a...) -> (null, b...)) = x -- OK in the old solver, not OK in the new
                const z : ((null, b...) -> (null, a...)) = x -- Not OK
                const w : ((number?, a...) -> (number?, b...)) = x -- OK in both solvers
            end
        end
    )");
    if (!FFlag::DebugLuauForceOldSolver)
    {
        LUAU_REQUIRE_ERROR_COUNT(2, result);
        const TypeMismatch* tm1 = get<TypeMismatch>(result.errors[0]);
        CHECK(tm1);
        CHECK_EQ(toString(tm1->wantedType), "(null, a...) -> (null, b...)");
        CHECK_EQ(toString(tm1->givenType), "((number?, a...) -> (number?, b...)) & ((string?, a...) -> (string?, b...))");
        const TypeMismatch* tm2 = get<TypeMismatch>(result.errors[1]);
        CHECK(tm2);
        CHECK_EQ(toString(tm2->wantedType), "(null, b...) -> (null, a...)");
        CHECK_EQ(toString(tm2->givenType), "((number?, a...) -> (number?, b...)) & ((string?, a...) -> (string?, b...))");

        const std::string expected1 =
            FFlag::LuauNewTypePathErrorMessages
                ? "Expected this to be\n\t"
                  "'(null, a...) -> (null, b...)'"
                  "\nbut got\n\t"
                  "'((number?, a...) -> (number?, b...)) & ((string?, a...) -> (string?, b...))'"
                  "; \nthis is because \n\t"
                  " * Expected the 1st return value to be `null`, but got `number`\n\t"
                  " * Expected the 1st return value to be `null`, but got `string`"
                : "Expected this to be\n\t"
                  "'(null, a...) -> (null, b...)'"
                  "\nbut got\n\t"
                  "'((number?, a...) -> (number?, b...)) & ((string?, a...) -> (string?, b...))'"
                  "; \nthis is because \n\t"
                  " * in the 1st component of the intersection, the function returns the 1st entry in the type pack which has the 1st component of "
                  "the "
                  "union as `number` and it returns the 1st entry in the type pack is `null`, and `number` is not a subtype of `null`\n\t"
                  " * in the 2nd component of the intersection, the function returns the 1st entry in the type pack which has the 1st component of "
                  "the "
                  "union as `string` and it returns the 1st entry in the type pack is `null`, and `string` is not a subtype of `null`";
        const std::string expected2 =
            FFlag::LuauNewTypePathErrorMessages
                ? "Expected this to be\n\t"
                  "'(null, b...) -> (null, a...)'"
                  "\nbut got\n\t"
                  "'((number?, a...) -> (number?, b...)) & ((string?, a...) -> (string?, b...))'"
                  "; \nthis is because \n\t"
                  " * Expected the 1st return value to be `null`, but got `number`\n\t"
                  " * Expected the 1st return value to be `null`, but got `string`\n\t"
                  " * Expected the parameter type pack tail to be a supertype of `b...`, but got `a...`\n\t"
                  " * Expected the return type pack tail to be `a...`, but got `b...`"
                : "Expected this to be\n\t"
                  "'(null, b...) -> (null, a...)'"
                  "\nbut got\n\t"
                  "'((number?, a...) -> (number?, b...)) & ((string?, a...) -> (string?, b...))'"
                  "; \nthis is because \n\t"
                  " * in the 1st component of the intersection, the function returns a tail of `b...` and it returns a tail of `a...`, and `b...` is "
                  "not a "
                  "subtype of `a...`\n\t"
                  " * in the 1st component of the intersection, the function returns the 1st entry in the type pack which has the 1st component of "
                  "the "
                  "union as `number` and it returns the 1st entry in the type pack is `null`, and `number` is not a subtype of `null`\n\t"
                  " * in the 1st component of the intersection, the function takes a tail of `a...` and it takes a tail of `b...`, and `a...` is not "
                  "a "
                  "supertype of `b...`\n\t"
                  " * in the 2nd component of the intersection, the function returns a tail of `b...` and it returns a tail of `a...`, and `b...` is "
                  "not a "
                  "subtype of `a...`\n\t"
                  " * in the 2nd component of the intersection, the function returns the 1st entry in the type pack which has the 1st component of "
                  "the "
                  "union as `string` and it returns the 1st entry in the type pack is `null`, and `string` is not a subtype of `null`\n\t"
                  " * in the 2nd component of the intersection, the function takes a tail of `a...` and it takes a tail of `b...`, and `a...` is not "
                  "a "
                  "supertype of `b...`";

        CHECK_EQ(expected1, toString(result.errors[0]));
        CHECK_EQ(expected2, toString(result.errors[1]));
    }
    else
    {
        LUAU_REQUIRE_ERROR_COUNT(1, result);
        const std::string expected = R"(Expected this to be
	'(null, b...) -> (null, a...)'
but got
	'((number?, a...) -> (number?, b...)) & ((string?, a...) -> (string?, b...))'; none of the intersection parts are compatible)";
        CHECK_EQ(expected, toString(result.errors[0]));
    }
}

TEST_CASE_FIXTURE(Fixture, "overloadeded_functions_with_unknown_result")
{
    // CLI-116474 Semantic subtyping of assignments needs to decide how to interpret intersections of functions
    DOES_NOT_PASS_NEW_SOLVER_GUARD();

    CheckResult result = check(R"(
        function f<a...,b...>()
            function g(x : ((number) -> number) & ((null) -> unknown))
                const y : (number?) -> unknown = x -- OK
                const z : (number?) -> number? = x -- Not OK
            end
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    const std::string expected = "Expected this to be\n\t"
                                 "'(number?) -> number?'"
                                 "\nbut got\n\t"
                                 "'((null) -> unknown) & ((number) -> number)'"
                                 "; none of the intersection parts are compatible";
    CHECK_EQ(expected, toString(result.errors[0]));
}

TEST_CASE_FIXTURE(Fixture, "overloadeded_functions_with_unknown_arguments")
{
    // CLI-116474 Semantic subtyping of assignments needs to decide how to interpret intersections of functions
    DOES_NOT_PASS_NEW_SOLVER_GUARD();

    CheckResult result = check(R"(
        function f<a...,b...>()
            function g(x : ((number) -> number?) & ((unknown) -> string?))
                const y : (number) -> null = x -- OK
                const z : (number?) -> null = x -- Not OK
            end
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    const std::string expected = "Expected this to be\n\t"
                                 "'(number?) -> null'"
                                 "\nbut got\n\t"
                                 "'((number) -> number?) & ((unknown) -> string?)'"
                                 "; none of the intersection parts are compatible";
    CHECK_EQ(expected, toString(result.errors[0]));
}

TEST_CASE_FIXTURE(Fixture, "overloadeded_functions_with_never_result")
{
    CheckResult result = check(R"(
    function f<a...,b...>()
        function g(x : ((number) -> number) & ((null) -> never))
            const y : (number?) -> number = x -- OK
            const z : (number?) -> never = x -- Not OK
        end
    end
    )");

    if (!FFlag::DebugLuauForceOldSolver)
    {
        const std::string expected1 =
            FFlag::LuauNewTypePathErrorMessages
                ? "Expected this to be\n\t"
                  "'(number?) -> number'"
                  "\nbut got\n\t"
                  "'((null) -> never) & ((number) -> number)'"
                  "; \nthis is because \n\t"
                  " * Expected the 1st parameter to be a supertype of `null`, but got `number`\n\t"
                  " * Expected the 1st parameter to be a supertype of `number`, but got `null`"
                : "Expected this to be\n\t"
                  "'(number?) -> number'"
                  "\nbut got\n\t"
                  "'((null) -> never) & ((number) -> number)'"
                  "; \nthis is because \n\t"
                  " * in the 1st component of the intersection, the function takes the 1st entry in the type pack which is `number` and it takes the "
                  "1st "
                  "entry in the type pack has the 2nd component of the union as `null`, and `number` is not a supertype of `null`\n\t"
                  " * in the 2nd component of the intersection, the function takes the 1st entry in the type pack which is `null` and it takes the "
                  "1st "
                  "entry in the type pack has the 1st component of the union as `number`, and `null` is not a supertype of `number`";
        const std::string expected2 =
            FFlag::LuauNewTypePathErrorMessages
                ? "Expected this to be\n\t"
                  "'(number?) -> never'"
                  "\nbut got\n\t"
                  "'((null) -> never) & ((number) -> number)'"
                  "; \nthis is because \n\t"
                  " * Expected the 1st parameter to be a supertype of `null`, but got `number`\n\t"
                  " * Expected the 1st parameter to be a supertype of `number`, but got `null`\n\t"
                  " * Expected the return type to be `never`, but got `number`"
                : "Expected this to be\n\t"
                  "'(number?) -> never'"
                  "\nbut got\n\t"
                  "'((null) -> never) & ((number) -> number)'"
                  "; \nthis is because \n\t"
                  " * in the 1st component of the intersection, the function returns the 1st entry in the type pack which is `number` and it returns "
                  "the "
                  "1st entry in the type pack is `never`, and `number` is not a subtype of `never`\n\t"
                  " * in the 1st component of the intersection, the function takes the 1st entry in the type pack which is `number` and it takes the "
                  "1st "
                  "entry in the type pack has the 2nd component of the union as `null`, and `number` is not a supertype of `null`\n\t"
                  " * in the 2nd component of the intersection, the function takes the 1st entry in the type pack which is `null` and it takes the "
                  "1st "
                  "entry in the type pack has the 1st component of the union as `number`, and `null` is not a supertype of `number`";

        CHECK_EQ(expected1, toString(result.errors[0]));
        CHECK_EQ(expected2, toString(result.errors[1]));
    }
    else
    {
        LUAU_REQUIRE_ERROR_COUNT(1, result);
        const std::string expected = R"(Expected this to be
	'(number?) -> never'
but got
	'((null) -> never) & ((number) -> number)'; none of the intersection parts are compatible)";
        CHECK_EQ(expected, toString(result.errors[0]));
    }
}

TEST_CASE_FIXTURE(Fixture, "overloadeded_functions_with_never_arguments")
{
    CheckResult result = check(R"(
        function f<a...,b...>()
            function g(x : ((number) -> number?) & ((never) -> string?))
                const y : (never) -> null = x -- OK
                const z : (number?) -> null = x -- Not OK
            end
        end
    )");

    if (!FFlag::DebugLuauForceOldSolver)
    {
        const std::string expected1 =
            FFlag::LuauNewTypePathErrorMessages
                ? "Expected this to be\n\t"
                  "'(never) -> null'"
                  "\nbut got\n\t"
                  "'((never) -> string?) & ((number) -> number?)'"
                  "; \nthis is because \n\t"
                  " * Expected the return type to be `null`, but got `number`\n\t"
                  " * Expected the return type to be `null`, but got `string`"
                : "Expected this to be\n\t"
                  "'(never) -> null'"
                  "\nbut got\n\t"
                  "'((never) -> string?) & ((number) -> number?)'"
                  "; \nthis is because \n\t"
                  " * in the 1st component of the intersection, the function returns the 1st entry in the type pack which has the 1st component of "
                  "the "
                  "union as `number` and it returns the 1st entry in the type pack is `null`, and `number` is not a subtype of `null`\n\t"
                  " * in the 2nd component of the intersection, the function returns the 1st entry in the type pack which has the 1st component of "
                  "the "
                  "union as `string` and it returns the 1st entry in the type pack is `null`, and `string` is not a subtype of `null`";
        const std::string expected2 =
            FFlag::LuauNewTypePathErrorMessages
                ? "Expected this to be\n\t"
                  "'(number?) -> null'"
                  "\nbut got\n\t"
                  "'((never) -> string?) & ((number) -> number?)'"
                  "; \nthis is because \n\t"
                  " * Expected the 1st parameter to be a supertype of `null`, but got `never`\n\t"
                  " * Expected the 1st parameter to be a supertype of `null`, but got `number`\n\t"
                  " * Expected the 1st parameter to be a supertype of `number`, but got `never`\n\t"
                  " * Expected the return type to be `null`, but got `number`\n\t"
                  " * Expected the return type to be `null`, but got `string`"
                : "Expected this to be\n\t"
                  "'(number?) -> null'"
                  "\nbut got\n\t"
                  "'((never) -> string?) & ((number) -> number?)'"
                  "; \nthis is because \n\t"
                  " * in the 1st component of the intersection, the function returns the 1st entry in the type pack which has the 1st component of "
                  "the "
                  "union as `number` and it returns the 1st entry in the type pack is `null`, and `number` is not a subtype of `null`\n\t"
                  " * in the 1st component of the intersection, the function takes the 1st entry in the type pack which is `number` and it takes the "
                  "1st "
                  "entry in the type pack has the 2nd component of the union as `null`, and `number` is not a supertype of `null`\n\t"
                  " * in the 2nd component of the intersection, the function returns the 1st entry in the type pack which has the 1st component of "
                  "the "
                  "union as `string` and it returns the 1st entry in the type pack is `null`, and `string` is not a subtype of `null`\n\t"
                  " * in the 2nd component of the intersection, the function takes the 1st entry in the type pack which is `never` and it takes the "
                  "1st "
                  "entry in the type pack has the 1st component of the union as `number`, and `never` is not a supertype of `number`\n\t"
                  " * in the 2nd component of the intersection, the function takes the 1st entry in the type pack which is `never` and it takes the "
                  "1st "
                  "entry in the type pack has the 2nd component of the union as `null`, and `never` is not a supertype of `null`";

        CHECK_EQ(expected1, toString(result.errors[0]));
        CHECK_EQ(expected2, toString(result.errors[1]));
    }
    else
    {
        LUAU_REQUIRE_ERROR_COUNT(1, result);
        const std::string expected = R"(Expected this to be
	'(number?) -> null'
but got
	'((never) -> string?) & ((number) -> number?)'; none of the intersection parts are compatible)";
        CHECK_EQ(expected, toString(result.errors[0]));
    }
}

TEST_CASE_FIXTURE(Fixture, "overloadeded_functions_with_overlapping_results_and_variadics")
{
    // CLI-116474 Semantic subtyping of assignments needs to decide how to interpret intersections of functions
    DOES_NOT_PASS_NEW_SOLVER_GUARD();

    CheckResult result = check(R"(
        function f(x : ((string?) -> (string | number)) & ((number?) -> ...number))
            const y : ((null) -> (number, number?)) = x -- OK
            const z : ((string | number) -> (number, number?)) = x -- Not OK
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    const std::string expected = "Expected this to be\n\t"
                                 "'(number | string) -> (number, number?)'"
                                 "\nbut got\n\t"
                                 "'((number?) -> (...number)) & ((string?) -> number | string)'"
                                 "; none of the intersection parts are compatible";
    CHECK(expected == toString(result.errors[0]));
}

TEST_CASE_FIXTURE(Fixture, "overloadeded_functions_with_weird_typepacks_1")
{
    CheckResult result = check(R"(
        function f<a...,b...>()
            function g(x : (() -> a...) & (() -> b...))
                const y : (() -> b...) & (() -> a...) = x -- OK
                const z : () -> () = x -- Not OK
            end
        end
    )");

    if (!FFlag::DebugLuauForceOldSolver)
    {
        LUAU_REQUIRE_NO_ERRORS(result);
    }
    else
    {
        LUAU_REQUIRE_ERROR_COUNT(1, result);
        CHECK_EQ(
            toString(result.errors[0]),
            "Expected this to be '() -> ()', but got '(() -> (a...)) & (() -> (b...))'; none of the intersection parts are compatible"
        );
    }
}

TEST_CASE_FIXTURE(Fixture, "overloadeded_functions_with_weird_typepacks_2")
{
    CheckResult result = check(R"(
        function f<a...,b...>()
            function g(x : ((a...) -> ()) & ((b...) -> ()))
                const y : ((b...) -> ()) & ((a...) -> ()) = x -- OK
                const z : () -> () = x -- Not OK
            end
        end
    )");

    if (!FFlag::DebugLuauForceOldSolver)
    {
        LUAU_REQUIRE_ERROR_COUNT(1, result);
        const TypeMismatch* tm = get<TypeMismatch>(result.errors[0]);
        CHECK(tm);
        CHECK_EQ(toString(tm->wantedType), "() -> ()");
        CHECK_EQ(toString(tm->givenType), "((a...) -> ()) & ((b...) -> ())");
    }
    else
    {
        LUAU_REQUIRE_ERROR_COUNT(1, result);
        CHECK_EQ(
            toString(result.errors[0]),
            "Expected this to be '() -> ()', but got '((a...) -> ()) & ((b...) -> ())'; none of the intersection parts are compatible"
        );
    }
}

TEST_CASE_FIXTURE(Fixture, "overloadeded_functions_with_weird_typepacks_3")
{
    CheckResult result = check(R"(
        function f<a...>()
            function g(x : (() -> a...) & (() -> (number?,a...)))
                const y : (() -> (number?,a...)) & (() -> a...) = x -- OK
                const z : () -> (number) = x -- Not OK
            end
        end
    )");

    if (!FFlag::DebugLuauForceOldSolver)
    {
        LUAU_REQUIRE_ERROR_COUNT(1, result);
        const TypeMismatch* tm = get<TypeMismatch>(result.errors[0]);
        CHECK(tm);
        CHECK_EQ(toString(tm->wantedType), "() -> number");
        CHECK_EQ(toString(tm->givenType), "(() -> (a...)) & (() -> (number?, a...))");
    }
    else
    {
        LUAU_REQUIRE_ERROR_COUNT(1, result);
        const std::string expected = R"(Expected this to be
	'() -> number'
but got
	'(() -> (a...)) & (() -> (number?, a...))'; none of the intersection parts are compatible)";
        CHECK_EQ(expected, toString(result.errors[0]));
    }
}

TEST_CASE_FIXTURE(Fixture, "overloadeded_functions_with_weird_typepacks_4")
{
    CheckResult result = check(R"(
        function f<a...>()
            function g(x : ((a...) -> ()) & ((number,a...) -> number))
                const y : ((number,a...) -> number) & ((a...) -> ()) = x -- OK
                const z : (number?) -> () = x -- Not OK
            end
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    if (!FFlag::DebugLuauForceOldSolver)
    {
        const TypeMismatch* tm = get<TypeMismatch>(result.errors[0]);
        CHECK(tm);
        CHECK_EQ(toString(tm->wantedType), "(number?) -> ()");
        CHECK_EQ(toString(tm->givenType), "((a...) -> ()) & ((number, a...) -> number)");
        const std::string expected =
            FFlag::LuauNewTypePathErrorMessages
                ? "Expected this to be\n\t"
                  "'(number?) -> ()'"
                  "\nbut got\n\t"
                  "'((a...) -> ()) & ((number, a...) -> number)'"
                  "; \nthis is because \n\t"
                  " * Expected the 1st parameter to be a supertype of `null`, but got `number`\n\t"
                  " * Expected the return types to be `()`, but got `number`\n\t"
                  " * the parameter type pack tail is `a...` and the parameter types are `number?`, and `a...` is not a supertype of `number?`\n\t"
                  " * the parameter type pack tail is `a...` and the parameters from the 1st onward are `number?`, and `a...` is not a supertype of "
                  "`number?`"
                : "Expected this to be\n\t"
                  "'(number?) -> ()'"
                  "\nbut got\n\t"
                  "'((a...) -> ()) & ((number, a...) -> number)'"
                  "; \nthis is because \n\t"
                  " * in the 1st component of the intersection, the function takes a tail of `a...` and it takes the portion of the type pack "
                  "starting at "
                  "index 0 to the end`number?`, and `a...` is not a supertype of `number?`\n\t"
                  " * in the 2nd component of the intersection, the function returns is `number` and it returns `()`, and `number` is not a subtype "
                  "of "
                  "`()`\n\t"
                  " * in the 2nd component of the intersection, the function takes a tail of `a...` and it takes `number?`, and `a...` is not a "
                  "supertype "
                  "of `number?`\n\t"
                  " * in the 2nd component of the intersection, the function takes the 1st entry in the type pack which is `number` and it takes the "
                  "1st "
                  "entry in the type pack has the 2nd component of the union as `null`, and `number` is not a supertype of `null`";

        CHECK(expected == toString(result.errors[0]));
    }
    else
    {
        CHECK_EQ(
            R"(Expected this to be
	'(number?) -> ()'
but got
	'((a...) -> ()) & ((number, a...) -> number)'; none of the intersection parts are compatible)",
            toString(result.errors[0])
        );
    }
}

TEST_CASE_FIXTURE(BuiltinsFixture, "intersect_metatables")
{
    // CLI-117121 - Intersection of types are not compatible with the equivalent alias
    if (!FFlag::DebugLuauForceOldSolver)
        return;

    if (!FFlag::DebugLuauForceOldSolver)
    {
        CheckResult result = check(R"(
            function f(a: string?, b: string?)
                const x = setmetatable({}, { p = 5, q = a })
                const y = setmetatable({}, { q = b, r = "hi" })
                const z = setmetatable({}, { p = 5, q = null, r = "hi" })

                type X = typeof(x)
                type Y = typeof(y)
                type Z = typeof(z)

                function g(xy: X&Y, yx: Y&X): (Z, Z)
                    return xy, yx
                end

                g(z, z)
            end
        )");

        LUAU_REQUIRE_NO_ERRORS(result);
    }
    else
    {
        CheckResult result = check(R"(
            const a : string? = null
            const b : number? = null

            const x = setmetatable({}, { p = 5, q = a });
            const y = setmetatable({}, { q = b, r = "hi" });
            const z = setmetatable({}, { p = 5, q = null, r = "hi" });

            type X = typeof(x)
            type Y = typeof(y)
            type Z = typeof(z)

            const xy : X&Y = z;
            const yx : Y&X = z;
            z = xy;
            z = yx;
        )");

        LUAU_REQUIRE_NO_ERRORS(result);
    }
}

TEST_CASE_FIXTURE(BuiltinsFixture, "intersect_metatable_subtypes")
{
    CheckResult result = check(R"(
        const x = setmetatable({ a = 5 }, { p = 5 })
        const y = setmetatable({ b = "hi" }, { p = 5, q = "hi" })
        const z = setmetatable({ a = 5, b = "hi" }, { p = 5, q = "hi" })

        type X = typeof(x)
        type Y = typeof(y)
        type Z = typeof(z)

        function f(xy: X&Y, yx: Y&X): (Z, Z)
            return xy, yx
        end

        f(z, z)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "intersect_metatables_with_properties")
{
    CheckResult result = check(R"(
        const x = setmetatable({ a = 5 }, { p = 5 })
        const y = setmetatable({ b = "hi" }, { q = "hi" })
        const z = setmetatable({ a = 5, b = "hi" }, { p = 5, q = "hi" })

        type X = typeof(x)
        type Y = typeof(y)
        type Z = typeof(z)

        function f(xy: X&Y): Z
            return xy
        end

        f(z)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "intersect_metatable_with_table")
{
    if (!FFlag::DebugLuauForceOldSolver)
    {
        CheckResult result = check(R"(
            const x = setmetatable({ a = 5 }, { p = 5 })
            const z = setmetatable({ a = 5, b = "hi" }, { p = 5 })

            type X = typeof(x)
            type Y = { b : string }
            type Z = typeof(z)

            function f(xy: X&Y, yx: Y&X): (Z, Z)
                return xy, yx
            end

            f(z, z)
        )");

        LUAU_REQUIRE_NO_ERRORS(result);
    }
    else
    {
        CheckResult result = check(R"(
            const x = setmetatable({ a = 5 }, { p = 5 });
            const z = setmetatable({ a = 5, b = "hi" }, { p = 5 });

            type X = typeof(x)
            type Y = { b : string }
            type Z = typeof(z)

            -- TODO: once we have shape types, we should be able to initialize these with z
            const xy : X&Y;
            const yx : Y&X;
            z = xy;
            z = yx;
        )");

        LUAU_REQUIRE_NO_ERRORS(result);
    }
}

TEST_CASE_FIXTURE(Fixture, "CLI-44817")
{
    CheckResult result = check(R"(
        type X = {x: number}
        type Y = {y: number}
        type Z = {z: number}

        type XY = {x: number, y: number}
        type XYZ = {x:number, y: number, z: number}

        function f(xy: XY, xyz: XYZ): (X&Y, X&Y&Z)
            return xy, xyz
        end

        const xNy, xNyNz = f({x = 0, y = 0}, {x = 0, y = 0, z = 0})

        const t1: XY = xNy -- Type 'X & Y' could not be converted into 'XY'
        const t2: XY = xNyNz -- Type 'X & Y & Z' could not be converted into 'XY'
        const t3: XYZ = xNyNz -- Type 'X & Y & Z' could not be converted into 'XYZ'
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "less_greedy_unification_with_intersection_types")
{
    if (FFlag::DebugLuauForceOldSolver)
        return;

    CheckResult result = check(R"(
        function f(t): { x: number } & { x: string }
            const x = t.x
            return t
        end
    )");

    // We have one error here for the parameter being reduced to never, and
    // then three bits of extra information indicating the three upper
    // bound contributors: `{ x: number }`, `{ x: string }`, and `{ x: a }`
    // from the function inference.
    LUAU_REQUIRE_ERROR_COUNT(3, result);

    CHECK_EQ("(never) -> { x: number } & { x: string }", toString(requireType("f")));
}

TEST_CASE_FIXTURE(Fixture, "less_greedy_unification_with_intersection_types_2")
{
    if (FFlag::DebugLuauForceOldSolver)
        return;

    CheckResult result = check(R"(
        function f(t: { x: number } & { x: string })
            return t.x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("({ x: number } & { x: string }) -> never", toString(requireType("f")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "index_property_table_intersection_1")
{
    CheckResult result = check(R"(
type Foo = {
	Bar: string,
} & { Baz: number }

function f(x: Foo)
    return x.Bar
end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "index_property_table_intersection_2")
{
    CheckResult result = check(R"(
        type Foo = {
            Bar: string,
        } & { Baz: number }

        function f(x: Foo)
            return x["Bar"]
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "cli_80596_simplify_degenerate_intersections")
{
    ScopedFastFlag dcr{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        type A = {
            x: number?,
        }

        type B = {
            x: number?,
        }

        type C = A & B

        function f(obj: C): number
            return obj.x or 3
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "cli_80596_simplify_more_realistic_intersections")
{
    ScopedFastFlag dcr{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        type A = {
            x: number?,
            y: string?,
        }

        type B = {
            x: number?,
            z: string?,
        }

        type C = A & B

        function f(obj: C): number
            return obj.x or 3
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "narrow_intersection_nevers")
{
    ScopedFastFlag sffs{FFlag::DebugLuauForceOldSolver, false};

    loadDefinition(R"(
        declare extern type Player with
            Character: unknown
        end
    )");
    LUAU_REQUIRE_NO_ERRORS(check(R"(
        function foo(player: Player?)
            if player and player.Character then
                print(player.Character)
            end
        end
    )"));

    CHECK_EQ("Player & { read Character: ~(false?) }", toString(requireTypeAtPosition({3, 23})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "bounds_propagate_into_free_intersection_bounds")
{
    /*
     * When unifying 'a <: T & C in a context where T is substituted for 't, we must constrain the lower bound of 't by 'a.
     */
    CheckResult result = check(R"(
        function f<T>(a: T & string): T
            return a
        end

        const b = f("hello")
        const c = f(("world" as string))
    )");

    LUAU_CHECK_NO_ERRORS(result);

    CHECK("string" == toString(requireType("b")));
    CHECK("string" == toString(requireType("c")));
}

TEST_SUITE_END();
