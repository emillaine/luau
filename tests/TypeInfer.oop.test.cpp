// This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details

#include "Luau/AstQuery.h"
#include "Luau/BuiltinDefinitions.h"
#include "Luau/Common.h"
#include "Luau/Error.h"
#include "Luau/Frontend.h"
#include "Luau/Type.h"

#include "Fixture.h"

#include "ScopedFlags.h"
#include "doctest.h"

using namespace Luau;

LUAU_FASTFLAG(DebugLuauForceOldSolver)
LUAU_FASTFLAG(LuauExportValueSyntax)
LUAU_FASTFLAG(LuauSetmetatableOverrides)

TEST_SUITE_BEGIN("TypeInferOOP");

TEST_CASE_FIXTURE(Fixture, "dont_suggest_using_colon_rather_than_dot_if_not_defined_with_colon")
{
    CheckResult result = check(R"(
        const someTable = {}

        function abs(x: number)
            if x < 0 then
                return -x
            else
                return x
            end
        end

        someTable.Function1 = function(Arg1)
            abs(Arg1)
        end

        someTable.Function1() # Argument count mismatch
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    REQUIRE(get<CountMismatch>(result.errors[0]));
}

TEST_CASE_FIXTURE(Fixture, "dont_suggest_using_colon_rather_than_dot_if_it_wont_help_2")
{
    CheckResult result = check(R"(
        const someTable = {}

        function abs(x: number)
            if x < 0 then
                return -x
            else
                return x
            end
        end

        someTable.Function2 = function(Arg1, Arg2)
            abs(Arg1)
            abs(Arg2)
        end

        someTable.Function2() # Argument count mismatch
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    REQUIRE(get<CountMismatch>(result.errors[0]));
}

TEST_CASE_FIXTURE(Fixture, "dont_suggest_using_colon_rather_than_dot_if_another_overload_works")
{
    CheckResult result = check(R"(
        type T = {method: ((T, number) -> number) & ((number) -> number)}
        const T: T = null as any

        T.method(4)
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "method_depends_on_table")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    CheckResult result = check(R"(
        # This catches a bug where x:m didn't count as a use of x
        # so toposort would happily reorder a definition of
        # function x:m before the definition of x.
        export f
        function g() f() end
        const x = {}
        function x:m() end
        function f() x:m() end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "methods_are_topologically_sorted")
{
    CheckResult result = check(R"(
        const T = {}

        function T:foo()
            return T:bar(999), T:bar("hi")
        end

        function T:bar(i)
            return i
        end

        const a, b = T:foo()
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    dumpErrors(result);

    CHECK_EQ(PrimitiveType::Number, getPrimitiveType(requireType("a")));
    CHECK_EQ(PrimitiveType::String, getPrimitiveType(requireType("b")));
}

TEST_CASE_FIXTURE(Fixture, "quantify_methods_defined_using_dot_syntax_and_explicit_self_parameter")
{
    check(R"(
        const T = {}

        function T.method(self)
            self:method()
        end

        function T.method2(self)
            self:method()
        end

        T:method2()
    )");
}

TEST_CASE_FIXTURE(Fixture, "inferring_hundreds_of_self_calls_should_not_suffocate_memory")
{
    CheckResult result = check(R"(
        ("foo")
            :lower()
            :lower()
            :lower()
            :lower()
            :lower()
            :lower()
            :lower()
            :lower()
            :lower()
            :lower()
            :lower()
            :lower()
            :lower()
            :lower()
            :lower()
            :lower()
            :lower()
            :lower()
    )");

    ModulePtr module = getMainModule();
    if (!FFlag::DebugLuauForceOldSolver)
        CHECK_GE(80, module->internalTypes->types.size());
    else
        CHECK_GE(50, module->internalTypes->types.size());
}

TEST_CASE_FIXTURE(Fixture, "pass_too_many_arguments")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        type T = {
            method: (T, number) -> number
        }

        function makeT(): T
            return {
                method=function(self, number)
                    return number * 2
                end
            }
        end

        const a = makeT()
        a:method(5, 7)
    )");

    LUAU_CHECK_ERROR_COUNT(1, result);

    const CountMismatch* countMismatch = get<CountMismatch>(result.errors.at(0));
    REQUIRE_MESSAGE(countMismatch, "Expected CountMismatch but got " << result.errors.at(0));

    CHECK(countMismatch->expected == 2);
    CHECK(countMismatch->actual == 3);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "object_constructor_can_refer_to_method_of_self")
{
    // CLI-30902
    CheckResult result = check(R"(
        #!strict

        type Foo = {
            fooConn: () -> () | null
        }

        const Foo = {}
        Foo.__index = Foo

        function Foo.new()
            const self: Foo = {
                fooConn = null,
            }
            setmetatable(self, Foo)

            self.fooConn = function()
                self:method() # Key 'method' not found in table self
            end

            return self
        end

        function Foo:method()
            print("foo")
        end

        const foo = Foo.new()

        # TODO This is the best our current refinement support can offer :(
        const bar = foo.fooConn
        if bar then bar() end

        # foo.fooConn()
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "CheckMethodsOfSealed")
{
    CheckResult result = check(R"(
const x: {prop: number} = {prop=9999}
function x:y(z: number)
    const s: string = z
end
)");

    LUAU_REQUIRE_ERROR_COUNT(2, result);
}

TEST_CASE_FIXTURE(Fixture, "nonstrict_self_mismatch_tail")
{
    CheckResult result = check(R"(
        #!nonstrict
        const f = {}
        function f:foo(a: number, b: number) end

        function bar(...)
            f.foo(f, 1, ...)
        end

        bar(2)
    )");
    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "inferred_methods_of_free_tables_have_the_same_level_as_the_enclosing_table")
{
    check(R"(
        function Base64FileReader(data)
            const reader = {}
            const index: number = 0

            function reader:PeekByte()
                return data:byte(index)
            end

            function reader:Byte()
                return data:byte(index - 1)
            end

            return reader
        end

        Base64FileReader()

        function ReadMidiEvents(data)

            const reader = Base64FileReader(data)

            while reader:HasMore() do
                (reader:Byte() % 128)
            end
        end
    )");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "table_oop")
{
    CheckResult result = check(R"(
   #!strict
const Class = {}
Class.__index = Class

type Class = typeof(setmetatable({} as { x: number }, Class))

function Class.new(x: number): Class
    return setmetatable({x = x}, Class)
end

function Class.getx(self: Class)
    return self.x
end

function test()
    const c = Class.new(42)
    const n = c:getx()
    const nn = c.x

    print(string.format("%d %d", n, nn))
end
)");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "set_prop_of_intersection_containing_metatable")
{
    CheckResult result = check(R"(
        export type Set<T> = typeof(setmetatable(
            {} as {
                add: (self: Set<T>, T) -> Set<T>,
            },
            {}
        ))

        const Set = {} as Set<any> & {}

        function Set:add(t)
            return self
        end
    )");
}

// DCR once had a bug in the following code where it would erroneously bind the 'self' table to itself.
TEST_CASE_FIXTURE(Fixture, "dont_bind_free_tables_to_themselves")
{
    CheckResult result = check(R"(
        const T = {}
        const b: any

        function T:m()
            const a = b[i]
            if a then
                self:n()
                if self:p(a) then
                    self:n()
                end
            end
        end
    )");
}

// We should probably flag an error on this.  See CLI-68672
TEST_CASE_FIXTURE(BuiltinsFixture, "flag_when_index_metamethod_returns_0_values")
{
    CheckResult result = check(R"(
        const T = {}
        function T.__index()
        end

        const a = setmetatable({}, T)
        const p = a.prop
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK("null" == toString(requireType("p")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "augmenting_an_unsealed_table_with_a_metatable")
{
    CheckResult result = check(R"(
        const A = {number = 8}

        const B = setmetatable({}, A)

        function B:method()
            return "hello!!"
        end
    )");

    if (!FFlag::DebugLuauForceOldSolver)
        CHECK("{ @metatable { number: number }, { method: (unknown) -> string } }" == toString(requireType("B"), {true}));
    else
        CHECK("{ @metatable {| number: number |}, {| method: <T>(T) -> string |} }" == toString(requireType("B"), {true}));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "react_style_oo")
{
    CheckResult result = check(R"(
        const Prototype = {}

        const ClassMetatable = {
            __index = Prototype
        }

        const BaseClass = (setmetatable({}, ClassMetatable))

        function BaseClass:extend(name)
            const class = {
                name=name
            }

            class.__index = class

            function class.ctor(props)
                return setmetatable({props=props}, class)
            end

            return setmetatable(class, getmetatable(self))
        end

        const C = BaseClass:extend('C')
        const i = C.ctor({hello='world'})

        const iName = i.name
        const cName = C.name
        const hello = i.props.hello
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK("string" == toString(requireType("iName")));
    CHECK("string" == toString(requireType("cName")));
    CHECK("string" == toString(requireType("hello")));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "cycle_between_object_constructor_and_alias")
{
    CheckResult result = check(R"(
        const T = {}
        T.__index = T

        function T.new(): T
            return setmetatable({}, T)
        end

        export type T = typeof(T.new())

        return T
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    auto module = getMainModule();

    REQUIRE(module->exportedTypeBindings.count("T"));

    TypeId aliasType = module->exportedTypeBindings["T"].type;
    CHECK_MESSAGE(get<MetatableType>(follow(aliasType)), "Expected metatable type but got: " << toString(aliasType));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "promise_type_error_too_complex" * doctest::timeout(LUAU_TIMEOUT))
{
    getFrontend().options.retainFullTypeGraphs = false;

    // Used `luau-reduce` tool to extract a minimal reproduction.
    // Credit: https://github.com/evaera/roblox-lua-promise/blob/v4.0.0/lib/init.lua
    CheckResult result = check(R"(
        #!strict

        const Promise = {}
        Promise.prototype = {}
        Promise.__index = Promise.prototype

        function Promise._new(traceback, callback, parent)
            if parent != null and not Promise.is(parent)then
            end

            const self = {
                _parent = parent,
            }

            parent._consumers[self] = true
            setmetatable(self, Promise)
            self:_reject()

            return self
        end

        function Promise.resolve(...)
            return Promise._new(debug.traceback(null, 2), function(resolve)
            end)
        end

        function Promise.reject(...)
            return Promise._new(debug.traceback(null, 2), function(_, reject)
            end)
        end

        function Promise._try(traceback, callback, ...)
            return Promise._new(traceback, function(resolve)
            end)
        end

        function Promise.try(callback, ...)
            return Promise._try(debug.traceback(null, 2), callback, ...)
        end

        function Promise._all(traceback, promises, amount)
            if promises.count == 0 or amount == 0 then
                return Promise.resolve({})
            end
            return Promise._new(traceback, function(resolve, reject, onCancel)
            end)
        end

        function Promise.all(promises)
            return Promise._all(debug.traceback(null, 2), promises)
        end

        function Promise.allSettled(promises)
            return Promise.resolve({})
        end

        function Promise.race(promises)
            return Promise._new(debug.traceback(null, 2), function(resolve, reject, onCancel)
            end)
        end

        function Promise.each(list, predicate)
            return Promise._new(debug.traceback(null, 2), function(resolve, reject, onCancel)
                const predicatePromise = Promise.resolve(predicate(value, index))
                const success, result = predicatePromise:await()
            end)
        end

        function Promise.is(object)
        end

        function Promise.prototype:_reject(...)
            self:_finalize()
        end
    )");

    LUAU_REQUIRE_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "method_should_not_create_cyclic_type")
{
    ScopedFastFlag sff{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        const Component = {}

        function Component:__resolveUpdate(incomingState)
            const oldState = self.state
            incomingState = oldState
            self.state = incomingState
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "cross_module_metatable")
{
    fileResolver.source["game/A"] = R"(
        #!strict
        const cls = {}
        cls.__index = cls
        function cls:abc() return 4 end
        return cls
    )";

    fileResolver.source["game/B"] = R"(
        #!strict
        const cls = require(game.A)
        const tbl = {}
        setmetatable(tbl, cls)
    )";

    CheckResult result = getFrontend().check("game/B");
    LUAU_REQUIRE_NO_ERRORS(result);

    ModulePtr b = getFrontend().moduleResolver.getModule("game/B");
    REQUIRE(b);

    std::optional<Binding> clsBinding = b->getModuleScope()->linearSearchForBinding("tbl");
    REQUIRE(clsBinding);

    TypeId clsType = clsBinding->typeId;

    CHECK("{ @metatable cls, tbl }" == toString(clsType));
}

// https://luau.org/typecheckadding.count-types-for-faux-object-oriented-programs
TEST_CASE_FIXTURE(BuiltinsFixture, "textbook_class_pattern")
{
    if (FFlag::DebugLuauForceOldSolver)
        return;

    CheckResult result = check(R"(
        const Account = {}
        Account.__index = Account

        type AccountData = {
            name: string,
            balance: number,
        }

        export type Account = setmetatable<AccountData, typeof(Account)>

        function Account.new(name, balance): Account
            const self = {}
            self.name = name
            self.balance = balance

            return setmetatable(self, Account)
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "textbook_class_pattern_2")
{
    if (FFlag::DebugLuauForceOldSolver)
        return;

    CheckResult result = check(R"(
        const Account = {}
        Account.__index = Account

        type AccountData = {
            name: string,
            balance: number,
        }

        export type Account = setmetatable<AccountData, typeof(Account)>

        function Account.new(name, balance): Account
            const self = {}
            self.name = name
            self.balance = balance

            return setmetatable(self, Account)
        end

        function Account.deposit(self: Account, credit: number)
            self.balance += credit
        end

        function Account.withdraw(self: Account, debit: number)
            self.balance -= debit
        end

        function Account.hasBalance(self: Account, amount: number): boolean
            return self.balance >= amount
        end

        const account = Account.new("Hina", 500)

        if account:hasBalance(123) then # TypeError: Value of type 'unknown' could be null
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "oop_invoke_with_inferred_self_type")
{
    LUAU_REQUIRE_NO_ERRORS(check(R"(
        const ItemContainer = {}
        ItemContainer.__index = ItemContainer

        function ItemContainer.new()
            const self = {}
            setmetatable(self, ItemContainer)
            return self
        end

        function ItemContainer:removeItem(itemId, itemType)
            self:getItem(itemId, itemType)
        end

        function ItemContainer:getItem(itemId, itemType): ()
        end

        const container = ItemContainer.new()

        container:removeItem(0, "magic")
    )"));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "oop_invoke_with_inferred_self_and_property")
{
    LUAU_REQUIRE_NO_ERRORS(check(R"(
        const ItemContainer = {}
        ItemContainer.__index = ItemContainer

        function ItemContainer.new(name)
            const self = {name = name}
            setmetatable(self, ItemContainer)
            return self
        end

        function ItemContainer:removeItem(itemId, itemType)
            print(self.name)
            self:getItem(itemId, itemType)
        end

        function ItemContainer:getItem(itemId, itemType): ()
        end

        const container = ItemContainer.new("library")

        container:removeItem(0, "magic")
    )"));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "metatable_field_allows_upcast")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
    };

    LUAU_REQUIRE_NO_ERRORS(check(R"(
        const Foobar = {}
        Foobar.__index = Foobar
        Foobar.const = 42

        const foobar = setmetatable({}, Foobar)

        const _: { read const: number } = foobar
    )"));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "metatable_field_disallows_invalid_upcast")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    CheckResult results = check(R"(
        const Foobar = {}
        Foobar.__index = Foobar
        Foobar.const = 42

        const foobar = setmetatable({}, Foobar)

        const _: { const: number } = foobar
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, results);
    auto err = get<TypeMismatch>(results.errors[0]);
    REQUIRE(err);
    CHECK_EQ("{ const: number }", toString(err->wantedType));
    CHECK_EQ("{ @metatable t1, {  } } where t1 = { __index: t1, const: number }", toString(err->givenType, {/* exhaustive */ true}));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "metatable_field_precedence_for_subtyping")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    CheckResult results = check(R"(
        function foobar1(_: { read foo: number }) end
        function foobar2(_: { read bar: boolean }) end
        function foobar3(_: { read foo: string }) end

        const t = { foo = 4 }
        setmetatable(t, { __index = { foo = "heh", bar = true }})
        foobar1(t)
        foobar2(t)
        foobar3(t)
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, results);
    auto err = get<TypeMismatch>(results.errors[0]);
    REQUIRE(err);
    CHECK_EQ("{ read foo: string }", toString(err->wantedType, {/* exhaustive */ true}));
    CHECK_EQ("{ @metatable { __index: { bar: boolean, foo: string } }, { foo: number } }", toString(err->givenType, {/* exhaustive */ true}));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "assign_to_prop_of_intersection_of_metatables")
{
    if (FFlag::DebugLuauForceOldSolver)
        return;

    CheckResult result = check(R"(
        #!strict

        const Base = {}
        Base.__index = Base

        type BaseStructure = { BaseString: string }

        export type Base = setmetatable<BaseStructure, typeof(Base)>

        function Base.new() : Base
            return null as any
        end

        const Sub = {}
        Sub.__index = Sub

        type SubStructure = { SubString: string }

        type Sub = setmetatable<SubStructure, typeof(Sub)> & Base

        function Sub.new() : Sub
            const self: Sub = setmetatable(Base.new(), Sub) as any

            self.SubString = 5 # Line 24
            self.BaseString = 5 # Line 25

            return self
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(2, result);

    CHECK_MESSAGE(nullptr != get<TypeMismatch>(result.errors[0]), "Expected TypeMismatch but got " << result.errors[0]);
    CHECK(24 == result.errors[0].location.begin.line);

    CHECK_MESSAGE(nullptr != get<TypeMismatch>(result.errors[1]), "Expected TypeMismatch but got " << result.errors[1]);
    CHECK(25 == result.errors[1].location.begin.line);
}

TEST_CASE_FIXTURE(Fixture, "classes_arent_in_old_solver")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauUserDefinedClasses, true},
        {FFlag::DebugLuauForceOldSolver, true},
    };

    CheckResult result = check(R"( class Point end )");
    LUAU_REQUIRE_ERROR_COUNT(1, result);
    auto err = get<GenericError>(result.errors[0]);
    REQUIRE(err);
    CHECK_EQ("class keyword is illegal here", err->message);
}

TEST_CASE_FIXTURE(Fixture, "export_class_isnt_in_old_solver")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauUserDefinedClasses, true},
        {FFlag::DebugLuauForceOldSolver, true},
    };

    CheckResult result = check(R"( export class Point end )");
    LUAU_REQUIRE_ERROR_COUNT(1, result);
    auto err = get<GenericError>(result.errors[0]);
    REQUIRE(err);
    CHECK_EQ("class keyword is illegal here", err->message);
}

TEST_CASE_FIXTURE(Fixture, "empty_class")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauUserDefinedClasses, true},
        {FFlag::DebugLuauForceOldSolver, false},
    };

    CheckResult result = check(R"( class Point end )");
    LUAU_REQUIRE_NO_ERRORS(result);
}

TEST_CASE_FIXTURE(Fixture, "class_decl")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauUserDefinedClasses, true},
        {FFlag::DebugLuauForceOldSolver, false},
    };

    CheckResult result = check(R"(
        class Point
            public x: number
            public y: number
        end

        const p = Point.new { x = 2, y = 3 }

        const x = p.x
        const y = p.y
    )");

    LUAU_CHECK_NO_ERRORS(result);

    TypeId t = requireTypeAlias("Point");
    CHECK("Point" == toString(t));

    const ExternType* point = get<ExternType>(t);
    REQUIRE(point);

    CHECK("Point" == toString(requireType("p")));
    CHECK("number" == toString(requireType("x")));
    CHECK("number" == toString(requireType("y")));
}

TEST_CASE_FIXTURE(Fixture, "point_class")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauUserDefinedClasses, true},
        {FFlag::DebugLuauForceOldSolver, false},
    };

    CheckResult result = check(R"(
        class Point
            public x: number
            public y: number

            function length(self)
                return 100
            end

            function __init(self, x: number, y: number)
                self.x = x
                self.y = y
            end
        end

        const p = Point.new(2, 3)
        const len = p:length()
    )");

    LUAU_CHECK_NO_ERRORS(result);

    TypeId p = requireType("p");
    const ExternType* et = get<ExternType>(p);
    REQUIRE(et);

    CHECK("Point" == toString(requireType("p")));
    CHECK("number" == toString(requireType("len")));
}

