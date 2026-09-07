// This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details

#include "Fixture.h"

#include "doctest.h"

using namespace Luau;

LUAU_FASTFLAG(DebugLuauForceOldSolver);
LUAU_FASTFLAG(LuauExportValueSyntax);

TEST_SUITE_BEGIN("TypeInferUnknownNever");

TEST_CASE_FIXTURE(Fixture, "string_subtype_and_unknown_supertype")
{
    CheckResult result = check(R"(
        function f(x: string)
            const foo: unknown = x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "unknown_subtype_and_string_supertype")
{
    CheckResult result = check(R"(
        function f(x: unknown)
            const foo: string = x
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
}

TEST_CASE_FIXTURE(Fixture, "unknown_is_reflexive")
{
    CheckResult result = check(R"(
        function f(x: unknown)
            const foo: unknown = x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "string_subtype_and_never_supertype")
{
    CheckResult result = check(R"(
        function f(x: string)
            const foo: never = x
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
}

TEST_CASE_FIXTURE(Fixture, "never_subtype_and_string_supertype")
{
    CheckResult result = check(R"(
        function f(x: never)
            const foo: string = x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "never_is_reflexive")
{
    CheckResult result = check(R"(
        function f(x: never)
            const foo: never = x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "unknown_is_optional_because_it_too_encompasses_nil")
{
    CheckResult result = check(R"(
        const t: {x: unknown} = {}
    )");
}

TEST_CASE_FIXTURE(Fixture, "table_with_prop_of_type_never_is_uninhabitable")
{
    CheckResult result = check(R"(
        const t: {x: never} = {}
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
}

TEST_CASE_FIXTURE(Fixture, "table_with_prop_of_type_never_is_also_reflexive")
{
    CheckResult result = check(R"(
        const t: {x: never} = {x = 5 as never}
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "array_like_table_of_never_is_inhabitable")
{
    CheckResult result = check(R"(
        const t: {never} = {}
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "type_packs_containing_never_is_itself_uninhabitable")
{
    CheckResult result = check(R"(
        function f() return "foo", 5 as never end

        const x, y, z = f()
    )");

    if (!FFlag::DebugLuauForceOldSolver)
    {
        LUAU_REQUIRE_ERROR_COUNT(1, result);
        CHECK("Function only returns 2 values, but 3 are required here" == toString(result.errors[0]));

        CHECK("string" == toString(requireType("x")));
        CHECK("never" == toString(requireType("y")));
        CHECK("null" == toString(requireType("z")));
    }
    else
    {
        LUAU_REQUIRE_NO_ERRORS(result);

        CHECK_EQ("never", toString(requireType("x")));
        CHECK_EQ("never", toString(requireType("y")));
        CHECK_EQ("never", toString(requireType("z")));
    }
}

TEST_CASE_FIXTURE(Fixture, "type_packs_containing_never_is_itself_uninhabitable2")
{
    CheckResult result = check(R"(
        function f(): (string, never) return "", 5 as never end
        function g(): (never, string) return 5 as never, "" end

        const x1, x2 = f()
        const y1, y2 = g()
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    if (!FFlag::DebugLuauForceOldSolver)
    {
        CHECK_EQ("string", toString(requireType("x1")));
        CHECK_EQ("never", toString(requireType("x2")));
        CHECK_EQ("never", toString(requireType("y1")));
        CHECK_EQ("string", toString(requireType("y2")));
    }
    else
    {
        CHECK_EQ("never", toString(requireType("x1")));
        CHECK_EQ("never", toString(requireType("x2")));
        CHECK_EQ("never", toString(requireType("y1")));
        CHECK_EQ("never", toString(requireType("y2")));
    }
}

TEST_CASE_FIXTURE(Fixture, "index_on_never")
{
    CheckResult result = check(R"(
        const x: never = 5 as never
        const z = x.y
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("never", toString(requireType("z")));
}

TEST_CASE_FIXTURE(Fixture, "call_never")
{
    CheckResult result = check(R"(
        const f: never = 5 as never
        const x, y, z = f()
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("never", toString(requireType("x")));
    CHECK_EQ("never", toString(requireType("y")));
    CHECK_EQ("never", toString(requireType("z")));
}

TEST_CASE_FIXTURE(Fixture, "assign_to_local_which_is_never")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    // CLI-117119 - What do we do about assigning to never?
    CheckResult result = check(R"(
        export t: never = null as any
        t = 3
    )");

    if (!FFlag::DebugLuauForceOldSolver)
    {
        LUAU_REQUIRE_ERROR_COUNT(1, result);
    }
    else
    {
        LUAU_REQUIRE_NO_ERRORS(result);
    }
}

TEST_CASE_FIXTURE(Fixture, "assign_to_global_which_is_never")
{
    CheckResult result = check(R"(
        #!nonstrict
        t = 5 as never
        t = ""
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "assign_to_prop_which_is_never")
{
    CheckResult result = check(R"(
        function f(t: never)
            t.x = 5
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "assign_to_subscript_which_is_never")
{
    CheckResult result = check(R"(
        function f(t: never)
            t[5] = 7
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "for_loop_over_never")
{
    CheckResult result = check(R"(
        for i, v in (5 as never) do
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "pick_never_from_variadic_type_pack")
{
    CheckResult result = check(R"(
        function f(...: never)
            const x, y = ...
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "index_on_union_of_tables_for_properties_that_is_never")
{
    // CLI-117116 - We are erroneously warning when passing a valid table literal where we expect a union of tables.
    if (!FFlag::DebugLuauForceOldSolver)
        return;
    CheckResult result = check(R"(
        type Disjoint = {foo: never, bar: unknown, tag: "ok"} | {foo: never, baz: unknown, tag: "err"}

        function f(disjoint: Disjoint)
            return disjoint.foo
        end

        const foo = f({foo = 5 as never, bar = true, tag = "ok"})
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("never", toString(requireType("foo")));
}

TEST_CASE_FIXTURE(Fixture, "index_on_union_of_tables_for_properties_that_is_sorta_never")
{
    // CLI-117116 - We are erroneously warning when passing a valid table literal where we expect a union of tables.
    if (!FFlag::DebugLuauForceOldSolver)
        return;
    CheckResult result = check(R"(
        type Disjoint = {foo: string, bar: unknown, tag: "ok"} | {foo: never, baz: unknown, tag: "err"}

        function f(disjoint: Disjoint)
            return disjoint.foo
        end

        const foo = f({foo = 5 as never, bar = true, tag = "ok"})
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("string", toString(requireType("foo")));
}

TEST_CASE_FIXTURE(Fixture, "unary_minus_of_never")
{
    CheckResult result = check(R"(
        const x = -(5 as never)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("never", toString(requireType("x")));
}

TEST_CASE_FIXTURE(Fixture, "length_of_never")
{
    CheckResult result = check(R"(
        const x = ({} as never).count
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("number", toString(requireType("x")));
}

TEST_CASE_FIXTURE(Fixture, "dont_unify_operands_if_one_of_the_operand_is_never_in_any_ordering_operators")
{
    CheckResult result = check(R"(
        function ord(x: null, y)
            return x != null and x > y
        end
    )");


    LUAU_REQUIRE_NO_ERRORS(result);
    if (!FFlag::DebugLuauForceOldSolver)
        CHECK_EQ("(null, null & ~null) -> boolean", toString(requireType("ord")));
    else
        CHECK_EQ("<T>(null, T) -> boolean", toString(requireType("ord")));
}

TEST_CASE_FIXTURE(Fixture, "math_operators_and_never")
{
    CheckResult result = check(R"(
        function mul(x: null, y)
            return x != null and x * y # infers boolean | never, which is normalized into boolean
        end
    )");

    if (!FFlag::DebugLuauForceOldSolver)
    {
        LUAU_REQUIRE_ERROR_COUNT(1, result);
        CHECK(get<ExplicitFunctionAnnotationRecommended>(result.errors[0]));

        // CLI-114134 Egraph-based simplification.
        // CLI-116549 x != null : false when x : null
        CHECK("<T>(null, T) -> false | mul<null & ~null, T>" == toString(requireType("mul")));
    }
    else
    {
        LUAU_REQUIRE_NO_ERRORS(result);
        CHECK_EQ("<T>(null, T) -> boolean", toString(requireType("mul")));
    }
}

TEST_CASE_FIXTURE(Fixture, "compare_never")
{
    CheckResult result = check(R"(
        function cmp(x: null, y: number)
            return x != null and x > y and x < y # infers boolean | never, which is normalized into boolean
        end
    )");

    LUAU_CHECK_NO_ERRORS(result);
    CHECK_EQ("(null, number) -> boolean", toString(requireType("cmp")));
}

TEST_CASE_FIXTURE(Fixture, "lti_error_at_declaration_for_never_normalizations")
{
    ScopedFastFlag sff_LuauSolverV2{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        function num(x: number) end
        function str(x: string) end
        function cond(): boolean return false end

        function f(a)
            if cond() then
                num(a)
            else
                str(a)
            end
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(3, result);
    CHECK(toString(result.errors[0]) == "Parameter 'a' has been reduced to never. This function is not callable with any possible value.");
    CHECK(toString(result.errors[1]) == "Parameter 'a' is required to be a subtype of 'number' here.");
    CHECK(toString(result.errors[2]) == "Parameter 'a' is required to be a subtype of 'string' here.");
}

TEST_CASE_FIXTURE(Fixture, "lti_permit_explicit_never_annotation")
{
    ScopedFastFlag sff_LuauSolverV2{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        function num(x: number) end
        function str(x: string) end
        function cond(): boolean return false end

        function f(a: never)
            if cond() then
                num(a)
            else
                str(a)
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "cast_from_never_does_not_error")
{
    CheckResult result = check(R"(
        function f(x: never): number
            return x as number
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_SUITE_END();
