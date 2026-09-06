// This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
#include "Luau/Autocomplete.h"
#include "Luau/AutocompleteTypes.h"
#include "Luau/BuiltinDefinitions.h"
#include "Luau/Common.h"
#include "Luau/Type.h"
#include "Luau/StringUtils.h"


#include "ClassFixture.h"
#include "Fixture.h"
#include "ScopedFlags.h"

#include "doctest.h"

LUAU_FASTFLAG(LuauExportValueSyntax)

#include <map>

LUAU_DYNAMIC_FASTINT(LuauSubtypingRecursionLimit)

LUAU_FASTINT(LuauTypeInferRecursionLimit)

LUAU_FASTFLAG(LuauAutocompleteMetatableInheritance)
LUAU_FASTFLAG(LuauCheckTypeForDeprecated)
LUAU_FASTFLAG(LuauDeprecatedAttributeOnAnonymousFunctions)
LUAU_FASTFLAG(LuauAutocompleteDotMethodConversion)
LUAU_FASTFLAG(LuauUseExplicitTypeArgsInGenerics)
LUAU_FASTFLAG(DebugLuauForceOldSolver)
LUAU_FASTFLAG(DebugLuauIfLocalSyntax)
LUAU_FASTFLAG(DebugLuauIfLocalAnalysis)

using namespace Luau;

static std::optional<AutocompleteEntryMap> nullCallback(std::string tag, std::optional<const ExternType*> ptr, std::optional<std::string> contents)
{
    return std::nullopt;
}

template<class BaseType>
struct ACFixtureImpl : BaseType
{
    ACFixtureImpl()
        : BaseType(true)
    {
    }

    AutocompleteResult autocomplete(unsigned row, unsigned column)
    {
        FrontendOptions opts;
        opts.forAutocomplete = true;
        opts.retainFullTypeGraphs = true;
        // NOTE: Autocomplete does *not* require strict checking, meaning we should
        // try to check all of these examples in `--!nocheck` mode.
        this->configResolver.defaultConfig.mode = Mode::NoCheck;
        this->getFrontend().check("MainModule", opts);

        return Luau::autocomplete(this->getFrontend(), "MainModule", Position{row, column}, nullCallback);
    }

    AutocompleteResult autocomplete(char marker, StringCompletionCallback callback = nullCallback)
    {
        FrontendOptions opts;
        opts.forAutocomplete = true;
        opts.retainFullTypeGraphs = true;
        // NOTE: Autocomplete does *not* require strict checking, meaning we should
        // try to check all of these examples in `--!nocheck` mode.
        this->configResolver.defaultConfig.mode = Mode::NoCheck;
        this->getFrontend().check("MainModule", opts);

        return Luau::autocomplete(this->getFrontend(), "MainModule", getPosition(marker), callback);
    }

    AutocompleteResult autocomplete(const ModuleName& name, Position pos, StringCompletionCallback callback = nullCallback)
    {
        FrontendOptions opts;
        opts.forAutocomplete = true;
        opts.retainFullTypeGraphs = true;
        // NOTE: Autocomplete does *not* require strict checking, meaning we should
        // try to check all of these examples in `--!nocheck` mode.
        this->configResolver.defaultConfig.mode = Mode::NoCheck;
        this->getFrontend().check(name, opts);

        return Luau::autocomplete(this->getFrontend(), name, pos, callback);
    }

    CheckResult check(const std::string& source)
    {
        this->getFrontend();
        markerPosition.clear();
        std::string filteredSource;
        filteredSource.reserve(source.size());

        Position curPos(0, 0);
        char prevChar{};
        for (char c : source)
        {
            if (prevChar == '@')
            {
                LUAU_ASSERT("Illegal marker character" && ((c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z')));
                LUAU_ASSERT("Duplicate marker found" && markerPosition.count(c) == 0);
                markerPosition.insert(std::pair{c, curPos});
            }
            else if (c == '@')
            {
                // skip the '@' character
                if (prevChar == '\\')
                {
                    // escaped @, prevent prevChar to be equal to '@' on next loop
                    c = '\0';
                    // replace escaping '\' with '@'
                    filteredSource.back() = '@';
                }
            }
            else
            {
                filteredSource.push_back(c);
                if (c == '\n')
                {
                    curPos.line++;
                    curPos.column = 0;
                }
                else
                {
                    curPos.column++;
                }
            }
            prevChar = c;
        }
        LUAU_ASSERT("Digit expected after @ symbol" && prevChar != '@');

        // NOTE: Autocomplete does *not* require strict checking, meaning we should
        // try to check all of these examples in `--!nocheck` mode.
        return BaseType::check(Mode::NoCheck, filteredSource, std::nullopt);
    }

    LoadDefinitionFileResult loadDefinition(const std::string& source)
    {
        GlobalTypes& globals = this->getFrontend().globalsForAutocomplete;
        unfreeze(globals.globalTypes);
        LoadDefinitionFileResult result = this->getFrontend().loadDefinitionFile(
            globals, globals.globalScope, source, "@test", /* captureComments */ false, /* typeCheckForAutocomplete */ true
        );
        freeze(globals.globalTypes);

        if (!FFlag::DebugLuauForceOldSolver)
        {
            GlobalTypes& globals = this->getFrontend().globals;
            unfreeze(globals.globalTypes);
            LoadDefinitionFileResult result = this->getFrontend().loadDefinitionFile(
                globals, globals.globalScope, source, "@test", /* captureComments */ false, /* typeCheckForAutocomplete */ true
            );
            freeze(globals.globalTypes);
        }

        if (!result.parseResult.errors.empty())
        {
            for (const auto &e: result.parseResult.errors)
                printf("Parse error at (%s): %s\n", toString(e.getLocation()).c_str(), e.getMessage().c_str());
        }

        REQUIRE_MESSAGE(result.success, "loadDefinition: unable to load definition file");
        return result;
    }

    const Position& getPosition(char marker) const
    {
        auto i = markerPosition.find(marker);
        LUAU_ASSERT(i != markerPosition.end());
        return i->second;
    }
    // Maps a marker character (0-9 inclusive) to a position in the source code.
    std::map<char, Position> markerPosition;
};

struct ACFixture : ACFixtureImpl<Fixture>
{
    ACFixture()
        : ACFixtureImpl<Fixture>()
    {
    }

    Frontend& getFrontend() override
    {
        if (frontend)
            return *frontend;

        Frontend& f = Fixture::getFrontend();
        // TODO - move this into its own constructor
        addGlobalBinding(f.globals, "table", Binding{getBuiltins()->anyType});
        addGlobalBinding(f.globals, "math", Binding{getBuiltins()->anyType});
        addGlobalBinding(f.globalsForAutocomplete, "table", Binding{getBuiltins()->anyType});
        addGlobalBinding(f.globalsForAutocomplete, "math", Binding{getBuiltins()->anyType});
        return *frontend;
    }
};

struct ACBuiltinsFixture : ACFixtureImpl<BuiltinsFixture>
{
};

struct ACExternTypeFixture : ACFixtureImpl<ExternTypeFixture>
{
};

TEST_SUITE_BEGIN("AutocompleteTest");

TEST_CASE_FIXTURE(ACFixture, "empty_program")
{
    check(" @1");

    auto ac = autocomplete('1');

    CHECK(!ac.entryMap.empty());
    CHECK(ac.entryMap.count("table"));
    CHECK(ac.entryMap.count("math"));
    CHECK_EQ(ac.context, AutocompleteContext::Statement);
}

TEST_CASE_FIXTURE(ACFixture, "local_initializer")
{
    check("const a = @1");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("table"));
    CHECK(ac.entryMap.count("math"));
    CHECK_EQ(ac.context, AutocompleteContext::Expression);
}

TEST_CASE_FIXTURE(ACFixture, "leave_numbers_alone")
{
    check("a = 3.@11");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.empty());
    CHECK_EQ(ac.context, AutocompleteContext::Unknown);
}

TEST_CASE_FIXTURE(ACFixture, "user_defined_globals")
{
    check("const myLocal = 4; @1");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("myLocal"));
    CHECK(ac.entryMap.count("table"));
    CHECK(ac.entryMap.count("math"));
    CHECK_EQ(ac.context, AutocompleteContext::Statement);
}

TEST_CASE_FIXTURE(ACFixture, "dont_suggest_local_before_its_definition")
{
    check(R"(
        const myLocal = 4
        function abc()
@1            const myInnerLocal = 1
@2
        end
@3    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("myLocal"));
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "myInnerLocal");

    ac = autocomplete('2');
    CHECK(ac.entryMap.count("myLocal"));
    CHECK(ac.entryMap.count("myInnerLocal"));

    ac = autocomplete('3');
    CHECK(ac.entryMap.count("myLocal"));
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "myInnerLocal");
}

TEST_CASE_FIXTURE(ACFixture, "recursive_function")
{
    check(R"(
        function foo()
@1        end
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("foo"));
    CHECK_EQ(ac.context, AutocompleteContext::Statement);
}

TEST_CASE_FIXTURE(ACFixture, "nested_recursive_function")
{
    check(R"(
        function outer()
            function inner()
@1            end
        end
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("inner"));
    CHECK(ac.entryMap.count("outer"));
}

TEST_CASE_FIXTURE(ACFixture, "user_defined_local_functions_in_own_definition")
{
    check(R"(
        function abc()
@1
        end
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("abc"));
    CHECK(ac.entryMap.count("table"));
    CHECK(ac.entryMap.count("math"));

    check(R"(
        abc = function()
@1
        end
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("abc")); // FIXME: This is actually incorrect!
    CHECK(ac.entryMap.count("table"));
    CHECK(ac.entryMap.count("math"));
}

TEST_CASE_FIXTURE(ACFixture, "global_functions_are_not_scoped_lexically")
{
    check(R"(
        if true then
            function abc()

            end
        end
@1    )");

    auto ac = autocomplete('1');

    CHECK(!ac.entryMap.empty());
    // Bare `function abc()` inside `if` is now block-local (implicit local), not a global.
    CHECK(ac.entryMap.count("abc") == 0);
    CHECK(ac.entryMap.count("table"));
    CHECK(ac.entryMap.count("math"));
}

TEST_CASE_FIXTURE(ACFixture, "local_functions_fall_out_of_scope")
{
    check(R"(
        if true then
            function abc()

            end
        end
@1    )");

    auto ac = autocomplete('1');

    CHECK_NE(0, ac.entryMap.size());
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "abc");
}

TEST_CASE_FIXTURE(ACFixture, "function_parameters")
{
    check(R"(
        function abc(test)

@1        end
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("test"));
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "get_member_completions")
{
    check(R"(
        a = table.@1
    )");

    auto ac = autocomplete('1');

    CHECK_EQ(17, ac.entryMap.size());
    CHECK(ac.entryMap.count("find"));
    CHECK(ac.entryMap.count("pack"));
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "math");
    CHECK_EQ(ac.context, AutocompleteContext::Property);
}