TEST_CASE_FIXTURE(Fixture, "self_argument_has_self_type")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauUserDefinedClasses, true},
        {FFlag::DebugLuauForceOldSolver, false},
    };

    CheckResult result = check(R"(
        class I
            function m(self)
                return self
            end
        end

        const i = I.new{}
        const i2 = i:m()
    )");

    LUAU_REQUIRE_NO_ERRORS(result);

    CHECK("I" == toString(requireType("i2")));
}

TEST_CASE_FIXTURE(Fixture, "fuzzer_duplicate_class_definition")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauUserDefinedClasses, true},
        {FFlag::DebugLuauForceOldSolver, false},
    };

    CheckResult result = check(R"(
        class l0
        end
        class l0
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    auto err = get<SyntaxError>(result.errors[0]);
    REQUIRE(err);
    CHECK_EQ("A class named 'l0' has already been declared in this module", err->message);
}

TEST_CASE_FIXTURE(Fixture, "repeat_props")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauUserDefinedClasses, true},
        {FFlag::DebugLuauForceOldSolver, false},
    };

    CheckResult result = check(
        R"(
class l0
    public foo
    public foo
end
)"
    );
    LUAU_REQUIRE_ERROR_COUNT(1, result);
    auto err = get<SyntaxError>(result.errors[0]);
    REQUIRE(err);
    CHECK_EQ("Duplicate class member 'foo'", err->message);
}

