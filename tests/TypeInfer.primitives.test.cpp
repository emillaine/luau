// This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details

#include "Luau/Type.h"
#include "Luau/VisitType.h"

#include "Fixture.h"

#include "doctest.h"

using namespace Luau;

TEST_SUITE_BEGIN("TypeInferPrimitives");

TEST_CASE_FIXTURE(Fixture, "cannot_call_primitives")
{
    CheckResult result = check("const foo = 5    foo()");
    LUAU_REQUIRE_ERROR_COUNT(1, result);

    REQUIRE(get<CannotCallNonFunction>(result.errors[0]) != nullptr);
}

TEST_CASE_FIXTURE(Fixture, "string_length")
{
    CheckResult result = check(R"(
        const s = "Hello, World!"
        const t = s.count
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ(getBuiltins()->numberType, requireType("t"));
}

TEST_CASE_FIXTURE(Fixture, "string_index")
{
    CheckResult result = check(R"(
        const s = "Hello, World!"
        const t = s[4]
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    NotATable* nat = get<NotATable>(result.errors[0]);
    REQUIRE(nat);
    CHECK_EQ("string", toString(nat->ty));

    CHECK_EQ("*error-type*", toString(requireType("t")));
}

TEST_CASE_FIXTURE(Fixture, "string_method")
{
    CheckResult result = check(R"(
        const p = ("tacos"):len()
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("number" == toString(requireType("p")));
}

TEST_CASE_FIXTURE(Fixture, "string_function_indirect")
{
    CheckResult result = check(R"(
        const s:string = ""
        const l = s.lower
        const p = l(s)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("string" == toString(requireType("p")));
}

TEST_CASE_FIXTURE(Fixture, "check_methods_of_number")
{
    CheckResult result = check(R"(
        const x: number = 9999
        function x:y(z: number)
            const s: string = z
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(2, result);

    if (!FFlag::DebugLuauForceOldSolver)
    {
        CHECK("Expected type table, got 'number' instead" == toString(result.errors[0]));
        CHECK("Expected this to be 'string', but got 'number'" == toString(result.errors[1]));
    }
    else
    {
        CHECK_EQ(toString(result.errors[0]), "Cannot add method to non-table type 'number'");
        CHECK("Expected this to be 'string', but got 'number'" == toString(result.errors[1]));
    }
}

TEST_CASE("singleton_types")
{
    BuiltinsFixture a;

    {
        BuiltinsFixture b;
    }

    // Check that Frontend 'a' environment wasn't modified by 'b'
    CheckResult result = a.check("const s: string = 'hello' const t = s:lower()");

    CHECK(result.errors.empty());
}

TEST_CASE_FIXTURE(BuiltinsFixture, "property_of_buffers")
{
    CheckResult result = check(R"(
        const b = buffer.create(100)
        print(b.foo)
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "properties_of_vectors")
{
    CheckResult result = check(R"(
        const a = vector.create(1, 2, 3)
        const b = vector.create(4, 5, 6)

        const t1 = {
            a + b,
            a - b,
            a * 3,
            a * b,
            3 * b,
            a / 3,
            a / b,
            3 / b,
            a // 4,
            a // b,
            4 // b,
            -a,
        }
        const t2 = {
            a.x,
            a.y,
            a.z,
        }
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_SUITE_END();