TEST_CASE_FIXTURE(ACFixture, "nested_member_completions")
{
    check(R"(
        tbl = { abc = { def = 1234, egh = false } }
        tbl.abc. @1
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(2, ac.entryMap.size());
    CHECK(ac.entryMap.count("def"));
    CHECK(ac.entryMap.count("egh"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);
}

TEST_CASE_FIXTURE(ACFixture, "unsealed_table")
{
    check(R"(
        tbl = {}
        tbl.prop = 5
        tbl.@1
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(1, ac.entryMap.size());
    CHECK(ac.entryMap.count("prop"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);
}

TEST_CASE_FIXTURE(ACFixture, "unsealed_table_2")
{
    check(R"(
        tbl = {}
        inner = { prop = 5 }
        tbl.inner = inner
        tbl.inner. @1
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(1, ac.entryMap.size());
    CHECK(ac.entryMap.count("prop"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);
}

TEST_CASE_FIXTURE(ACFixture, "cyclic_table")
{
    check(R"(
        abc = {}
        def = { abc = abc }
        abc.def = def
        abc.def. @1
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("abc"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);
}

TEST_CASE_FIXTURE(ACFixture, "table_union")
{
    check(R"(
        type t1 = { a1 : string, b2 : number }
        type t2 = { b2 : string, c3 : string }
        function func(abc : t1 | t2)
            abc.  @1
        end
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(1, ac.entryMap.size());
    CHECK(ac.entryMap.count("b2"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);
}

TEST_CASE_FIXTURE(ACFixture, "table_intersection")
{
    check(R"(
        type t1 = { a1 : string, b2 : number }
        type t2 = { b2 : number, c3 : string }
        function func(abc : t1 & t2)
            abc.  @1
        end
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(3, ac.entryMap.size());
    CHECK(ac.entryMap.count("a1"));
    CHECK(ac.entryMap.count("b2"));
    CHECK(ac.entryMap.count("c3"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "get_string_completions")
{
    check(R"(
        a = ("foo"):@1
    )");

    auto ac = autocomplete('1');

    CHECK_EQ(17, ac.entryMap.size());
    CHECK_EQ(ac.context, AutocompleteContext::Property);
}

TEST_CASE_FIXTURE(ACFixture, "get_suggestions_for_new_statement")
{
    check("@1");

    auto ac = autocomplete('1');

    CHECK_NE(0, ac.entryMap.size());

    CHECK(ac.entryMap.count("table"));
    CHECK_EQ(ac.context, AutocompleteContext::Statement);
}

TEST_CASE_FIXTURE(ACFixture, "get_suggestions_for_the_very_start_of_the_script")
{
    check(R"(@1

        function aaa() end
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("table"));
    CHECK_EQ(ac.context, AutocompleteContext::Statement);
}

TEST_CASE_FIXTURE(ACFixture, "method_call_inside_function_body")
{
    check(R"(
        game = { GetService=function(s) return 'hello' end }

        function a()
            game:  @1
        end
    )");

    auto ac = autocomplete('1');

    CHECK_NE(0, ac.entryMap.size());

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "math");
    CHECK_EQ(ac.context, AutocompleteContext::Property);
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "method_call_inside_if_conditional")
{
    check(R"(
        if table:  @1
    )");

    auto ac = autocomplete('1');

    CHECK_NE(0, ac.entryMap.size());
    CHECK(ac.entryMap.count("concat"));
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "math");
    CHECK_EQ(ac.context, AutocompleteContext::Property);
}

TEST_CASE_FIXTURE(ACFixture, "statement_between_two_statements")
{
    check(R"(
        function getmyscripts() end

        g@1

        getmyscripts()
    )");

    auto ac = autocomplete('1');

    CHECK_NE(0, ac.entryMap.size());

    CHECK(ac.entryMap.count("getmyscripts"));

    CHECK_EQ(ac.context, AutocompleteContext::Statement);
}

TEST_CASE_FIXTURE(ACFixture, "bias_toward_inner_scope")
{
    check(R"(
        const A = {one=1}

        function B()
            const A = {two=2}

            A  @1
        end
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("A"));
    CHECK_EQ(ac.context, AutocompleteContext::Statement);

    TypeId t = follow(*ac.entryMap["A"].type);
    const TableType* tt = get<TableType>(t);
    REQUIRE(tt);

    CHECK(tt->props.count("two"));
}

TEST_CASE_FIXTURE(ACFixture, "recommend_statement_starting_keywords")
{
    check("@1");
    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("local") == 0);
    CHECK_EQ(ac.context, AutocompleteContext::Statement);

    check("const i = @1");
    auto ac2 = autocomplete('1');
    CHECK(!ac2.entryMap.count("local"));
    CHECK_EQ(ac2.context, AutocompleteContext::Expression);
}

TEST_CASE_FIXTURE(ACFixture, "do_not_overwrite_context_sensitive_kws")
{
    check(R"(
        function continue()
        end


@1    )");

    auto ac = autocomplete('1');

    AutocompleteEntry entry = ac.entryMap["continue"];
    CHECK(entry.kind == AutocompleteEntryKind::Binding);
    CHECK_EQ(ac.context, AutocompleteContext::Statement);
}

TEST_CASE_FIXTURE(ACFixture, "dont_offer_any_suggestions_from_within_a_comment")
{
    check(R"(
        --!strict
        foo = {}
        function foo:bar() end

        --[[
            foo:@1
        ]]
    )");

    auto ac = autocomplete('1');

    CHECK_EQ(0, ac.entryMap.size());
    CHECK_EQ(ac.context, AutocompleteContext::Unknown);
}

TEST_CASE_FIXTURE(ACFixture, "dont_offer_any_suggestions_from_within_a_broken_comment")
{
    check(R"(
        --[[ @1
    )");

    auto ac = autocomplete('1');

    CHECK_EQ(0, ac.entryMap.size());
    CHECK_EQ(ac.context, AutocompleteContext::Unknown);
}

TEST_CASE_FIXTURE(ACFixture, "dont_offer_any_suggestions_from_within_a_broken_comment_at_the_very_end_of_the_file")
{
    check("--[[@1");

    auto ac = autocomplete('1');
    CHECK_EQ(0, ac.entryMap.size());
    CHECK_EQ(ac.context, AutocompleteContext::Unknown);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_for_middle_keywords")
{
    check(R"(
        for x @1=
    )");

    auto ac1 = autocomplete('1');
    CHECK_EQ(ac1.entryMap.count("do"), 0);
    CHECK_EQ(ac1.entryMap.count("end"), 0);
    CHECK_EQ(ac1.context, AutocompleteContext::Unknown);

    check(R"(
        for x =@1 1
    )");

    auto ac2 = autocomplete('1');
    CHECK_EQ(ac2.entryMap.count("do"), 0);
    CHECK_EQ(ac2.entryMap.count("end"), 0);
    CHECK_EQ(ac2.context, AutocompleteContext::Unknown);

    check(R"(
        for x = 1,@1 2
    )");

    auto ac3 = autocomplete('1');
    CHECK_EQ(1, ac3.entryMap.size());
    CHECK_EQ(ac3.entryMap.count("do"), 1);
    CHECK_EQ(ac3.context, AutocompleteContext::Keyword);

    check(R"(
        for x = 1, @12,
    )");

    auto ac4 = autocomplete('1');
    CHECK_EQ(ac4.entryMap.count("do"), 0);
    CHECK_EQ(ac4.entryMap.count("end"), 0);
    CHECK_EQ(ac4.context, AutocompleteContext::Expression);

    check(R"(
        for x = 1, 2, @15
    )");

    auto ac5 = autocomplete('1');
    CHECK_EQ(ac5.entryMap.count("math"), 1);
    CHECK_EQ(ac5.entryMap.count("do"), 0);
    CHECK_EQ(ac5.entryMap.count("end"), 0);
    CHECK_EQ(ac5.context, AutocompleteContext::Expression);

    check(R"(
        for x = 1, 2, 5 f@1
    )");

    auto ac6 = autocomplete('1');
    CHECK_EQ(ac6.entryMap.size(), 1);
    CHECK_EQ(ac6.entryMap.count("do"), 1);
    CHECK_EQ(ac6.context, AutocompleteContext::Keyword);

    check(R"(
        for x = 1, 2, 5 do      @1
    )");

    auto ac7 = autocomplete('1');
    CHECK_EQ(ac7.entryMap.count("end"), 1);
    CHECK_EQ(ac7.context, AutocompleteContext::Statement);

    check(R"(const Foo = 1
        for x = @11, @22, @35
    )");

    for (int i = 0; i < 3; ++i)
    {
        auto ac8 = autocomplete('1' + i);
        CHECK_EQ(ac8.entryMap.count("Foo"), 1);
        CHECK_EQ(ac8.entryMap.count("do"), 0);
    }

    check(R"(const Foo = 1
        for x = @11, @22
    )");

    for (int i = 0; i < 2; ++i)
    {
        auto ac9 = autocomplete('1' + i);
        CHECK_EQ(ac9.entryMap.count("Foo"), 1);
        CHECK_EQ(ac9.entryMap.count("do"), 0);
    }
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_for_in_middle_keywords")
{
    check(R"(
        for @1
    )");

    auto ac1 = autocomplete('1');
    CHECK_EQ(0, ac1.entryMap.size());
    CHECK_EQ(ac1.context, AutocompleteContext::Unknown);

    check(R"(
        for x@1 @2
    )");

    auto ac2 = autocomplete('1');
    CHECK_EQ(0, ac2.entryMap.size());
    CHECK_EQ(ac2.context, AutocompleteContext::Unknown);

    auto ac2a = autocomplete('2');
    CHECK_EQ(1, ac2a.entryMap.size());
    CHECK_EQ(1, ac2a.entryMap.count("in"));
    CHECK_EQ(ac2a.context, AutocompleteContext::Keyword);

    check(R"(
        for x in y@1
    )");

    auto ac3 = autocomplete('1');
    CHECK_EQ(ac3.entryMap.count("table"), 1);
    CHECK_EQ(ac3.entryMap.count("do"), 0);
    CHECK_EQ(ac3.context, AutocompleteContext::Expression);

    check(R"(
        for x in y @1
    )");

    auto ac4 = autocomplete('1');
    CHECK_EQ(ac4.entryMap.size(), 1);
    CHECK_EQ(ac4.entryMap.count("do"), 1);
    CHECK_EQ(ac4.context, AutocompleteContext::Keyword);

    check(R"(
        for x in f f@1
    )");

    auto ac5 = autocomplete('1');
    CHECK_EQ(ac5.entryMap.size(), 1);
    CHECK_EQ(ac5.entryMap.count("do"), 1);
    CHECK_EQ(ac5.context, AutocompleteContext::Keyword);

    check(R"(
        for x in y do  @1
    )");

    auto ac6 = autocomplete('1');
    CHECK_EQ(ac6.entryMap.count("in"), 0);
    CHECK_EQ(ac6.entryMap.count("table"), 1);
    CHECK_EQ(ac6.entryMap.count("end"), 1);
    CHECK_EQ(ac6.entryMap.count("function"), 1);
    CHECK_EQ(ac6.context, AutocompleteContext::Statement);

    check(R"(
        for x in y do e@1
    )");

    auto ac7 = autocomplete('1');
    CHECK_EQ(ac7.entryMap.count("in"), 0);
    CHECK_EQ(ac7.entryMap.count("table"), 1);
    CHECK_EQ(ac7.entryMap.count("end"), 1);
    CHECK_EQ(ac7.entryMap.count("function"), 1);
    CHECK_EQ(ac7.context, AutocompleteContext::Statement);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_while_middle_keywords")
{
    check(R"(
        while@1
    )");

    auto ac1 = autocomplete('1');
    CHECK_EQ(ac1.entryMap.count("do"), 0);
    CHECK_EQ(ac1.entryMap.count("end"), 0);
    CHECK_EQ(ac1.context, AutocompleteContext::Expression);

    check(R"(
        while true @1
    )");

    auto ac2 = autocomplete('1');
    CHECK_EQ(3, ac2.entryMap.size());
    CHECK_EQ(ac2.entryMap.count("do"), 1);
    CHECK_EQ(ac2.entryMap.count("and"), 1);
    CHECK_EQ(ac2.entryMap.count("or"), 1);
    CHECK_EQ(ac2.context, AutocompleteContext::Keyword);

    check(R"(
        while true do  @1
    )");

    auto ac3 = autocomplete('1');
    CHECK_EQ(ac3.entryMap.count("end"), 1);
    CHECK_EQ(ac3.context, AutocompleteContext::Statement);

    check(R"(
        while true d@1
    )");

    auto ac4 = autocomplete('1');
    CHECK_EQ(3, ac4.entryMap.size());
    CHECK_EQ(ac4.entryMap.count("do"), 1);
    CHECK_EQ(ac4.entryMap.count("and"), 1);
    CHECK_EQ(ac4.entryMap.count("or"), 1);
    CHECK_EQ(ac4.context, AutocompleteContext::Keyword);

    check(R"(
        while t@1
    )");

    auto ac5 = autocomplete('1');
    CHECK_EQ(ac5.entryMap.count("do"), 0);
    CHECK_EQ(ac5.entryMap.count("true"), 1);
    CHECK_EQ(ac5.entryMap.count("false"), 1);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_if_middle_keywords")
{
    check(R"(
        if   @1
    )");

    auto ac1 = autocomplete('1');
    CHECK_EQ(ac1.entryMap.count("then"), 0);
    CHECK_EQ(
        ac1.entryMap.count("function"),
        1
    ); // FIXME: This is kind of dumb.  It is technically syntactically valid but you can never do anything interesting with this.
    CHECK_EQ(ac1.entryMap.count("table"), 1);
    CHECK_EQ(ac1.entryMap.count("else"), 0);
    CHECK_EQ(ac1.entryMap.count("elseif"), 0);
    CHECK_EQ(ac1.entryMap.count("end"), 0);
    CHECK_EQ(ac1.context, AutocompleteContext::Expression);

    check(R"(
        if x  @1
    )");

    auto ac2 = autocomplete('1');
    CHECK_EQ(ac2.entryMap.count("then"), 1);
    CHECK_EQ(ac2.entryMap.count("function"), 0);
    CHECK_EQ(ac2.entryMap.count("else"), 0);
    CHECK_EQ(ac2.entryMap.count("elseif"), 0);
    CHECK_EQ(ac2.entryMap.count("end"), 0);
    CHECK_EQ(ac2.context, AutocompleteContext::Keyword);

    check(R"(
        if x t@1
    )");

    auto ac3 = autocomplete('1');
    CHECK_EQ(3, ac3.entryMap.size());
    CHECK_EQ(ac3.entryMap.count("then"), 1);
    CHECK_EQ(ac3.entryMap.count("and"), 1);
    CHECK_EQ(ac3.entryMap.count("or"), 1);
    CHECK_EQ(ac3.context, AutocompleteContext::Keyword);

    check(R"(
        if x then
@1
        end
    )");

    auto ac4 = autocomplete('1');
    CHECK_EQ(ac4.entryMap.count("then"), 0);
    CHECK_EQ(ac4.entryMap.count("else"), 1);
    CHECK_EQ(ac4.entryMap.count("function"), 1);
    CHECK_EQ(ac4.entryMap.count("elseif"), 0);
    CHECK_EQ(ac4.entryMap.count("end"), 0);
    CHECK_EQ(ac4.context, AutocompleteContext::Statement);

    check(R"(
        if x then
            t@1
        end
    )");

    auto ac4a = autocomplete('1');
    CHECK_EQ(ac4a.entryMap.count("then"), 0);
    CHECK_EQ(ac4a.entryMap.count("table"), 1);
    CHECK_EQ(ac4a.entryMap.count("else"), 1);
    CHECK_EQ(ac4a.entryMap.count("elseif"), 0);
    CHECK_EQ(ac4a.context, AutocompleteContext::Statement);

    check(R"(
        if x then
@1
        else if x then
        end
    )");

    auto ac5 = autocomplete('1');
    CHECK_EQ(ac5.entryMap.count("then"), 0);
    CHECK_EQ(ac5.entryMap.count("function"), 1);
    CHECK_EQ(ac5.entryMap.count("else"), 0);
    CHECK_EQ(ac5.entryMap.count("elseif"), 0);
    CHECK_EQ(ac5.entryMap.count("end"), 0);
    CHECK_EQ(ac5.context, AutocompleteContext::Statement);

    check(R"(
        if t@1
    )");

    auto ac6 = autocomplete('1');
    CHECK_EQ(ac6.entryMap.count("true"), 1);
    CHECK_EQ(ac6.entryMap.count("false"), 1);
    CHECK_EQ(ac6.entryMap.count("then"), 0);
    CHECK_EQ(ac6.entryMap.count("function"), 1);
    CHECK_EQ(ac6.entryMap.count("else"), 0);
    CHECK_EQ(ac6.entryMap.count("elseif"), 0);
    CHECK_EQ(ac6.entryMap.count("end"), 0);
    CHECK_EQ(ac6.context, AutocompleteContext::Expression);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_until_in_repeat")
{
    check(R"(
        repeat  @1
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("table"), 1);
    CHECK_EQ(ac.entryMap.count("until"), 1);
    CHECK_EQ(ac.context, AutocompleteContext::Statement);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_until_expression")
{
    check(R"(
        repeat
        until   @1
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("table"), 1);
    CHECK_EQ(ac.context, AutocompleteContext::Expression);
}

TEST_CASE_FIXTURE(ACFixture, "local_names")
{
    check(R"(
        const ab@1
    )");

    auto ac1 = autocomplete('1');
    CHECK_EQ(ac1.entryMap.size(), 1);
    CHECK_EQ(ac1.entryMap.count("function"), 1);
    CHECK_EQ(ac1.context, AutocompleteContext::Unknown);

    check(R"(
        const ab, cd@1
    )");

    auto ac2 = autocomplete('1');
    CHECK(ac2.entryMap.empty());
    CHECK_EQ(ac2.context, AutocompleteContext::Unknown);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_end_with_fn_exprs")
{
    check(R"(
        function f()  @1
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("end"), 1);
    CHECK_EQ(ac.context, AutocompleteContext::Statement);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_end_with_lambda")
{
    check(R"(
        a = function() bar = foo en@1
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("end"), 1);
    CHECK_EQ(ac.context, AutocompleteContext::Statement);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_end_of_do_block")
{
    check("do @1");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("end"));

    check(R"(
        function f()
            do
                @1
        end
        @2
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("end"));

    ac = autocomplete('2');

    CHECK(ac.entryMap.count("end"));
}

TEST_CASE_FIXTURE(ACFixture, "stop_at_first_stat_when_recommending_keywords")
{
    check(R"(
        repeat
            for x @1
    )");

    auto ac1 = autocomplete('1');
    CHECK_EQ(ac1.entryMap.count("in"), 1);
    CHECK_EQ(ac1.entryMap.count("until"), 0);
    CHECK_EQ(ac1.context, AutocompleteContext::Keyword);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_repeat_middle_keyword")
{
    check(R"(
        repeat @1
    )");

    auto ac1 = autocomplete('1');
    CHECK_EQ(ac1.entryMap.count("do"), 1);
    CHECK_EQ(ac1.entryMap.count("function"), 1);
    CHECK_EQ(ac1.entryMap.count("until"), 1);

    check(R"(
        repeat f f@1
    )");

    auto ac2 = autocomplete('1');
    CHECK_EQ(ac2.entryMap.count("function"), 1);
    CHECK_EQ(ac2.entryMap.count("until"), 1);

    check(R"(
        repeat
            u@1
        until
    )");

    auto ac3 = autocomplete('1');
    CHECK_EQ(ac3.entryMap.count("until"), 0);
}

TEST_CASE_FIXTURE(ACFixture, "local_function")
{
    check(R"(
        const f@1
    )");

    auto ac1 = autocomplete('1');
    CHECK_EQ(ac1.entryMap.size(), 1);
    CHECK_EQ(ac1.entryMap.count("function"), 1);

    check(R"(
        const f@1, cd
    )");

    auto ac2 = autocomplete('1');
    CHECK(ac2.entryMap.empty());
}

TEST_CASE_FIXTURE(ACFixture, "local_function")
{
    check(R"(
        function @1
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.empty());

    check(R"(
        function @1s@2
    )");

    ac = autocomplete('1');
    CHECK(ac.entryMap.empty());

    ac = autocomplete('2');
    CHECK(ac.entryMap.empty());

    check(R"(
        function @1()@2
    )");

    ac = autocomplete('1');
    CHECK(ac.entryMap.empty());

    ac = autocomplete('2');
    CHECK(ac.entryMap.count("end"));

    check(R"(
        function something@1
    )");

    ac = autocomplete('1');
    CHECK(ac.entryMap.empty());

    check(R"(
        tbl = {}
        function tbl.something@1() end
    )");

    ac = autocomplete('1');
    CHECK(ac.entryMap.empty());
}

TEST_CASE_FIXTURE(ACFixture, "local_function_params")
{
    check(R"(
        function @1a@2bc(@3d@4ef)@5 @6
    )");

    CHECK(autocomplete('1').entryMap.empty());
    CHECK(autocomplete('2').entryMap.empty());
    CHECK(autocomplete('3').entryMap.empty());
    CHECK(autocomplete('4').entryMap.empty());
    CHECK(!autocomplete('5').entryMap.empty());

    CHECK(!autocomplete('6').entryMap.empty());

    check(R"(
        function abc(def)
@1        end
    )");

    for (unsigned int i = 17; i < 25; ++i)
    {
        CHECK(autocomplete(1, i).entryMap.empty());
    }
    CHECK(!autocomplete(1, 26).entryMap.empty());

    auto ac2 = autocomplete('1');
    CHECK_EQ(ac2.entryMap.count("abc"), 1);
    CHECK_EQ(ac2.entryMap.count("def"), 1);
    CHECK_EQ(ac2.context, AutocompleteContext::Statement);

    check(R"(
        function abc(def, ghi@1)
        end
    )");

    auto ac3 = autocomplete('1');
    CHECK(ac3.entryMap.empty());
    CHECK_EQ(ac3.context, AutocompleteContext::Unknown);
}

TEST_CASE_FIXTURE(ACFixture, "global_function_params")
{
    check(R"(
        function abc(def)
    )");

    for (unsigned int i = 17; i < 25; ++i)
    {
        CHECK(autocomplete(1, i).entryMap.empty());
    }
    CHECK(!autocomplete(1, 26).entryMap.empty());

    check(R"(
        function abc(def)
        end
    )");

    for (unsigned int i = 17; i < 25; ++i)
    {
        CHECK(autocomplete(1, i).entryMap.empty());
    }
    CHECK(!autocomplete(1, 26).entryMap.empty());

    check(R"(
        function abc(def)
@1
        end
    )");

    auto ac2 = autocomplete('1');
    CHECK_EQ(ac2.entryMap.count("abc"), 1);
    CHECK_EQ(ac2.entryMap.count("def"), 1);
    CHECK_EQ(ac2.context, AutocompleteContext::Statement);

    check(R"(
        function abc(def, ghi@1)
        end
    )");

    auto ac3 = autocomplete('1');
    CHECK(ac3.entryMap.empty());
    CHECK_EQ(ac3.context, AutocompleteContext::Unknown);
}

TEST_CASE_FIXTURE(ACFixture, "arguments_to_global_lambda")
{
    check(R"(
        abc = function(def, ghi@1)
        end
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.empty());
}

TEST_CASE_FIXTURE(ACFixture, "function_expr_params")
{
    check(R"(
        abc = function(def) @1
    )");

    for (unsigned int i = 20; i < 27; ++i)
    {
        CHECK(autocomplete(1, i).entryMap.empty());
    }
    CHECK(!autocomplete('1').entryMap.empty());

    check(R"(
        abc = function(def) @1
        end
    )");

    for (unsigned int i = 20; i < 27; ++i)
    {
        CHECK(autocomplete(1, i).entryMap.empty());
    }
    CHECK(!autocomplete('1').entryMap.empty());

    check(R"(
        abc = function(def)
@1
        end
    )");

    auto ac2 = autocomplete('1');
    CHECK_EQ(ac2.entryMap.count("def"), 1);
    CHECK_EQ(ac2.context, AutocompleteContext::Statement);
}

TEST_CASE_FIXTURE(ACFixture, "local_initializer")
{
    check(R"(
        const a = t@1
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("table"), 1);
    CHECK_EQ(ac.entryMap.count("true"), 1);
}

TEST_CASE_FIXTURE(ACFixture, "local_initializer_2")
{
    check(R"(
        a=@1
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("table"));
}

TEST_CASE_FIXTURE(ACFixture, "get_member_completions")
{
    check(R"(
        a = 12.@13
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.empty());
}

TEST_CASE_FIXTURE(ACFixture, "sometimes_the_metatable_is_an_error")
{
    check(R"(
        T = {}
        T.__index = T

        function T.new()
            return setmetatable({x=6}, X) -- oops!
        end
        t = T.new()
        t.  @1
    )");

    autocomplete('1');
    // Don't crash!
}

TEST_CASE_FIXTURE(ACFixture, "local_types_builtin")
{
    check(R"(
const a: n@1
const b: string = "don't trip"
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("null"));
    CHECK(ac.entryMap.count("number"));
    CHECK_EQ(ac.context, AutocompleteContext::Type);
}

TEST_CASE_FIXTURE(ACFixture, "private_types")
{
    check(R"(
do
    type num = number
    const a: n@1u
    const b: nu@2m
end
const a: nu@3
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("num"));
    CHECK(ac.entryMap.count("number"));

    ac = autocomplete('2');

    CHECK(ac.entryMap.count("num"));
    CHECK(ac.entryMap.count("number"));

    ac = autocomplete('3');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "num");
    CHECK(ac.entryMap.count("number"));
}

TEST_CASE_FIXTURE(ACFixture, "type_scoping_easy")
{
    check(R"(
type Table = { a: number, b: number }
do
    type Table = { x: string, y: string }
    const a: T@1
end
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("Table"));
    REQUIRE(ac.entryMap["Table"].type);
    const TableType* tv = get<TableType>(follow(*ac.entryMap["Table"].type));
    REQUIRE(tv);
    CHECK(tv->props.count("x"));
}

TEST_CASE_FIXTURE(ACFixture, "modules_with_types")
{
    fileResolver.source["Module/A"] = R"(
export type A = { x: number, y: number }
export type B = { z: number, w: number }
return {}
    )";

    LUAU_REQUIRE_NO_ERRORS(getFrontend().check("Module/A"));

    fileResolver.source["Module/B"] = R"(
const aaa = require(script.Parent.A)
const a: aa
    )";

    getFrontend().check("Module/B");

    auto ac = autocomplete("Module/B", Position{2, 11});

    CHECK(ac.entryMap.count("aaa"));
    CHECK_EQ(ac.context, AutocompleteContext::Type);
}

TEST_CASE_FIXTURE(ACFixture, "module_type_members")
{
    fileResolver.source["Module/A"] = R"(
export type A = { x: number, y: number }
export type B = { z: number, w: number }
return {}
    )";

    LUAU_REQUIRE_NO_ERRORS(getFrontend().check("Module/A"));

    fileResolver.source["Module/B"] = R"(
const aaa = require(script.Parent.A)
const a: aaa.
    )";

    getFrontend().check("Module/B");

    auto ac = autocomplete("Module/B", Position{2, 13});

    CHECK_EQ(2, ac.entryMap.size());
    CHECK(ac.entryMap.count("A"));
    CHECK(ac.entryMap.count("B"));
    CHECK_EQ(ac.context, AutocompleteContext::Type);
}

TEST_CASE_FIXTURE(ACFixture, "argument_types")
{
    check(R"(
function f(a: n@1
const b: string = "don't trip"
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("null"));
    CHECK(ac.entryMap.count("number"));
    CHECK_EQ(ac.context, AutocompleteContext::Type);
}

TEST_CASE_FIXTURE(ACFixture, "return_types")
{
    check(R"(
function f(a: number): n@1
const b: string = "don't trip"
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("null"));
    CHECK(ac.entryMap.count("number"));
    CHECK_EQ(ac.context, AutocompleteContext::Type);
}

TEST_CASE_FIXTURE(ACFixture, "as_types")
{
    check(R"(
const a: any = 5
const b: number = (a as n@1
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("null"));
    CHECK(ac.entryMap.count("number"));
    CHECK_EQ(ac.context, AutocompleteContext::Type);
}

TEST_CASE_FIXTURE(ACFixture, "function_type_types")
{
    check(R"(
const a: (n@1) = null
const b: (number, (n@2)) = null
const c: (number, (number) -> n@3) = null
const d: (number, (number) -> (number, n@4)) = null
const e: (n: n@5) = null
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("null"));
    CHECK(ac.entryMap.count("number"));

    ac = autocomplete('2');

    CHECK(ac.entryMap.count("null"));
    CHECK(ac.entryMap.count("number"));

    ac = autocomplete('3');

    CHECK(ac.entryMap.count("null"));
    CHECK(ac.entryMap.count("number"));

    ac = autocomplete('4');

    CHECK(ac.entryMap.count("null"));
    CHECK(ac.entryMap.count("number"));

    ac = autocomplete('5');

    CHECK(ac.entryMap.count("null"));
    CHECK(ac.entryMap.count("number"));
}

TEST_CASE_FIXTURE(ACFixture, "generic_types")
{
    check(R"(
function f<Tee, Use>(a: T@1
const b: string = "don't trip"
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("Tee"));
    CHECK_EQ(ac.context, AutocompleteContext::Type);
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_suggestion_in_argument")
{
    // local
    check(R"(
function target(a: number, b: string) return a + b.count end

const one = 4
const two = "hello"
return target(o@1
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("one"));
    CHECK(ac.entryMap["one"].typeCorrect == TypeCorrectKind::Correct);
    CHECK(ac.entryMap["two"].typeCorrect == TypeCorrectKind::None);

    check(R"(
function target(a: number, b: string) return a + b.count end

const one = 4
const two = "hello"
return target(one, t@1
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("two"));
    CHECK(ac.entryMap["two"].typeCorrect == TypeCorrectKind::Correct);
    CHECK(ac.entryMap["one"].typeCorrect == TypeCorrectKind::None);

    // member
    check(R"(
function target(a: number, b: string) return a + b.count end

const a = { one = 4, two = "hello" }
return target(a.@1
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("one"));
    CHECK(ac.entryMap["one"].typeCorrect == TypeCorrectKind::Correct);
    CHECK(ac.entryMap["two"].typeCorrect == TypeCorrectKind::None);

    check(R"(
function target(a: number, b: string) return a + b.count end

const a = { one = 4, two = "hello" }
return target(a.one, a.@1
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("two"));
    CHECK(ac.entryMap["two"].typeCorrect == TypeCorrectKind::Correct);
    CHECK(ac.entryMap["one"].typeCorrect == TypeCorrectKind::None);

    // union match
    check(R"(
function target(a: string?) return b.count end

const a = { one = 4, two = "hello" }
return target(a.@1
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("two"));
    CHECK(ac.entryMap["two"].typeCorrect == TypeCorrectKind::Correct);
    CHECK(ac.entryMap["one"].typeCorrect == TypeCorrectKind::None);
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_suggestion_in_table")
{
    check(R"(
type Foo = { a: number, b: string }
a = { one = 4, two = "hello" }
const b: Foo = { a = a.@1
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("one"));
    CHECK(ac.entryMap["one"].typeCorrect == TypeCorrectKind::Correct);
    CHECK(ac.entryMap["two"].typeCorrect == TypeCorrectKind::None);
    CHECK_EQ(ac.context, AutocompleteContext::Property);

    check(R"(
type Foo = { a: number, b: string }
a = { one = 4, two = "hello" }
const b: Foo = { b = a.@1
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("two"));
    CHECK(ac.entryMap["two"].typeCorrect == TypeCorrectKind::Correct);
    CHECK(ac.entryMap["one"].typeCorrect == TypeCorrectKind::None);
    CHECK_EQ(ac.context, AutocompleteContext::Property);
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_function_return_types")
{
    check(R"(
function target(a: number, b: string) return a + b.count end
function bar1(a: number) return -a end
function bar2(a: string) return a .. 'x' end

return target(b@1
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("bar1"));
    CHECK(ac.entryMap["bar1"].typeCorrect == TypeCorrectKind::CorrectFunctionResult);
    CHECK(ac.entryMap["bar2"].typeCorrect == TypeCorrectKind::None);

    check(R"(
function target(a: number, b: string) return a + b.count end
function bar1(a: number) return -a end
function bar2(a: string) return a .. 'x' end

return target(bar1, b@1
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("bar2"));
    CHECK(ac.entryMap["bar2"].typeCorrect == TypeCorrectKind::CorrectFunctionResult);
    CHECK(ac.entryMap["bar1"].typeCorrect == TypeCorrectKind::None);

    check(R"(
function target(a: number, b: string) return a + b.count end
function bar1(a: number): (...number) return -a, a end
function bar2(a: string) return a .. 'x' end

return target(b@1
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("bar1"));
    CHECK(ac.entryMap["bar1"].typeCorrect == TypeCorrectKind::CorrectFunctionResult);
    CHECK(ac.entryMap["bar2"].typeCorrect == TypeCorrectKind::None);
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_local_type_suggestion")
{
    check(R"(
const b: s@1 = "str"
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("string"));
    CHECK(ac.entryMap["string"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
function f() return "str" end
const b: s@1 = f()
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("string"));
    CHECK(ac.entryMap["string"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
const b: s@1, c: n@2 = "str", 2
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("string"));
    CHECK(ac.entryMap["string"].typeCorrect == TypeCorrectKind::Correct);

    ac = autocomplete('2');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
function f() return 1, "str", 3 end
const a: b@1, b: n@2, c: s@3, d: n@4 = false, f()
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("boolean"));
    CHECK(ac.entryMap["boolean"].typeCorrect == TypeCorrectKind::Correct);

    ac = autocomplete('2');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);

    ac = autocomplete('3');

    CHECK(ac.entryMap.count("string"));
    CHECK(ac.entryMap["string"].typeCorrect == TypeCorrectKind::Correct);

    ac = autocomplete('4');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
function f(): ...number return 1, 2, 3 end
const a: boolean, b: n@1 = false, f()
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_function_type_suggestion")
{
    check(R"(
const b: (n@1) -> number = function(a: number, b: string) return a + b.count end
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
const b: (number, s@1 = function(a: number, b: string) return a + b.count end
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("string"));
    CHECK(ac.entryMap["string"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
const b: (number, string) -> b@1 = function(a: number, b: string): boolean return a + b.count == 0 end
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("boolean"));
    CHECK(ac.entryMap["boolean"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
const b: (number, ...s@1) = function(a: number, ...: string) return a end
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("string"));
    CHECK(ac.entryMap["string"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
const b: (number) -> ...s@1 = function(a: number): ...string return "a", "b", "c" end
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("string"));
    CHECK(ac.entryMap["string"].typeCorrect == TypeCorrectKind::Correct);
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_full_type_suggestion")
{
    check(R"(
const b:@1 @2= "str"
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("string"));
    CHECK(ac.entryMap["string"].typeCorrect == TypeCorrectKind::Correct);

    ac = autocomplete('2');

    CHECK(ac.entryMap.count("string"));
    CHECK(ac.entryMap["string"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
const b: @1= function(a: number) return -a end
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("(number) -> number"));
    CHECK(ac.entryMap["(number) -> number"].typeCorrect == TypeCorrectKind::Correct);
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_argument_type_suggestion")
{
    check(R"(
function target(a: number, b: string) return a + b.count end

function d(a: n@1, b)
    return target(a, b)
end
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
function target(a: number, b: string) return a + b.count end

function d(a, b: s@1)
    return target(a, b)
end
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("string"));
    CHECK(ac.entryMap["string"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
function target(a: number, b: string) return a + b.count end

function d(a:@1 @2, b)
    return target(a, b)
end
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);

    ac = autocomplete('2');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
function target(a: number, b: string) return a + b.count end

function d(a, b: @1)@2: number
    return target(a, b)
end
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("string"));
    CHECK(ac.entryMap["string"].typeCorrect == TypeCorrectKind::Correct);

    ac = autocomplete('2');

    CHECK(ac.entryMap["string"].typeCorrect == TypeCorrectKind::None);
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_expected_argument_type_suggestion")
{
    check(R"(
function target(callback: (a: number, b: string) -> number) return callback(4, "hello") end

x = target(function(a: @1
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
function target(callback: (a: number, b: string) -> number) return callback(4, "hello") end

x = target(function(a: n@1
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
function target(callback: (a: number, b: string) -> number) return callback(4, "hello") end

x = target(function(a: n@1, b: @2)
    return a + b.count
end)
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);

    ac = autocomplete('2');

    CHECK(ac.entryMap.count("string"));
    CHECK(ac.entryMap["string"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
function target(callback: (...number) -> number) return callback(1, 2, 3) end

x = target(function(a: n@1)
    return a
end
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_expected_argument_type_pack_suggestion")
{
    check(R"(
function target(callback: (...number) -> number) return callback(1, 2, 3) end

x = target(function(...:n@1)
    return a
end
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
function target(callback: (...number) -> number) return callback(1, 2, 3) end

x = target(function(a:number, b:number, ...:@1)
    return a + b
end
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_expected_return_type_suggestion")
{
    check(R"(
function target(callback: () -> number) return callback() end

x = target(function(): n@1
    return 1
end
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
function target(callback: () -> (number, number)) return callback() end

x = target(function(): (number, n@1
    return 1, 2
end
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_expected_return_type_pack_suggestion")
{
    check(R"(
function target(callback: () -> ...number) return callback() end

x = target(function(): ...n@1
    return 1, 2, 3
end
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
function target(callback: () -> ...number) return callback() end

x = target(function(): (number, number, ...n@1
    return 1, 2, 3
end
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_expected_argument_type_suggestion_optional")
{
    check(R"(
function target(callback: null | (a: number, b: string) -> number) return callback(4, "hello") end

x = target(function(a: @1
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_expected_argument_type_suggestion_self")
{
    check(R"(
t = {}
t.x = 5
function t:target(callback: (a: number, b: string) -> number) return callback(self.x, "hello") end

x = t:target(function(a: @1, b:@2 ) end)
y = t.target(t, function(a: number, b: @3) end)
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap["number"].typeCorrect == TypeCorrectKind::Correct);

    ac = autocomplete('2');

    CHECK(ac.entryMap.count("string"));
    CHECK(ac.entryMap["string"].typeCorrect == TypeCorrectKind::Correct);

    ac = autocomplete('3');

    CHECK(ac.entryMap.count("string"));
    CHECK(ac.entryMap["string"].typeCorrect == TypeCorrectKind::Correct);
}

TEST_CASE_FIXTURE(ACFixture, "do_not_suggest_internal_module_type")
{
    fileResolver.source["Module/A"] = R"(
type done = { x: number, y: number }
function a(a: (done) -> number) return a({x=1, y=2}) end
function b(a: ((done) -> number) -> number) return a(function(done) return 1 end) end
return {a = a, b = b}
    )";

    LUAU_REQUIRE_NO_ERRORS(getFrontend().check("Module/A"));

    fileResolver.source["Module/B"] = R"(
ex = require(script.Parent.A)
ex.a(function(x:
    )";

    getFrontend().check("Module/B");

    auto ac = autocomplete("Module/B", Position{2, 16});

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "done");

    fileResolver.source["Module/C"] = R"(
ex = require(script.Parent.A)
ex.b(function(x:
    )";

    getFrontend().check("Module/C");

    ac = autocomplete("Module/C", Position{2, 16});

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "(done) -> number");
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "suggest_external_module_type")
{
    fileResolver.source["Module/A"] = R"(
export type done = { x: number, y: number }
function a(a: (done) -> number) return a({x=1, y=2}) end
function b(a: ((done) -> number) -> number) return a(function(done) return 1 end) end
return {a = a, b = b}
    )";

    LUAU_REQUIRE_NO_ERRORS(getFrontend().check("Module/A"));

    fileResolver.source["Module/B"] = R"(
const ex = require(script.Parent.A)
ex.a(function(x:
    )";

    getFrontend().check("Module/B");

    auto ac = autocomplete("Module/B", Position{2, 16});

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "done");
    CHECK(ac.entryMap.count("ex.done"));
    CHECK(ac.entryMap["ex.done"].typeCorrect == TypeCorrectKind::Correct);

    fileResolver.source["Module/C"] = R"(
const ex = require(script.Parent.A)
ex.b(function(x:
    )";

    getFrontend().check("Module/C");

    ac = autocomplete("Module/C", Position{2, 16});

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "(done) -> number");
    CHECK(ac.entryMap.count("(ex.done) -> number"));
    CHECK(ac.entryMap["(ex.done) -> number"].typeCorrect == TypeCorrectKind::Correct);
}

TEST_CASE_FIXTURE(ACFixture, "do_not_suggest_synthetic_table_name")
{
    check(R"(
foo = { a = 1, b = 2 }
const bar: @1= foo
    )");

    auto ac = autocomplete('1');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "foo");
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_function_no_parenthesis")
{
    check(R"(
function target(a: (number) -> number) return a(4) end
function bar1(a: number) return -a end
function bar2(a: string) return a .. 'x' end

return target(b@1
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("bar1"));
    CHECK(ac.entryMap["bar1"].typeCorrect == TypeCorrectKind::Correct);
    CHECK(ac.entryMap["bar1"].parens == ParenthesesRecommendation::None);
    CHECK(ac.entryMap["bar2"].typeCorrect == TypeCorrectKind::None);
}

TEST_CASE_FIXTURE(ACFixture, "function_in_assignment_has_parentheses")
{
    check(R"(
function bar(a: number) return -a end
abc = b@1
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("bar"));
    CHECK(ac.entryMap["bar"].parens == ParenthesesRecommendation::CursorInside);
}

TEST_CASE_FIXTURE(ACFixture, "function_result_passed_to_function_has_parentheses")
{
    check(R"(
function foo() return 1 end
function bar(a: number) return -a end
abc = bar(@1)
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("foo"));
    CHECK(ac.entryMap["foo"].parens == ParenthesesRecommendation::CursorAfter);
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_sealed_table")
{

    check(R"(
function f(a: { x: number, y: number }) return a.x + a.y end
const fp: @1= f
    )");

    auto ac = autocomplete('1');

    if (!FFlag::DebugLuauForceOldSolver)
        REQUIRE_EQ("({ x: number, y: number }) -> number", toString(requireType("f")));
    else
    {
        // NOTE: All autocomplete tests occur under no-check mode.
        REQUIRE_EQ("({ x: number, y: number }) -> (...any)", toString(requireType("f")));
    }
    CHECK(ac.entryMap.count("({ x: number, y: number }) -> number"));
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_keywords")
{
    check(R"(
function a(x: boolean) end
function b(x: number?) end
function c(x: (number) -> string) end
function d(x: ((number) -> string)?) end
function e(x: ((number) -> string) & ((boolean) -> number)) end

const tru = {}
const ni = false

const ac = a(t@1)
const bc = b(n@2)
const cc = c(f@3)
const dc = d(f@4)
const ec = e(f@5)
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("tru"));
    CHECK(ac.entryMap["tru"].typeCorrect == TypeCorrectKind::None);
    CHECK(ac.entryMap["true"].typeCorrect == TypeCorrectKind::Correct);
    CHECK(ac.entryMap["false"].typeCorrect == TypeCorrectKind::Correct);

    ac = autocomplete('2');
    CHECK(ac.entryMap.count("ni"));
    CHECK(ac.entryMap["ni"].typeCorrect == TypeCorrectKind::None);
    CHECK(ac.entryMap["null"].typeCorrect == TypeCorrectKind::Correct);

    ac = autocomplete('3');
    CHECK(ac.entryMap.count("false"));
    CHECK(ac.entryMap["false"].typeCorrect == TypeCorrectKind::None);
    CHECK(ac.entryMap["function"].typeCorrect == TypeCorrectKind::Correct);

    ac = autocomplete('4');
    CHECK(ac.entryMap["function"].typeCorrect == TypeCorrectKind::Correct);

    ac = autocomplete('5');
    CHECK(ac.entryMap["function"].typeCorrect == TypeCorrectKind::Correct);
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_suggestion_for_overloads")
{
    if (!FFlag::DebugLuauForceOldSolver) // CLI-116814 Autocomplete needs to populate expected types for function arguments correctly
        return;                          // (overloads and singletons)
    check(R"(
const target: ((number) -> string) & ((string) -> number))

one = 4
two = "hello"
return target(o@1)
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("one"));
    CHECK(ac.entryMap["one"].typeCorrect == TypeCorrectKind::Correct);
    CHECK(ac.entryMap["two"].typeCorrect == TypeCorrectKind::Correct);

    check(R"(
const target: ((number) -> string) & ((number) -> number))

one = 4
two = "hello"
return target(o@1)
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("one"));
    CHECK(ac.entryMap["one"].typeCorrect == TypeCorrectKind::Correct);
    CHECK(ac.entryMap["two"].typeCorrect == TypeCorrectKind::None);

    check(R"(
const target: ((number, number) -> string) & ((string) -> number))

one = 4
two = "hello"
return target(1, o@1)
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("one"));
    CHECK(ac.entryMap["one"].typeCorrect == TypeCorrectKind::Correct);
    CHECK(ac.entryMap["two"].typeCorrect == TypeCorrectKind::None);
}

TEST_CASE_FIXTURE(ACFixture, "optional_members")
{
    check(R"(
a = { x = 2, y = 3 }
type A = typeof(a)
const b: A? = a
return b.@1
    )");

    auto ac = autocomplete('1');

    CHECK_EQ(2, ac.entryMap.size());
    CHECK(ac.entryMap.count("x"));
    CHECK(ac.entryMap.count("y"));

    check(R"(
a = { x = 2, y = 3 }
type A = typeof(a)
const b: null | A = a
return b.@1
    )");

    ac = autocomplete('1');

    CHECK_EQ(2, ac.entryMap.size());
    CHECK(ac.entryMap.count("x"));
    CHECK(ac.entryMap.count("y"));

    check(R"(
const b: null | null
return b.@1
    )");

    ac = autocomplete('1');

    CHECK_EQ(0, ac.entryMap.size());
}

TEST_CASE_FIXTURE(ACFixture, "no_function_name_suggestions")
{
    check(R"(
function na@1
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.empty());

    check(R"(
function @1
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.empty());

    check(R"(
function na@1
    )");

    ac = autocomplete('1');

    CHECK(ac.entryMap.empty());
}

TEST_CASE_FIXTURE(ACFixture, "skip_current_local")
{
    check(R"(
const other = 1
const name = na@1
    )");

    auto ac = autocomplete('1');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "name");
    CHECK(ac.entryMap.count("other"));

    check(R"(
const other = 1
name, test = na@1
    )");

    ac = autocomplete('1');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "name");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "test");
    CHECK(ac.entryMap.count("other"));
}

TEST_CASE_FIXTURE(ACFixture, "keyword_members")
{
    check(R"(
a = { done = 1, forever = 2 }
b = a.do@1
c = a.for@2
d = a.@3
do
end
    )");

    auto ac = autocomplete('1');

    CHECK_EQ(2, ac.entryMap.size());
    CHECK(ac.entryMap.count("done"));
    CHECK(ac.entryMap.count("forever"));

    ac = autocomplete('2');

    CHECK_EQ(2, ac.entryMap.size());
    CHECK(ac.entryMap.count("done"));
    CHECK(ac.entryMap.count("forever"));

    ac = autocomplete('3');

    CHECK_EQ(2, ac.entryMap.size());
    CHECK(ac.entryMap.count("done"));
    CHECK(ac.entryMap.count("forever"));
}

TEST_CASE_FIXTURE(ACFixture, "keyword_methods")
{
    check(R"(
a = {}
function a:done() end
b = a:do@1
    )");

    auto ac = autocomplete('1');

    CHECK_EQ(1, ac.entryMap.size());
    CHECK(ac.entryMap.count("done"));
}

TEST_CASE_FIXTURE(ACFixture, "keyword_types")
{
    fileResolver.source["Module/A"] = R"(
export type done = { x: number, y: number }
export type other = { z: number, w: number }
return {}
    )";

    LUAU_REQUIRE_NO_ERRORS(getFrontend().check("Module/A"));

    fileResolver.source["Module/B"] = R"(
const aaa = require(script.Parent.A)
const a: aaa.do
    )";

    getFrontend().check("Module/B");

    auto ac = autocomplete("Module/B", Position{2, 15});

    CHECK_EQ(2, ac.entryMap.size());
    CHECK(ac.entryMap.count("done"));
    CHECK(ac.entryMap.count("other"));
}


TEST_CASE_FIXTURE(ACFixture, "comments")
{
    fileResolver.source["Comments"] = "--foo";

    auto ac = autocomplete("Comments", Position{0, 5});
    CHECK_EQ(0, ac.entryMap.size());
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "autocompleteProp_index_function_metamethod_is_variadic")
{
    fileResolver.source["Module/A"] = R"(
        type Foo = {x: number}
        const t = {}
        setmetatable(t, {
            const __index = function(index: string): ...Foo
                return {x = 1}, {x = 2}
            end
        })

        const a = t. -- Line 9
        --          | Column 20
    )";

    auto ac = autocomplete("Module/A", Position{9, 20});
    REQUIRE_EQ(1, ac.entryMap.size());
    CHECK(ac.entryMap.count("x"));
}

TEST_CASE_FIXTURE(ACFixture, "if_then_else_full_keywords")
{
    check(R"(
thenceforth = false
elsewhere = false
doover = false
endurance = true

if 1 then@1
else@2
end

while false do@3
end

repeat@4
until
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.size() == 1);
    CHECK(ac.entryMap.count("then"));

    ac = autocomplete('2');
    CHECK(ac.entryMap.count("else"));
    CHECK(ac.entryMap.count("elseif") == 0);

    ac = autocomplete('3');
    CHECK(ac.entryMap.count("do"));

    ac = autocomplete('4');
    CHECK(ac.entryMap.count("do"));

    // FIXME: ideally we want to handle start and end of all statements as well
}

TEST_CASE_FIXTURE(ACFixture, "if_then_else_elseif_completions")
{
    check(R"(
const elsewhere = false

if true then
    return 1
el@1
end
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("else"));
    CHECK(ac.entryMap.count("elseif") == 0);
    CHECK(ac.entryMap.count("elsewhere") == 0);

    check(R"(
const elsewhere = false

if true then
    return 1
else
    return 2
el@1
end
    )");

    ac = autocomplete('1');
    CHECK(ac.entryMap.count("else") == 0);
    CHECK(ac.entryMap.count("elseif") == 0);
    CHECK(ac.entryMap.count("elsewhere"));

    check(R"(
const elsewhere = false

if true then
    print("1")
elif true then
    print("2")
el@1
end
    )");
    ac = autocomplete('1');
    CHECK(ac.entryMap.count("else"));
    CHECK(ac.entryMap.count("elseif") == 0);
    CHECK(ac.entryMap.count("elsewhere"));
}

TEST_CASE_FIXTURE(ACFixture, "not_the_var_we_are_defining")
{
    fileResolver.source["Module/A"] = "abc,de";

    auto ac = autocomplete("Module/A", Position{0, 6});
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "de");
}

TEST_CASE_FIXTURE(ACFixture, "recursive_function_global")
{
    fileResolver.source["global"] = R"(function abc()

end
)";

    auto ac = autocomplete("global", Position{1, 0});
    CHECK(ac.entryMap.count("abc"));
}



TEST_CASE_FIXTURE(ACFixture, "recursive_function_local")
{
    fileResolver.source["const"] = R"(function abc()

end
)";

    auto ac = autocomplete("const", Position{1, 0});
    CHECK(ac.entryMap.count("abc"));
}

TEST_CASE_FIXTURE(ACFixture, "suggest_table_keys")
{
    if (!FFlag::DebugLuauForceOldSolver) // CLI-116812 AutocompleteTest.suggest_table_keys needs to populate expected types for nested
                                         // tables without an annotation
        return;

    check(R"(
type Test = { first: number, second: number }
const t: Test = { f@1 }
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("first"));
    CHECK(ac.entryMap.count("second"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);

    // Intersection
    check(R"(
type Test = { first: number } & { second: number }
const t: Test = { f@1 }
    )");

    ac = autocomplete('1');
    CHECK(ac.entryMap.count("first"));
    CHECK(ac.entryMap.count("second"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);

    // Union
    check(R"(
type Test = { first: number, second: number } | { second: number, third: number }
const t: Test = { s@1 }
    )");

    ac = autocomplete('1');
    CHECK(ac.entryMap.count("second"));
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "first");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "third");
    CHECK_EQ(ac.context, AutocompleteContext::Property);

    // No parenthesis suggestion
    check(R"(
type Test = { first: (number) -> number, second: number }
const t: Test = { f@1 }
    )");

    ac = autocomplete('1');
    CHECK(ac.entryMap.count("first"));
    CHECK(ac.entryMap["first"].parens == ParenthesesRecommendation::None);
    CHECK_EQ(ac.context, AutocompleteContext::Property);

    // When key is changed
    check(R"(
type Test = { first: number, second: number }
const t: Test = { f@1 = 2 }
    )");

    ac = autocomplete('1');
    CHECK(ac.entryMap.count("first"));
    CHECK(ac.entryMap.count("second"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);

    // Alternative key syntax
    check(R"(
type Test = { first: number, second: number }
const t: Test = { ["f@1"] }
    )");

    ac = autocomplete('1');
    CHECK(ac.entryMap.count("first"));
    CHECK(ac.entryMap.count("second"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);

    // Not an alternative key syntax
    check(R"(
type Test = { first: number, second: number }
const t: Test = { "f@1" }
    )");

    ac = autocomplete('1');
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "first");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "second");
    CHECK_EQ(ac.context, AutocompleteContext::String);

    // Skip keys that are already defined
    check(R"(
type Test = { first: number, second: number }
const t: Test = { first = 2, s@1 }
    )");

    ac = autocomplete('1');
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "first");
    CHECK(ac.entryMap.count("second"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);

    // Don't skip active key
    check(R"(
type Test = { first: number, second: number }
const t: Test = { first@1 }
    )");

    ac = autocomplete('1');
    CHECK(ac.entryMap.count("first"));
    CHECK(ac.entryMap.count("second"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);

    // Inference after first key
    check(R"(
t = {
    { first = 5, second = 10 },
    { f@1 }
}
    )");

    ac = autocomplete('1');
    CHECK(ac.entryMap.count("first"));
    CHECK(ac.entryMap.count("second"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);

    check(R"(
t = {
    [2] = { first = 5, second = 10 },
    [5] = { f@1 }
}
    )");

    ac = autocomplete('1');
    CHECK(ac.entryMap.count("first"));
    CHECK(ac.entryMap.count("second"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);
}

TEST_CASE_FIXTURE(ACFixture, "suggest_table_keys_no_initial_character")
{
    check(R"(
type Test = { first: number, second: number }
const t: Test = { @1 }
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("first"));
    CHECK(ac.entryMap.count("second"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);
}

TEST_CASE_FIXTURE(ACFixture, "suggest_table_keys_no_initial_character_2")
{
    check(R"(
type Test = { first: number, second: number }
const t: Test = { first = 1, @1 }
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("first"), 0);
    CHECK(ac.entryMap.count("second"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);
}

TEST_CASE_FIXTURE(ACFixture, "suggest_table_keys_no_initial_character_3")
{
    check(R"(
type Properties = { TextScaled: boolean, Text: string }
function create(props: Properties) end

create({ @1 })
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.size() > 0);
    CHECK(ac.entryMap.count("TextScaled"));
    CHECK(ac.entryMap.count("Text"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_documentation_symbols")
{
    loadDefinition(R"(
        declare y: {
            x: number,
        }
    )");

    check(R"(
        a = y.@1
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("x"));
    CHECK_EQ(ac.entryMap["x"].documentationSymbol, "@test/global/y.x");
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_ifelse_expressions")
{
    check(R"(
const temp = false
const even = true;
const a = true
const a = if t@1emp then t
const a = if temp t@2
const a = if temp then e@3
const a = if temp then even e@4
const a = if temp then even else if t@5
const a = if temp then even else if true t@6
const a = if temp then even else if true then t@7
const a = if temp then even else if true then temp e@8
const a = if temp then even else if true then temp else e@9
        )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("temp"));
    CHECK(ac.entryMap.count("true"));
    CHECK(ac.entryMap.count("then") == 0);
    CHECK(ac.entryMap.count("else") == 0);
    CHECK(ac.entryMap.count("elseif") == 0);
    CHECK_EQ(ac.context, AutocompleteContext::Expression);

    ac = autocomplete('2');
    CHECK(ac.entryMap.count("temp") == 0);
    CHECK(ac.entryMap.count("true") == 0);
    CHECK(ac.entryMap.count("then"));
    CHECK(ac.entryMap.count("else") == 0);
    CHECK(ac.entryMap.count("elseif") == 0);
    CHECK_EQ(ac.context, AutocompleteContext::Keyword);

    ac = autocomplete('3');
    CHECK(ac.entryMap.count("even"));
    CHECK(ac.entryMap.count("then") == 0);
    CHECK(ac.entryMap.count("else") == 0);
    CHECK(ac.entryMap.count("elseif") == 0);
    CHECK_EQ(ac.context, AutocompleteContext::Expression);

    ac = autocomplete('4');
    CHECK(ac.entryMap.count("even") == 0);
    CHECK(ac.entryMap.count("then") == 0);
    CHECK(ac.entryMap.count("else"));
    CHECK(ac.entryMap.count("elseif") == 0);
    CHECK_EQ(ac.context, AutocompleteContext::Keyword);

    ac = autocomplete('5');
    CHECK(ac.entryMap.count("temp"));
    CHECK(ac.entryMap.count("true"));
    CHECK(ac.entryMap.count("then") == 0);
    CHECK(ac.entryMap.count("else") == 0);
    CHECK(ac.entryMap.count("elseif") == 0);
    CHECK_EQ(ac.context, AutocompleteContext::Expression);

    ac = autocomplete('6');
    CHECK(ac.entryMap.count("temp") == 0);
    CHECK(ac.entryMap.count("true") == 0);
    CHECK(ac.entryMap.count("then"));
    CHECK(ac.entryMap.count("else") == 0);
    CHECK(ac.entryMap.count("elseif") == 0);
    CHECK_EQ(ac.context, AutocompleteContext::Keyword);

    ac = autocomplete('7');
    CHECK(ac.entryMap.count("temp"));
    CHECK(ac.entryMap.count("true"));
    CHECK(ac.entryMap.count("then") == 0);
    CHECK(ac.entryMap.count("else") == 0);
    CHECK(ac.entryMap.count("elseif") == 0);
    CHECK_EQ(ac.context, AutocompleteContext::Expression);

    ac = autocomplete('8');
    CHECK(ac.entryMap.count("even") == 0);
    CHECK(ac.entryMap.count("then") == 0);
    CHECK(ac.entryMap.count("else"));
    CHECK(ac.entryMap.count("elseif") == 0);
    CHECK_EQ(ac.context, AutocompleteContext::Keyword);

    ac = autocomplete('9');
    CHECK(ac.entryMap.count("then") == 0);
    CHECK(ac.entryMap.count("else") == 0);
    CHECK(ac.entryMap.count("elseif") == 0);
    CHECK_EQ(ac.context, AutocompleteContext::Expression);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_if_else_regression")
{
    check(R"(
const abcdef = 0;
const temp = false
const even = true;
const a = null
const a = if temp then even else@1
const a = if temp then even else @2
const a = if temp then even else abc@3
        )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("else") == 0);
    ac = autocomplete('2');
    CHECK(ac.entryMap.count("else") == 0);
    ac = autocomplete('3');
    CHECK(ac.entryMap.count("abcdef"));
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_interpolated_string_constant")
{
    check(R"(f(`@1`))");
    auto ac = autocomplete('1');
    CHECK(ac.entryMap.empty());
    CHECK_EQ(ac.context, AutocompleteContext::String);

    check(R"(f(`@1 {"a"}`))");
    ac = autocomplete('1');
    CHECK(ac.entryMap.empty());
    CHECK_EQ(ac.context, AutocompleteContext::String);

    check(R"(f(`{"a"} @1`))");
    ac = autocomplete('1');
    CHECK(ac.entryMap.empty());
    CHECK_EQ(ac.context, AutocompleteContext::String);

    check(R"(f(`{"a"} @1 {"b"}`))");
    ac = autocomplete('1');
    CHECK(ac.entryMap.empty());
    CHECK_EQ(ac.context, AutocompleteContext::String);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_interpolated_string_expression")
{
    check(R"(f(`expression = {@1}`))");
    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("table"));
    CHECK_EQ(ac.context, AutocompleteContext::Expression);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_interpolated_string_expression_with_comments")
{
    check(R"(f(`expression = {--[[ bla bla bla ]]@1`))");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("table"));
    CHECK_EQ(ac.context, AutocompleteContext::Expression);

    check(R"(f(`expression = {@1 --[[ bla bla bla ]]`))");
    ac = autocomplete('1');
    CHECK(!ac.entryMap.empty());
    CHECK(ac.entryMap.count("table"));
    CHECK_EQ(ac.context, AutocompleteContext::Expression);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_interpolated_string_as_singleton")
{
    check(R"(
        --!strict
        function f(a: "cat" | "dog") end

        f(`@1`)
        f(`uhhh{'try'}@2`)
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("cat"));
    CHECK_EQ(ac.context, AutocompleteContext::String);

    ac = autocomplete('2');
    CHECK(ac.entryMap.empty());
    CHECK_EQ(ac.context, AutocompleteContext::String);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_explicit_type_pack")
{
    check(R"(
type A<T...> = () -> T...
const a: A<(number, s@1>
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap.count("string"));
    CHECK_EQ(ac.context, AutocompleteContext::Type);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_first_function_arg_expected_type")
{
    check(R"(
function foo1() return 1 end
function foo2() return "1" end

function bar0() return "got" .. a end
function bar1(a: number) return "got " .. a end
function bar2(a: number, b: string) return "got " .. a .. b end

t = {}
function t:bar1(a: number) return "got " .. a end

r1 = bar0(@1)
r2 = bar1(@2)
r3 = bar2(@3)
r4 = t:bar1(@4)
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("foo1"));
    CHECK(ac.entryMap["foo1"].typeCorrect == TypeCorrectKind::None);
    REQUIRE(ac.entryMap.count("foo2"));
    CHECK(ac.entryMap["foo2"].typeCorrect == TypeCorrectKind::None);

    ac = autocomplete('2');

    REQUIRE(ac.entryMap.count("foo1"));
    CHECK(ac.entryMap["foo1"].typeCorrect == TypeCorrectKind::CorrectFunctionResult);
    REQUIRE(ac.entryMap.count("foo2"));
    CHECK(ac.entryMap["foo2"].typeCorrect == TypeCorrectKind::None);

    ac = autocomplete('3');

    REQUIRE(ac.entryMap.count("foo1"));
    CHECK(ac.entryMap["foo1"].typeCorrect == TypeCorrectKind::CorrectFunctionResult);
    REQUIRE(ac.entryMap.count("foo2"));
    CHECK(ac.entryMap["foo2"].typeCorrect == TypeCorrectKind::None);

    ac = autocomplete('4');

    REQUIRE(ac.entryMap.count("foo1"));
    CHECK(ac.entryMap["foo1"].typeCorrect == TypeCorrectKind::CorrectFunctionResult);
    REQUIRE(ac.entryMap.count("foo2"));
    CHECK(ac.entryMap["foo2"].typeCorrect == TypeCorrectKind::None);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_default_type_parameters")
{
    check(R"(
type A<T = @1> = () -> T
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap.count("string"));
    CHECK_EQ(ac.context, AutocompleteContext::Type);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_default_type_pack_parameters")
{
    check(R"(
type A<T... = ...@1> = () -> T
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("number"));
    CHECK(ac.entryMap.count("string"));
    CHECK_EQ(ac.context, AutocompleteContext::Type);
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "autocomplete_oop_implicit_self")
{
    check(R"(
--!strict
Class = {}
Class.__index = Class
type Class = typeof(setmetatable({} as { x: number }, Class))
function Class.new(x: number): Class
    return setmetatable({x = x}, Class)
end
function Class.getx(self: Class)
    return self.x
end
function test()
    c = Class.new(42)
    n = c:@1
    print(n)
end
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("getx"));
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "autocomplete_on_string_singletons")
{
    check(R"(
        --!strict
        const foo: "hello" | "bye" = "hello"
        foo:@1
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("format"));
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_string_singletons_in_literal")
{
    if (!FFlag::DebugLuauForceOldSolver)
        return;

    // CLI-116814: Under the new solver, we fail to properly apply the expected
    // type to `tag` as we fail to recognize that we can "break apart" unions
    // when trying to apply an expected type.

    check(R"(
        type tagged = {tag:"cat", fieldx:number} | {tag:"dog", fieldy:number}
        const x: tagged = {tag="@1"}
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("cat"));
    CHECK(ac.entryMap.count("dog"));
    CHECK_EQ(ac.context, AutocompleteContext::String);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_string_singletons")
{
    check(R"(
        type tag = "cat" | "dog"
        function f(a: tag) end
        f("@1")
        f(@2)
        const x: tag = "@3"
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("cat"));
    CHECK(ac.entryMap.count("dog"));
    CHECK_EQ(ac.context, AutocompleteContext::String);

    ac = autocomplete('2');

    CHECK(ac.entryMap.count("\"cat\""));
    CHECK(ac.entryMap.count("\"dog\""));
    CHECK_EQ(ac.context, AutocompleteContext::Expression);

    ac = autocomplete('3');

    CHECK(ac.entryMap.count("cat"));
    CHECK(ac.entryMap.count("dog"));
    CHECK_EQ(ac.context, AutocompleteContext::String);
}

TEST_CASE_FIXTURE(ACFixture, "string_singleton_as_table_key_iso")
{
    check(R"(
        type Direction = "up" | "down"
        const b: {[Direction]: boolean} = {["@2"] = true}
    )");

    auto ac = autocomplete('2');

    CHECK(ac.entryMap.count("up"));
    CHECK(ac.entryMap.count("down"));
}

TEST_CASE_FIXTURE(ACFixture, "string_singleton_as_table_key")
{
    check(R"(
        type Direction = "up" | "down"

        const a: {[Direction]: boolean} = {[@1] = true}
        const b: {[Direction]: boolean} = {["@2"] = true}
        const c: {[Direction]: boolean} = {u@3 = true}
        const d: {[Direction]: boolean} = {[u@4] = true}

        const e: {[Direction]: boolean} = {[@5]}
        const f: {[Direction]: boolean} = {["@6"]}
        const g: {[Direction]: boolean} = {u@7}
        const h: {[Direction]: boolean} = {[u@8]}
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("\"up\""));
    CHECK(ac.entryMap.count("\"down\""));

    ac = autocomplete('2');

    CHECK(ac.entryMap.count("up"));
    CHECK(ac.entryMap.count("down"));

    ac = autocomplete('3');

    CHECK(ac.entryMap.count("up"));
    CHECK(ac.entryMap.count("down"));

    ac = autocomplete('4');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "up");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "down");

    CHECK(ac.entryMap.count("\"up\""));
    CHECK(ac.entryMap.count("\"down\""));

    ac = autocomplete('5');

    CHECK(ac.entryMap.count("\"up\""));
    CHECK(ac.entryMap.count("\"down\""));

    ac = autocomplete('6');

    CHECK(ac.entryMap.count("up"));
    CHECK(ac.entryMap.count("down"));

    ac = autocomplete('7');

    CHECK(ac.entryMap.count("up"));
    CHECK(ac.entryMap.count("down"));

    ac = autocomplete('8');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "up");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "down");

    CHECK(ac.entryMap.count("\"up\""));
    CHECK(ac.entryMap.count("\"down\""));
}

// https://github.com/Roblox/luau/issues/858
TEST_CASE_FIXTURE(ACFixture, "string_singleton_in_if_statement")
{
    ScopedFastFlag sff[]{
        {FFlag::DebugLuauForceOldSolver, false},
    };

    check(R"(
        --!strict

        type Direction = "left" | "right"

        const dir: Direction = "left"

        if dir == @1"@2"@3 then end
        const a: {[Direction]: boolean} = {[@4"@5"@6]}

        if dir == @7`@8`@9 then end
        const a: {[Direction]: boolean} = {[@A`@B`@C]}
    )");

    Luau::AutocompleteResult ac;

    ac = autocomplete('1');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");

    ac = autocomplete('2');

    LUAU_CHECK_HAS_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_KEY(ac.entryMap, "right");

    ac = autocomplete('3');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");

    ac = autocomplete('4');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");

    ac = autocomplete('5');

    LUAU_CHECK_HAS_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_KEY(ac.entryMap, "right");

    ac = autocomplete('6');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");

    ac = autocomplete('7');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");

    ac = autocomplete('8');

    LUAU_CHECK_HAS_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_KEY(ac.entryMap, "right");

    ac = autocomplete('9');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");

    ac = autocomplete('A');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");

    ac = autocomplete('B');

    LUAU_CHECK_HAS_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_KEY(ac.entryMap, "right");

    ac = autocomplete('C');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");
}

// https://github.com/Roblox/luau/issues/858
TEST_CASE_FIXTURE(ACFixture, "string_singleton_in_if_statement2")
{
    // don't run this when the DCR flag isn't set
    if (FFlag::DebugLuauForceOldSolver)
        return;

    ScopedFastFlag sff{FFlag::LuauExportValueSyntax, true};

    check(R"(
        --!strict

        type Direction = "left" | "right"

        -- typestate here means dir is actually typed as `"left"`
        export dir: Direction
        dir = "left"

        if dir == @1"@2"@3 then end
        const a: {[Direction]: boolean} = {[@4"@5"@6]}

        if dir == @7`@8`@9 then end
        const b: {[Direction]: boolean} = {[@A`@B`@C]}
    )");

    Luau::AutocompleteResult ac;

    ac = autocomplete('1');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");

    ac = autocomplete('2');

    LUAU_CHECK_HAS_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");

    ac = autocomplete('3');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");

    ac = autocomplete('4');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");

    ac = autocomplete('5');

    LUAU_CHECK_HAS_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_KEY(ac.entryMap, "right");

    ac = autocomplete('6');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");

    ac = autocomplete('7');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");

    ac = autocomplete('8');

    LUAU_CHECK_HAS_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");

    ac = autocomplete('9');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");

    ac = autocomplete('A');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");

    ac = autocomplete('B');

    LUAU_CHECK_HAS_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_KEY(ac.entryMap, "right");

    ac = autocomplete('C');

    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "left");
    LUAU_CHECK_HAS_NO_KEY(ac.entryMap, "right");
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_string_singleton_equality")
{
    check(R"(
        type tagged = {tag:"cat", fieldx:number} | {tag:"dog", fieldy:number}
        const x: tagged = {tag="cat", fieldx=2}
        if x.tag == "@1" or "@2" != x.tag then end
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("cat"));
    CHECK(ac.entryMap.count("dog"));

    ac = autocomplete('2');

    CHECK(ac.entryMap.count("cat"));
    CHECK(ac.entryMap.count("dog"));

    // CLI-48823: assignment to x.tag should also autocomplete, but union l-values are not supported yet
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_boolean_singleton")
{
    check(R"(
function f(x: true) end
f(@1)
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("true"));
    CHECK(ac.entryMap["true"].typeCorrect == TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap.count("false"));
    CHECK(ac.entryMap["false"].typeCorrect == TypeCorrectKind::None);
    CHECK_EQ(ac.context, AutocompleteContext::Expression);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_string_singleton_escape")
{
    check(R"(
        type tag = "strange\t\"cat\"" | 'nice\t"dog"'
        function f(x: tag) end
        f(@1)
        f("@2")
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("\"strange\\t\\\"cat\\\"\""));
    CHECK(ac.entryMap.count("\"nice\\t\\\"dog\\\"\""));

    ac = autocomplete('2');

    CHECK(ac.entryMap.count("strange\\t\\\"cat\\\""));
    CHECK(ac.entryMap.count("nice\\t\\\"dog\\\""));
}

TEST_CASE_FIXTURE(ACFixture, "function_in_assignment_has_parentheses_2")
{
    check(R"(
const bar: ((number) -> number) & (number, number) -> number)
abc = b@1
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("bar"));
    CHECK(ac.entryMap["bar"].parens == ParenthesesRecommendation::CursorInside);
}

TEST_CASE_FIXTURE(ACFixture, "no_incompatible_self_calls_on_class")
{
    // Legacy behavior: dot on an extern type method (`one`) is flagged wrongIndexType. The
    // conversion feature changes this — see extern_type_method_via_dot for the flag-on case.
    ScopedFastFlag sff{FFlag::LuauAutocompleteDotMethodConversion, false};

    loadDefinition(R"(
declare extern type Foo with
    function one(self): number
    two: () -> number
end
    )");

    {
        check(R"(
function f(t: Foo)
    t:@1
end
        )");

        auto ac = autocomplete('1');

        REQUIRE(ac.entryMap.count("one"));
        REQUIRE(ac.entryMap.count("two"));
        CHECK(!ac.entryMap["one"].wrongIndexType);
        CHECK(ac.entryMap["two"].wrongIndexType);
        CHECK(ac.entryMap["one"].indexedWithSelf);
        CHECK(ac.entryMap["two"].indexedWithSelf);
    }

    {
        check(R"(
function f(t: Foo)
    t.@1
end
        )");

        auto ac = autocomplete('1');

        REQUIRE(ac.entryMap.count("one"));
        REQUIRE(ac.entryMap.count("two"));
        CHECK(ac.entryMap["one"].wrongIndexType);
        CHECK(!ac.entryMap["two"].wrongIndexType);
        CHECK(!ac.entryMap["one"].indexedWithSelf);
        CHECK(!ac.entryMap["two"].indexedWithSelf);
    }
}

TEST_CASE_FIXTURE(ACFixture, "simple")
{
    check(R"(
t = {}
function t:m() end
t:m()
    )");

    // auto ac = autocomplete('1');

    //  REQUIRE(ac.entryMap.count("m"));
    // CHECK(!ac.entryMap["m"].wrongIndexType);
}

TEST_CASE_FIXTURE(ACFixture, "do_compatible_self_calls")
{
    check(R"(
t = {}
function t:m() end
t:@1
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("m"));
    CHECK(!ac.entryMap["m"].wrongIndexType);
    CHECK(ac.entryMap["m"].indexedWithSelf);
}

TEST_CASE_FIXTURE(ACFixture, "no_incompatible_self_calls")
{
    check(R"(
t = {}
function t.m() end
t:@1
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("m"));
    CHECK(ac.entryMap["m"].wrongIndexType);
    CHECK(ac.entryMap["m"].indexedWithSelf);
}

TEST_CASE_FIXTURE(ACFixture, "no_incompatible_self_calls_2")
{
    check(R"(
const f: (() -> number) & ((number) -> number) = function(x: number?) return 2 end
t = {}
t.f = f
t:@1
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("f"));
    CHECK(ac.entryMap["f"].wrongIndexType);
    CHECK(ac.entryMap["f"].indexedWithSelf);
}

TEST_CASE_FIXTURE(ACFixture, "do_wrong_compatible_self_calls")
{
    check(R"(
t = {}
function t.m(x: typeof(t)) end
t:@1
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("m"));
    // We can make changes to mark this as a wrong way to call even though it's compatible
    CHECK(!ac.entryMap["m"].wrongIndexType);
    CHECK(ac.entryMap["m"].indexedWithSelf);
}

TEST_CASE_FIXTURE(ACFixture, "do_wrong_compatible_nonself_calls")
{
    // Legacy behavior: dot on a method is flagged wrongIndexType. The conversion feature
    // intentionally changes this — see dot_method_marks_for_conversion for the flag-on case.
    ScopedFastFlag sff{FFlag::LuauAutocompleteDotMethodConversion, false};

    check(R"(
t = {}
function t:m(x: string) end
t.@1
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("m"));

    if (!FFlag::DebugLuauForceOldSolver)
        CHECK(ac.entryMap["m"].wrongIndexType);
    else
        CHECK(!ac.entryMap["m"].wrongIndexType);
    CHECK(!ac.entryMap["m"].indexedWithSelf);
}

TEST_CASE_FIXTURE(ACFixture, "no_wrong_compatible_self_calls_with_generics")
{
    check(R"(
t = {}
function t.m<T>(a: T) end
t:@1
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("m"));
    // While this call is compatible with the type, this requires instantiation of a generic type which we don't perform
    CHECK(ac.entryMap["m"].wrongIndexType);
    CHECK(ac.entryMap["m"].indexedWithSelf);
}

TEST_CASE_FIXTURE(ACFixture, "dot_method_marks_for_conversion")
{
    // The conversion signal relies on `checkTypeMatch` precisely identifying that the receiver
    // matches the function's first arg — which the new solver does and the old solver does not
    // (see do_wrong_compatible_nonself_calls). Force the new solver so this test is deterministic.
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::LuauAutocompleteDotMethodConversion, true},
    };

    check(R"(
t = {}
function t:m() end
t.@1
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("m"));
    CHECK(ac.entryMap["m"].replaceDotWithColon);
    CHECK(!ac.entryMap["m"].wrongIndexType);
    CHECK(ac.entryMap["m"].indexedWithSelf);
}

TEST_CASE_FIXTURE(ACFixture, "dot_function_no_conversion")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::LuauAutocompleteDotMethodConversion, true},
    };

    check(R"(
t = {}
function t.m() end
t.@1
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("m"));
    CHECK(!ac.entryMap["m"].replaceDotWithColon);
    CHECK(!ac.entryMap["m"].wrongIndexType);
}

TEST_CASE_FIXTURE(ACFixture, "colon_no_conversion_marker")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::LuauAutocompleteDotMethodConversion, true},
    };

    check(R"(
t = {}
function t:m() end
t:@1
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("m"));
    CHECK(!ac.entryMap["m"].replaceDotWithColon);
    CHECK(!ac.entryMap["m"].wrongIndexType);
    CHECK(ac.entryMap["m"].indexedWithSelf);
}

TEST_CASE_FIXTURE(ACFixture, "extern_type_method_via_dot")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::LuauAutocompleteDotMethodConversion, true},
    };

    loadDefinition(R"(
        declare extern type Foo with
            function one(self): number
            two: () -> number
        end
    )");

    check(R"(
        function f(t: Foo)
            t.@1
        end
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("one"));
    REQUIRE(ac.entryMap.count("two"));
    CHECK(ac.entryMap["one"].replaceDotWithColon);
    CHECK(!ac.entryMap["one"].wrongIndexType);
    CHECK(ac.entryMap["one"].indexedWithSelf);
    // Plain function field on the extern type stays as-is.
    CHECK(!ac.entryMap["two"].replaceDotWithColon);
    CHECK(!ac.entryMap["two"].wrongIndexType);
}

TEST_CASE_FIXTURE(ACFixture, "extern_type_first_arg_match_does_not_make_colon_compatible")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::LuauAutocompleteDotMethodConversion, true},
    };

    // For ExternTypes, the `hasSelf` property of the method is the only thing we look at.
    // If the function does not set this, then `:` is always wrong.

    loadDefinition(R"(
        declare extern type Foo with
            bar: (Foo) -> number
        end
    )");

    check(R"(
        function f(t: Foo)
            t:@1
        end
    )");

    auto ac = autocomplete('1');
    REQUIRE(ac.entryMap.count("bar"));
    CHECK(ac.entryMap["bar"].wrongIndexType);
    CHECK(!ac.entryMap["bar"].replaceDotWithColon);
}

TEST_CASE_FIXTURE(ACFixture, "intersection_with_some_self_overloads")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::LuauAutocompleteDotMethodConversion, true},
    };

    // An intersection where at least one overload is dot-callable: keep the dot,
    // don't propose conversion (the user might intend the non-self overload).
    check(R"(
const f: (() -> number) & ((number) -> number) = function(x: number?) return 2 end
t = {}
t.f = f
t.@1
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("f"));
    CHECK(!ac.entryMap["f"].replaceDotWithColon);
}

TEST_CASE_FIXTURE(ACFixture, "string_prim_self_calls_are_fine")
{
    check(R"(
s = "hello"
s:@1
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("byte"));
    CHECK(ac.entryMap["byte"].wrongIndexType == false);
    CHECK(ac.entryMap["byte"].indexedWithSelf);
    REQUIRE(ac.entryMap.count("char"));
    CHECK(ac.entryMap["char"].wrongIndexType == true);
    CHECK(ac.entryMap["char"].indexedWithSelf);
    REQUIRE(ac.entryMap.count("sub"));
    CHECK(ac.entryMap["sub"].wrongIndexType == false);
    CHECK(ac.entryMap["sub"].indexedWithSelf);
}

TEST_CASE_FIXTURE(ACFixture, "string_prim_non_self_calls_are_avoided")
{
    // Legacy behavior: dot on a string method like `sub` is flagged wrongIndexType. The
    // conversion feature changes this — `sub` becomes a convertible method completion.
    ScopedFastFlag sff{FFlag::LuauAutocompleteDotMethodConversion, false};

    check(R"(
s = "hello"
s.@1
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("char"));
    CHECK(ac.entryMap["char"].wrongIndexType == false);
    CHECK(!ac.entryMap["char"].indexedWithSelf);
    REQUIRE(ac.entryMap.count("sub"));
    CHECK(ac.entryMap["sub"].wrongIndexType == true);
    CHECK(!ac.entryMap["sub"].indexedWithSelf);
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "library_non_self_calls_are_fine")
{
    check(R"(
string.@1
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("byte"));
    CHECK(ac.entryMap["byte"].wrongIndexType == false);
    CHECK(!ac.entryMap["byte"].indexedWithSelf);
    REQUIRE(ac.entryMap.count("char"));
    CHECK(ac.entryMap["char"].wrongIndexType == false);
    CHECK(!ac.entryMap["char"].indexedWithSelf);
    REQUIRE(ac.entryMap.count("sub"));
    CHECK(ac.entryMap["sub"].wrongIndexType == false);
    CHECK(!ac.entryMap["sub"].indexedWithSelf);

    check(R"(
table.@1
    )");

    ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("remove"));
    CHECK(ac.entryMap["remove"].wrongIndexType == false);
    CHECK(!ac.entryMap["remove"].indexedWithSelf);
    REQUIRE(ac.entryMap.count("getn"));
    CHECK(ac.entryMap["getn"].wrongIndexType == false);
    CHECK(!ac.entryMap["getn"].indexedWithSelf);
    REQUIRE(ac.entryMap.count("insert"));
    CHECK(ac.entryMap["insert"].wrongIndexType == false);
    CHECK(!ac.entryMap["insert"].indexedWithSelf);
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "library_self_calls_are_invalid")
{
    check(R"(
string:@1
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count("byte"));
    CHECK(ac.entryMap["byte"].wrongIndexType == true);
    CHECK(ac.entryMap["byte"].indexedWithSelf);
    REQUIRE(ac.entryMap.count("char"));
    CHECK(ac.entryMap["char"].wrongIndexType == true);
    CHECK(ac.entryMap["char"].indexedWithSelf);

    // We want the next test to evaluate to 'true', but we have to allow function defined with 'self' to be callable with ':'
    // We may change the definition of the string metatable to not use 'self' types in the future (like byte/char/pack/unpack)
    REQUIRE(ac.entryMap.count("sub"));
    CHECK(ac.entryMap["sub"].wrongIndexType == false);
    CHECK(ac.entryMap["sub"].indexedWithSelf);
}

TEST_CASE_FIXTURE(ACFixture, "source_module_preservation_and_invalidation")
{
    check(R"(
a = { x = 2, y = 4 }
a.@1
    )");

    getFrontend().clear();

    auto ac = autocomplete('1');

    CHECK(2 == ac.entryMap.size());

    CHECK(ac.entryMap.count("x"));
    CHECK(ac.entryMap.count("y"));

    getFrontend().check("MainModule", {});

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("x"));
    CHECK(ac.entryMap.count("y"));

    getFrontend().markDirty("MainModule", nullptr);

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("x"));
    CHECK(ac.entryMap.count("y"));

    getFrontend().check("MainModule", {});

    ac = autocomplete('1');

    CHECK(ac.entryMap.count("x"));
    CHECK(ac.entryMap.count("y"));
}

TEST_CASE_FIXTURE(ACFixture, "globals_are_order_independent")
{
    check(R"(
        const myLocal = 4
        function abc0()
            const myInnerLocal = 1
@1
        end

        function abc1()
            const myInnerLocal = 1
        end
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("myLocal"));
    CHECK(ac.entryMap.count("myInnerLocal"));
    CHECK(ac.entryMap.count("abc0"));
    // Bare `function abc1()` is now an implicit top-level local (not a global), so forward
    // references from earlier definitions are not visible (locals are order-dependent).
    CHECK(ac.entryMap.count("abc1") == 0);
}

TEST_CASE_FIXTURE(ACFixture, "string_contents_is_available_to_callback")
{
    loadDefinition(R"(
        declare function require(path: string): any
    )");

    GlobalTypes& globals = !FFlag::DebugLuauForceOldSolver ? getFrontend().globals : getFrontend().globalsForAutocomplete;

    std::optional<Binding> require = globals.globalScope->linearSearchForBinding("require");
    REQUIRE(require);
    Luau::unfreeze(globals.globalTypes);
    attachTag(require->typeId, "RequireCall");
    Luau::freeze(globals.globalTypes);

    check(R"(
        x = require("testing/@1")
    )");

    bool isCorrect = false;
    auto ac1 = autocomplete(
        '1',
        [&isCorrect](std::string, std::optional<const ExternType*>, std::optional<std::string> contents) -> std::optional<AutocompleteEntryMap>
        {
            isCorrect = contents && *contents == "testing/";
            return std::nullopt;
        }
    );

    CHECK(isCorrect);
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "require_by_string")
{
    fileResolver.source["MainModule"] = R"(
        const info = "MainModule serves as the root directory"
    )";

    fileResolver.source["MainModule/Folder"] = R"(
        const info = "MainModule/Folder serves as a subdirectory"
    )";

    fileResolver.source["MainModule/Folder/Requirer"] = R"(
        const res0 = require("@")

        const res1 = require(".")
        const res2 = require("./")
        const res3 = require("./Sib")

        const res4 = require("..")
        const res5 = require("../")
        const res6 = require("../Sib")
    )";

    fileResolver.source["MainModule/Folder/SiblingDependency"] = R"(
        return {"result"}
    )";

    fileResolver.source["MainModule/ParentDependency"] = R"(
        return {"result"}
    )";

    struct RequireCompletion
    {
        std::string label;
        std::string insertText;
    };

    auto checkEntries = [](const AutocompleteEntryMap& entryMap, const std::vector<RequireCompletion>& completions)
    {
        CHECK(completions.size() == entryMap.size());
        for (const auto& completion : completions)
        {
            CHECK(entryMap.count(completion.label));
            CHECK(entryMap.at(completion.label).insertText == completion.insertText);
        }
    };

    AutocompleteResult acResult;
    acResult = autocomplete("MainModule/Folder/Requirer", Position{1, 31});
    checkEntries(acResult.entryMap, {{"@defaultalias", "@defaultalias"}, {"./", "./"}, {"../", "../"}});

    acResult = autocomplete("MainModule/Folder/Requirer", Position{3, 31});
    checkEntries(acResult.entryMap, {{"@defaultalias", "@defaultalias"}, {"./", "./"}, {"../", "../"}});
    acResult = autocomplete("MainModule/Folder/Requirer", Position{4, 32});
    checkEntries(acResult.entryMap, {{"..", "."}, {"Requirer", "./Requirer"}, {"SiblingDependency", "./SiblingDependency"}});
    acResult = autocomplete("MainModule/Folder/Requirer", Position{5, 35});
    checkEntries(acResult.entryMap, {{"..", "."}, {"Requirer", "./Requirer"}, {"SiblingDependency", "./SiblingDependency"}});

    acResult = autocomplete("MainModule/Folder/Requirer", Position{7, 32});
    checkEntries(acResult.entryMap, {{"@defaultalias", "@defaultalias"}, {"./", "./"}, {"../", "../"}});
    acResult = autocomplete("MainModule/Folder/Requirer", Position{8, 33});
    checkEntries(acResult.entryMap, {{"..", "../.."}, {"Folder", "../Folder"}, {"ParentDependency", "../ParentDependency"}});
    acResult = autocomplete("MainModule/Folder/Requirer", Position{9, 36});
    checkEntries(acResult.entryMap, {{"..", "../.."}, {"Folder", "../Folder"}, {"ParentDependency", "../ParentDependency"}});
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_response_perf1" * doctest::timeout(LUAU_TIMEOUT))
{
    if (!FFlag::DebugLuauForceOldSolver)
        return; // FIXME: This test is just barely at the threshold which makes it very flaky under the new solver

    // Build a function type with a large overload set
    const int parts = 100;
    std::string source;

    for (int i = 0; i < parts; i++)
        formatAppend(source, "type T%d = { f%d: number }\n", i, i);

    source += "type Instance = { new: (('s0', extra: Instance?) -> T0)";

    for (int i = 1; i < parts; i++)
        formatAppend(source, " & (('s%d', extra: Instance?) -> T%d)", i, i);

    source += " }\n";

    source += "const Instance: Instance = {} as any\n";
    source += "function c(): boolean return t@1 end\n";

    check(source);

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("true"));
    CHECK(ac.entryMap.count("Instance"));
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_subtyping_recursion_limit")
{
    // TODO: in old solver, type resolve can't handle the type in this test without a stack overflow
    if (FFlag::DebugLuauForceOldSolver)
        return;

    ScopedFastInt luauTypeInferRecursionLimit{FInt::LuauTypeInferRecursionLimit, 10};
    ScopedFastInt luauSubtypingRecursionLimit{DFInt::LuauSubtypingRecursionLimit, 10};

    const int parts = 100;
    std::string source;

    source += "function f()\n";

    std::string prefix;
    for (int i = 0; i < parts; i++)
        formatAppend(prefix, "(null|({a%d:number}&", i);
    formatAppend(prefix, "(null|{a%d:number})", parts);
    for (int i = 0; i < parts; i++)
        formatAppend(prefix, "))");

    source += "const x1 : " + prefix + "\n";
    source += "const y : {a1:number} = x@1\n";

    source += "end\n";

    check(source);

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("true"));
    CHECK(ac.entryMap.count("x1"));
}

TEST_CASE_FIXTURE(ACFixture, "strict_mode_force")
{
    check(R"(
--!nonstrict
const a: {x: number} = {x=1}
b = a
c = b.@1
    )");

    auto ac = autocomplete('1');

    CHECK_EQ(1, ac.entryMap.size());
    CHECK(ac.entryMap.count("x"));
}

TEST_CASE_FIXTURE(ACFixture, "suggest_exported_types")
{
    check(R"(
export type Type = {a: number}
const a: T@1
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("Type"));
    CHECK_EQ(ac.context, AutocompleteContext::Type);
}

TEST_CASE_FIXTURE(ACFixture, "getFrontend().use_correct_global_scope")
{
    loadDefinition(R"(
        declare extern type Instance with
            Name: string
        end
    )");

    CheckResult result = check(R"(
        const a: unknown = null
        if typeof(a) == "Instance" then
            b = a.@1
        end
    )");
    auto ac = autocomplete('1');

    CHECK_EQ(1, ac.entryMap.size());
    CHECK(ac.entryMap.count("Name"));
}

TEST_CASE_FIXTURE(ACFixture, "string_completion_outside_quotes")
{
    loadDefinition(R"(
        declare function require(path: string): any
    )");

    GlobalTypes& globals = !FFlag::DebugLuauForceOldSolver ? getFrontend().globals : getFrontend().globalsForAutocomplete;

    std::optional<Binding> require = globals.globalScope->linearSearchForBinding("require");
    REQUIRE(require);
    Luau::unfreeze(globals.globalTypes);
    attachTag(require->typeId, "RequireCall");
    Luau::freeze(globals.globalTypes);

    check(R"(
        x = require(@1"@2"@3)
    )");

    StringCompletionCallback callback =
        [](std::string, std::optional<const ExternType*>, std::optional<std::string> contents) -> std::optional<AutocompleteEntryMap>
    {
        Luau::AutocompleteEntryMap results = {{"test", Luau::AutocompleteEntry{Luau::AutocompleteEntryKind::String, std::nullopt, false, false}}};
        return results;
    };

    auto ac = autocomplete('2', callback);

    CHECK_EQ(1, ac.entryMap.size());
    CHECK(ac.entryMap.count("test"));

    ac = autocomplete('1', callback);

    CHECK_EQ(0, ac.entryMap.size());

    ac = autocomplete('3', callback);

    CHECK_EQ(0, ac.entryMap.size());
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_empty")
{
    check(R"(
function foo(a: () -> ())
    a()
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function()  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_args")
{
    check(R"(
function foo(a: (number, string) -> ())
    a()
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function(a0: number, a1: string)  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_args_single_return")
{
    check(R"(
function foo(a: (number, string) -> (string))
    a()
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function(a0: number, a1: string): string  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_args_multi_return")
{
    check(R"(
function foo(a: (number, string) -> (string, number))
    a()
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function(a0: number, a1: string): (string, number)  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled__noargs_multi_return")
{
    check(R"(
function foo(a: () -> (string, number))
    a()
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function(): (string, number)  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled__varargs_multi_return")
{
    check(R"(
function foo(a: (...number) -> (string, number))
    a()
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function(...: number): (string, number)  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_multi_varargs_multi_return")
{
    check(R"(
function foo(a: (string, ...number) -> (string, number))
    a()
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function(a0: string, ...: number): (string, number)  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_multi_varargs_varargs_return")
{
    check(R"(
function foo(a: (string, ...number) -> ...number)
    a()
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function(a0: string, ...: number): ...number  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_multi_varargs_multi_varargs_return")
{
    check(R"(
function foo(a: (string, ...number) -> (boolean, ...number))
    a()
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function(a0: string, ...: number): (boolean, ...number)  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_named_args")
{
    check(R"(
function foo(a: (foo: number, bar: string) -> (string, number))
    a()
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function(foo: number, bar: string): (string, number)  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_partially_args")
{
    check(R"(
function foo(a: (number, bar: string) -> (string, number))
    a()
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function(a0: number, bar: string): (string, number)  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_partially_args_last")
{
    check(R"(
function foo(a: (foo: number, string) -> (string, number))
    a()
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function(foo: number, a1: string): (string, number)  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_typeof_args")
{
    check(R"(
const t = { a = 1, b = 2 }

function foo(a: (foo: typeof(t)) -> ())
    a()
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function(foo)  end"; // Cannot utter this type.

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_table_literal_args")
{
    check(R"(
function foo(a: (tbl: { x: number, y: number }) -> number) return a({x=2, y = 3}) end
foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function(tbl: { x: number, y: number }): number  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_typeof_returns")
{
    check(R"(
const t = { a = 1, b = 2 }

function foo(a: () -> typeof(t))
    a()
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function()  end"; // Cannot utter this type.

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_table_literal_args")
{
    check(R"(
function foo(a: () -> { x: number, y: number }) return {x=2, y = 3} end
foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function(): { x: number, y: number }  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_typeof_vararg")
{
    check(R"(
const t = { a = 1, b = 2 }

function foo(a: (...typeof(t)) -> ())
    a()
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function(...)  end"; // Cannot utter this type.

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_generic_type_pack_vararg")
{
    check(R"(
function foo<A>(a: (...A) -> number, ...: A)
	return a(...)
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function(...): number  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_generic_named_arg")
{
    check(R"(
function foo<A>(f: (a: A) -> number, a: A)
	return f(a)
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function(a): number  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_generic_return_type")
{
    check(R"(
function foo<A>(f: () -> A)
	return f()
end

foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT = "function()  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_generic_on_argument_type_pack_vararg")
{
    // Caveat lector!  This is actually invalid syntax!
    // The correct syntax would be as follows:
    //
    // local function foo(a: <T...>(T...) -> number)
    //
    // We leave it as-written here because we still expect autocomplete to
    // handle this code sensibly.
    CheckResult result = check(R"(
        function foo(a: <T...>(...: T...) -> number)
            return a(4, 5, 6)
        end

        foo(@1)
    )");

    const std::optional<std::string> EXPECTED_INSERT =
        !FFlag::DebugLuauForceOldSolver ? "function(...: number): number  end" : "function(...): number  end";

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ(EXPECTED_INSERT, *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

// When the user has already typed "function(" (cursor is inside the arg list), the suggestion
// should only insert the argument parameter list, not the full "function(...) end" expression.

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_cursor_after_function_keyword")
{
    // Cursor is right after the "function" keyword but before any "(" — the arg list has not been
    // opened yet. The suggestion must expand the full "function(...) end" expression, not just the
    // parameter list (which would replace the word "function" with bare argument names).

    check(R"(
function foo(a: (number, string) -> ())
    a()
end

foo(function@1)
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ("function(a0: number, a1: string)  end", *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_cursor_in_arglist_empty")
{
    check(R"(
function foo(a: () -> ())
    a()
end

foo(function(@1))
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ("", *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_cursor_in_arglist_args")
{
    check(R"(
function foo(a: (number, string) -> ())
    a()
end

foo(function(@1))
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ("a0: number, a1: string", *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_cursor_in_arglist_with_return")
{
    check(R"(
function foo(a: (number, string) -> string)
    return a(1, "x")
end

foo(function(@1))
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ("a0: number, a1: string", *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_cursor_in_arglist_named_args")
{
    check(R"(
function foo(a: (foo: number, bar: string) -> ())
    a()
end

foo(function(@1))
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ("foo: number, bar: string", *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "anonymous_autofilled_cursor_in_arglist_varargs")
{
    check(R"(
function foo(a: (...number) -> ())
    a()
end

foo(function(@1))
    )");

    auto ac = autocomplete('1');

    REQUIRE(ac.entryMap.count(kGeneratedAnonymousFunctionEntryName) == 1);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].kind == Luau::AutocompleteEntryKind::GeneratedFunction);
    CHECK(ac.entryMap[kGeneratedAnonymousFunctionEntryName].typeCorrect == Luau::TypeCorrectKind::Correct);
    REQUIRE(ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
    CHECK_EQ("...: number", *ac.entryMap[kGeneratedAnonymousFunctionEntryName].insertText);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_at_end_of_stmt_should_continue_as_part_of_stmt")
{
    check(R"(
data = { x = 1 }
var = data.@1
    )");
    auto ac = autocomplete('1');
    CHECK(!ac.entryMap.empty());
    CHECK(ac.entryMap.count("x"));
    CHECK_EQ(ac.context, AutocompleteContext::Property);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_after_semicolon_should_complete_a_new_statement")
{
    check(R"(
data = { x = 1 }
var = data;@1
    )");
    auto ac = autocomplete('1');
    CHECK(!ac.entryMap.empty());
    CHECK(ac.entryMap.count("table"));
    CHECK(ac.entryMap.count("math"));
    CHECK_EQ(ac.context, AutocompleteContext::Statement);
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "require_tracing")
{
    fileResolver.source["Module/A"] = R"(
return { x = 0 }
    )";

    fileResolver.source["Module/B"] = R"(
result = require(script.Parent.A)
x = 1 + result.
    )";

    auto ac = autocomplete("Module/B", Position{2, 21});

    CHECK(ac.entryMap.size() == 1);
    CHECK(ac.entryMap.count("x"));
}

TEST_CASE_FIXTURE(ACExternTypeFixture, "ac_dont_overflow_on_recursive_union")
{
    check(R"(
        const table1: {ChildClass} = {}
        table2 = {}

        for index, value in table2[1] do
            table.insert(table1, value)
            value.@1
        end
    )");

    auto ac = autocomplete('1');

    if (!FFlag::DebugLuauForceOldSolver)
    {
        CHECK(ac.entryMap.count("BaseMethod") > 0);
        CHECK(ac.entryMap.count("Method") > 0);
    }
    else
    {
        // Otherwise, we don't infer anything for `value`, which is _fine_.
        CHECK(ac.entryMap.empty());
    }
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "type_function_has_types_definitions")
{
    ScopedFastFlag newSolver{FFlag::DebugLuauForceOldSolver, false};

    check(R"(
type function foo()
    types.@1
end
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("singleton"), 1);
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "type_function_private_scope")
{
    ScopedFastFlag newSolver{FFlag::DebugLuauForceOldSolver, false};

    // Global scope pollution by the embedder has no effect
    addGlobalBinding(getFrontend().globals, "thisAlsoShouldNotBeThere", Binding{getBuiltins()->anyType});
    addGlobalBinding(getFrontend().globalsForAutocomplete, "thisAlsoShouldNotBeThere", Binding{getBuiltins()->anyType});

    check(R"(
function thisShouldNotBeThere() end

type function thisShouldBeThere() end

type function foo()
    this@1
end

this@2
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("thisShouldNotBeThere"), 0);
    CHECK_EQ(ac.entryMap.count("thisAlsoShouldNotBeThere"), 0);
    CHECK_EQ(ac.entryMap.count("thisShouldBeThere"), 1);

    ac = autocomplete('2');
    CHECK_EQ(ac.entryMap.count("thisShouldNotBeThere"), 1);
    CHECK_EQ(ac.entryMap.count("thisAlsoShouldNotBeThere"), 1);
    CHECK_EQ(ac.entryMap.count("thisShouldBeThere"), 0);
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "type_function_eval_in_autocomplete")
{
    ScopedFastFlag newSolver{FFlag::DebugLuauForceOldSolver, false};

    check(R"(
type function foo(x)
    tbl = types.newtable(null, null, null)
    tbl:setproperty(types.singleton("boolean"), x)
    tbl:setproperty(types.singleton("number"), types.number)
    return tbl
end

function test(a: foo<string>)
    return a.@1
end
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("boolean"), 1);
    CHECK_EQ(ac.entryMap.count("number"), 1);
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "type_function_string_singleton_union")
{
    // Type functions are only handled in the new solver
    ScopedFastFlag newSolver{FFlag::DebugLuauForceOldSolver, false};

    check(R"(
type function test(ty: type)
    return types.unionof(types.singleton("test"), types.singleton("test2"))
end

const a: test<number> = "@1"
)");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.context, AutocompleteContext::String);
    CHECK_EQ(ac.entryMap.count("test"), 1);
    CHECK_EQ(ac.entryMap.count("test2"), 1);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_for_assignment")
{
    check(R"(
        function foobar(tbl: { tag: "left" | "right" })
            tbl.tag = "@1"
        end
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("left"), 1);
    CHECK_EQ(ac.entryMap.count("right"), 1);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_in_local_table")
{
    check(R"(
        type Entry = { field: number, prop: string }
        const x : {Entry} = {}
        x[1] = {
           f@1,
           p@2,
        }

        const t : { key1: boolean, thing2: CFrame, aaa3: vector } = {
            k@3,
            th@4,
        }
    )");

    auto ac1 = autocomplete('1');
    CHECK_EQ(ac1.entryMap.count("field"), 1);
    auto ac2 = autocomplete('2');
    CHECK_EQ(ac2.entryMap.count("prop"), 1);
    auto ac3 = autocomplete('3');
    CHECK_EQ(ac3.entryMap.count("key1"), 1);
    auto ac4 = autocomplete('4');
    CHECK_EQ(ac4.entryMap.count("thing2"), 1);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_in_type_assertion")
{
    check(R"(
        type Entry = { field: number, prop: string }
        return ( { f@1, p@2 } as Entry )
    )");

    auto ac1 = autocomplete('1');
    CHECK_EQ(ac1.entryMap.count("field"), 1);
    auto ac2 = autocomplete('2');
    CHECK_EQ(ac2.entryMap.count("prop"), 1);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_implicit_named_index_index_expr")
{
    // Somewhat surprisingly, the old solver didn't cover this case.
    ScopedFastFlag sff{FFlag::DebugLuauForceOldSolver, false};

    check(R"(
        type Constraint = "A" | "B" | "C"
        const foo : { [Constraint]: string } = {
            A = "Value for A",
            B = "Value for B",
            C = "Value for C",
        }
        foo["@1"]
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("A"), 1);
    CHECK_EQ(ac.entryMap["A"].kind, AutocompleteEntryKind::String);
    CHECK_EQ(ac.entryMap.count("B"), 1);
    CHECK_EQ(ac.entryMap["B"].kind, AutocompleteEntryKind::String);
    CHECK_EQ(ac.entryMap.count("C"), 1);
    CHECK_EQ(ac.entryMap["C"].kind, AutocompleteEntryKind::String);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_implicit_named_index_index_expr_without_annotation")
{
    ScopedFastFlag sffs{FFlag::DebugLuauForceOldSolver, false};

    check(R"(
        foo = {
            ["Item/Foo"] = 42,
            ["Item/Bar"] = "it's true",
            ["Item/Baz"] = true,
        }
        foo["@1"]
    )");

    auto ac = autocomplete('1');

    auto checkEntry = [&](auto key, auto type)
    {
        REQUIRE_EQ(ac.entryMap.count(key), 1);
        auto entry = ac.entryMap.at(key);
        CHECK_EQ(entry.kind, AutocompleteEntryKind::Property);
        REQUIRE(entry.type);
        CHECK_EQ(type, toString(*entry.type));
    };

    checkEntry("Item/Foo", "number");
    checkEntry("Item/Bar", "string");
    checkEntry("Item/Baz", "boolean");
}

TEST_CASE_FIXTURE(ACFixture, "bidirectional_autocomplete_in_function_call")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    check(R"(
        function take(_: { choice: "left" | "right" }) end

        take({ choice = "@1" })
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("left"), 1);
    CHECK_EQ(ac.entryMap.count("right"), 1);
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "autocomplete_via_bidirectional_self")
{
    ScopedFastFlag sff{FFlag::DebugLuauForceOldSolver, false};

    check(R"(
        type IAccount = {
            __index: IAccount,
            new : (string, number) -> Account,
            report: (self: Account) -> (),
        }

        export type Account = setmetatable<{
            name: string,
            balance: number
        }, IAccount>;

        Account = {} as IAccount
        Account.__index = Account

        function Account.new(name, balance): Account
            self = {}
            self.name = name
            self.balance = balance
            return setmetatable(self, Account)
        end

        function Account:report()
            print("My balance is: " .. self.@1)
        end
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("name"), 1);
    CHECK_EQ(ac.entryMap.count("balance"), 1);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_include_break_continue_in_loop")
{
    check(R"(for x in y do
        @1
        if true then
            @2
        end
    end)");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("break") > 0);
    CHECK(ac.entryMap.count("continue") > 0);

    ac = autocomplete('2');

    CHECK(ac.entryMap.count("break") > 0);
    CHECK(ac.entryMap.count("continue") > 0);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_exclude_break_continue_outside_loop")
{
    check(R"(@1if true then
        @2
    end)");

    auto ac = autocomplete('1');

    CHECK_EQ(ac.entryMap.count("break"), 0);
    CHECK_EQ(ac.entryMap.count("continue"), 0);

    ac = autocomplete('2');
    CHECK_EQ(ac.entryMap.count("break"), 0);
    CHECK_EQ(ac.entryMap.count("continue"), 0);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_exclude_break_continue_function_boundary")
{
    check(R"(for i = 1, 10 do
    function helper()
        @1
    end
    end)");

    auto ac = autocomplete('1');

    CHECK_EQ(ac.entryMap.count("break"), 0);
    CHECK_EQ(ac.entryMap.count("continue"), 0);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_exclude_break_continue_in_param")
{
    check(R"(while @1 do
        end)");

    auto ac = autocomplete('1');

    CHECK_EQ(ac.entryMap.count("break"), 0);
    CHECK_EQ(ac.entryMap.count("continue"), 0);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_exclude_break_continue_incomplete_while")
{
    check("while @1");

    auto ac = autocomplete('1');

    CHECK_EQ(ac.entryMap.count("break"), 0);
    CHECK_EQ(ac.entryMap.count("continue"), 0);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_exclude_break_continue_incomplete_for")
{
    check("for @1 in @2 do");

    auto ac = autocomplete('1');

    ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("break"), 0);
    CHECK_EQ(ac.entryMap.count("continue"), 0);

    ac = autocomplete('2');
    CHECK_EQ(ac.entryMap.count("break"), 0);
    CHECK_EQ(ac.entryMap.count("continue"), 0);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_exclude_break_continue_expr_func")
{
    check(R"(while true do
        _ = function ()
        @1
        end
    end)");

    auto ac = autocomplete('1');

    CHECK_EQ(ac.entryMap.count("break"), 0);
    CHECK_EQ(ac.entryMap.count("continue"), 0);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_include_break_continue_in_repeat")
{
    check(R"(repeat
        @1
    until foo())");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("break") > 0);
    CHECK(ac.entryMap.count("continue") > 0);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_include_break_continue_in_nests")
{
    check(R"(while ((function ()
        while true do
            @1
        end
        end)()) do
    end)");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("break") > 0);
    CHECK(ac.entryMap.count("continue") > 0);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_exclude_break_continue_in_incomplete_loop")
{
    check(R"(while foo() do
        @1)");

    auto ac = autocomplete('1');

    // We'd like to include break/continue here but the incomplete loop ends immediately.
    CHECK_EQ(ac.entryMap.count("break"), 0);
    CHECK_EQ(ac.entryMap.count("continue"), 0);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_suggest_hot_comments")
{
    check("--!@1");

    auto ac = autocomplete('1');

    CHECK(!ac.entryMap.empty());
    CHECK(ac.entryMap.count("strict"));
    CHECK(ac.entryMap.count("nonstrict"));
    CHECK(ac.entryMap.count("nocheck"));
    CHECK(ac.entryMap.count("native"));
    CHECK(ac.entryMap.count("nolint"));
    CHECK(ac.entryMap.count("optimize"));
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_method_in_unfinished_repeat_body_eof")
{
    check(R"(t = {}
        function t:Foo() end
        repeat
        t:@1)");

    auto ac = autocomplete('1');

    CHECK(!ac.entryMap.empty());
    CHECK(ac.entryMap.count("Foo"));
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_method_in_unfinished_repeat_body_not_eof")
{
    check(R"(t = {}
        function t:Foo() end
        repeat
        t:@1
        )");

    auto ac = autocomplete('1');

    CHECK(!ac.entryMap.empty());
    CHECK(ac.entryMap.count("Foo"));
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_method_in_unfinished_while_body")
{
    check(R"(t = {}
        function t:Foo() end
        while true do
        t:@1)");

    auto ac = autocomplete('1');

    CHECK(!ac.entryMap.empty());
    CHECK(ac.entryMap.count("Foo"));
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "autocomplete_empty_attribute")
{
    check(R"(
        \@@1
        function foo() return 42 end
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("deprecated"), 1);
    CHECK_EQ(ac.entryMap.count("checked"), 1);
    CHECK_EQ(ac.entryMap.count("native"), 1);
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "autocomplete_deprecated_attribute")
{
    check(R"(
        \@dep@1
        function foo() return 42 end
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("deprecated"), 1);
    CHECK_EQ(ac.entryMap.count("checked"), 1);
    CHECK_EQ(ac.entryMap.count("native"), 1);
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "autocomplete_empty_braced_attribute")
{
    check(R"(
        \@[@1]
        function foo() return 42 end
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("deprecated"), 1);
    CHECK_EQ(ac.entryMap.count("checked"), 1);
    CHECK_EQ(ac.entryMap.count("native"), 1);
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "autocomplete_deprecated_braced_attribute")
{
    check(R"(
        \@[dep@1]
        function foo() return 42 end
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("deprecated"), 1);
    CHECK_EQ(ac.entryMap.count("checked"), 1);
    CHECK_EQ(ac.entryMap.count("native"), 1);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_using_indexer_with_singleton_keys")
{
    check(R"(
        type List = "Val1" | "Val2" | "Val3"
        const Table: { [List]: boolean }
        _ = Table.@1
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("Val1"), 1);
    CHECK_EQ(ac.entryMap.count("Val2"), 1);
    CHECK_EQ(ac.entryMap.count("Val3"), 1);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_deprecated_on_function")
{
    ScopedFastFlag _{FFlag::LuauCheckTypeForDeprecated, true};
    check(R"(
        \@deprecated
        function foo()
        end

        @1
    )");

    auto ac = autocomplete('1');
    REQUIRE_EQ(ac.entryMap.count("foo"), 1);

    auto entry = ac.entryMap["foo"];
    CHECK(entry.deprecated);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_deprecated_on_local_function")
{
    ScopedFastFlag _{FFlag::LuauCheckTypeForDeprecated, true};
    check(R"(
        \@deprecated
        function foo()
        end

        @1
    )");

    auto ac = autocomplete('1');
    REQUIRE_EQ(ac.entryMap.count("foo"), 1);

    auto entry = ac.entryMap["foo"];
    CHECK(entry.deprecated);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_deprecated_on_anonymous_function")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauCheckTypeForDeprecated, true}, {FFlag::LuauDeprecatedAttributeOnAnonymousFunctions, true}};

    check(R"(
        const foo = \@deprecated function()
        end

        @1
    )");

    auto ac = autocomplete('1');
    REQUIRE_EQ(ac.entryMap.count("foo"), 1);

    auto entry = ac.entryMap["foo"];
    CHECK(entry.deprecated);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_deprecated_on_function_in_table")
{
    ScopedFastFlag _{FFlag::LuauCheckTypeForDeprecated, true};
    check(R"(
        t = {}

        \@deprecated
        function t.foo()
        end

        t.@1
    )");

    auto ac = autocomplete('1');
    REQUIRE_EQ(ac.entryMap.count("foo"), 1);

    auto entry = ac.entryMap["foo"];
    CHECK(entry.deprecated);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_deprecated_on_global_function")
{
    ScopedFastFlag _{FFlag::LuauCheckTypeForDeprecated, true};

    loadDefinition(R"(
        @deprecated
        declare function foo(): ()
    )");

    check(R"(
        @1
    )");

    auto ac = autocomplete('1');
    REQUIRE_EQ(ac.entryMap.count("foo"), 1);

    auto entry = ac.entryMap["foo"];
    CHECK(entry.deprecated);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_deprecated_on_extern_member_function")
{
    ScopedFastFlag _{FFlag::LuauCheckTypeForDeprecated, true};

    loadDefinition(R"(
        declare extern type MyClass with
            @deprecated
            function foo(self): ()
        end
    )");

    check(R"(
        const x: MyClass
        x.@1
    )");

    auto ac = autocomplete('1');
    REQUIRE_EQ(ac.entryMap.count("foo"), 1);

    auto entry = ac.entryMap["foo"];
    CHECK(entry.deprecated);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_deprecated_on_overloaded_extern_member_function")
{
    ScopedFastFlag _{FFlag::LuauCheckTypeForDeprecated, true};

    loadDefinition(R"(
        declare extern type MyClass with
            @deprecated
            function foo(self, val: string): ()
            @deprecated
            function foo(self, val: number): ()
        end
    )");

    check(R"(
        const x: MyClass
        x.@1
    )");

    auto ac = autocomplete('1');
    REQUIRE_EQ(ac.entryMap.count("foo"), 1);

    auto entry = ac.entryMap["foo"];
    CHECK(entry.deprecated);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_not_deprecated_on_overloaded_extern_member_function")
{
    ScopedFastFlag _{FFlag::LuauCheckTypeForDeprecated, true};

    loadDefinition(R"(
        declare extern type MyClass with
            function foo(self, val: string): ()
            @deprecated
            function foo(self, val: number): ()
        end
    )");

    check(R"(
        const x: MyClass
        x.@1
    )");

    auto ac = autocomplete('1');
    REQUIRE_EQ(ac.entryMap.count("foo"), 1);

    auto entry = ac.entryMap["foo"];
    CHECK_FALSE(entry.deprecated);
}

TEST_CASE_FIXTURE(ACFixture, "we_know_the_fields_of_a_class_instance")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::DebugLuauUserDefinedClasses, true},
    };

    check(R"(
        class Point2d
            public x: number
            public y: number
        end

        p = Point2d.new { x=3, y=4 }

        q = p.@1
    )");

    auto ac = autocomplete('1');
    CHECK(1 == ac.entryMap.count("x"));
    CHECK(1 == ac.entryMap.count("y"));
    CHECK(0 == ac.entryMap.count("z"));
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_using_function_with_singleton_arg")
{
    check(R"(
        function foo(...: "Val1") end
        foo(@1)
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("\"Val1\""), 1);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_using_function_with_singleton_union_arg")
{
    check(R"(
        function foo(...: "Val1" | "Val2") end
        foo(@1)
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("\"Val1\""), 1);
    CHECK_EQ(ac.entryMap.count("\"Val2\""), 1);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_using_function_with_singleton_intersection_arg")
{
    check(R"(
        function foo(_: "Val1"&"Val1") end
        foo(@1)
    )");

    auto ac = autocomplete('1');
    CHECK_EQ(ac.entryMap.count("\"Val1\""), 1);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_string_singleton_intersection_variable")
{
    check(R"(
        const _: "cat"&"cat" = "@1"
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("cat"));
    CHECK_EQ(ac.context, AutocompleteContext::String);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_string_singleton_intersection_multiple")
{
    check(R"(
        function C(_: "Example"&"Example") end
        C("@1")
        C(@2)
        const x: "Example"&"Example" = "@3"
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("Example"));
    CHECK_EQ(ac.context, AutocompleteContext::String);

    ac = autocomplete('2');
    CHECK(ac.entryMap.count("\"Example\""));
    CHECK_EQ(ac.context, AutocompleteContext::Expression);

    ac = autocomplete('3');
    CHECK(ac.entryMap.count("Example"));
    CHECK_EQ(ac.context, AutocompleteContext::String);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_string_singletons_in_intersection")
{
    ScopedFastFlag sff = {FFlag::DebugLuauForceOldSolver, false};

    check(R"(
        const _: "foo"&"baz" = "@1"
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("foo"));
    CHECK(ac.entryMap.count("baz"));
    CHECK_EQ(ac.context, AutocompleteContext::String);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_string_singleton_disjoint_intersection_arg")
{
    ScopedFastFlag sff = {FFlag::DebugLuauForceOldSolver, false};

    check(R"(
        function f(_: "foo"&"baz") end
        f("@1")
        f(@2)
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("foo"));
    CHECK(ac.entryMap.count("baz"));
    CHECK_EQ(ac.context, AutocompleteContext::String);

    ac = autocomplete('2');
    CHECK(ac.entryMap.count("\"foo\""));
    CHECK(ac.entryMap.count("\"baz\""));
    CHECK_EQ(ac.context, AutocompleteContext::Expression);
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "autocomplete_string_singleton_keyof_intersection")
{
    ScopedFastFlag sff = {FFlag::DebugLuauForceOldSolver, false};

    check(R"(
        foo = {
            Element1 = "Value1",
            Element2 = "Value2",
        }
        function bar<T>(key: keyof<typeof(foo)>&T) end
        bar("@1")
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("Element1") > 0);
    CHECK(ac.entryMap.count("Element2") > 0);
    CHECK_EQ(ac.context, AutocompleteContext::String);
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "autocomplete_metatable_fill_writeonly_prop_no_crash")
{
    // Due to how memory is allocated and cleaned up on the stack in noopt builds, this will not crash on certain platforms.
    // This can crash in optimized builds, but the test is mostly here to exercise that the branch in question gets hit
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
    };
    check(R"(

t0 = { thing = 5 }

type function evil(x)
    tbl = types.newtable(null, null, null)
    tbl:setwriteproperty(types.singleton("__index"), types.any)
    return tbl
end

type BadMTType = evil<{ thing : number}>
function foo(t : BadMTType)
        t2 = setmetatable({}, t)
        return t2
end

x = foo(null as any)
x.@1
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.empty());
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "autocomplete_props_through_metatable_typed_metatable")
{
    ScopedFastFlag sff{FFlag::LuauAutocompleteMetatableInheritance, true};

    check(R"(
        Base = { baseProp = 5 }
        Meta = setmetatable({ __index = Base }, {})
        obj = setmetatable({}, Meta)
        obj.@1
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("baseProp"));
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "autocomplete_table_insert")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    check(R"(
        function addToTable(t: {{ foobar: number }})
            table.insert(t, { f@1 })
        end
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("foobar") > 0);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_react")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    check(R"(
        type React_Node = any
        type ReactElement<P, T> = any

        type React_StatelessFunctionalComponent<Props> = (props: Props, context: any) -> React_Node
        type React_Component<Props, State = null> = {}
        type createElementFn = <P, T>(
            type_:
              | React_StatelessFunctionalComponent<P>
              | React_Component<P>
              | string,
            props: P?,
            ...(React_Node | (...any) -> React_Node)
        ) -> ReactElement<P, T>

        const createElement: createElementFn = null as any

        function MyComponent(props: { foobar: string, barbaz: { bazquxx: string } })
        	return null
        end

        createElement(MyComponent, { f@1 })
        createElement(MyComponent, { barbaz = { b@2 } })
        createElement(MyComponent, { foobar = {}, b@3 })
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("foobar") > 0);

    ac = autocomplete('2');
    CHECK(ac.entryMap.count("bazquxx") > 0);

    ac = autocomplete('3');
    CHECK(ac.entryMap.count("barbaz") > 0);
}

TEST_CASE_FIXTURE(ACBuiltinsFixture, "cli_197197_autocomplete_generic_keyof")
{
    ScopedFastFlag _{FFlag::DebugLuauForceOldSolver, false};

    check(R"(
        function ToggleButton<T>(Table: T, Key: keyof<T>)
            -- don't need to do anything here.
        end

        const tbl: { Changed: bool, RemoveTag: bool } = null as any

        ToggleButton(tbl, "@1")
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("Changed") > 0);
    CHECK(ac.entryMap.count("RemoveTag") > 0);
}

TEST_CASE_FIXTURE(ACFixture, "ac_static_method_autocomplete")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::DebugLuauUserDefinedClasses, true},
    };

    check(R"(
        class Bar
            public value: number
            function new()
                return Bar { value = 0 }
            end
        end

        Bar.@1
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("new") > 0);
}

TEST_CASE_FIXTURE(ACFixture, "class_autocomplete_classname_inside_method")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::DebugLuauUserDefinedClasses, true},
    };

    check(R"(
        class Bar
            function new()
                return Bar {}
            end
            function hmm(self)
                self:h@2
            end
        end

        class Bar
            function make()
                return Bar {}
            end
            function huh(self)
                self:h@3
            end
        end

        Bar.@1
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("new") > 0);
    CHECK(ac.entryMap.count("make") == 0);

    ac = autocomplete('2');
    CHECK(ac.entryMap.count("hmm") > 0);
    CHECK(ac.entryMap.count("huh") == 0);

    ac = autocomplete('3');

    // FIXME CLI-204201: It would be a nice-to-have if autocomplete inside
    // erroneous classes still worked as expected.
    CHECK(ac.entryMap.count("huh") == 0);
    CHECK(ac.entryMap.count("hmm") == 0);
}

TEST_CASE_FIXTURE(ACFixture, "class_autocomplete_classname_inside_method")
{
    ScopedFastFlag sffs[] = {
        {FFlag::DebugLuauForceOldSolver, false},
        {FFlag::DebugLuauUserDefinedClasses, true},
    };

    check(R"(
        class Bar
            public value: number
            function new()
                return B@1
            end
        end
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("Bar"));
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_on_nonexistent_table")
{
    check(R"(
        mygame = {}

        char = (null as any) as {
            Humanoid: {
                Animator: number
            }
        } & typeof(mygame.interesting)

        char.Humanoid.@1
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("Animator"));
}

TEST_CASE_FIXTURE(ACFixture, "type_correct_suggestion_with_explicit_type_args_on_method_call")
{
    ScopedFastFlag sff{FFlag::LuauUseExplicitTypeArgsInGenerics, true};

    check(R"(
const ModuleTable = {}
function ModuleTable:GenericFunctionInsideATable<T>(value: T): T
    return value
end

const myString = "hello"
const myNumber = 42
ModuleTable:GenericFunctionInsideATable<<string>>(@1)
    )");

    auto ac = autocomplete('1');

    CHECK(ac.entryMap.count("myString"));
    CHECK(ac.entryMap["myString"].typeCorrect == TypeCorrectKind::Correct);
    CHECK(ac.entryMap["myNumber"].typeCorrect == TypeCorrectKind::None);
}

TEST_CASE_FIXTURE(ACFixture, "autocomplete_deprecated_on_recursive_intersection")
{
    std::ignore = check(R"(
        export type T = {
            prop: number
        }
        function make(): MakeT
            return null as any
        end

        type MakeT = typeof(make()) & T

        const var: MakeT = null as any

        @1
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("var"));
}

TEST_CASE_FIXTURE(ACFixture, "if_local_binding_is_in_scope_in_then_body")
{
    ScopedFastFlag sffs[] = {{FFlag::DebugLuauForceOldSolver, false}, {FFlag::DebugLuauIfLocalSyntax, true}, {FFlag::DebugLuauIfLocalAnalysis, true}};

    check(R"(
        t = {}
        if const x = t then
            @1
        end
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("x"));
}

TEST_CASE_FIXTURE(ACFixture, "if_local_binding_offers_member_completion")
{
    ScopedFastFlag sffs[] = {{FFlag::DebugLuauForceOldSolver, false}, {FFlag::DebugLuauIfLocalSyntax, true}, {FFlag::DebugLuauIfLocalAnalysis, true}};

    check(R"(
        t = {foo = 1, bar = 2}
        if const x = t then
            x.@1
        end
    )");

    auto ac = autocomplete('1');
    CHECK(ac.entryMap.count("foo"));
    CHECK(ac.entryMap.count("bar"));
}

TEST_SUITE_END();