TEST_CASE_FIXTURE(Fixture, "repeat_class_methods")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauUserDefinedClasses, true},
        {FFlag::DebugLuauForceOldSolver, false},
    };

    CheckResult result = check(
        R"(
class l0
    function foo()
    end
    function foo()
    end
end
)"
    );

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    auto err = get<SyntaxError>(result.errors[0]);
    REQUIRE(err);
    CHECK_EQ("Duplicate class member 'foo'", err->message);
}

TEST_CASE_FIXTURE(Fixture, "repeat_nameless_class_methods")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauUserDefinedClasses, true},
        {FFlag::DebugLuauForceOldSolver, false},
    };

    CheckResult result = check(
        R"(
class l0
    function  ()
    end
    function ()
    end
end
)"
    );

    LUAU_REQUIRE_ERROR_COUNT(3, result);
    auto err1 = get<SyntaxError>(result.errors[0]);
    REQUIRE(err1);
    CHECK_EQ("Expected identifier when parsing method name, got '('", err1->message);
    auto err2 = get<SyntaxError>(result.errors[1]);
    REQUIRE(err2);
    CHECK_EQ("Expected identifier when parsing method name, got '('", err2->message);
    auto err3 = get<SyntaxError>(result.errors[2]);
    REQUIRE(err3);
    CHECK_EQ(R"(Duplicate class member '%error-id%')", err3->message);
}

