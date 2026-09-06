// This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
#include "Luau/Common.h"
#include "Luau/Parser.h"
#include "Luau/PrettyPrinter.h"

#include "Fixture.h"
#include "ScopedFlags.h"

#include "doctest.h"

LUAU_FASTFLAG(LuauExportValueSyntax)
LUAU_FASTFLAG(DebugLuauNoInline)
LUAU_FASTFLAG(DebugLuauUserDefinedClasses)
LUAU_FASTFLAG(LuauPrettyPrintVisualizeIndexerAccess)

using namespace Luau;

TEST_SUITE_BEGIN("PrettyPrinterTests");

TEST_CASE("test_1")
{
    const std::string example = R"(
function isPortal(element)
    if type(element)!='table'then
        return false
    end

    return element.component == Core.Portal
end
)";

    CHECK_EQ(example, prettyPrint(example).code);
}

TEST_CASE("prettyPrint_AstStatBlock_overload")
{
    const std::string code = "a = 1";
    ParseOptions options;
    Allocator allocator;
    AstNameTable names(allocator);
    ParseResult result = Parser::parse(code.c_str(), code.size(), names, allocator, options);
    REQUIRE(result.root != nullptr);

    std::string printed = prettyPrint(*result.root);
    CHECK_EQ("a = 1", printed);
}

