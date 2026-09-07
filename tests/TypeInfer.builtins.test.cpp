// This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
#include "Luau/TypeInfer.h"
#include "Luau/BuiltinDefinitions.h"
#include "Luau/Common.h"

#include "Fixture.h"

#include "ScopedFlags.h"
#include "doctest.h"

using namespace Luau;

LUAU_FASTFLAG(DebugLuauForceOldSolver)
LUAU_FASTFLAG(LuauNewTypePathErrorMessages)
LUAU_FASTFLAG(LuauExportValueSyntax)

TEST_SUITE_BEGIN("BuiltinTests");

TEST_CASE_FIXTURE(BuiltinsFixture, "math_things_are_defined")
{
    CheckResult result = check(R"(
        const a00 = math.frexp
        const a01 = math.ldexp
        const a02 = math.fmod
        const a03 = math.modf
        const a04 = math.pow
        const a05 = math.exp
        const a06 = math.floor
        const a07 = math.abs
        const a08 = math.sqrt
        const a09 = math.log
        const a10 = math.log10
        const a11 = math.rad
        const a12 = math.deg
        const a13 = math.sin
        const a14 = math.cos
        const a15 = math.tan
        const a16 = math.sinh
        const a17 = math.cosh
        const a18 = math.tanh
        const a19 = math.atan
        const a20 = math.acos
        const a21 = math.asin
        const a22 = math.atan2
        const a23 = math.ceil
        const a24 = math.min
        const a25 = math.max
        const a26 = math.pi
        const a27 = math.huge
        const a28 = math.nan
        const a29 = math.e
        const a30 = math.phi
        const a31 = math.sqrt2
        const a32 = math.tau
        const a33 = math.randomseed
        const a34 = math.random
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "next_iterator_should_infer_types_and_type_check")
{
    CheckResult result = check(R"(
        const a: string, b: number = next({ 1 })

        const s = "foo"
        const t = { [s] = 1 }
        const c: string?, d: number = next(t)
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "pairs_iterator_should_infer_types_and_type_check")
{
    CheckResult result = check(R"(
        type Map<K, V> = { [K]: V }
        const map: Map<string, number> = { ["foo"] = 1, ["bar"] = 2, ["baz"] = 3 }

        const it: (Map<string, number>, string | null) -> (string?, number), t: Map<string, number>, i: null = pairs(map)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "ipairs_iterator_should_infer_types_and_type_check")
{
    CheckResult result = check(R"(
        type Map<K, V> = { [K]: V }
        const array: Map<number, string> = { "foo", "bar", "baz" }

        const it: (Map<number, string>, number) -> (number?, string), t: Map<number, string>, i: number = ipairs(array)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_dot_remove_optionally_returns_generic")
{
    CheckResult result = check(R"(
        const t = { 1 }
        const n = table.remove(t, 7)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ(toString(requireType("n")), "number?");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_concat_returns_string")
{
    CheckResult result = check(R"(
        const r = table.concat({1,2,3,4}, ",", 2);
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("string" == toString(requireType("r")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "sort")
{
    CheckResult result = check(R"(
        const t = {1, 2, 3};
        table.sort(t)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "sort_with_predicate")
{
    CheckResult result = check(R"(
        #!strict
        const t = {1, 2, 3}
        function p(a: number, b: number) return a < b end
        table.sort(t, p)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "sort_with_bad_predicate")
{
    DOES_NOT_PASS_NEW_SOLVER_GUARD();

    CheckResult result = check(R"(
        #!strict
        const t = {'one', 'two', 'three'}
        function p(a: number, b: number) return a < b end
        table.sort(t, p)
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    const std::string expected = "Expected this to be\n\t"
                                 "'((string, string) -> boolean)?'"
                                 "\nbut got\n\t"
                                 "'(number, number) -> boolean'"
                                 "\ncaused by:\n"
                                 "  None of the union options are compatible. For example:\n"
                                 "Expected this to be\n\t"
                                 "'(string, string) -> boolean'"
                                 "\nbut got\n\t"
                                 "'(number, number) -> boolean'"
                                 "\ncaused by:\n"
                                 "  Argument #1 type is not compatible.\n"
                                 "Expected this to be 'number', but got 'string'";
    CHECK_EQ(expected, toString(result.errors[0]));
}

TEST_CASE_FIXTURE(Fixture, "strings_have_methods")
{
    CheckResult result = check(R"LUA(
        const s = ("RoactHostChangeEvent(%s)"):format("hello")
    )LUA");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("string" == toString(requireType("s")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "math_max_variatic")
{
    CheckResult result = check(R"(
        const n = math.max(1,2,3,4,5,6,7,8,9,0)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("number" == toString(requireType("n")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "math_max_checks_for_numbers")
{
    CheckResult result = check(R"(
        const n = math.max(1,2,"3")
    )");

    LUAU_REQUIRE_ERRORS(result);
    CHECK_EQ("Expected this to be 'number', but got 'string'", toString(result.errors[0]));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "builtin_tables_sealed")
{
    CheckResult result = check(R"LUA(
        const b = bit32
    )LUA");
    TypeId bit32 = requireType("b");
    REQUIRE(bit32 != nullptr);
    const TableType* bit32t = get<TableType>(bit32);
    REQUIRE(bit32t != nullptr);
    CHECK_EQ(bit32t->state, TableState::Sealed);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "lua_51_exported_globals_all_exist")
{
    // Extracted from lua5.1
    CheckResult result = check(R"(
        const v__G = _G
        const v_string_sub = string.sub
        const v_string_upper = string.upper
        const v_string_len = string.len
        const v_string_rep = string.rep
        const v_string_find = string.find
        const v_string_match = string.match
        const v_string_char = string.char
        const v_string_gmatch = string.gmatch
        const v_string_reverse = string.reverse
        const v_string_byte = string.byte
        const v_string_format = string.format
        const v_string_gsub = string.gsub
        const v_string_lower = string.lower

        const v_xpcall = xpcall

        #local v_package_loadlib = package.loadlib
        #local v_package_loaders_1_ = package.loaders[1]
        #local v_package_loaders_2_ = package.loaders[2]
        #local v_package_loaders_3_ = package.loaders[3]
        #local v_package_loaders_4_ = package.loaders[4]

        const v_tostring = tostring
        const v_print = print

        #local v_os_exit = os.exit
        #local v_os_setlocale = os.setlocale
        const v_os_date = os.date
        #local v_os_getenv = os.getenv
        const v_os_difftime = os.difftime
        #local v_os_remove = os.remove
        const v_os_time = os.time
        #local v_os_clock = os.clock
        #local v_os_tmpname = os.tmpname
        #local v_os_rename = os.rename
        #local v_os_execute = os.execute

        const v_unpack = unpack
        const v_require = require
        const v_getfenv = getfenv
        const v_setmetatable = setmetatable
        const v_next = next
        const v_assert = assert
        const v_tonumber = tonumber

        #local v_io_lines = io.lines
        #local v_io_write = io.write
        #local v_io_close = io.close
        #local v_io_flush = io.flush
        #local v_io_open = io.open
        #local v_io_output = io.output
        #local v_io_type = io.type
        #local v_io_read = io.read
        #local v_io_stderr = io.stderr
        #local v_io_stdin = io.stdin
        #local v_io_input = io.input
        #local v_io_stdout = io.stdout
        #local v_io_popen = io.popen
        #local v_io_tmpfile = io.tmpfile

        const v_rawequal = rawequal
        #local v_collectgarbage = collectgarbage
        const v_getmetatable = getmetatable
        const v_rawset = rawset

        const v_math_log = math.log
        const v_math_max = math.max
        const v_math_acos = math.acos
        const v_math_huge = math.huge
        const v_math_ldexp = math.ldexp
        const v_math_pi = math.pi
        const v_math_cos = math.cos
        const v_math_tanh = math.tanh
        const v_math_pow = math.pow
        const v_math_deg = math.deg
        const v_math_tan = math.tan
        const v_math_cosh = math.cosh
        const v_math_sinh = math.sinh
        const v_math_random = math.random
        const v_math_randomseed = math.randomseed
        const v_math_frexp = math.frexp
        const v_math_ceil = math.ceil
        const v_math_floor = math.floor
        const v_math_rad = math.rad
        const v_math_abs = math.abs
        const v_math_sqrt = math.sqrt
        const v_math_modf = math.modf
        const v_math_asin = math.asin
        const v_math_min = math.min
        #local v_math_mod = math.mod
        const v_math_fmod = math.fmod
        const v_math_log10 = math.log10
        const v_math_atan2 = math.atan2
        const v_math_exp = math.exp
        const v_math_sin = math.sin
        const v_math_atan = math.atan

        #local v_debug_getupvalue = debug.getupvalue
        #local v_debug_debug = debug.debug
        #local v_debug_sethook = debug.sethook
        #local v_debug_getmetatable = debug.getmetatable
        #local v_debug_gethook = debug.gethook
        #local v_debug_setmetatable = debug.setmetatable
        #local v_debug_setlocal = debug.setlocal
        #local v_debug_traceback = debug.traceback
        #local v_debug_setfenv = debug.setfenv
        #local v_debug_getinfo = debug.getinfo
        #local v_debug_setupvalue = debug.setupvalue
        #local v_debug_getlocal = debug.getlocal
        #local v_debug_getregistry = debug.getregistry
        #local v_debug_getfenv = debug.getfenv

        const v_pcall = pcall

        #local v_table_setn = table.setn
        const v_table_insert = table.insert
        #local v_table_getn = table.getn
        #local v_table_foreachi = table.foreachi
        const v_table_maxn = table.maxn
        #local v_table_foreach = table.foreach
        const v_table_concat = table.concat
        const v_table_sort = table.sort
        const v_table_remove = table.remove

        const v_newproxy = newproxy
        const v_type = type

        const v_coroutine_resume = coroutine.resume
        const v_coroutine_yield = coroutine.yield
        const v_coroutine_status = coroutine.status
        const v_coroutine_wrap = coroutine.wrap
        const v_coroutine_create = coroutine.create
        const v_coroutine_running = coroutine.running

        const v_select = select
        const v_gcinfo = gcinfo
        const v_pairs = pairs
        const v_rawget = rawget
        const v_loadstring = loadstring
        const v_ipairs = ipairs
        const v__VERSION = _VERSION
        #local v_dofile = dofile
        const v_setfenv = setfenv
        #local v_load = load
        const v_error = error
        #local v_loadfile = loadfile
    )");

    dumpErrors(result);
    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "setmetatable_unpacks_arg_types_correctly")
{
    CheckResult result = check(R"(
        setmetatable({}, setmetatable({}, {}))
    )");
    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "setmetatable_on_union_of_tables")
{
    CheckResult result = check(R"(
        type A = {tag: "A", x: number}
        type B = {tag: "B", y: string}

        type T = A | B

        type X = typeof(
            setmetatable({} as T, {})
        )
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    if (!FFlag::DebugLuauForceOldSolver)
        CHECK("{ @metatable {  }, A } | { @metatable {  }, B }" == toString(requireTypeAlias("X")));
    else
        CHECK("{ @metatable {|  |}, A } | { @metatable {|  |}, B }" == toString(requireTypeAlias("X")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_insert_correctly_infers_type_of_array_2_args_overload")
{
    CheckResult result = check(R"(
        const t = {}
        table.insert(t, "foo")
        const s = t[1]
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ(getBuiltins()->stringType, requireType("s"));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_insert_correctly_infers_type_of_array_3_args_overload")
{
    CheckResult result = check(R"(
        const t = {}
        table.insert(t, 1, "foo")
        const s = t[1]
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireType("s")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_insert_method_call")
{
    CheckResult result = check(R"(
        const t = {}
        t:insert("foo")
        t:insert(1, "bar")
        const s = t[1]
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("string", toString(requireType("s")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "buffer_method_call")
{
    CheckResult result = check(R"(
        const b = buffer.create(8)
        b:writeu8(0, 42)
        const n = b:readu8(0)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ(getBuiltins()->numberType, requireType("n"));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "vector_method_call")
{
    CheckResult result = check(R"(
        const v = vector.create(1, 2, 3)
        const m = v:magnitude()
        const w = v:normalize()
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ(getBuiltins()->numberType, requireType("m"));
    CHECK_EQ("vector", toString(requireType("w")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_pack")
{
    CheckResult result = check(R"(
        const t = table.pack(1, "foo", true)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("{ [number]: boolean | number | string, n: number }", toString(requireType("t")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_pack_variadic")
{
    CheckResult result = check(R"(
#!strict
function f(): (string, ...number)
    return "str", 2, 3, 4
end

const t = table.pack(f())
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("{ [number]: number | string, n: number }", toString(requireType("t")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_pack_reduce_1")
{
    CheckResult result = check(R"(
        const t = table.pack(1, 2, true)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("{ [number]: boolean | number, n: number }", toString(requireType("t")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_pack_reduce_2")
{
    CheckResult result = check(R"(
        const t = table.pack("a", "b", "c")
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    auto ty = requireType("t");

    if (!FFlag::DebugLuauForceOldSolver)
    {
        // FIXME: This is a result of us solving for `table.pack` before we
        // generalize its arguments. After we've solved it, we end up
        // with a type like:
        //
        //  { n: number, [number]: ("a" <: 'a <: string) | ("b" <: 'b <: string) | ("c" <: 'c <: string) }
        //
        // ... which we cannot reasonably know to simplify at this time.
        CHECK_EQ("{ [number]: string | string | string, n: number }", toString(ty));
    }
    else
    {
        CHECK_EQ("{ [number]: string, n: number }", toString(ty));
    }
}

TEST_CASE_FIXTURE(BuiltinsFixture, "gcinfo")
{
    CheckResult result = check(R"(
        const n = gcinfo()
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("number" == toString(requireType("n")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "getfenv")
{
    LUAU_REQUIRE_NO_ERRORS(check("getfenv(1)"));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "os_time_takes_optional_date_table")
{
    CheckResult result = check(R"(
        const n1 = os.time()
        const n2 = os.time({ year = 2020, month = 4, day = 20 })
        const n3 = os.time({ year = 2020, month = 4, day = 20, hour = 0, min = 0, sec = 0, isdst = true })
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("number" == toString(requireType("n1")));
    CHECK("number" == toString(requireType("n2")));
    CHECK("number" == toString(requireType("n3")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "thread_is_a_type")
{
    CheckResult result = check(R"(
        const co = coroutine.create(function() end)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("thread" == toString(requireType("co")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "buffer_is_a_type")
{
    CheckResult result = check(R"(
        const b = buffer.create(10)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK("buffer" == toString(requireType("b")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "coroutine_resume_anything_goes")
{
    CheckResult result = check(R"(
        function nifty(x, y)
            print(x, y)
            const z = coroutine.yield(1, 2)
            print(z)
            return 42
        end

        const co = coroutine.create(nifty)
        const x, y = coroutine.resume(co, 1, 2)
        const answer = coroutine.resume(co, 3)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "coroutine_wrap_anything_goes")
{
    CheckResult result = check(R"(
        #!nonstrict
        function nifty(x, y)
            print(x, y)
            const z = coroutine.yield(1, 2)
            print(z)
            return 42
        end

        const f = coroutine.wrap(nifty)
        const x, y = f(1, 2)
        const answer = f(3)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "setmetatable_should_not_mutate_persisted_types")
{
    if (!FFlag::DebugLuauForceOldSolver)
        return;

    CheckResult result = check(R"(
        const string = string

        setmetatable(string, {})
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    auto stringType = requireType("string");
    auto ttv = get<TableType>(stringType);
    REQUIRE(ttv);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "string_format_arg_types_inference")
{
    CheckResult result = check(R"(
        #!strict
        function f(a, b, c)
            return string.format("%f %d %s", a, b, c)
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("(number, number, string) -> string", toString(requireType("f")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "string_format_arg_count_mismatch")
{
    CheckResult result = check(R"(
        #!strict
        string.format("%f %d %s")
        string.format("%s", "hi", 42)
        string.format("%s", "hi", 42, ...)
        string.format("%s", "hi", ...)
    )");

    LUAU_REQUIRE_ERROR_COUNT(3, result);
    CHECK_EQ(result.errors[0].location.begin.line, 2);
    CHECK_EQ(result.errors[1].location.begin.line, 3);
    CHECK_EQ(result.errors[2].location.begin.line, 4);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "string_format_correctly_ordered_types")
{
    // CLI-115690
    if (!FFlag::DebugLuauForceOldSolver)
        return;

    CheckResult result = check(R"(
        #!strict
        string.format("%s", 123)
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    TypeMismatch* tm = get<TypeMismatch>(result.errors[0]);
    REQUIRE(tm);
    CHECK_EQ(tm->wantedType, getBuiltins()->stringType);
    CHECK_EQ(tm->givenType, getBuiltins()->numberType);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "string_format_tostring_specifier")
{
    CheckResult result = check(R"(
        #!strict
        string.format("%* %* %* %*", "string", 1, true, function() end)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "string_format_tostring_specifier_type_constraint")
{
    CheckResult result = check(R"(
        function f(x): string
            const _ = string.format("%*", x)
            return x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("(string) -> string", toString(requireType("f")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "xpcall")
{
    CheckResult result = check(R"(
        #!strict
        const a, b, c = xpcall(
            function() return 5, true end,
            function(e) return 0, false end
        )
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("boolean", toString(requireType("a")));
    CHECK_EQ("number", toString(requireType("b")));
    CHECK_EQ("boolean", toString(requireType("c")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "pcall_returns_at_least_two_value_but_function_returns_nothing")
{
    // We have no plans to fix this in the old solver.
    if (FFlag::DebugLuauForceOldSolver)
        return;

    CheckResult result = check(R"(
        function f(): () end
        const ok, res = pcall(f)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("boolean", toString(requireType("ok")));
    CHECK_EQ("unknown", toString(requireType("res")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "trivial_select")
{
    CheckResult result = check(R"(
        const a:number = select(1, 42)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "see_thru_select")
{
    CheckResult result = check(R"(
        const a:number, b:boolean = select(2,"hi", 10, true)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "see_thru_select_count")
{
    CheckResult result = check(R"(
        const a = select("#","hi", 10, true)
    )");

    dumpErrors(result);
    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "select_with_decimal_argument_is_rounded_down")
{
    CheckResult result = check(R"(
        const a: number, b: boolean = select(2.9, "foo", 1, true)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

// Could be flaky if the fix has regressed.
TEST_CASE_FIXTURE(BuiltinsFixture, "bad_select_should_not_crash")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    CheckResult result = check(R"(
        do end
        export _ = function(l0,...)
        end
        const _ = function()
            _(_);
            _ += select(_())
        end
    )");

    if (!FFlag::DebugLuauForceOldSolver)
    {
        // Note, the function "_" places no constraints on its arguments.  They
        // can therefore be null.  They are therefore optional.  Only the
        // select() call is invalid here.
        LUAU_REQUIRE_ERROR_COUNT(1, result);

        CHECK(Location{{6, 17}, {6, 23}} == result.errors.at(0).location);
        const CountMismatch* err = get<CountMismatch>(result.errors.at(0));
        REQUIRE(err);
        CHECK(1 == err->expected);

        // "_" returns 0 values.
        CHECK(0 == err->actual);
    }
    else if (!FFlag::DebugLuauForceOldSolver)
    {
        LUAU_REQUIRE_ERROR_COUNT(2, result);
        CHECK_EQ("Argument count mismatch. Function expects at least 1 argument, but none are specified", toString(result.errors[0]));
        CHECK_EQ("Argument count mismatch. Function expects at least 1 argument, but none are specified", toString(result.errors[1]));
    }
    else
    {
        LUAU_REQUIRE_ERROR_COUNT(2, result);
        CHECK_EQ("Argument count mismatch. Function '_' expects at least 1 argument, but none are specified", toString(result.errors[0]));
        CHECK_EQ("Argument count mismatch. Function 'select' expects 1 argument, but none are specified", toString(result.errors[1]));
    }
}

TEST_CASE_FIXTURE(BuiltinsFixture, "select_way_out_of_range")
{
    // CLI-115720
    if (!FFlag::DebugLuauForceOldSolver)
        return;

    CheckResult result = check(R"(
        select(5432598430953240958)
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    REQUIRE(get<GenericError>(result.errors[0]));
    CHECK_EQ("bad argument #1 to select (index out of range)", toString(result.errors[0]));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "select_slightly_out_of_range")
{
    // CLI-115720
    if (!FFlag::DebugLuauForceOldSolver)
        return;

    CheckResult result = check(R"(
        select(3, "a", 1)
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    REQUIRE(get<GenericError>(result.errors[0]));
    CHECK_EQ("bad argument #1 to select (index out of range)", toString(result.errors[0]));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "select_with_variadic_typepack_tail")
{
    CheckResult result = check(R"(
        #!nonstrict
        function f(...)
            return ...
        end

        const foo, bar, baz, quux = select(1, f("foo", true))
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("any", toString(requireType("foo")));
    CHECK_EQ("any", toString(requireType("bar")));
    CHECK_EQ("any", toString(requireType("baz")));
    CHECK_EQ("any", toString(requireType("quux")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "select_with_variadic_typepack_tail_and_string_head")
{
    // CLI-115720
    if (!FFlag::DebugLuauForceOldSolver)
        return;

    CheckResult result = check(R"(
        #!nonstrict
        function f(...)
            return ...
        end

        const foo, bar, baz, quux = select(1, "foo", f("bar", true))
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("any", toString(requireType("foo")));
    CHECK_EQ("any", toString(requireType("bar")));
    CHECK_EQ("any", toString(requireType("baz")));
    CHECK_EQ("any", toString(requireType("quux")));
}

TEST_CASE_FIXTURE(Fixture, "string_format_as_method")
{
    CheckResult result = check("const _ = ('%s'):format(5)");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    TypeMismatch* tm = get<TypeMismatch>(result.errors[0]);
    REQUIRE(tm);
    CHECK_EQ(tm->wantedType, getBuiltins()->stringType);
    CHECK_EQ(tm->givenType, getBuiltins()->numberType);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "string_format_trivial_arity")
{
    CheckResult result = check(R"(
        string.format()
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    CHECK_EQ("Argument count mismatch. Function 'string.format' expects at least 1 argument, but none are specified", toString(result.errors[0]));
}

TEST_CASE_FIXTURE(Fixture, "string_format_use_correct_argument")
{
    CheckResult result = check(R"(
        const _ = ("%s"):format("%d", "hello")
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    CHECK_EQ("Argument count mismatch. Function expects 2 arguments, but 3 are specified", toString(result.errors[0]));
}

TEST_CASE_FIXTURE(Fixture, "string_format_use_correct_argument2")
{
    CheckResult result = check(R"(
        const _ = ("%s %d").format("%d %s", "A type error", 2)
    )");

    LUAU_REQUIRE_ERROR_COUNT(2, result);

    CHECK_EQ("Expected this to be 'number', but got 'string'", toString(result.errors[0]));
    CHECK_EQ("Expected this to be 'string', but got 'number'", toString(result.errors[1]));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "string_format_use_correct_argument3")
{
    CheckResult result = check(R"(
        const s1 = string.format("%d")
        const s2 = string.format("%d", 1)
        const s3 = string.format("%d", 1, 2)
    )");

    LUAU_REQUIRE_ERROR_COUNT(2, result);

    CHECK_EQ("Argument count mismatch. Function expects 2 arguments, but only 1 is specified", toString(result.errors[0]));
    CHECK_EQ("Argument count mismatch. Function expects 2 arguments, but 3 are specified", toString(result.errors[1]));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "debug_traceback_is_crazy")
{
    CheckResult result = check(R"(
        function f(co: thread)
            # debug.traceback takes thread?, message?, level? - yes, all optional!
            debug.traceback()
            debug.traceback(null, 1)
            debug.traceback("msg")
            debug.traceback("msg", 1)
            debug.traceback(co)
            debug.traceback(co, "msg")
            debug.traceback(co, "msg", 1)
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "debug_info_is_crazy")
{
    CheckResult result = check(R"(
        function f(co: thread, f: () -> ())
            # debug.info takes thread?, level, options or function, options
            debug.info(1, "n")
            debug.info(co, 1, "n")
            debug.info(f, "n")
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "aliased_string_format")
{
    CheckResult result = check(R"(
        const fmt = string.format
        const s = fmt("%d", "oops")
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    CHECK_EQ("Expected this to be 'number', but got 'string'", toString(result.errors[0]));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "string_lib_self_noself")
{
    CheckResult result = check(R"(
        #!nonstrict
        const a1 = string.byte("abcdef", 2)
        const a2 = string.find("abcdef", "def")
        const a3 = string.gmatch("ab ab", "%a+")
        const a4 = string.gsub("abab", "ab", "cd")
        const a5 = string.len("abc")
        const a6 = string.match("12 ab", "%d+ %a+")
        const a7 = string.rep("a", 10)
        const a8 = string.sub("abcd", 1, 2)
        const a9 = string.split("a,b,c", ",")
        const a0 = string.packsize("ff")
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "gmatch_definition")
{
    CheckResult result = check(R"_(
        const a, b, c = ("hey"):gmatch("(.)(.)(.)")()

        for c in ("hey"):gmatch("(.)") do
            print(c:upper())
        end
    )_");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "select_on_variadic")
{
    CheckResult result = check(R"(
        function f(): (number, ...(boolean | number))
            return 100, true, 1
        end

        const a, b, c = select(f())
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("any", toString(requireType("a")));
    CHECK_EQ("any", toString(requireType("b")));
    CHECK_EQ("any", toString(requireType("c")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "string_format_report_all_type_errors_at_correct_positions")
{
    CheckResult result = check(R"(
        ("%s%d%s"):format(1, "hello", true)
        string.format("%s%d%s", 1, "hello", true)
    )");

    TypeId stringType = getBuiltins()->stringType;
    TypeId numberType = getBuiltins()->numberType;
    TypeId booleanType = getBuiltins()->booleanType;

    LUAU_REQUIRE_ERROR_COUNT(6, result);

    CHECK_EQ(Location(Position{1, 26}, Position{1, 27}), result.errors[0].location);
    CHECK_EQ(TypeErrorData(TypeMismatch{stringType, numberType}), result.errors[0].data);

    CHECK_EQ(Location(Position{1, 29}, Position{1, 36}), result.errors[1].location);
    CHECK_EQ(TypeErrorData(TypeMismatch{numberType, stringType}), result.errors[1].data);

    CHECK_EQ(Location(Position{1, 38}, Position{1, 42}), result.errors[2].location);
    CHECK_EQ(TypeErrorData(TypeMismatch{stringType, booleanType}), result.errors[2].data);

    CHECK_EQ(Location(Position{2, 32}, Position{2, 33}), result.errors[3].location);
    CHECK_EQ(TypeErrorData(TypeMismatch{stringType, numberType}), result.errors[3].data);

    CHECK_EQ(Location(Position{2, 35}, Position{2, 42}), result.errors[4].location);
    CHECK_EQ(TypeErrorData(TypeMismatch{numberType, stringType}), result.errors[4].data);

    CHECK_EQ(Location(Position{2, 44}, Position{2, 48}), result.errors[5].location);
    CHECK_EQ(TypeErrorData(TypeMismatch{stringType, booleanType}), result.errors[5].data);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "tonumber_returns_optional_number_type")
{
    CheckResult result = check(R"(
        #!strict
        const b: number = tonumber('asdf')
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    if (!FFlag::DebugLuauForceOldSolver)
    {
        if (FFlag::LuauNewTypePathErrorMessages)
            CHECK_EQ(
                "Expected this to be 'number', but got 'number?'; \n"
                "`null` is not a subtype of `number`",
                toString(result.errors[0])
            );
        else
            CHECK_EQ(
                "Expected this to be 'number', but got 'number?'; \n"
                "the 2nd component of the union is `null`, which is not a subtype of `number`",
                toString(result.errors[0])
            );
    }
    else
    {
        CHECK_EQ("Expected this to be 'number', but got 'number?'", toString(result.errors[0]));
    }
}

TEST_CASE_FIXTURE(BuiltinsFixture, "tonumber_returns_optional_number_type2")
{
    CheckResult result = check(R"(
        #!strict
        const b: number = tonumber('asdf') or 1
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "dont_add_definitions_to_persistent_types")
{
    // This test makes no sense with type states and I think it generally makes no sense under the new solver.
    // TODO: clip.
    if (!FFlag::DebugLuauForceOldSolver)
        return;

    CheckResult result = check(R"(
        const f = math.sin
        function g(x) return math.sin(x) end
        f = g
    )");
    LUAU_REQUIRE_NO_ERRORS(result);

    TypeId fType = requireType("f");
    const FunctionType* ftv = get<FunctionType>(fType);
    REQUIRE(fType);
    REQUIRE(fType->persistent);
    REQUIRE(!ftv->definition);

    TypeId gType = requireType("g");
    const FunctionType* gtv = get<FunctionType>(gType);
    REQUIRE(gType);
    REQUIRE(!gType->persistent);
    REQUIRE(gtv->definition);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "assert_removes_falsy_types")
{
    CheckResult result = check(R"(
        function f(x: (number | boolean)?)
            return assert(x)
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    if (!FFlag::DebugLuauForceOldSolver)
        CHECK_EQ("((boolean | number)?) -> number | true", toString(requireType("f")));
    else
        CHECK_EQ("((boolean | number)?) -> boolean | number", toString(requireType("f")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "assert_removes_falsy_types2")
{
    CheckResult result = check(R"(
        function f(x: (number | boolean)?): number | true
            return assert(x)
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("((boolean | number)?) -> number | true", toString(requireType("f")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "assert_removes_falsy_types3")
{
    CheckResult result = check(R"(
        function f(x: (number | boolean)?)
            assert(x)
            return x
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    if (!FFlag::DebugLuauForceOldSolver)
        CHECK_EQ("((boolean | number)?) -> number | true", toString(requireType("f")));
    else // without the annotation, the old solver doesn't infer the best return type here
        CHECK_EQ("((boolean | number)?) -> boolean | number", toString(requireType("f")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "assert_removes_falsy_types_even_from_type_pack_tail_but_only_for_the_first_type")
{
    if (!FFlag::DebugLuauForceOldSolver)
        return;

    CheckResult result = check(R"(
        function f(...: number?)
            return assert(...)
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("(...number?) -> (number, ...number?)", toString(requireType("f")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "assert_returns_false_and_string_iff_it_knows_the_first_argument_cannot_be_truthy")
{
    if (!FFlag::DebugLuauForceOldSolver)
    {
        // CLI-114134 - egraph simplification
        return;
    }

    CheckResult result = check(R"(
        function f(x: null)
            return assert(x, "hmm")
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ("(null) -> (never, ...never)", toString(requireType("f")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_freeze_is_generic")
{
    CheckResult result = check(R"(
        const t1: {a: number} = {a = 42}
        const t2: {b: string} = {b = "hello"}
        const t3: {boolean} = {false, true}

        const tf1 = table.freeze(t1)
        const tf2 = table.freeze(t2)
        const tf3 = table.freeze(t3)

        const a = tf1.a
        const b = tf2.b
        const c = tf3[2]

        const d = tf1.b

        const a2 = t1.a
        const b2 = t2.b
        const c2 = t3[2]
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    if (!FFlag::DebugLuauForceOldSolver)
        CHECK("Key 'b' not found in table '{ read a: number }'" == toString(result.errors[0]));
    else
        CHECK_EQ("Key 'b' not found in table '{ a: number }'", toString(result.errors[0]));
    CHECK(Location({13, 18}, {13, 23}) == result.errors[0].location);

    if (!FFlag::DebugLuauForceOldSolver)
    {
        CHECK_EQ("{ read a: number }", toString(requireTypeAtPosition({15, 19})));
        CHECK_EQ("{ read b: string }", toString(requireTypeAtPosition({16, 19})));
        CHECK_EQ("{boolean}", toString(requireTypeAtPosition({17, 19})));
    }

    CHECK_EQ("number", toString(requireType("a")));
    CHECK_EQ("string", toString(requireType("b")));
    CHECK_EQ("boolean", toString(requireType("c")));

    if (!FFlag::DebugLuauForceOldSolver)
        CHECK_EQ("any", toString(requireType("d")));
    else
        CHECK_EQ("*error-type*", toString(requireType("d")));

    CHECK_EQ("number", toString(requireType("a2")));
    CHECK_EQ("string", toString(requireType("b2")));
    CHECK_EQ("boolean", toString(requireType("c2")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_freeze_does_not_retroactively_block_mutation")
{
    CheckResult result = check(R"(
        const t1 = {a = 42}

        t1.q = ":3"

        const tf1 = table.freeze(t1)

        const a = tf1.a
        const b = t1.a
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    if (!FFlag::DebugLuauForceOldSolver)
    {
        CHECK_EQ("{ read a: number, read q: string }", toString(requireType("t1"), {/*exhaustive */ true}));
        // before the assignment, it's `t1`
        CHECK_EQ("{ a: number, q: string }", toString(requireTypeAtPosition({3, 8}), {/*exhaustive */ true}));
        // after the assignment, it's read-only.
        CHECK_EQ("{ read a: number, read q: string }", toString(requireTypeAtPosition({8, 18}), {/*exhaustive */ true}));
    }

    CHECK_EQ("number", toString(requireType("a")));
    CHECK_EQ("number", toString(requireType("b")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_freeze_no_generic_table")
{
    ScopedFastFlag sff{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        #!strict
        type k = {
            read k: string,
        }

        function _(): k
            return table.freeze({
                k = "",
            })
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_freeze_on_metatable")
{
    CheckResult result = check(R"(
        #!strict
        const meta = {
            __index = function()
                return "foo"
            end
        }

        const myTable = setmetatable({}, meta)
        table.freeze(myTable)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_freeze_errors_on_no_args")
{
    CheckResult result = check(R"(
        #!strict
        table.freeze()
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    CHECK(get<CountMismatch>(result.errors[0]));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_freeze_errors_on_non_tables")
{
    CheckResult result = check(R"(
        #!strict
        table.freeze(42)
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    TypeMismatch* tm = get<TypeMismatch>(result.errors[0]);
    REQUIRE(tm);

    if (!FFlag::DebugLuauForceOldSolver)
        CHECK_EQ(toString(tm->wantedType), "table");
    else
        CHECK_EQ(toString(tm->wantedType), "{-  -}");
    CHECK_EQ(toString(tm->givenType), "number");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_freeze_persistent_skip")
{
    CheckResult result = check(R"(
        table.freeze(table)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_clone_persistent_skip")
{
    CheckResult result = check(R"(
        table.clone(table)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_clone_should_support_variadic_any_in_old_solver")
{
    fileResolver.source["game/A"] = R"(
        #!nonstrict
        return function()
            return {}
        end
    )";

    fileResolver.source["game/B"] = R"(
        const A = require(game.A)
        const _ = table.clone(A())
    )";

    CheckResult result = getFrontend().check("game/B");
    LUAU_REQUIRE_ERROR_COUNT(0, result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "set_metatable_needs_arguments")
{
    // In the new solver, null can certainly be used where a generic is required, so all generic parameters are optional.
    DOES_NOT_PASS_NEW_SOLVER_GUARD();

    CheckResult result = check(R"(
        const a = {b=setmetatable}
        a.b()
        a:b()
        a:b({})
    )");
    LUAU_REQUIRE_ERROR_COUNT(2, result);
    CHECK_EQ(toString(result.errors[0]), "Argument count mismatch. Function 'a.b' expects 2 arguments, but none are specified");
    CHECK_EQ(toString(result.errors[1]), "Argument count mismatch. Function 'a.b' expects 2 arguments, but only 1 is specified");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_clone_intersection_of_tables")
{
    CheckResult result = check(R"(
        type FIRST = {
            some: string,
        }

        type SECOND = FIRST & {
            thing: string,
        }

        const b: SECOND = null as any
        # c's type used to be FIRST, but should be the full type of SECOND
        const c = table.clone(b)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ("{ some: string } & { thing: string }", toString(requireType("c"), {true}));
    CHECK_EQ("FIRST & { thing: string }", toString(requireType("c")));
}

TEST_CASE_FIXTURE(Fixture, "typeof_unresolved_function")
{
    CheckResult result = check(R"(
        function f(a: typeof(f)) end
        )");
    LUAU_REQUIRE_ERROR_COUNT(1, result);
    CHECK_EQ("Unknown global 'f'; consider assigning to it first", toString(result.errors[0]));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "no_persistent_typelevel_change")
{
    TypeId mathTy = requireType(getFrontend().globals.globalScope, "math");
    REQUIRE(mathTy);
    TableType* ttv = getMutable<TableType>(mathTy);
    REQUIRE(ttv);

    REQUIRE(ttv->props["frexp"].readTy);
    const FunctionType* ftv = get<FunctionType>(*ttv->props["frexp"].readTy);

    REQUIRE(ftv);
    auto original = ftv->level;

    CheckResult result = check("const a = math.frexp");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK(ftv->level.level == original.level);
    CHECK(ftv->level.subLevel == original.subLevel);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "global_singleton_types_are_sealed")
{
    CheckResult result = check(R"(
function f(x: string)
    p = x:split('a')
    p = table.pack(table.unpack(p, 1, p.count - 1))
    return p
end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "string_match")
{
    CheckResult result = check(R"(
        const s: string = "hello"
        const p = s:match("foo")
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    CHECK_EQ(toString(requireType("p")), "string?");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "gmatch_capture_types")
{
    CheckResult result = check(R"END(
        const a, b, c = string.gmatch("This is a string", "(.()(%a+))")()
    )END");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ(toString(requireType("a")), "string?");
    CHECK_EQ(toString(requireType("b")), "number?");
    CHECK_EQ(toString(requireType("c")), "string?");
}

TEST_CASE_FIXTURE(Fixture, "gmatch_capture_types2")
{
    CheckResult result = check(R"END(
        const a, b, c = ("This is a string"):gmatch("(.()(%a+))")()
    )END");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ(toString(requireType("a")), "string?");
    CHECK_EQ(toString(requireType("b")), "number?");
    CHECK_EQ(toString(requireType("c")), "string?");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "gmatch_capture_types_default_capture")
{
    CheckResult result = check(R"END(
        const a, b, c, d = string.gmatch("T(his)() is a string", ".")()
    )END");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    CountMismatch* acm = get<CountMismatch>(result.errors[0]);
    REQUIRE(acm);
    CHECK_EQ(acm->context, CountMismatch::FunctionResult);
    CHECK_EQ(acm->expected, 1);
    CHECK_EQ(acm->actual, 4);

    CHECK_EQ(toString(requireType("a")), "string?");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "gmatch_capture_types_balanced_escaped_parens")
{
    CheckResult result = check(R"END(
        const a, b, c, d = string.gmatch("T(his) is a string", "((.)%b()())")()
    )END");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    CountMismatch* acm = get<CountMismatch>(result.errors[0]);
    REQUIRE(acm);
    CHECK_EQ(acm->context, CountMismatch::FunctionResult);
    CHECK_EQ(acm->expected, 3);
    CHECK_EQ(acm->actual, 4);

    CHECK_EQ(toString(requireType("a")), "string?");
    CHECK_EQ(toString(requireType("b")), "string?");
    CHECK_EQ(toString(requireType("c")), "number?");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "gmatch_capture_types_parens_in_sets_are_ignored")
{
    CheckResult result = check(R"END(
        const a, b, c = string.gmatch("T(his)() is a string", "(T[()])()")()
    )END");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    CountMismatch* acm = get<CountMismatch>(result.errors[0]);
    REQUIRE(acm);
    CHECK_EQ(acm->context, CountMismatch::FunctionResult);
    CHECK_EQ(acm->expected, 2);
    CHECK_EQ(acm->actual, 3);

    CHECK_EQ(toString(requireType("a")), "string?");
    CHECK_EQ(toString(requireType("b")), "number?");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "gmatch_capture_types_set_containing_lbracket")
{
    CheckResult result = check(R"END(
        const a, b = string.gmatch("[[[", "()([[])")()
    )END");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ(toString(requireType("a")), "number?");
    CHECK_EQ(toString(requireType("b")), "string?");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "gmatch_capture_types_leading_end_bracket_is_part_of_set")
{
    CheckResult result = check(R"END(
        # An immediate right-bracket following a left-bracket is included within the set;
        # thus, '[]]'' is the set containing ']', and '[]' is an invalid set missing an enclosing
        # right-bracket. We detect an invalid set in this case and fall back to to default gmatch
        # typing.
        const foo = string.gmatch("T[hi%]s]]]() is a string", "([]s)")
    )END");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ(toString(requireType("foo")), "() -> (...string)");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "gmatch_capture_types_invalid_pattern_fallback_to_builtin")
{
    CheckResult result = check(R"END(
        const foo = string.gmatch("T(his)() is a string", ")")
    )END");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ(toString(requireType("foo")), "() -> (...string)");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "gmatch_capture_types_invalid_pattern_fallback_to_builtin2")
{
    CheckResult result = check(R"END(
        const foo = string.gmatch("T(his)() is a string", "[")
    )END");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ(toString(requireType("foo")), "() -> (...string)");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "match_capture_types")
{
    CheckResult result = check(R"END(
        const a, b, c = string.match("This is a string", "(.()(%a+))")
    )END");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ(toString(requireType("a")), "string?");
    CHECK_EQ(toString(requireType("b")), "number?");
    CHECK_EQ(toString(requireType("c")), "string?");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "match_capture_types2")
{
    CheckResult result = check(R"END(
        const a, b, c = string.match("This is a string", "(.()(%a+))", "this should be a number")
    )END");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    TypeMismatch* tm = get<TypeMismatch>(result.errors[0]);
    REQUIRE(tm);
    CHECK_EQ(toString(tm->wantedType), "number?");
    CHECK_EQ(toString(tm->givenType), "string");

    CHECK_EQ(toString(requireType("a")), "string?");
    CHECK_EQ(toString(requireType("b")), "number?");
    CHECK_EQ(toString(requireType("c")), "string?");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "find_capture_types")
{
    CheckResult result = check(R"END(
        const d, e, a, b, c = string.find("This is a string", "(.()(%a+))")
    )END");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ(toString(requireType("a")), "string?");
    CHECK_EQ(toString(requireType("b")), "number?");
    CHECK_EQ(toString(requireType("c")), "string?");
    CHECK_EQ(toString(requireType("d")), "number?");
    CHECK_EQ(toString(requireType("e")), "number?");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "find_capture_types2")
{
    CheckResult result = check(R"END(
        const d, e, a, b, c = string.find("This is a string", "(.()(%a+))", "this should be a number")
    )END");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    TypeMismatch* tm = get<TypeMismatch>(result.errors[0]);
    REQUIRE(tm);
    CHECK_EQ(toString(tm->wantedType), "number?");
    CHECK_EQ(toString(tm->givenType), "string");

    CHECK_EQ(toString(requireType("a")), "string?");
    CHECK_EQ(toString(requireType("b")), "number?");
    CHECK_EQ(toString(requireType("c")), "string?");
    CHECK_EQ(toString(requireType("d")), "number?");
    CHECK_EQ(toString(requireType("e")), "number?");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "find_capture_types3")
{
    CheckResult result = check(R"END(
        const d, e, a, b, c = string.find("This is a string", "(.()(%a+))", 1, "this should be a bool")
    )END");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    TypeMismatch* tm = get<TypeMismatch>(result.errors[0]);
    REQUIRE(tm);
    CHECK_EQ(toString(tm->wantedType), "boolean?");
    CHECK_EQ(toString(tm->givenType), "string");

    CHECK_EQ(toString(requireType("a")), "string?");
    CHECK_EQ(toString(requireType("b")), "number?");
    CHECK_EQ(toString(requireType("c")), "string?");
    CHECK_EQ(toString(requireType("d")), "number?");
    CHECK_EQ(toString(requireType("e")), "number?");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "find_capture_types3")
{
    CheckResult result = check(R"END(
        const d, e, a, b = string.find("This is a string", "(.()(%a+))", 1, true)
    )END");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    CountMismatch* acm = get<CountMismatch>(result.errors[0]);
    REQUIRE(acm);
    CHECK_EQ(acm->context, CountMismatch::FunctionResult);
    CHECK_EQ(acm->expected, 2);
    CHECK_EQ(acm->actual, 4);

    CHECK_EQ(toString(requireType("d")), "number?");
    CHECK_EQ(toString(requireType("e")), "number?");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "string_find_should_not_crash")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    LUAU_REQUIRE_NO_ERRORS(check(R"(
        function StringSplit(input, separator)
            string.find(input, separator)
            if not separator then
                separator = "%s+"
            end
        end
    )"));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_dot_clone_type_states")
{
    CheckResult result = check(R"(
        const t1 = {}
        t1.x = 5
        const t2 = table.clone(t1)
        t2.y = 6
        t1.z = 3
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    if (!FFlag::DebugLuauForceOldSolver)
    {
        CHECK_EQ(toString(requireType("t1"), {true}), "{ x: number, z: number }");
        CHECK_EQ(toString(requireType("t2"), {true}), "{ x: number, y: number }");
    }
    else
    {
        CHECK_EQ(toString(requireType("t1"), {true}), "{| x: number, z: number |}");
        CHECK_EQ(toString(requireType("t2"), {true}), "{| x: number, y: number |}");
    }
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_clone_should_not_break")
{
    CheckResult result = check(R"(
        const Immutable = {}

        function Immutable.Set(dictionary, key, value)
            const new = table.clone(dictionary)

            new[key] = value

            return new
        end

        return Immutable
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_clone_should_not_break_2")
{
    CheckResult result = check(R"(
        function set(dictionary, key, value)
            const new = table.clone(dictionary)

            new[key] = value

            return new
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "string_format_should_support_any")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        const x: any = "world"
        print(string.format("Hello, %s!", x))
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "string_format_should_support_any_2")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        const fmt = "Hello, %s!" as any
        const x = "world" as any
        print(string.format(fmt, x))
        print(string.format(fmt, "hello"))
        print(string.format(fmt, 5)) # unchecked because the format string is `any`!
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "string_format_should_support_singleton_types")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        const fmt: "Hello, %s!" = "Hello, %s!"
        print(string.format(fmt, "hello"))
        print(string.format(fmt, 5)) # should still produce an error since the expected type is `string`!
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    TypeMismatch* tm = get<TypeMismatch>(result.errors[0]);
    REQUIRE(tm);
    CHECK_EQ(tm->wantedType, getBuiltins()->stringType);
    CHECK_EQ(tm->givenType, getBuiltins()->numberType);
}

TEST_CASE_FIXTURE(Fixture, "write_only_table_assertion")
{
    DOES_NOT_PASS_OLD_SOLVER_GUARD();

    LUAU_REQUIRE_NO_ERRORS(check(R"(
        function accept(t: { write foo: number })
        end

        accept({ foo = "lol", foo = true })
    )"));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_insert_into_any")
{
    LUAU_REQUIRE_NO_ERRORS(check(R"(
table.insert(1 as any, 2 as any)
    )"));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_insert_requires_all_fields")
{
    CheckResult result = check(R"(
        function huh(): { { x: number, y: string } }
            const ret = {}
            while true do
                table.insert(ret, { x = 42 })
            end
            return ret
        end
    )");

    LUAU_REQUIRE_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "read_refinements_on_persistent_tables_known_property_identity")
{
    // This will not result in a real refinement, as we refine `bnot`, a function, to be truthy
    LUAU_REQUIRE_NO_ERRORS(check(R"(
        if bit32.bnot then
        end
    )"));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "read_refinements_on_persistent_tables_unknown_property")
{
    CheckResult results = check(R"(
        if bit32.scrambleEggs then
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, results);
    auto err = get<UnknownProperty>(results.errors[0]);
    CHECK_EQ(err->key, "scrambleEggs");
    CHECK_EQ(toString(err->table), "typeof(bit32)");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "read_refinements_on_persistent_tables_known_property_narrow")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    LUAU_REQUIRE_NO_ERRORS(check(R"(
        const myutf8 = utf8
        if myutf8.charpattern == "lol" then
            const foobar = myutf8.charpattern
            const _ = foobar
        end
    )"));
    CHECK_EQ("\"lol\"", toString(requireTypeAtPosition(Position{4, 23})));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "next_with_refined_any")
{
    ScopedFastFlag lsv2{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        #!strict
        const t: any = {"hello", "world"}
        if type(t) == "table" and next(t) then
            const foo, bar = next(t)
            const _ = foo
            const _ = bar
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ(toString(requireTypeAtPosition(Position{5, 23})), "unknown?");
    CHECK_EQ(toString(requireTypeAtPosition(Position{6, 23})), "unknown");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "pairs_with_refined_any")
{
    ScopedFastFlag lsv2{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        #!strict
        const t: any = {"hello", "world"}
        if type(t) == "table" and pairs(t) then
	        const foo, bar, lorem = pairs(t)
            const _ = foo
            const _ = bar
            const _ = lorem
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK_EQ(toString(requireTypeAtPosition(Position{5, 23})), "({+ [unknown]: unknown +}, unknown?) -> (unknown?, unknown)");
    CHECK_EQ(toString(requireTypeAtPosition(Position{6, 23})), "{+ [unknown]: unknown +}");
    CHECK_EQ(toString(requireTypeAtPosition(Position{7, 23})), "null");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "vector_lerp_should_not_crash")
{
    LUAU_REQUIRE_NO_ERRORS(check(R"(
        function half(x: number, y: number, z: number): vector
            return vector.lerp(vector.zero, vector.create(x, y, z), 0.5)
        end
    )"));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "instantiation_works_on_builtins")
{
    CheckResult result = check(R"(
        const foo = table.create<<string>>(4)
        const bar = table.unpack<<string>>({})
        const baz = table.find<<string>>({}, 1) # should error
        assert<<string>>("asd", "lol")
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    CHECK_EQ("Expected this to be 'string', but got 'number'", toString(result.errors[0]));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_freeze_on_any_should_not_error")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        function foo(): any
            return true
        end

        table.freeze(foo())
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_freeze_with_type_check_should_not_error")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        function maybeFreeze(t: any)
            if type(t) == "table" then
                table.freeze(t)
            end
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_freeze_no_args")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        table.freeze()
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    CHECK_EQ("Argument count mismatch. Function 'table.freeze' expects 1 argument, but none are specified", toString(result.errors[0]));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_freeze_with_type_pack_should_error")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        table.freeze({x = 5}, {y = "hello"})
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    CHECK_EQ("Argument count mismatch. Function 'table.freeze' expects 1 argument, but 2 are specified", toString(result.errors[0]));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_freeze_with_variadic_any_should_not_error")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        function bar(): ...any
            return true
        end

        table.freeze(bar())
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_freeze_with_variadic_non_error_suppressing_should_error")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        function bar(): ...string
            return
        end

        table.freeze(bar())
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    // TODO (CLI-185019): We probably want a count mismatch error here instead.
    CHECK_EQ("Expected this to be 'table', but got 'string'", toString(result.errors[0]));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "variadic_return_to_single_parameter_function")
{
    CheckResult result = check(R"(
        function bar(): ...string
            return
        end

        function foo(x: string)
            print(x) # null
        end

        foo(bar())
    )");

    // TODO (CLI-185019): We want to error here in some way, maybe a count mismatch?
    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_freeze_generic_pack")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        function foo<T...>(...: T...)
            table.freeze(...)
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);

    TypePackMismatch* tpm = get<TypePackMismatch>(result.errors[0]);
    REQUIRE(tpm);
    CHECK_EQ(toString(tpm->wantedTp), "table");
    CHECK_EQ(toString(tpm->givenTp), "T...");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_freeze_function")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        function foo(f: () -> ())
            table.freeze(f())
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    CHECK_EQ("Argument count mismatch. Function 'table.freeze' expects 1 argument, but none are specified", toString(result.errors[0]));
}

TEST_SUITE_END();