TEST_CASE_FIXTURE(Fixture, "fuzzer_self_referential_class_definition")
{
    ScopedFastFlag _{FFlag::DebugLuauUserDefinedClasses, true};
    ScopedFastFlag newSolver{FFlag::DebugLuauForceOldSolver, false};

    CheckResult result = check(R"(
        class l0
            public _:typeof(l0)
        end
    )");

    LUAU_REQUIRE_NO_ERRORS(result);
    TypeId l0 = requireType("l0");
    CHECK(is<ExternType>(l0));
}

TEST_CASE_FIXTURE(Fixture, "instantiate_duplicate_class")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauUserDefinedClasses, true},
        {FFlag::DebugLuauForceOldSolver, false},
    };

    CheckResult result = check(
        R"(
class l0
end
class l0
end
_ = l0 {  }
)"
    );

    LUAU_REQUIRE_ERROR_COUNT(2, result);
    auto err = get<SyntaxError>(result.errors[0]);
    REQUIRE(err);
    CHECK_EQ("A class named 'l0' has already been declared in this module", err->message);
    REQUIRE(get<CannotCallNonFunction>(result.errors[1]));
}

TEST_CASE_FIXTURE(Fixture, "prop_with_typeof_reassigned_class")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::DebugLuauUserDefinedClasses, true},
        {FFlag::LuauExportValueSyntax, true},
    };

    // This should not assert or crash
    CheckResult result = check(
        R"(
class Animal end
Animal = null
class l0
public _:typeof(Animal)
end
)"
    );

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    auto err = get<SyntaxError>(result.errors[0]);
    REQUIRE(err);
    CHECK_EQ("'Animal' refers to a class and cannot be used as a variable name (defined on line 2)", err->message);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "class_that_shadows_a_type_alias")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::DebugLuauUserDefinedClasses, true},
    };

    CheckResult result = check(R"(
        type AAA = { x: number }
        class AAA end
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    auto err = get<DuplicateTypeDefinition>(result.errors[0]);
    REQUIRE(err);
    CHECK(err->name == "AAA");
    CHECK(err->previousLocation.has_value());
}