TEST_CASE("string_literals")
{
    const std::string code = R"( S='abcdef\n\f\a\020' )";

    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("string_literals_containing_utf8")
{
    const std::string code = R"( S='lalala こんにちは' )"; // Konichiwa!
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("if_stmt_spaces_around_tokens")
{
    const std::string one = R"( if     This then Once() end)";
    CHECK_EQ(one, prettyPrint(one).code);

    const std::string two = R"( if This     then Once() end)";
    CHECK_EQ(two, prettyPrint(two).code);

    const std::string three = R"( if This then     Once() end)";
    CHECK_EQ(three, prettyPrint(three).code);

    const std::string four = R"( if This then Once()     end)";
    CHECK_EQ(four, prettyPrint(four).code);

    const std::string five = R"( if This then Once()   else Other() end)";
    CHECK_EQ(five, prettyPrint(five).code);

    const std::string six = R"( if This then Once() else    Other() end)";
    CHECK_EQ(six, prettyPrint(six).code);

    const std::string seven = R"( if This then Once()    else if true then Other() end)";
    CHECK_EQ(seven, prettyPrint(seven).code);

    const std::string eight = R"( if This then Once() else if     true then Other() end)";
    CHECK_EQ(eight, prettyPrint(eight).code);

    const std::string nine = R"( if This then Once() else if true    then Other() end)";
    CHECK_EQ(nine, prettyPrint(nine).code);
}

TEST_CASE("optional_then_and_do_after_newline")
{
    const std::string code = R"(if true
    print("if")
end
while true
    break
end
for i = 1, 2
    print(i)
end
for k, v in pairs({})
    print(k, v)
end)";

    CHECK_EQ(code, prettyPrint(code).code);

    Fixture fixture;
    AstStatBlock* block = fixture.parse(code);
    REQUIRE(block != nullptr);
    const std::string printed = prettyPrint(*block);
    CHECK_EQ(printed.find(" then"), std::string::npos);
    CHECK_EQ(printed.find(" do"), std::string::npos);
}

TEST_CASE("elseif_chains_indent_sensibly")
{
    const std::string code = R"(
        if This then
            Once()
        else if That then
            Another()
        else if SecondLast then
            Third()
        else
            IfAllElseFails()
        end
    )";

    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("strips_type_annotations")
{
    const std::string code = R"( const s: string= 'hello there' )";
    const std::string expected = R"( const s        = 'hello there' )";
    CHECK_EQ(expected, prettyPrint(code).code);
}

TEST_CASE("strips_type_assertion_expressions")
{
    const std::string code = R"( s= some_function() as any+ something_else() as number )";
    const std::string expected = R"( s= some_function()       + something_else()           )";
    CHECK_EQ(expected, prettyPrint(code).code);
}

TEST_CASE("function_taking_ellipsis")
{
    const std::string code = R"( function F(...) end )";

    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("omit_decimal_place_for_integers")
{
    const std::string code = R"( a=5, 6, 7, 3.141, 1.1290000000000002e+45 )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("for_loop")
{
    const std::string one = R"( for i=1,10 do end )";
    CHECK_EQ(one, prettyPrint(one).code);

    const std::string code = R"( for i=5,6,7 do end )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("for_loop_spaces_around_tokens")
{
    const std::string one = R"( for index = 1, 10 do call(index) end )";
    CHECK_EQ(one, prettyPrint(one).code);

    const std::string two = R"( for index = 1  , 10 do call(index) end )";
    CHECK_EQ(two, prettyPrint(two).code);

    const std::string three = R"( for index = 1, 10  ,  3 do call(index) end )";
    CHECK_EQ(three, prettyPrint(three).code);

    const std::string four = R"( for index = 1, 10    do call(index) end )";
    CHECK_EQ(four, prettyPrint(four).code);

    const std::string five = R"( for index = 1, 10 do call(index)    end )";
    CHECK_EQ(five, prettyPrint(five).code);
}

TEST_CASE("for_in_loop")
{
    const std::string code = R"( for k, v in ipairs(x)do end )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("for_in_loop_spaces_around_tokens")
{
    const std::string one = R"( for k, v in ipairs(x)   do end )";
    CHECK_EQ(one, prettyPrint(one).code);

    const std::string two = R"( for k, v    in    ipairs(x) do end )";
    CHECK_EQ(two, prettyPrint(two).code);

    const std::string three = R"( for k  ,  v in ipairs(x) do end )";
    CHECK_EQ(three, prettyPrint(three).code);

    const std::string four = R"( for k, v in next  , t  do end )";
    CHECK_EQ(four, prettyPrint(four).code);

    const std::string five = R"( for k, v in ipairs(x) do   end )";
    CHECK_EQ(five, prettyPrint(five).code);
}

TEST_CASE("for_in_single_variable")
{
    const std::string one = R"( for key in pairs(x) do end )";
    CHECK_EQ(one, prettyPrint(one).code);
}

TEST_CASE("while_loop")
{
    const std::string code = R"( while f(x)do print() end )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("while_loop_spaces_around_tokens")
{
    const std::string one = R"( while     f(x) do print() end )";
    CHECK_EQ(one, prettyPrint(one).code);

    const std::string two = R"( while f(x)    do print() end )";
    CHECK_EQ(two, prettyPrint(two).code);

    const std::string three = R"( while f(x) do    print() end )";
    CHECK_EQ(three, prettyPrint(three).code);

    const std::string four = R"( while f(x) do print()    end )";
    CHECK_EQ(four, prettyPrint(four).code);
}

TEST_CASE("repeat_until_loop")
{
    const std::string code = R"( repeat print() until f(x) )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("repeat_until_loop_condition_on_new_line")
{
    const std::string code = R"(
    repeat
        print()
    until
        f(x) )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("lambda")
{
    const std::string one = R"( p=function(o, m, g) return 77 end )";
    CHECK_EQ(one, prettyPrint(one).code);

    const std::string two = R"( p=function(o, m, g,...)  return 77 end )";
    CHECK_EQ(two, prettyPrint(two).code);
}

TEST_CASE("local_assignment")
{
    const std::string one = R"( x = 1 )";
    CHECK_EQ(one, prettyPrint(one).code);

    const std::string two = R"( x, y, z = 1, 2, 3 )";
    CHECK_EQ(two, prettyPrint(two).code);

    const std::string three = R"( x  = nil)";
    CHECK_EQ(three, prettyPrint(three).code);
}

TEST_CASE("local_assignment_spaces_around_tokens")
{
    const std::string one = R"( x = 1 )";
    CHECK_EQ(one, prettyPrint(one).code);

    const std::string two = R"( x    = 1 )";
    CHECK_EQ(two, prettyPrint(two).code);

    const std::string three = R"( x =    1 )";
    CHECK_EQ(three, prettyPrint(three).code);

    const std::string four = R"( x   , y = 1, 2 )";
    CHECK_EQ(four, prettyPrint(four).code);

    const std::string five = R"( x,    y = 1, 2 )";
    CHECK_EQ(five, prettyPrint(five).code);

    const std::string six = R"( x, y = 1   , 2 )";
    CHECK_EQ(six, prettyPrint(six).code);

    const std::string seven = R"( x, y = 1,    2 )";
    CHECK_EQ(seven, prettyPrint(seven).code);
}

TEST_CASE("local_function")
{
    const std::string one = R"( function p(o, m, g) return 77 end )";
    CHECK_EQ(one, prettyPrint(one).code);

    const std::string two = R"( function p(o, m, g,...)  return 77 end )";
    CHECK_EQ(two, prettyPrint(two).code);
}

TEST_CASE("local_function_spaces_around_tokens")
{
    const std::string one = R"( function p(o, m, ...) end )";
    CHECK_EQ(one, prettyPrint(one).code);

    const std::string two = R"( function    p(o, m, ...) end )";
    CHECK_EQ(two, prettyPrint(two).code);
}

TEST_CASE("function")
{
    const std::string one = R"( function p(o, m, g) return 77 end )";
    CHECK_EQ(one, prettyPrint(one).code);

    const std::string two = R"( function p(o, m, g,...)  return 77 end )";
    CHECK_EQ(two, prettyPrint(two).code);
}

TEST_CASE("function_spaces_around_tokens")
{
    const std::string two = R"( function     p(o, m, ...) end )";
    CHECK_EQ(two, prettyPrint(two).code);

    const std::string three = R"( function p(   o, m, ...) end )";
    CHECK_EQ(three, prettyPrint(three).code);

    const std::string four = R"( function p(o   , m, ...) end )";
    CHECK_EQ(four, prettyPrint(four).code);

    const std::string five = R"( function p(o,   m, ...) end )";
    CHECK_EQ(five, prettyPrint(five).code);

    const std::string six = R"( function p(o, m   , ...) end )";
    CHECK_EQ(six, prettyPrint(six).code);

    const std::string seven = R"( function p(o, m,   ...) end )";
    CHECK_EQ(seven, prettyPrint(seven).code);

    const std::string eight = R"( function p(o, m, ...   ) end )";
    CHECK_EQ(eight, prettyPrint(eight).code);

    const std::string nine = R"( function p(o, m, ...)   end )";
    CHECK_EQ(nine, prettyPrint(nine).code);
}

TEST_CASE("function_with_types_spaces_around_tokens")
{
    std::string code = R"( function p<X, Y, Z...>(o: string, m: number, ...: any): string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( function p   <X, Y, Z...>(o: string, m: number, ...: any): string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( function p<X   , Y, Z...>(o: string, m: number, ...: any): string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( function p<X,   Y, Z...>(o: string, m: number, ...: any): string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( function p<X, Y,   Z...>(o: string, m: number, ...: any): string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( function p<X, Y, Z  ...>(o: string, m: number, ...: any): string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( function p<X, Y, Z...  >(o: string, m: number, ...: any): string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( function p<X, Y, Z...>  (o: string, m: number, ...: any): string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( function p<X, Y, Z...>(o  : string, m: number, ...: any): string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( function p<X, Y, Z...>(o:   string, m: number, ...: any): string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( function p<X, Y, Z...>(o: string  , m: number, ...: any): string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( function p<X, Y, Z...>(o: string,   m: number, ...: any): string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( function p<X, Y, Z...>(o: string, m: number,   ...: any): string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( function p<X, Y, Z...>(o: string, m: number, ...  : any): string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( function p<X, Y, Z...>(o: string, m: number, ...:   any): string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( function p<X, Y, Z...>(o: string, m: number, ...: any  ): string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( function p<X, Y, Z...>(o: string, m: number, ...: any)   :string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( function p<X, Y, Z...>(o: string, m: number, ...: any):    string end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("returns_spaces_around_tokens")
{
    const std::string one = R"( return    1 )";
    CHECK_EQ(one, prettyPrint(one).code);

    const std::string two = R"( return 1   , 2 )";
    CHECK_EQ(two, prettyPrint(two).code);

    const std::string three = R"( return 1,  2 )";
    CHECK_EQ(three, prettyPrint(three).code);
}

TEST_CASE_FIXTURE(Fixture, "type_alias_spaces_around_tokens")
{
    std::string code = R"( type Foo = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type    Foo = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo    = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo =    string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( export type Foo = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( export    type Foo = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo<X, Y, Z...> = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo  <X, Y, Z...> = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo<  X, Y, Z...> = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo<X  , Y, Z...> = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo<X,   Y, Z...> = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo<X, Y  , Z...> = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo<X, Y,   Z...> = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo<X, Y, Z  ...> = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo<X, Y, Z...  > = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "type_alias_with_defaults_spaces_around_tokens")
{
    std::string code = R"( type Foo<X = string, Z... = ...any> = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo<X   = string, Z... = ...any> = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo<X =   string, Z... = ...any> = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo<X = string, Z...   = ...any> = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo<X = string, Z... =   ...any> = string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("table_literals")
{
    const std::string code = R"( t={1, 2, 3, foo='bar', baz=99,[5.5]='five point five', 'end'} )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("more_table_literals")
{
    const std::string code = R"( t={['Content-Type']='text/plain'} )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("table_literal_preserves_record_vs_general")
{
    const std::string code = R"( t={['foo']='bar',quux=42} )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("table_literal_with_numeric_key")
{
    const std::string code = R"( t={[5]='five',[6]='six'} )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("table_literal_with_keyword_key")
{
    const std::string code = R"( t={['nil']=nil,['true']=true} )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("table_literal_closing_brace_at_correct_position")
{
    const std::string code = R"(
        t={
            eggs='Tasty',
            avocado='more like awesomecavo amirite'
        }
    )";

    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("table_literal_with_semicolon_separators")
{
    const std::string code = R"(
        t = { x = 1; y = 2 }
    )";

    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("table_literal_with_trailing_separators")
{
    const std::string code = R"(
        t = { x = 1, y = 2, }
    )";

    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("table_literal_with_spaces_around_separator")
{
    const std::string code = R"(
        t = { x = 1  , y = 2 }
    )";

    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("table_literal_with_spaces_around_equals")
{
    const std::string code = R"(
        t = { x    =   1  }
    )";

    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("table_literal_multiline_with_indexers")
{
    const std::string code = R"(
        t = {
            ["my first value"] = "x";
            ["my second value"] = "y";
        }
    )";

    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("method_calls")
{
    const std::string code = R"( foo.bar.baz:quux() )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("method_definitions")
{
    const std::string code = R"( function foo.bar.baz:quux() end )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("spaces_between_keywords_even_if_it_pushes_the_line_estimation_off")
{
    const std::string code = R"( if math.abs(raySlope) < .01 then return 0 end )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("numbers")
{
    const std::string code = R"( a=2510238627 )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("infinity")
{
    const std::string code = R"( a = 1e500    b = 1e400 )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("numbers_with_separators")
{
    const std::string code = R"( a = 123_456_789 )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("hexadecimal_numbers")
{
    const std::string code = R"( a = 0xFFFF )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("binary_numbers")
{
    const std::string code = R"( a = 0b0101 )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("single_quoted_strings")
{
    const std::string code = R"( a = 'hello world' )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("double_quoted_strings")
{
    const std::string code = R"( a = "hello world" )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("simple_interp_string")
{
    const std::string code = R"( a = `hello world` )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("raw_strings")
{
    const std::string code = R"( a = [[ hello world ]] )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("raw_strings_with_blocks")
{
    const std::string code = R"( a = [==[ hello world ]==] )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("escaped_strings")
{
    const std::string code = R"( s='\\b\\t\\n\\\\' )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("escaped_strings_2")
{
    const std::string code = R"( s="\a\b\f\n\r\t\v\'\"\\" )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("escaped_strings_newline")
{
    const std::string code = R"(
    print("foo \
        bar")
    )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("escaped_strings_raw")
{
    const std::string code = R"( x = [=[\v<((do|load)file|require)\s*\(?['"]\zs[^'"]+\ze['"]]=] )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("position_correctly_updated_when_writing_multiline_string")
{
    const std::string code = R"(
    call([[
        testing
    ]]) )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("need_a_space_between_number_literals_and_dots")
{
    const std::string code = R"( return point and math.ceil(point* 100000* 100)/ 100000 .. '%'or '' )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("binary_keywords")
{
    const std::string code = "c = a0 ._ or b0 ._";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("function_call_parentheses_no_args")
{
    const std::string code = R"( call() )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("function_call_parentheses_one_arg")
{
    const std::string code = R"( call(arg) )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("function_call_parentheses_multiple_args")
{
    const std::string code = R"( call(arg1, arg3, arg3) )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("function_call_parentheses_multiple_args_no_space")
{
    const std::string code = R"( call(arg1,arg3,arg3) )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("function_call_parentheses_multiple_args_space_before_commas")
{
    const std::string code = R"( call(arg1 ,arg3 ,arg3) )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("function_call_spaces_before_parentheses")
{
    const std::string code = R"( call () )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("function_call_spaces_within_parentheses")
{
    const std::string code = R"( call(  ) )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("function_call_string_double_quotes")
{
    const std::string code = R"( call "string" )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("function_call_string_single_quotes")
{
    const std::string code = R"( call 'string' )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("function_call_string_no_space")
{
    const std::string code = R"( call'string' )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("function_call_table_literal")
{
    const std::string code = R"( call { x = 1 } )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("function_call_table_literal_no_space")
{
    const std::string code = R"( call{x=1} )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("do_blocks")
{
    const std::string code = R"(
        foo()

        do
            bar=baz()
            quux()
        end

        foo2()
    )";

    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("nested_do_block")
{
    const std::string code = R"(
        do
            do
                x = 1
            end
        end
    )";

    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE("emit_a_do_block_in_cases_of_potentially_ambiguous_syntax")
{
    const std::string code = R"(
        f();
        (g or f)()
    )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE_FIXTURE(Fixture, "parentheses_multiline")
{
    std::string code = R"(
test = (
    x
)
    )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "stmt_semicolon")
{
    std::string code = R"( test = 1; )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( test = 1  ; )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "do_block_ending_with_semicolon")
{
    std::string code = R"(
        do
            return;
        end;
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "if_stmt_semicolon")
{
    std::string code = R"(
        if init then
            x = string.sub(x, utf8.offset(x, init));
        end;
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "if_stmt_semicolon_2")
{
    std::string code = R"(
        if (t < 1) then return c/2*t*t + b end;
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "for_loop_stmt_semicolon")
{
    std::string code = R"(
        for i,v in ... do
        end;
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "while_do_semicolon")
{
    std::string code = R"(
        while true do
        end;
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "function_definition_semicolon")
{
    std::string code = R"(
        function foo()
        end;
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("roundtrip_types")
{
    const std::string code = R"(
        const s:string='str'
        const t:{a:string,b:number,[string]:number}=nil
        const fn:(string,string)->(number,number)=nil
        const s2:typeof(s)='foo'
        const os:string?=nil
        const sn:string|number=nil
        const it:{x:number}&{y:number}=nil
    )";
    auto allocator = Allocator{};
    auto names = AstNameTable{allocator};

    ParseOptions options;

    ParseResult parseResult = Parser::parse(code.data(), code.size(), names, allocator, options);
    REQUIRE(parseResult.errors.empty());

    CHECK_EQ(code, prettyPrintWithTypes(*parseResult.root));
}

TEST_CASE("roundtrip_generic_types")
{
    const std::string code = R"(
        export type A<T> = {v:T, next:A<T>}
    )";
    auto allocator = Allocator{};
    auto names = AstNameTable{allocator};

    ParseOptions options;

    ParseResult parseResult = Parser::parse(code.data(), code.size(), names, allocator, options);
    REQUIRE(parseResult.errors.empty());

    CHECK_EQ(code, prettyPrintWithTypes(*parseResult.root));
}

TEST_CASE_FIXTURE(Fixture, "attach_types")
{
    const std::string code = R"(
        const s='str'
        const t={a=1,b=false}
        function fn()
            return 10
        end
    )";
    const std::string expected = R"(
        const s:string='str'
        const t:{a:number,b:boolean}={a=1,b=false}
        function fn(): number
            return 10
        end
    )";

    CHECK_EQ(expected, decorateWithTypes(code));
}

TEST_CASE_FIXTURE(Fixture, "attach_type_negate")
{
    DOES_NOT_PASS_OLD_SOLVER_GUARD();

    const std::string code = R"(
        function foo(x: unknown)
            assert(x)
            const b = x
            return b
        end
    )";
    const std::string expected = R"(
        function foo(x: unknown): negate<false?>
            assert(x)
            const b:negate<false?>=x
            return b
        end
    )";

    CHECK_EQ(expected, decorateWithTypes(code));
}

TEST_CASE("a_table_key_can_be_the_empty_string")
{
    std::string code = "T = {[''] = true}";

    CHECK_EQ(code, prettyPrint(code).code);
}

// There's a bit of login in the prettyPrintr that always adds a space before a dot if the previous symbol ends in a digit.
// This was surfacing an issue where we might not insert a space after the 'local' keyword.
TEST_CASE("always_emit_a_space_after_local_keyword")
{
    std::string code = "do aZZZZ = Workspace.P1.Shape bZZZZ = Enum.PartType.Cylinder end";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE_FIXTURE(Fixture, "types_should_not_be_considered_cyclic_if_they_are_not_recursive")
{
    std::string code = R"(
        const common: {foo:string} = {foo = 'foo'}

        const t = {}
        t.x = common
        t.y = common
    )";

    std::string expected = R"(
        const common: {foo:string} = {foo = 'foo'}

        const t:{x:{foo:string},y:{foo:string}}={}
        t.x = common
        t.y = common
    )";

    CHECK_EQ(expected, decorateWithTypes(code));
}

TEST_CASE_FIXTURE(Fixture, "type_lists_should_be_emitted_correctly")
{
    std::string code = R"(
        const a = function(a: string, b: number, ...: string): (string, ...number)
        end

        const b = function(...: string): ...number
        end

        const c = function()
        end
    )";

    std::string expected = R"(
        const a:(a:string,b:number,...string)->(string,...number)=function(a:string,b:number,...:string): (string,...number)
        end

        const b:(...string)->(...number)=function(...:string): ...number
        end

        const c:()->()=function(): ()
        end
    )";

    std::string actual = decorateWithTypes(code);

    CHECK_EQ(expected, actual);
}

TEST_CASE_FIXTURE(Fixture, "function_type_location")
{
    std::string code = R"(
        function foo(x: number): number
         return x
        end
        const g: (number)->number = foo
    )";

    std::string expected = R"(
        function foo(x: number): number
         return x
        end
        const g: (number)->(number)=foo
    )";

    std::string actual = decorateWithTypes(code);

    CHECK_EQ(expected, actual);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_type_assertion")
{
    std::string code = "a = 5 as number";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "type_assertion_spaces_around_tokens")
{
    std::string code = "a = 5   as number";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = "a = 5 as   number";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_if_then_else")
{
    std::string code = "a = if 1 then 2 else 3";

    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_if_then_else_multiple_conditions")
{
    std::string code = "a = if 1 then 2 else if 3 then 4 else 5";

    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_if_then_else_multiple_conditions_2")
{
    std::string code = R"(
        x = if yes
            then nil
            else if no
                then if this
                    then that
                    else other
                else nil
    )";

    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE_FIXTURE(Fixture, "if_then_else_spaces_around_tokens")
{
    std::string code = "a = if   1 then 2 else 3";
    CHECK_EQ(code, prettyPrint(code).code);

    code = "a = if 1   then 2 else 3";
    CHECK_EQ(code, prettyPrint(code).code);

    code = "a = if 1 then   2 else 3";
    CHECK_EQ(code, prettyPrint(code).code);

    code = "a = if 1 then 2   else 3";
    CHECK_EQ(code, prettyPrint(code).code);

    code = "a = if 1 then 2 else   3";
    CHECK_EQ(code, prettyPrint(code).code);

    code = "a = if 1 then 2   else if 3 then 4 else 5";
    CHECK_EQ(code, prettyPrint(code).code);

    code = "a = if 1 then 2 else if   3 then 4 else 5";
    CHECK_EQ(code, prettyPrint(code).code);

    code = "a = if 1 then 2 else if 3   then 4 else 5";
    CHECK_EQ(code, prettyPrint(code).code);

    code = "a = if 1 then 2 else if 3 then   4 else 5";
    CHECK_EQ(code, prettyPrint(code).code);

    code = "a = if 1 then 2 else if 3 then 4   else 5";
    CHECK_EQ(code, prettyPrint(code).code);

    code = "a = if 1 then 2 else if 3 then 4 else   5";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE_FIXTURE(Fixture, "if_then_else_spaces_between_else_if")
{
    std::string code = R"(
    return
        if a then "was a" else
        if b then "was b" else
        if c then "was c" else
        "was nothing!"
    )";
    CHECK_EQ(code, prettyPrint(code).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_type_reference_import")
{
    fileResolver.source["game/A"] = R"(
export type Type = { a: number }
return {}
    )";

    std::string code = R"(
Import = require(game.A)
const a: Import.Type = nil
    )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_type_reference_spaces_around_tokens")
{
    std::string code = R"( const _: Foo.Type = nil )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( const _: Foo   .Type = nil )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( const _: Foo.   Type = nil )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( const _: Type  <> = nil )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( const _: Type<  > = nil )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( const _: Type<  number> = nil )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( const _: Type<number  ,string> = nil )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( const _: Type<number,  string  > = nil )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_type_annotation_spaces_around_tokens")
{
    std::string code = R"( const _: Type = nil )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( const _  : Type = nil )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( const _:   Type = nil )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( const x: Type, y = nil, 1 )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( const x  : Type, y = nil, 1 )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_for_loop_annotation_spaces_around_tokens")
{
    std::string code = R"( for i: number = 1, 10 do end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( for i   : number = 1, 10 do end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( for i:    number = 1, 10 do end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( for x: number, y: number in ... do end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( for x   : number, y: number in ... do end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( for x:    number, y: number in ... do end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( for x: number, y   : number in ... do end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( for x: number, y:    number in ... do end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_type_packs")
{
    std::string code = R"(
type Packed<T...> = (T...)->(T...)
const a: Packed<> = nil
const b: Packed<(number, string)> = nil
    )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "type_packs_spaces_around_tokens")
{
    std::string code = R"( type _ = Packed<  T...> )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type _ = Packed<T  ...> )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type _ = Packed<   ...T> )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type _ = Packed<...   T> )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type _ = Packed<  ()> )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type _ = Packed<  (string, number)> )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type _ = Packed<(  string, number)> )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type _ = Packed<(string  , number)> )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type _ = Packed<(string,   number)> )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type _ = Packed<(string, number  )> )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type _ = Packed<(string, number)  > )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type _ = Packed<(  )> )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type _ = Packed<()  > )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_union_type_nested")
{
    std::string code = "const a: ((number)->(string))|((string)->(string)) = nil";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_union_type_nested_2")
{
    std::string code = "const a: (number&string)|(string&boolean) = nil";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_union_type_nested_3")
{
    std::string code = "const a: nil | (string & number) = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_intersection_type_nested")
{
    std::string code = "const a: ((number)->(string))&((string)->(string)) = nil";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_intersection_type_nested_2")
{
    std::string code = "const a: (number|string)&(string|boolean) = nil";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_intersection_type_with_function")
{
    std::string code = "type FnB<U...> = () -> U... & T";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_leading_union_pipe")
{
    std::string code = "const a: | string | number = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = "const a: | string = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_union_spaces_around_tokens")
{
    std::string code = "const a: string   | number = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = "const a: string |   number = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_leading_intersection_ampersand")
{
    std::string code = "const a: & string & number = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = "const a: & string = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_intersection_spaces_around_tokens")
{
    std::string code = "const a: string   & number = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = "const a: string &   number = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_mixed_union_intersection")
{
    std::string code = "const a: string | (Foo & Bar) = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = "const a: string |   (Foo & Bar) = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = "const a: string | (  Foo & Bar) = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = "const a: string | (Foo & Bar  ) = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = "const a: string &   (Foo | Bar) = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = "const a: string & (  Foo | Bar) = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = "const a: string & (Foo | Bar  ) = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_preserve_union_optional_style")
{
    std::string code = "const a: string | nil = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = "const a: string? = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = "const a: string??? = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = "const a: string? | nil = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = "const a: string | nil | number = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = "const a: string | nil | number? = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = "const a: string? | number? = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_varargs")
{
    std::string code = "function f(...) return ... end";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "index_name_spaces_around_tokens")
{
    std::string one = "_ = a.name";
    CHECK_EQ(one, prettyPrint(one, {}, true).code);

    std::string two = "_ = a   .name";
    CHECK_EQ(two, prettyPrint(two, {}, true).code);

    std::string three = "_ = a.   name";
    CHECK_EQ(three, prettyPrint(three, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "index_name_ends_with_digit")
{
    std::string code = "sparkles.Color = Color3.new()";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_index_expr")
{
    std::string code = "a = {1, 2, 3} b = a[2]";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "index_expr_spaces_around_tokens")
{
    std::string one = "_ = a[2]";
    CHECK_EQ(one, prettyPrint(one, {}, true).code);

    std::string two = "_ = a   [2]";
    CHECK_EQ(two, prettyPrint(two, {}, true).code);

    std::string three = "_ = a[   2]";
    CHECK_EQ(three, prettyPrint(three, {}, true).code);

    std::string four = "_ = a[2   ]";
    CHECK_EQ(four, prettyPrint(four, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_unary")
{
    std::string code = R"(
a = 1
b = -1
c = true
d = not c
e = 'hello'
d = e.count
    )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "unary_spaces_around_tokens")
{
    std::string code = R"(
_ =   -1
_ = -  1
_ =   not true
_ = not   true
_ =   e.count
_ = e  .  count
    )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "binary_spaces_around_tokens")
{
    std::string code = R"(
_ =    1+1
_ = 1   +1
_ = 1+   1
    )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_break_continue")
{
    std::string code = R"(
a, b, c = nil, nil, nil
repeat
    if a then break end
    if b then continue end
until c
    )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_compound_assignment")
{
    std::string code = R"(
a = 1
a += 2
a -= 3
a *= 4
a /= 5
a //= 5
a %= 6
a ^= 7
a ..= ' - result'
    )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "compound_assignment_spaces_around_tokens")
{
    std::string one = R"( a = 0 a   += 1 )";
    CHECK_EQ(one, prettyPrint(one, {}, true).code);

    std::string two = R"( a = 0 a +=   1 )";
    CHECK_EQ(two, prettyPrint(two, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_assign_multiple")
{
    std::string code = "a, b, c = 1, 2, 3";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_assign_spaces_around_tokens")
{
    std::string one = "a = 1";
    CHECK_EQ(one, prettyPrint(one).code);

    std::string two = "a    = 1";
    CHECK_EQ(two, prettyPrint(two).code);

    std::string three = "a =    1";
    CHECK_EQ(three, prettyPrint(three).code);

    std::string four = "a   , b = 1, 2";
    CHECK_EQ(four, prettyPrint(four).code);

    std::string five = "a,    b = 1, 2";
    CHECK_EQ(five, prettyPrint(five).code);

    std::string six = "a, b = 1   , 2";
    CHECK_EQ(six, prettyPrint(six).code);

    std::string seven = "a, b = 1,    2";
    CHECK_EQ(seven, prettyPrint(seven).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_generic_function")
{
    std::string code = R"(
function foo<T,S...>(a: T, ...: S...) return 1 end
const f: <T,S...>(T, S...)->(number) = foo
    )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_union_reverse")
{
    std::string code = "const a: nil | number = nil";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_for_in_multiple")
{
    std::string code = "for k,v in next,{}do print(k,v) end";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_error_expr")
{
    std::string code = "a = f:-";

    auto allocator = Allocator{};
    auto names = AstNameTable{allocator};
    ParseResult parseResult = Parser::parse(code.data(), code.size(), names, allocator, {});

    CHECK_EQ("a = (error-expr: f:%error-id%)-(error-expr)", prettyPrintWithTypes(*parseResult.root));
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_error_stat")
{
    std::string code = "-";

    auto allocator = Allocator{};
    auto names = AstNameTable{allocator};
    ParseResult parseResult = Parser::parse(code.data(), code.size(), names, allocator, {});

    CHECK_EQ("(error-stat: (error-expr))", prettyPrintWithTypes(*parseResult.root));
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_error_type")
{
    std::string code = "const a: ";

    auto allocator = Allocator{};
    auto names = AstNameTable{allocator};
    ParseResult parseResult = Parser::parse(code.data(), code.size(), names, allocator, {});

    CHECK_EQ("const a:%error-type%", prettyPrintWithTypes(*parseResult.root));
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_parse_error")
{
    std::string code = "a = -";

    auto result = prettyPrint(code);
    CHECK_EQ("", result.code);
    CHECK_EQ("Expected identifier when parsing expression, got <eof>", result.parseError);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_declare_global_stat")
{
    std::string code = "declare _G: any";

    ParseOptions options;
    options.allowDeclarationSyntax = true;

    auto allocator = Allocator{};
    auto names = AstNameTable{allocator};
    ParseResult parseResult = Parser::parse(code.data(), code.size(), names, allocator, options);

    auto result = prettyPrintWithTypes(*parseResult.root);

    CHECK_EQ(result, code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_to_string")
{
    std::string code = "const a: string = 'hello'";

    auto allocator = Allocator{};
    auto names = AstNameTable{allocator};
    ParseResult parseResult = Parser::parse(code.data(), code.size(), names, allocator, {});

    REQUIRE(parseResult.root);
    REQUIRE(parseResult.root->body.size == 1);
    AstStatLocal* statLocal = parseResult.root->body.data[0]->as<AstStatLocal>();
    REQUIRE(statLocal);
    CHECK_EQ("const a: string = 'hello'", toString(statLocal));
    REQUIRE(statLocal->vars.size == 1);
    AstLocal* local = statLocal->vars.data[0];
    REQUIRE(local->annotation);
    CHECK_EQ("string", toString(local->annotation));
    REQUIRE(statLocal->values.size == 1);
    AstExpr* expr = statLocal->values.data[0];
    CHECK_EQ("'hello'", toString(expr));
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_type_alias_default_type_parameters")
{
    std::string code = R"(
type Packed<T = string, U = T, V... = ...boolean, W... = (T, U, V...)> = (T, U, V...)->(W...)
const a: Packed<number> = nil
    )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_singleton_types")
{
    std::string code = R"(
type t1 = 'hello'
type t2 = true
type t3 = ''
type t4 = false
    )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_array_types")
{
    std::string code = R"(
type t1 = {number}
type t2 = {[string]: number}
    )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_for_in_multiple_types")
{
    std::string code = "for k:string,v:boolean in next,{}do end";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_string_interp")
{
    std::string code = R"( _ = `hello {name}` )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_string_interp_multiline")
{
    std::string code = R"( _ = `hello {
        name
    }!` )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_string_interp_on_new_line")
{
    std::string code = R"(
        error(
            `a {b} c`
        )
    )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_string_interp_multiline_escape")
{
    std::string code = R"( _ = `hello \
        world!` )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_string_literal_escape")
{
    std::string code = R"( _ = ` bracket = \{, backtick = \` = {'ok'} ` )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_type_functions")
{
    std::string code = R"( type function foo(arg1, arg2) if arg1 == arg2 then return arg1 end return arg2 end )";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_type_functions_spaces_around_tokens")
{
    std::string code = R"( type   function foo() end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type function   foo() end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type function foo  () end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( export   type function foo() end )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE_FIXTURE(Fixture, "prettyPrint_typeof_spaces_around_tokens")
{
    std::string code = R"( type X = typeof(x) )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type X =    typeof(x) )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type X = typeof   (x) )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type X = typeof(   x) )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type X = typeof(x   ) )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("prettyPrint_single_quoted_string_types")
{
    const std::string code = R"( type a = 'hello world' )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("prettyPrint_double_quoted_string_types")
{
    const std::string code = R"( type a = "hello world" )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("prettyPrint_raw_string_types")
{
    std::string code = R"( type a = [[ hello world ]] )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type a = [==[ hello world ]==] )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("prettyPrint_escaped_string_types")
{
    const std::string code = R"( type a = "\\b\\t\\n\\\\" )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("prettyPrint_type_table_semicolon_separators")
{
    const std::string code = R"(
        type Foo = {
            bar: number;
            baz: number;
        }
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("prettyPrint_type_table_access_modifiers")
{
    std::string code = R"(
        type Foo = {
            read  bar: number,
              write baz: number,
        }
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = { read string } )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = {
        read [string]: number,
        read ["property"]: number
    } )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("prettyPrint_type_table_spaces_between_tokens")
{
    std::string code = R"( type Foo = { bar: number, } )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = {   bar: number, } )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = { bar  : number, } )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = { bar:   number, } )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = { bar: number  , } )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = { bar: number,   } )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = { bar: number   } )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = { [string]: number } )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = {    [string]: number } )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = { [   string]: number } )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = { [string   ]: number } )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = { [string]   : number } )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = { [string]:   number } )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("prettyPrint_type_table_preserve_original_indexer_style")
{
    std::string code = R"(
        type Foo = {
            [number]: string
        }
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"(
        type Foo = { { number } }
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("prettyPrint_type_table_preserve_indexer_location")
{
    std::string code = R"(
        type Foo = {
            [number]: string,
            property: number,
        }
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"(
        type Foo = {
            property: number,
            [number]: string,
        }
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"(
        type Foo = {
            property: number,
            [number]: string,
            property2: number,
        }
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("prettyPrint_type_table_preserve_property_definition_style")
{
    std::string code = R"(
        type Foo = {
            ["$$typeof1"]: string,
            ['$$typeof2']: string,
        }
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("prettyPrint_type_table_string_properties_spaces_between_tokens")
{
    std::string code = R"(
        type Foo = {
            [  "$$typeof1"]: string,
            ['$$typeof2'  ]: string,
        }
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("prettyPrint_types_preserve_parentheses_style")
{
    std::string code = R"( type Foo = number )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = (number) )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = ((number)) )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = (  (number)  ) )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("fuzzer_prettyPrint_with_zero_location")
{
    const std::string example = R"(
if _ then
else if _ then
else if l0 then
else
function l0<t0>(...):(t0<t0...>,(any)|(<t0>((any)|(<t0>(""[[[[[[[[[[[[[[[[[[[[[[[[!*t")->()))->()))
end
end
)";

    Luau::ParseOptions parseOptions;
    parseOptions.captureComments = true;

    auto allocator = std::make_unique<Luau::Allocator>();
    auto names = std::make_unique<Luau::AstNameTable>(*allocator);
    ParseResult parseResult = Parser::parse(example.data(), example.size(), *names, *allocator, parseOptions);

    prettyPrintWithTypes(*parseResult.root);
}

TEST_CASE("prettyPrint_type_function_unnamed_arguments")
{
    std::string code = R"( type Foo = () -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo =   () -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = (string) -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = (string, number) -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = (  string, number) -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = (string  , number) -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = (string,   number) -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = (string, number  ) -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = (string, number)   -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = (string, number) ->   ()  )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("prettyPrint_type_function_named_arguments")
{
    std::string code = R"( type Foo = (x: string) -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = (x: string, y: number) -> ()  )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = (  x: string, y: number) -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = (x  : string, y: number) -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = (x:   string, y: number) -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = (x: string,   y: number) -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = (number, info: string) -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = (first: string, second: string, ...string) -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("prettyPrint_type_function_generics")
{
    std::string code = R"( type Foo = <X, Y, Z...>() -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo =   <X, Y, Z...>() -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = <  X, Y, Z...>() -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = <X  , Y, Z...>() -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = <X,   Y, Z...>() -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = <X, Y  , Z...>() -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = <X, Y,   Z...>() -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = <X, Y, Z  ...>() -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = <X, Y, Z...  >() -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = <X, Y, Z...>  () -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("prettyPrint_type_function_return_types")
{
    std::string code = R"( type Foo = () ->   () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = () -> (  ) )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = () -> string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = () ->   string )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = () -> (string) )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = () ->   (string) )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = () -> ...any )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = () ->   ...any )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = () -> ...  any )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = () -> (...any) )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = () -> (  string, number) )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = () -> (string  , number) )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = () -> (string,   number) )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = () -> (string, number  ) )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("prettyPrint_chained_function_types")
{
    std::string code = R"( type Foo = () -> () -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = () -> ()   -> () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"( type Foo = () -> () ->   () )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("fuzzer_nil_optional")
{
    const std::string code = R"( const x: nil? = nil )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("fuzzer_class")
{
    ScopedFastFlag fflag{FFlag::DebugLuauUserDefinedClasses, true};
    const std::string code = R"( class l0 end )";
    // should not crash
    prettyPrint(code, {}, true);
}

TEST_CASE("simple_class_example")
{
    ScopedFastFlag fflag{FFlag::DebugLuauUserDefinedClasses, true};

    std::string code = R"(
class Point
    public x: number
    public y: number
    function length(self)
        return 100
    end
    function __init(self)
        self.x = 0
        self.y = 0
    end
end
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("remixed_simple_class")
{
    ScopedFastFlag fflag{FFlag::DebugLuauUserDefinedClasses, true};

    std::string code = R"(
class Point
    function length(self)
        return 100
    end
    public x
    function __init(self)
        self.x = 0
        self.y = 0
    end
    public y
end
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("simple_class_with_public_functions")
{
    ScopedFastFlag fflag{FFlag::DebugLuauUserDefinedClasses, true};

    std::string code = R"(
class Point
    public function length(self)
        return 100
    end
    public x
    public function __init(self)
        self.x = 0
        self.y = 0
    end
    public y
end
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("simple_class_inheritance")
{
    ScopedFastFlag fflag{FFlag::DebugLuauUserDefinedClasses, true};

    std::string code = R"(
class Animal
    public species: string
end

class Cat extends Animal
    public meowMult: number
end
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("prettyPrint_function_attributes")
{
    ScopedFastFlag sff{FFlag::LuauExportValueSyntax, true};

    std::string code = R"(
        @native
        function foo()
        end
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"(
        @native
        function foo()
        end
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"(
        @checked function foo()
        end
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"(
        foo = @native function() end
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"(
        @native
        function foo:bar()
        end
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"(
        @native   @checked
        function foo:bar()
        end
    )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    {
        ScopedFastFlag noInline{FFlag::DebugLuauNoInline, true};
        code = R"(
        @debugnoinline
        function t() end
        )";
        CHECK_EQ(code, prettyPrint(code, {}, true).code);
    }

    code = R"=(
    @[deprecated {
        use = "newApi()",
        reason = "newApi is faster and supports all value types.",
    }]
    function oldApi()
    end
    )=";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"=(
    @[deprecated {use = "newApi()"}, native]
    function oldFastApi()
    end
    )=";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"=(
    @[deprecated({use = "newApi()"})]
    function oldFastApi()
    end
    )=";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"=(
    @[deprecated {
        use = "newApi()",
        reason = "newApi is faster and supports all value types.",
    }, native]
    function oldApi()
    end
    )=";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"=(
    @checked
    @[    deprecated  , native    ]
    function oldApi()
    end
    )=";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = R"=(
    @checked
    @[    deprecated  , native    ]
    export function oldApi()
    end
    )=";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
    {
        // We don't currently have any attributes which accept a single string, so we ignore parse errors for this example.
        code = R"=(
    @checked
    @[    why  "it's bad"     , native    ]
    const function oldApi()
    end
    )=";

        CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
    }

    code = R"=(
    foo = @checked
    @[    deprecated  , native    ]
    function()
    end
    )=";

    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("pretty_print_explicit_type_instantiations")
{
    std::string code = "f<<A, B, C...>>() t.f<<A, B, C...>>() t:f<<A, B, C>>()";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    Allocator allocator;
    AstNameTable names = {allocator};
    ParseResult parseResult = Parser::parse(code.data(), code.size(), names, allocator, {});
    REQUIRE(parseResult.errors.empty());
    CHECK_EQ(code, prettyPrintWithTypes(*parseResult.root));

    // No types
    CHECK_EQ("f              () t.f              () t:f           ()", prettyPrint(code).code);

    code = "f < < A , B , C... > >( ) t.f < < A, B, C... > >  ( )  t:f< < A, B, C > > ( )";
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("export")
{
    ScopedFastFlag sffs[] = {{FFlag::LuauExportValueSyntax, true}};
    std::string code;

    code = (R"(
export version = "1.0.0"
export           const tabbed = ...
export const TAU = math.pi * 2
export settings: Settings = getSettings()
export a, b, c = 1, 2, 3
export d
    )");
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = (R"(
export function add(a: number, b: number): number
    return a + b
end

export function greet(name: string): string
    return "Hello, " .. name
end

export function noop()
end

export        function tabbed(): number
    return 1
end
    )");
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = (R"(
@native
export function foo()
end

@native
export                 function tabbed_attribute()
end
    )");
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = (R"(
export f, g

function f()
    return g()
end

function g()
    return 42
end
    )");
    CHECK_EQ(code, prettyPrint(code, {}, true).code);

    code = (R"(
export type Config = {
    debug: boolean,
    timeout: number,
}

export currentConfig: Config

export function createConfig(debug: boolean, timeout: number): Config
    return {
        debug = debug,
        timeout = timeout,
    }
end
    )");
    CHECK_EQ(code, prettyPrint(code, {}, true).code);
}

TEST_CASE("pretty_print_incomplete_expr_group")
{
    std::string code = "x = (1 + 2";
    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);

    code = "x = (1 + 2                 )";
    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE("pretty_print_incomplete_type_group")
{
    std::string code = "type t = (number";
    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);

    code = "type t = (number           )";
    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE("pretty_print_incomplete_explicit_type_instantiations")
{
    // Parser branch for explicit type instantiations is triggered by two '<' tokens
    std::string code = "f<<A, B, C...>() t.f<<A, B, C...>() t:f<<A, B, C>()";
    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);

    code = "f < < A , B , C...  >( ) t.f < < A, B, C...  >  ( )  t:f< < A, B, C  > ( )";
    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE("pretty_print_incomplete_function_call")
{
    // Parser branch for function call is triggered by a '(' token
    std::string code = "print('hello world'";
    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);

    code = "t:hello('world'";
    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE_FIXTURE(Fixture, "pretty_print_incomplete_index_expr")
{
    // Parser branch for index expr is triggered by a '[' token
    std::string code = "a = {1, 2, 3} b = a[2";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE_FIXTURE(Fixture, "pretty_print_incomplete_function_expr")
{
    std::string code = R"(
a = function<T(x : T, y: string, ... : number)
    return x
end)";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE_FIXTURE(Fixture, "pretty_print_incomplete_table_expr")
{
    std::string code = R"(a = { a = 1 ["b"] = 2 })";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);

    code = R"(a = { ["b" = 2, ["c"] 3, ["d" 4 })";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE_FIXTURE(Fixture, "pretty_print_incomplete_if_else_expr")
{
    std::string code = R"(a = if true 1 else 2)";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE_FIXTURE(Fixture, "pretty_print_incomplete_do_stat")
{
    std::string code = R"(
do
    print("hello world")
)";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE_FIXTURE(Fixture, "pretty_print_incomplete_repeat_stat")
{
    std::string code = R"(
repeat
    print("hello world")
)";
    // The parser tries to parse the condition even if "until" is missing
    std::string expected = R"(
repeat
    print("hello world")
(error-expr))";

    CHECK_EQ(expected, prettyPrint(code, {}, true, true).code);
}

TEST_CASE_FIXTURE(Fixture, "pretty_print_incomplete_for_stat")
{
    std::string code = R"(
for i : number = 1 10 do
    print(i)
end
)";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE_FIXTURE(Fixture, "pretty_print_incomplete_assign_stat")
{
    std::string code = R"(
x , y 1, 2
)";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE_FIXTURE(Fixture, "pretty_print_incomplete_generic_typepack")
{
    std::string code = "type foo<T, U..., V> = bar<T, U..., V>";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE_FIXTURE(Fixture, "pretty_print_incomplete_type_alias")
{
    std::string code = "type foo number";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE_FIXTURE(Fixture, "pretty_print_incomplete_type_reference")
{
    std::string code = "type foo = Bar<number";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE_FIXTURE(Fixture, "pretty_print_incomplete_table_type")
{
    std::string code = R"(type foo = { ["hello" : number })";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);

    code = R"(type foo = { ["hello"] number })";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);

    code = R"(type foo = { ["hello" number })";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);

    code = R"(type foo = { ["hello"] number, ["world"] number, ["i" : "rule" })";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);

    code = R"(type foo = { [number] number })";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);

    code = R"(type foo = { [number : number })";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);

    code = R"(type foo = { [number  number })";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE_FIXTURE(Fixture, "pretty_print_incomplete_function_type")
{
    std::string code = R"(
function foo() : (number, string -> ()
end
)";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);

    code = "type foo = <A(number) -> string";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);

    code = "type foo = <A>number) -> string";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);

    code = "type foo = <A>(number -> string";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE_FIXTURE(Fixture, "pretty_print_incomplete_typeof_type")
{
    std::string code = "type foo = typeof x)";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);

    code = "type foo = typeof(x";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);

    code = "type foo = typeof x";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE("pretty_print_incomplete_attr_list")
{
    std::string code = R"=(
    @unknown
    @[deprecated  , native
    function oldApi()
    end
    )=";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE("pretty_print_incomplete_attr_args")
{
    std::string code = R"=(
    @[deprecated ({ use = "newApi()"} ]
    function oldApi()
    end
    )=";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_CASE("pretty_print_readonly_indexer")
{
    ScopedFastFlag visualizeIndexerAccess{FFlag::LuauPrettyPrintVisualizeIndexerAccess, true};

    std::string code = R"(
        const _t: { read number } = {}
        const _u: { read [string]: boolean }
    )";

    CHECK_EQ(code, prettyPrint(code, {}, true, true).code);
}

TEST_SUITE_END();
