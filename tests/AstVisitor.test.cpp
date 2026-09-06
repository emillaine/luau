// This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
#include "Fixture.h"

#include "Luau/Ast.h"

#include "doctest.h"

using namespace Luau;

namespace
{

class AstVisitorTracking : public AstVisitor
{
private:
    std::vector<AstNode*> visitedNodes;
    std::set<size_t> seen;

public:
    bool visit(AstNode* n) override
    {
        visitedNodes.push_back(n);
        return true;
    }

    AstNode* operator[](size_t index)
    {
        REQUIRE(index < visitedNodes.size());

        seen.insert(index);
        return visitedNodes[index];
    }

    ~AstVisitorTracking() override
    {
        std::string s = "Seen " + std::to_string(seen.size()) + " nodes but got " + std::to_string(visitedNodes.size());
        CHECK_MESSAGE(seen.size() == visitedNodes.size(), s);
    }
};

class AstTypeVisitorTrackingWiths : public AstVisitorTracking
{
public:
    using AstVisitorTracking::visit;
    bool visit(AstType* n) override
    {
        return visit((AstNode*)n);
    }
};

} // namespace

TEST_SUITE_BEGIN("AstVisitorTest");

TEST_CASE_FIXTURE(Fixture, "TypeAnnotationsAreNotVisited")
{
    AstStatBlock* block = parse(R"(
        const a: A<number> = null
    )");

    AstVisitorTracking v;
    block->visit(&v);

    CHECK(v[0]->is<AstStatBlock>());
    CHECK(v[1]->is<AstStatLocal>());
    CHECK(v[2]->is<AstExprConstantNil>());
    // We should not have nodes that point to the annotation
    // (no AstTypeReference for 'A' or 'number' is visited).
}

TEST_CASE_FIXTURE(Fixture, "LocalTwoBindings")
{
    AstStatBlock* block = parse(R"(
        const a, b = null, null
    )");

    AstVisitorTracking v;
    block->visit(&v);

    CHECK(v[0]->is<AstStatBlock>());
    CHECK(v[1]->is<AstStatLocal>());
    CHECK(v[2]->is<AstExprConstantNil>());
    CHECK(v[3]->is<AstExprConstantNil>());
}

TEST_CASE_FIXTURE(Fixture, "LocalTwoAnnotatedBindings")
{
    AstStatBlock* block = parse(R"(
        const a: A, b: B<number> = null, null
    )");

    AstTypeVisitorTrackingWiths v;
    block->visit(&v);

    CHECK(v[0]->is<AstStatBlock>());
    CHECK(v[1]->is<AstStatLocal>());
    CHECK(v[2]->is<AstTypeReference>());
    CHECK(v[3]->is<AstTypeReference>());
    CHECK(v[4]->is<AstTypeReference>());
    CHECK(v[5]->is<AstExprConstantNil>());
    CHECK(v[6]->is<AstExprConstantNil>());
}

TEST_CASE_FIXTURE(Fixture, "LocalTwoAnnotatedBindingsWithTwoValues")
{
    AstStatBlock* block = parse(R"(
        const a: A, b: B<number> = 1, 2
    )");

    AstTypeVisitorTrackingWiths v;
    block->visit(&v);

    CHECK(v[0]->is<AstStatBlock>());
    CHECK(v[1]->is<AstStatLocal>());
    CHECK(v[2]->is<AstTypeReference>());
    CHECK(v[3]->is<AstTypeReference>());
    CHECK(v[4]->is<AstTypeReference>());
    CHECK(v[5]->is<AstExprConstantNumber>());
    CHECK(v[6]->is<AstExprConstantNumber>());
}

TEST_SUITE_END();