TEST_CASE_FIXTURE(BuiltinsFixture, "typecheck_class_method_field_access")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::DebugLuauUserDefinedClasses, true},
    };

    CheckResult result = check(R"(
        class Point
            public x: number?
            public y: number?
            function magnitude(self)
                return math.sqrt(self.x * self.x + self.y * self.y)
            end
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(4, result);

    for (const auto& err : result.errors)
    {
        auto* utf = get<UninhabitedTypeFunction>(err);
        REQUIRE(utf);
        CHECK_EQ(toString(utf->ty), "mul<number?, number?>");
    }
}

TEST_CASE_FIXTURE(BuiltinsFixture, "typecheck_class_annotations")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::DebugLuauUserDefinedClasses, true},
    };

    CheckResult result = check(R"(
        class Point
            public x: number
            public y: number
            public name: string
            function magnitude(self): string
                # self.name is not a number
                self.name = self.x

                # This function is declared to return string.
                return math.sqrt(self.x * self.x + self.y * self.y)
            end
        end
    )");

    LUAU_REQUIRE_ERROR_COUNT(2, result);
    LUAU_REQUIRE_ERROR(result, TypeMismatch);
    LUAU_REQUIRE_ERROR(result, TypePackMismatch);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "read_unknown_property_from_class_object_or_instance")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::DebugLuauUserDefinedClasses, true},
    };

    CheckResult result = check(R"(
        class Point
            public x: number
            public y: number

            function zero()
                return Point.new {x=0, y=0}
            end
        end

        const p = Point.zero()
        const a = p.z
        const b = Point.z
    )");

    LUAU_REQUIRE_ERROR_COUNT(2, result);

    auto* up0 = get<UnknownProperty>(result.errors[0]);
    REQUIRE(up0);
    CHECK(up0->key == "z");

    auto* up1 = get<UnknownProperty>(result.errors[1]);
    REQUIRE(up1);
    CHECK(up1->key == "z");
}

