// This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
#include "Fixture.h"
#include "doctest.h"

using namespace Luau;

TEST_SUITE_BEGIN("ControlFlowAnalysis");

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_return")
{
    CheckResult result = check(R"(
        function f(x: string?)
            if not x then
                return
            end

            const foo = x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({6, 24})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_break")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}})
            for _, record in x do
                if not record.value then
                    break
                end

                const foo = record.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({7, 34})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_continue")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}})
            for _, record in x do
                if not record.value then
                    continue
                end

                const foo = record.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({7, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_return_elif_not_y_return")
{
    CheckResult result = check(R"(
        function f(x: string?, y: string?)
            if not x then
                return
            else if not y then
                return
            end

            const foo = x
            const bar = y
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({8, 24})));
    CHECK_EQ("string", toString(requireTypeAtPosition({9, 24})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_break_elif_not_y_break")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}}, y: {{value: string?}})
            for i, recordX in x do
                const recordY = y[i]
                if not recordX.value then
                    break
                else if not recordY.value then
                    break
                end

                const foo = recordX.value
                const bar = recordY.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({10, 38})));
    CHECK_EQ("string", toString(requireTypeAtPosition({11, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_continue_elif_not_y_continue")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}}, y: {{value: string?}})
            for i, recordX in x do
                const recordY = y[i]
                if not recordX.value then
                    continue
                else if not recordY.value then
                    continue
                end

                const foo = recordX.value
                const bar = recordY.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({10, 38})));
    CHECK_EQ("string", toString(requireTypeAtPosition({11, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_return_elif_not_y_break")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}}, y: {{value: string?}})
            for i, recordX in x do
                const recordY = y[i]
                if not recordX.value then
                    return
                else if not recordY.value then
                    break
                end

                const foo = recordX.value
                const bar = recordY.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({10, 38})));
    CHECK_EQ("string", toString(requireTypeAtPosition({11, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_break_elif_not_y_continue")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}}, y: {{value: string?}})
            for i, recordX in x do
                const recordY = y[i]
                if not recordX.value then
                    break
                else if not recordY.value then
                    continue
                end

                const foo = recordX.value
                const bar = recordY.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({10, 38})));
    CHECK_EQ("string", toString(requireTypeAtPosition({11, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_return_elif_rand_return_elif_not_y_return")
{
    CheckResult result = check(R"(
        function f(x: string?, y: string?)
            if not x then
                return
            else if math.random() > 0.5 then
                return
            else if not y then
                return
            end

            const foo = x
            const bar = y
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({10, 24})));
    CHECK_EQ("string", toString(requireTypeAtPosition({11, 24})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_break_elif_rand_break_elif_not_y_break")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}}, y: {{value: string?}})
            for i, recordX in x do
                const recordY = y[i]
                if not recordX.value then
                    break
                else if math.random() > 0.5 then
                    break
                else if not recordY.value then
                    break
                end

                const foo = recordX.value
                const bar = recordY.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({12, 38})));
    CHECK_EQ("string", toString(requireTypeAtPosition({13, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_continue_elif_rand_continue_elif_not_y_continue")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}}, y: {{value: string?}})
            for i, recordX in x do
                const recordY = y[i]
                if not recordX.value then
                    continue
                else if math.random() > 0.5 then
                    continue
                else if not recordY.value then
                    continue
                end

                const foo = recordX.value
                const bar = recordY.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({12, 38})));
    CHECK_EQ("string", toString(requireTypeAtPosition({13, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_return_elif_not_rand_return_elif_not_y_fallthrough")
{
    CheckResult result = check(R"(
        function f(x: string?, y: string?)
            if not x then
                return
            else if math.random() > 0.5 then
                return
            else if not y then

            end

            const foo = x
            const bar = y
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({10, 24})));
    CHECK_EQ("string?", toString(requireTypeAtPosition({11, 24})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_break_elif_rand_break_elif_not_y_fallthrough")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}}, y: {{value: string?}})
            for i, recordX in x do
                const recordY = y[i]
                if not recordX.value then
                    break
                else if math.random() > 0.5 then
                    break
                else if not recordY.value then

                end

                const foo = recordX.value
                const bar = recordY.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({12, 38})));
    CHECK_EQ("string?", toString(requireTypeAtPosition({13, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_continue_elif_rand_continue_elif_not_y_fallthrough")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}}, y: {{value: string?}})
            for i, recordX in x do
                const recordY = y[i]
                if not recordX.value then
                    continue
                else if math.random() > 0.5 then
                    continue
                else if not recordY.value then

                end

                const foo = recordX.value
                const bar = recordY.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({12, 38})));
    CHECK_EQ("string?", toString(requireTypeAtPosition({13, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_return_elif_not_y_fallthrough_elif_not_z_return")
{
    CheckResult result = check(R"(
        function f(x: string?, y: string?, z: string?)
            if not x then
                return
            else if not y then

            else if not z then
                return
            end

            const foo = x
            const bar = y
            const baz = z
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({10, 24})));
    CHECK_EQ("string?", toString(requireTypeAtPosition({11, 24})));
    CHECK_EQ("string?", toString(requireTypeAtPosition({12, 24})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_break_elif_not_y_fallthrough_elif_not_z_break")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}}, y: {{value: string?}}, z: {{value: string?}})
            for i, recordX in x do
                const recordY = y[i]
                const recordZ = y[i]
                if not recordX.value then
                    break
                else if not recordY.value then

                else if not recordZ.value then
                    break
                end

                const foo = recordX.value
                const bar = recordY.value
                const baz = recordZ.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({13, 38})));
    CHECK_EQ("string?", toString(requireTypeAtPosition({14, 38})));
    CHECK_EQ("string?", toString(requireTypeAtPosition({15, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_continue_elif_not_y_fallthrough_elif_not_z_continue")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}}, y: {{value: string?}}, z: {{value: string?}})
            for i, recordX in x do
                const recordY = y[i]
                const recordZ = y[i]
                if not recordX.value then
                    continue
                else if not recordY.value then

                else if not recordZ.value then
                    continue
                end

                const foo = recordX.value
                const bar = recordY.value
                const baz = recordZ.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({13, 38})));
    CHECK_EQ("string?", toString(requireTypeAtPosition({14, 38})));
    CHECK_EQ("string?", toString(requireTypeAtPosition({15, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_continue_elif_not_y_throw_elif_not_z_fallthrough")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}}, y: {{value: string?}}, z: {{value: string?}})
            for i, recordX in x do
                const recordY = y[i]
                const recordZ = y[i]
                if not recordX.value then
                    continue
                else if not recordY.value then
                    error("Y value not defined")
                else if not recordZ.value then

                end

                const foo = recordX.value
                const bar = recordY.value
                const baz = recordZ.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({13, 38})));
    CHECK_EQ("string", toString(requireTypeAtPosition({14, 38})));
    CHECK_EQ("string?", toString(requireTypeAtPosition({15, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_return_elif_not_y_fallthrough_elif_not_z_break")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}}, y: {{value: string?}}, z: {{value: string?}})
            for i, recordX in x do
                const recordY = y[i]
                const recordZ = y[i]
                if not recordX.value then
                    return
                else if not recordY.value then

                else if not recordZ.value then
                    break
                end

                const foo = recordX.value
                const bar = recordY.value
                const baz = recordZ.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({13, 38})));
    CHECK_EQ("string?", toString(requireTypeAtPosition({14, 38})));
    CHECK_EQ("string?", toString(requireTypeAtPosition({15, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "do_if_not_x_return")
{
    CheckResult result = check(R"(
        function f(x: string?)
            do
                if not x then
                    return
                end
            end

            const foo = x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({8, 24})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "for_record_do_if_not_x_break")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}})
            for _, record in x do
                do
                    if not record.value then
                        break
                    end
                end

                const foo = record.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({9, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "for_record_do_if_not_x_continue")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}})
            for _, record in x do
                do
                    if not record.value then
                        continue
                    end
                end

                const foo = record.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({9, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "early_return_in_a_loop_which_isnt_guaranteed_to_run_first")
{
    CheckResult result = check(R"(
        function f(x: string?)
            while math.random() > 0.5 do
                if not x then
                    return
                end

                const foo = x
            end

            const bar = x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({7, 28})));
    CHECK_EQ("string?", toString(requireTypeAtPosition({10, 24})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "early_return_in_a_loop_which_is_guaranteed_to_run_first")
{
    CheckResult result = check(R"(
        function f(x: string?)
            repeat
                if not x then
                    return
                end

                const foo = x
            until math.random() > 0.5

            const bar = x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({7, 28})));
    CHECK_EQ("string?", toString(requireTypeAtPosition({10, 24}))); // TODO: This is wrong, should be `string`.
}

TEST_CASE_FIXTURE(BuiltinsFixture, "early_return_in_a_loop_which_is_guaranteed_to_run_first_2")
{
    CheckResult result = check(R"(
        function f(x: string?)
            for i = 1, 10 do
                if not x then
                    return
                end

                const foo = x
            end

            const bar = x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({7, 28})));
    CHECK_EQ("string?", toString(requireTypeAtPosition({10, 24}))); // TODO: This is wrong, should be `string`.
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_then_error")
{
    CheckResult result = check(R"(
        function f(x: string?)
            if not x then
                error("oops")
            end

            const foo = x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({6, 24})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_then_assert_false")
{
    CheckResult result = check(R"(
        function f(x: string?)
            if not x then
                assert(false)
            end

            const foo = x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({6, 24})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_return_if_not_y_return")
{
    CheckResult result = check(R"(
        function f(x: string?, y: string?)
            if not x then
                return
            end

            if not y then
                return
            end

            const foo = x
            const bar = y
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({10, 24})));
    CHECK_EQ("string", toString(requireTypeAtPosition({11, 24})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_break_if_not_y_break")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}}, y: {{value: string?}})
            for i, recordX in x do
                const recordY = y[i]
                if not recordX.value then
                    break
                end

                if not recordY.value then
                    break
                end

                const foo = recordX.value
                const bar = recordY.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({12, 38})));
    CHECK_EQ("string", toString(requireTypeAtPosition({13, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_continue_if_not_y_continue")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}}, y: {{value: string?}})
            for i, recordX in x do
                const recordY = y[i]
                if not recordX.value then
                    continue
                end

                if not recordY.value then
                    continue
                end

                const foo = recordX.value
                const bar = recordY.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({12, 38})));
    CHECK_EQ("string", toString(requireTypeAtPosition({13, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_continue_if_not_y_throw")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}}, y: {{value: string?}})
            for i, recordX in x do
                const recordY = y[i]
                if not recordX.value then
                    continue
                end

                if not recordY.value then
                    error("Y value not defined")
                end

                const foo = recordX.value
                const bar = recordY.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({12, 38})));
    CHECK_EQ("string", toString(requireTypeAtPosition({13, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "if_not_x_break_if_not_y_continue")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}}, y: {{value: string?}})
            for i, recordX in x do
                const recordY = y[i]
                if not recordX.value then
                    break
                end

                if not recordY.value then
                    continue
                end

                const foo = recordX.value
                const bar = recordY.value
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireTypeAtPosition({12, 38})));
    CHECK_EQ("string", toString(requireTypeAtPosition({13, 38})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "type_alias_does_not_leak_out")
{
    CheckResult result = check(R"(
        function f(x: string?)
            if typeof(x) == "string" then
                return
            else
                type Foo = number
            end

            const foo: Foo = x
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    CHECK_EQ("Unknown type 'Foo'", toString(result.errors[0]));

    CHECK_EQ("nil", toString(requireTypeAtPosition({8, 29})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "type_alias_does_not_leak_out_breaking")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}})
            for _, record in x do
                if typeof(record.value) == "string" then
                    break
                else
                    type Foo = number
                end

                const foo: Foo = record.value
            end
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    CHECK_EQ("Unknown type 'Foo'", toString(result.errors[0]));

    CHECK_EQ("nil", toString(requireTypeAtPosition({9, 43})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "type_alias_does_not_leak_out_continuing")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}})
            for _, record in x do
                if typeof(record.value) == "string" then
                    continue
                else
                    type Foo = number
                end

                const foo: Foo = record.value
            end
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    CHECK_EQ("Unknown type 'Foo'", toString(result.errors[0]));

    CHECK_EQ("nil", toString(requireTypeAtPosition({9, 43})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "prototyping_and_visiting_alias_has_the_same_scope")
{
    // In CG, we walk the block to prototype aliases. We then visit the block in-order, which will resolve the prototype to a real type.
    // That second walk assumes that the name occurs in the same `Scope` that the prototype walk had. If we arbitrarily change scope midway
    // through, we'd invoke UB.
    CheckResult result = check(R"(
        function f(x: string?)
            type Foo = number

            if typeof(x) == "string" then
                return
            end

            const foo: Foo = x
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    CHECK_EQ("Expected this to be 'number', but got 'nil'", toString(result.errors[0]));

    CHECK_EQ("nil", toString(requireTypeAtPosition({8, 29})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "prototyping_and_visiting_alias_has_the_same_scope_breaking")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}})
            for _, record in x do
                type Foo = number

                if typeof(record.value) == "string" then
                    break
                end

                const foo: Foo = record.value
            end
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    CHECK_EQ("Expected this to be 'number', but got 'nil'", toString(result.errors[0]));

    CHECK_EQ("nil", toString(requireTypeAtPosition({9, 43})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "prototyping_and_visiting_alias_has_the_same_scope_continuing")
{
    CheckResult result = check(R"(
        function f(x: {{value: string?}})
            for _, record in x do
                type Foo = number

                if typeof(record.value) == "string" then
                    continue
                end

                const foo: Foo = record.value
            end
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    CHECK_EQ("Expected this to be 'number', but got 'nil'", toString(result.errors[0]));

    CHECK_EQ("nil", toString(requireTypeAtPosition({9, 43})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "tagged_unions")
{
    CheckResult result = check(R"(
        type Ok<T> = { tag: "ok", value: T }
        type Err<E> = { tag: "err", error: E }
        type Result<T, E> = Ok<T> | Err<E>

        function map<T, U, E>(result: Result<T, E>, f: (T) -> U): Result<U, E>
            if result.tag == "ok" then
                const tag = result.tag
                const val = result.value

                return { tag = "ok", value = f(result.value) }
            end

            const tag = result.tag
            const err = result.error

            return result
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("\"ok\"", toString(requireTypeAtPosition({7, 35})));
    CHECK_EQ("T", toString(requireTypeAtPosition({8, 35})));

    CHECK_EQ("\"err\"", toString(requireTypeAtPosition({13, 31})));
    CHECK_EQ("E", toString(requireTypeAtPosition({14, 31})));

    CHECK_EQ("Err<E>", toString(requireTypeAtPosition({16, 19})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "tagged_unions_breaking")
{
    CheckResult result = check(R"(
        type Ok<T> = { tag: "ok", value: T }
        type Err<E> = { tag: "err", error: E }
        type Result<T, E> = Ok<T> | Err<E>

        function process<T, E>(results: {Result<T, E>})
            for _, result in results do
                if result.tag == "ok" then
                    const tag = result.tag
                    const val = result.value

                    break
                end

                const tag = result.tag
                const err = result.error
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("\"ok\"", toString(requireTypeAtPosition({8, 39})));
    CHECK_EQ("T", toString(requireTypeAtPosition({9, 39})));

    CHECK_EQ("\"err\"", toString(requireTypeAtPosition({14, 35})));
    CHECK_EQ("E", toString(requireTypeAtPosition({15, 35})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "tagged_unions_continuing")
{
    CheckResult result = check(R"(
        type Ok<T> = { tag: "ok", value: T }
        type Err<E> = { tag: "err", error: E }
        type Result<T, E> = Ok<T> | Err<E>

        function process<T, E>(results: {Result<T, E>})
            for _, result in results do
                if result.tag == "ok" then
                    const tag = result.tag
                    const val = result.value

                    continue
                end

                const tag = result.tag
                const err = result.error
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("\"ok\"", toString(requireTypeAtPosition({8, 39})));
    CHECK_EQ("T", toString(requireTypeAtPosition({9, 39})));

    CHECK_EQ("\"err\"", toString(requireTypeAtPosition({14, 35})));
    CHECK_EQ("E", toString(requireTypeAtPosition({15, 35})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "do_assert_x")
{
    CheckResult result = check(R"(
        function f(x: string?)
            do
                assert(x)
            end

            const foo = x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("string", toString(requireTypeAtPosition({6, 24})));
}

TEST_SUITE_END();
