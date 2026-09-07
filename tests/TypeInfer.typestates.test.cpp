// This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
#include "Fixture.h"

#include "doctest.h"

LUAU_FASTFLAG(DebugLuauForceOldSolver)
LUAU_FASTFLAG(LuauExportValueSyntax)

using namespace Luau;

namespace
{
struct TypeStateFixture : BuiltinsFixture
{
    ScopedFastFlag dcr{FFlag::DebugLuauForceOldSolver, false};
};
} // namespace

TEST_SUITE_BEGIN("TypeStatesTest");

TEST_CASE_FIXTURE(TypeStateFixture, "initialize_x_of_type_string_or_nil_with_nil")
{
    CheckResult result = check(R"(
        const x: string? = null
        const a = x
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("string?" == toString(requireType("a")));
}

TEST_CASE_FIXTURE(TypeStateFixture, "extraneous_lvalues_are_populated_with_nil")
{
    CheckResult result = check(R"(
        function f(): (string, number)
            return "hello", 5
        end

        const x, y, z = f()
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    CHECK("Function only returns 2 values, but 3 are required here" == toString(result.errors[0]));
    CHECK("string" == toString(requireType("x")));
    CHECK("number" == toString(requireType("y")));
    CHECK("null" == toString(requireType("z")));
}

TEST_CASE_FIXTURE(TypeStateFixture, "assign_different_values_to_x")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    CheckResult result = check(R"(
        export x: string? = null
        const a = x
        x = "hello!"
        const b = x
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("string?" == toString(requireType("a")));
    CHECK("string" == toString(requireType("b")));
}

TEST_CASE_FIXTURE(TypeStateFixture, "parameter_x_was_constrained_by_two_types")
{
    // Parameter `x` has a fresh type `'x` bounded by `never` and `unknown`.
    // The first use of `x` constrains `x`'s upper bound by `string | number`.
    // The second use of `x`, aliased by `y`, constrains `x`'s upper bound by `string?`.
    // This results in `'x <: (string | number) & (string?)`.
    // The principal type of the upper bound is `string`.
    CheckResult result = check(R"(
        function f(x): string?
            const y: string | number = x
            return y
        end
    )");

    if (!FFlag::DebugLuauForceOldSolver)
    {
        // `y` is annotated `string | number` which is explicitly not compatible with `string?`
        // as such, we produce an error here for that mismatch.
        //
        // this is not necessarily the best inference here, since we can indeed produce `string`
        // as a type for `x`, but it's a limitation we can accept for now.
        LUAU_REQUIRE_ERRORS(result);

        TypeMismatch* tm = get<TypeMismatch>(result.errors[0]);
        REQUIRE_MESSAGE(tm, "Expected TypeMismatch but got " << result.errors[0]);
        CHECK("string?" == toString(tm->wantedType));
        CHECK("number | string" == toString(tm->givenType));
        CHECK("(number | string) -> string?" == toString(requireType("f")));
    }
    else
    {
        LUAU_REQUIRE_NO_ERRORS(result);

        CHECK("(string) -> string?" == toString(requireType("f")));
    }
}

#if 0
TEST_CASE_FIXTURE(TypeStateFixture, "local_that_will_be_assigned_later")
{
    CheckResult result = check(R"(
        const x: string
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
}

TEST_CASE_FIXTURE(TypeStateFixture, "refine_a_local_and_then_assign_it")
{
    CheckResult result = check(R"(
        function f(x: string?)
            if typeof(x) == "string" then
                x = null
            end

            const y: null = x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}
#endif

TEST_CASE_FIXTURE(TypeStateFixture, "assign_a_local_and_then_refine_it")
{
    CheckResult result = check(R"(
        function f(x: string?)
            x = null

            if typeof(x) == "string" then
                const y: typeof(x) = "hello"
            end
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    CHECK("Expected this to be unreachable, but got 'string'" == toString(result.errors[0]));
}

TEST_CASE_FIXTURE(TypeStateFixture, "recursive_local_function")
{
    CheckResult result = check(R"(
        function f(x)
            f(5)
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(TypeStateFixture, "recursive_function")
{
    CheckResult result = check(R"(
        function f(x)
            f(5)
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(TypeStateFixture, "compound_assignment")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    CheckResult result = check(R"(
        export x = 5
        x += 7

        const a = x
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(TypeStateFixture, "assignment_identity")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    CheckResult result = check(R"(
        export x = 5
        x = x

        const a = x
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("number" == toString(requireType("a")));
}

TEST_CASE_FIXTURE(TypeStateFixture, "assignment_swap")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    CheckResult result = check(R"(
        export x, y = 5, "hello"
        x, y = y, x

        const a, b = x, y
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("string" == toString(requireType("a")));
    CHECK("number" == toString(requireType("b")));
}

TEST_CASE_FIXTURE(TypeStateFixture, "parameter_x_was_constrained_by_two_types_2")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    CheckResult result = check(R"(
        export y: string? = null  # 'y <: string?

        function f(x): number?
            y = x                   # 'y ~ 'x
            return y                # 'y <: number?

                                    # We therefore infer 'y <: (string | null) & (number | null)
                                    # or 'y <: null
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("(null) -> number?" == toString(requireType("f")));
}

TEST_CASE_FIXTURE(TypeStateFixture, "parameter_x_is_some_type_or_optional_then_assigned_with_alternate_value")
{
    CheckResult result = check(R"(
        function f(x: number?)
            x = x or 5
            return x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("(number?) -> number" == toString(requireType("f")));
}

TEST_CASE_FIXTURE(TypeStateFixture, "local_assigned_in_either_branches_that_falls_through")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    CheckResult result = check(R"(
        export x = null
        if math.random() > 0.5 then
            x = 5
        else
            x = "hello"
        end
        const y = x
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("number | string" == toString(requireType("y")));
}

TEST_CASE_FIXTURE(TypeStateFixture, "local_assigned_in_only_one_branch_that_falls_through")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    CheckResult result = check(R"(
        export x = null
        if math.random() > 0.5 then
            x = 5
        end
        const y = x
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("number?" == toString(requireType("y")));
}

TEST_CASE_FIXTURE(TypeStateFixture, "then_branch_assigns_and_else_branch_also_assigns_but_is_met_with_return")
{
    CheckResult result = check(R"(
        x = null
        if math.random() > 0.5 then
            x = 5
        else
            x = "hello"
            return
        end
        const y = x
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("number" == toString(requireType("y")));
}

TEST_CASE_FIXTURE(TypeStateFixture, "then_branch_assigns_but_is_met_with_return_and_else_branch_assigns")
{
    CheckResult result = check(R"(
        x = null
        if math.random() > 0.5 then
            x = 5
            return
        else
            x = "hello"
        end
        const y = x
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("string" == toString(requireType("y")));
}

TEST_CASE_FIXTURE(TypeStateFixture, "invalidate_type_refinements_upon_assignments")
{
    CheckResult result = check(R"(
        type Ok<T> = { tag: "ok", val: T }
        type Err<E> = { tag: "err", err: E }
        type Result<T, E> = Ok<T> | Err<E>

        function f<T, E>(res: Result<T, E>)
            assert(res.tag == "ok")
            const tag: "ok", val: T = res.tag, res.val
            res = { tag = "err" as "err", err = (5 as any) as E }
            const tag: "err", err: E = res.tag, res.err
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

#if 0
TEST_CASE_FIXTURE(TypeStateFixture, "local_t_is_assigned_a_fresh_table_with_x_assigned_a_union_and_then_assert_restricts_actual_outflow_of_types")
{
    CheckResult result = check(R"(
        const t = null

        if math.random() > 0.5 then
            t = {}
            t.x = if math.random() > 0.5 then 5 else "hello"
            assert(typeof(t.x) == "string")
        else
            t = {}
            t.x = if math.random() > 0.5 then 7 else true
            assert(typeof(t.x) == "boolean")
        end

        const x = t.x
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    // CHECK("boolean | string" == toString(requireType("x")));
    CHECK("boolean | number | number | string" == toString(requireType("x")));
}
#endif

TEST_CASE_FIXTURE(TypeStateFixture, "captured_locals_do_not_mutate_upvalue_type")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    CheckResult result = check(R"(
        export x = null

        function f()
            print(x)
            x = "five"
        end

        x = 5
        f()
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    auto err = get<TypeMismatch>(result.errors[0]);
    CHECK_EQ("number?", toString(err->wantedType));
    CHECK_EQ("string", toString(err->givenType));
    CHECK("number?" == toString(requireTypeAtPosition({4, 18})));
}

TEST_CASE_FIXTURE(TypeStateFixture, "captured_locals_do_not_mutate_upvalue_type_2")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};

    CheckResult result = check(R"(
        export t = {x = null}

        function f()
            print(t.x)
            t = {x = "five"}
        end

        t = {x = 5}
        f()
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    auto err = get<TypeMismatch>(result.errors[0]);
    CHECK_EQ("{ x: null } | { x: number }", toString(err->wantedType, {/* exhaustive */ true}));
    CHECK_EQ("{ x: string }", toString(err->givenType));
    CHECK("{ x: null } | { x: number }" == toString(requireTypeAtPosition({4, 18}), {true}));
    CHECK("number?" == toString(requireTypeAtPosition({4, 20})));
}

TEST_CASE_FIXTURE(TypeStateFixture, "prototyped_recursive_functions")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    CheckResult result = check(R"(
        export f = null
        function f()
            if math.random() > 0.5 then
                f()
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("(() -> ())?" == toString(requireType("f")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "prototyped_recursive_functions_but_has_future_assignments")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::LuauExportValueSyntax, true},
    };

    CheckResult result = check(R"(
        export f = null
        function f()
            if math.random() > 0.5 then
                f()
            end
        end
        f = 5
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    CHECK("((() -> ()) | number)?" == toString(requireType("f")));
}

TEST_CASE_FIXTURE(TypeStateFixture, "prototyped_recursive_functions_but_has_previous_assignments")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    CheckResult result = check(R"(
        export f = null
        f = 5
        function f()
            if math.random() > 0.5 then
                f()
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("((() -> ()) | number)?" == toString(requireType("f")));
}

TEST_CASE_FIXTURE(TypeStateFixture, "multiple_assignments_in_loops")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    CheckResult result = check(R"(
        export x = null

        for i = 1, 10 do
            x = 5
            x = "hello"
        end

        print(x)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("(number | string)?" == toString(requireType("x")));
}

TEST_CASE_FIXTURE(TypeStateFixture, "typestates_preserve_error_suppression")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    CheckResult result = check(R"(
        export a: any = 51
        a = "pickles" # We'll have a new DefId for this iteration of `a`.  Its type must also be error-suppressing
        print(a)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("*error-type* | string" == toString(requireTypeAtPosition({3, 14}), {true}));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "typestates_do_not_apply_to_the_initial_local_definition")
{
    // early return if the flag isn't set since this is blocking gated commits
    if (FFlag::DebugLuauForceOldSolver)
        return;

    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    CheckResult result = check(R"(
        type MyType = number | string
        export foo: MyType = 5
        print(foo)
        foo = 7
        print(foo)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("number | string" == toString(requireTypeAtPosition({3, 14}), {true}));
    CHECK("number" == toString(requireTypeAtPosition({5, 14}), {true}));
}

TEST_CASE_FIXTURE(Fixture, "typestate_globals")
{
    ScopedFastFlag sff{FFlag::DebugLuauForceOldSolver, false};

    loadDefinition(R"(
        declare foo: string | number
        declare function f(x: string): ()
    )");

    CheckResult result = check(R"(
        foo = "a"
        f(foo)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "typestate_unknown_global")
{
    ScopedFastFlag sff{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        const _ = x
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    CHECK(get<UnknownSymbol>(result.errors[0]));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "fuzzer_normalized_type_variables_are_bad" * doctest::timeout(LUAU_TIMEOUT))
{
    // We do not care about the errors here, only that this finishes typing
    // in a sensible amount of time.
    LUAU_REQUIRE_ERRORS(check(R"(
        const _ = null
        while _[""] do
            _, _ = null
            while _.n0 do
                _, _ = null
            end
            _, _ = null
        end
        while _[""] do
            while if _ then if _ then _ else "" else "" do
                _, _ = null
                do
                end
                _, _, _ = null
            end
            _, _ = null
            _, _, _ = null
            while _.readi16 do
                _, _ = null
            end
            _, _ = null
        end
    )"));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "oss_1547_simple")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    LUAU_REQUIRE_NO_ERRORS(check(R"(
        export rand = 0

        function a()
            rand = (rand % 4) + 1;
        end
    )"));

    auto randTy = getType("rand");
    REQUIRE(randTy);
    CHECK_EQ("number", toString(*randTy));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "oss_1547")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    LUAU_REQUIRE_NO_ERRORS(check(R"(
        export rand = 0

        function a()
            rand = (rand % 4) + 1;
        end

        function b()
            rand = math.max(rand - 1, 0);
        end
    )"));

    auto randTy = getType("rand");
    REQUIRE(randTy);
    CHECK_EQ("number", toString(*randTy));
}

TEST_CASE_FIXTURE(Fixture, "modify_captured_table_field")
{
    LUAU_REQUIRE_NO_ERRORS(check(R"(
        const state = { x = 0 }
        function incr()
            state.x = state.x + 1
        end
    )"));

    auto randTy = getType("state");
    REQUIRE(randTy);
    if (!FFlag::DebugLuauForceOldSolver)
        CHECK_EQ("{ x: number }", toString(*randTy, {true}));
    else
        CHECK_EQ("{| x: number |}", toString(*randTy, {true}));
}

TEST_CASE_FIXTURE(Fixture, "oss_1561")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    loadDefinition(R"(
        declare extern type Vector3 with
            X: number
            Y: number
            Z: number
        end

        declare Vector3: {
            new: (number?, number?, number?) -> Vector3
        }
    )");

    LUAU_REQUIRE_NO_ERRORS(check(R"(
        export targetVelocity: Vector3 = Vector3.new()
        function set2D(X: number, Y: number)
            targetVelocity = Vector3.new(X, Y, targetVelocity.Z)
        end
    )"));

    CHECK_EQ("(number, number) -> ()", toString(requireType("set2D")));
}

TEST_CASE_FIXTURE(Fixture, "oss_1575")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    LUAU_REQUIRE_NO_ERRORS(check(R"(
        export flag = true
        function Flip()
            flag = not flag
        end
    )"));
}

TEST_CASE_FIXTURE(Fixture, "capture_upvalue_in_returned_function")
{
    LUAU_REQUIRE_NO_ERRORS(check(R"(
        function def()
            i = 0
            function Counter()
                i = i + 1
                return i
            end
            return Counter
        end
    )"));
    CHECK_EQ("() -> () -> number", toString(requireType("def")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "throw_in_else_branch")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    CheckResult result = check(R"(
        #!strict
        export x = null
        const coinflip : () -> boolean = (null as any)

        if coinflip () then
            x = "I win."
        else
            error("You lose.")
        end

        print(x)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("string", toString(requireTypeAtPosition({11, 14})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "throw_in_if_branch")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    CheckResult result = check(R"(
        #!strict
        export x = null
        const coinflip : () -> boolean = (null as any)

        if coinflip () then
            error("You lose.")
        else
            x = "I win."
        end

        print(x)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("string", toString(requireTypeAtPosition({11, 14})));
}


TEST_CASE_FIXTURE(BuiltinsFixture, "refinement_through_erroring")
{
    CheckResult result = check(R"(
        #!strict
        type Payload = { payload: number }

        function decode(s: string): Payload?
            return (null as any)
        end

        function decodeEx(s: string): Payload
            const p = decode(s)
            if not p then
                error("failed to decode payload!!!")
            end
            return p
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "refinement_through_erroring_in_loop")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};

    CheckResult result = check(R"(
        #!strict

        x = null

        while math.random() > 0.5 do
            x = 42
            return
        end

        print(x)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("null", toString(requireTypeAtPosition({10, 14})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "type_refinement_in_loop")
{
    CheckResult result = check(R"(
        #!strict
        function onEachString(t: { string | number })
            for _, v in t do
                if type(v) != "string" then
                    continue
                end
                print(v)
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("number | string", toString(requireTypeAtPosition({4, 24})));
    CHECK_EQ("string", toString(requireTypeAtPosition({7, 22})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "throw_in_if_branch_and_do_nothing_in_else")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        #!strict
        const x = null
        const coinflip : () -> boolean = (null as any)

        if coinflip () then
            error("You lose.")
        else
        end

        print(x)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("null", toString(requireTypeAtPosition({10, 14})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "assign_in_an_if_branch_without_else")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};

    CheckResult result = check(R"(
        #!strict
        export x = null
        const coinflip : () -> boolean = (null as any)

        if coinflip () then
            x = "I win."
        end

        print(x)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("string?", toString(requireTypeAtPosition({9, 14})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "fuzzer_table_freeze_in_binary_expr")
{
    DOES_NOT_PASS_OLD_SOLVER_GUARD();

    CheckResult result = check(R"(
        const _ = null
        if _ or table.freeze(_,_) or table.freeze(_,_) then
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(4, result);
    auto err0 = get<TypeMismatch>(result.errors[0]);
    CHECK(err0);
    CHECK_EQ("null", toString(err0->givenType));
    CHECK_EQ("table", toString(err0->wantedType));
    auto err1 = get<CountMismatch>(result.errors[1]);
    CHECK(err1);
    CHECK_EQ(1, err1->expected);
    CHECK_EQ(2, err1->actual);
    auto err2 = get<TypeMismatch>(result.errors[0]);
    CHECK(err2);
    CHECK_EQ("null", toString(err2->givenType));
    CHECK_EQ("table", toString(err2->wantedType));
    auto err3 = get<CountMismatch>(result.errors[1]);
    CHECK(err3);
    CHECK_EQ(1, err3->expected);
    CHECK_EQ(2, err3->actual);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_freeze_in_conditional")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};
    // NOTE: This _probably_ should be disallowed, but it is representing that
    // type stating functions in short circuiting binary expressions do not
    // reflect their type states.
    CheckResult result = check(R"(
        const t = { x = 42 }
        if math.random() > 0.5 and table.freeze(t) then
        end
        t.y = 13
    )");
    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "fuzzer_table_freeze_in_conditional_expr")
{
    DOES_NOT_PASS_OLD_SOLVER_GUARD();

    CheckResult result = check(R"(
        const _ = null
        if
            if table.freeze(_,_) then _ else _
        then
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(2, result);
    auto err0 = get<TypeMismatch>(result.errors[0]);
    CHECK(err0);
    CHECK_EQ("null", toString(err0->givenType));
    CHECK_EQ("table", toString(err0->wantedType));
    auto err1 = get<CountMismatch>(result.errors[1]);
    CHECK(err1);
    CHECK_EQ(1, err1->expected);
    CHECK_EQ(2, err1->actual);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "setmetatable_depends_on_sub_expression")
{
    DOES_NOT_PASS_OLD_SOLVER_GUARD();

    CheckResult result = check(R"(
        type AB = setmetatable<{ foo: number }, { bar: number }>

        function takes(tbl: AB, _: unknown): ()
        end

        function sends(tbl: { foo: number }): ()
            takes(tbl, setmetatable(tbl, { bar = 3 }))
        end
    )");

    auto err = get<TypeMismatch>(result.errors[0]);
    REQUIRE(err);
    CHECK_EQ("{ @metatable { bar: number }, { foo: number } }", toString(err->wantedType, {/* exhaustive */ true}));
    CHECK_EQ("{ foo: number }", toString(err->givenType, {/* exhaustive */ true}));
}

TEST_SUITE_END();