TEST_CASE_FIXTURE(BuiltinsFixture, "writes_to_class_object_properties_are_forbidden")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::DebugLuauUserDefinedClasses, true},
    };

    CheckResult result = check(R"(
        class Point
            public x: number
            public y: number

            function zero()
                return Point.new {x=0, y=0}
            end

            function magnitude(self): number
                return 5 # stochastic approximation for performance
            end
        end

        Point.magnitude = function(p: Point) return 3 end
        Point.zero = function() return Point.new { x = 1, y = 1 } end
        Point.one = function() return Point.new { x = 1, y = 1 } end
    )");

    LUAU_REQUIRE_ERROR_COUNT(3, result);

    auto* pav0 = get<PropertyAccessViolation>(result.errors[0]);
    REQUIRE(pav0);
    CHECK(pav0->key == "magnitude");
    CHECK(pav0->context == PropertyAccessViolation::CannotWrite);

    auto* pav1 = get<PropertyAccessViolation>(result.errors[1]);
    REQUIRE(pav1);
    CHECK(pav1->key == "zero");
    CHECK(pav1->context == PropertyAccessViolation::CannotWrite);

    auto* pav2 = get<PropertyAccessViolation>(result.errors[2]);
    REQUIRE(pav2);
    CHECK(pav2->key == "one");
    CHECK(pav2->context == PropertyAccessViolation::CannotWrite);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "writes_to_unknown_class_instance_properties_are_forbidden")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::DebugLuauUserDefinedClasses, true},
    };

    CheckResult result = check(R"(
        class Point
            public x: number
            public y: number

            function zero()
                return Point.new {x=0, y=0}
            end

            function magnitude(self): number
                return 5 # stochastic approximation for performance
            end
        end

        const p = Point.zero()

        p.magnitude = function(p: Point) return 3 end
        p.zero = function() return Point.new { x = 1, y = 1 } end
        p.one = function() return Point.new { x = 1, y = 1 } end

        p.__index = {}
    )");

    LUAU_REQUIRE_ERROR_COUNT(4, result);

    auto* pav0 = get<PropertyAccessViolation>(result.errors[0]);
    REQUIRE(pav0);
    CHECK(pav0->key == "magnitude");
    CHECK(pav0->context == PropertyAccessViolation::CannotWrite);

    auto* pav1 = get<PropertyAccessViolation>(result.errors[1]);
    REQUIRE(pav1);
    CHECK(pav1->key == "zero");
    CHECK(pav1->context == PropertyAccessViolation::CannotWrite);

    auto* pav2 = get<PropertyAccessViolation>(result.errors[2]);
    REQUIRE(pav2);
    CHECK(pav2->key == "one");
    CHECK(pav2->context == PropertyAccessViolation::CannotWrite);

    auto* pav3 = get<PropertyAccessViolation>(result.errors[3]);
    REQUIRE(pav3);
    CHECK(pav3->key == "__index");
    CHECK(pav3->context == PropertyAccessViolation::CannotWrite);
}

TEST_CASE_FIXTURE(BuiltinsFixture, "subclass_property_access")
{
    DOES_NOT_PASS_OLD_SOLVER_GUARD();

    ScopedFastFlag _{FFlag::LuauSetmetatableOverrides, true};

    LUAU_REQUIRE_NO_ERRORS(check(R"(
        type Instance = { Name: string }

        const Base = {}
        Base.__index = {}

        export type Class = setmetatable<{ read instance: Instance }, typeof(Base)>

        function Base.new(instance: Instance): Class
            return setmetatable({ instance = instance, }, Base)
        end

        function Base.ChangeName(self: Class, name: string): ()
            error("Override required.")
        end

        const Derived = setmetatable({}, Base)
        Derived.__index = Derived

        export type Subclass = setmetatable<Class & { #[[ new members here ]] }, typeof(Derived)>

        function Derived.new(instance: Instance): Subclass
            return table.freeze(setmetatable(Base.new(instance), Derived))
        end

        function Derived.ChangeName(self: Subclass, name: string): ()
            self.instance.Name = name # TypeError: Type 'Class' does not have key 'instance'
        end

        return Derived
    )"));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "setmetatable_overrides_1")
{
    DOES_NOT_PASS_OLD_SOLVER_GUARD();

    ScopedFastFlag _{FFlag::LuauSetmetatableOverrides, true};

    CheckResult result = check(R"(
        const root = {}
        const mt1 = { __index = { propA = 42 } }
        const mt2 = { __index = { propB = "hmm" } }

        setmetatable(root, mt1)

        const getpropA = root.propA

        setmetatable(root, mt2)

        const getpropB = root.propB
        const ohno = root.propA
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    CHECK_EQ("number", toString(requireType("getpropA"), {/* exhaustive */ true}));
    CHECK_EQ("string", toString(requireType("getpropB"), {/* exhaustive */ true}));

    // TODO CLI-221097: This is incorrect, we should be claiming that `uhoh`
    // has type `any`, but we report an error, so it's not awful.
    CHECK_EQ("number", toString(requireType("ohno"), {/* exhaustive */ true}));

    auto err = get<UnknownProperty>(result.errors[0]);
    REQUIRE(err);
    CHECK_EQ("propA", err->key);
    CHECK_EQ("{ @metatable mt2, root }", toString(err->table));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "setmetatable_overrides_2")
{
    DOES_NOT_PASS_OLD_SOLVER_GUARD();

    ScopedFastFlag _{FFlag::LuauSetmetatableOverrides, true};

    CheckResult result = check(R"(
        type MT1 = { __index: { propA: number } }
        type MT2 = { __index: { propB: string } }

        const root: setmetatable<setmetatable<{ Name: string }, MT1>, MT2> = null as any

        const getpropB = root.propB
        const ohno = root.propA
    )");

    LUAU_REQUIRE_ERROR_COUNT(1, result);
    CHECK_EQ("string", toString(requireType("getpropB"), {/* exhaustive */ true}));
    CHECK_EQ("any", toString(requireType("ohno"), {/* exhaustive */ true}));

    auto err = get<UnknownProperty>(result.errors[0]);
    REQUIRE(err);
    CHECK_EQ("propA", err->key);
    CHECK_EQ("{ @metatable MT2, { Name: string } }", toString(err->table));
}

TEST_CASE_FIXTURE(BuiltinsFixture, "fuzzer_setmetatable_invalid_types")
{
    // Prior, we raised assertions here as we constructed `MetatableType`s that
    // had non-tables as their `MetatableType::table` member.
    LUAU_REQUIRE_ERRORS(check(R"(
        return setmetatable(_ < _,setmetatable(setmetatable(_,_),{"",},math.abs))
    )"));

    LUAU_REQUIRE_ERRORS(check(R"(
        return setmetatable(if _ then setmetatable(_,_) else {""}, {""}, _)
    )"));
}

TEST_SUITE_END();
