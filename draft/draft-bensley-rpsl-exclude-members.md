---
stand_alone: true
title: Explicitly excluding objects from RPSL sets
abbrev: Excluding objects from RPSL sets
lang: en
kw:
  - rpsl
docname: draft-bensley-rpsl-exclude-members-00
updates: 2622, 4012
category: info
ipr: trust200902
submissiontype: IETF
area:
wg:
author:
 -
    ins: J. Bensley
    name: James Bensley
    organization: Inter.link GmbH
    email: james@inter.link
    street: Boxhagener Str. 80
    city: Berlin
    code: "10245"
    country: Germany
 -
    ins: S. Romijn
    name: Sasha Romijn
    organization: Reliably Coded
    email: sasha@reliablycoded.nl
    city: Amsterdam
    country: Netherlands
normative:
  RFC2622:
  RFC4012:
  I-D.ietf-grow-rpsl-registry-scoped-members:
informative:
  RFC9234:
  RFC9582:
  I-D.ietf-sidrops-aspa-verification:
  I-D.ietf-grow-routing-ops-terms:

--- abstract

This document updates RFC 2622 and RFC 4012 by defining the `excl-members` attribute on the as-set and route-set classes in the Routing Policy Specification Language (RPSL). A set that references another set includes everything the referenced set contains, however deeply nested. RPSL currently has no way for the set owner to make an exception. The `excl-members` attribute lets a set owner exclude specific members, including ones brought in by a referenced set.

--- middle

# Introduction

The Routing Policy Specification Language (RPSL) {{RFC2622}} defines the as-set and route-set classes, whose objects are held in the Internet Routing Registry (IRR). A set can reference direct members, such as an AS number or IP prefix, and it can reference other sets. Those sets can reference further sets, recursively. Server and client software resolve a set by following these references until it is reduced to a set of prefixes or AS numbers. The result is used mainly to build filters on routers.

## Existing Methods of Inclusion

Existing RPSL syntax offers several ways to include members in an as-set or route-set:

1. The `members` attribute. On an as-set it holds AS numbers and as-set primary keys ({{Section 5.1 of RFC2622}}).

    A route-set's members are address prefixes. Its `members` attribute contains an IPv4 address prefix or a route-set primary key, each optionally followed by a range operator ({{Section 5.2 of RFC2622}}). It may also contain an AS number or an as-set primary key, which per {{Section 5.3 of RFC2622}} stand for the routes originated by that AS, or by the ASes in that as-set.
1. The `mp-members` attribute for route-sets ({{Section 4.2 of RFC4012}}), which takes the same values as `members` and adds IPv6 address prefixes. Like `members`, this may contain an AS number or an as-set primary key.
1. The `mbrs-by-ref` and `member-of` attributes. These add an AS to an as-set through its aut-num object, or a route object's prefix to a route-set, when that object's `member-of` names the set and the set's `mbrs-by-ref` lists one of the object's maintainers or `ANY`, per {{Sections 5.1 and 5.2 of RFC2622}}. {{Section 3 of RFC4012}} extends this to route6 objects.

## Resolving Members of a Set

Resolving a set means working out which AS numbers or prefixes it includes. A resolver reads the set object and, wherever a member names another set, reads that set as well, continuing until it reaches members that are AS numbers or address prefixes. Those members are the result. In practice, implementations place limits on the depth and detect loops.

A set that names another as-set or route-set in `(src/mp-)members` is called the including set, and the set it names the included set. Everything an included set resolves to becomes part of what the including set resolves to.

In {{fig-resolving}}, AS-EXAMPLE-A1 lists a single member. It resolves to AS64500, AS64501 and AS64502:

~~~~ rpsl
as-set: AS-EXAMPLE-A1
members: AS-EXAMPLE-B1

as-set: AS-EXAMPLE-B1
members: AS64500, AS64501, AS-EXAMPLE-C1

as-set: AS-EXAMPLE-C1
members: AS64502
~~~~
{: #fig-resolving title='A three-level as-set hierarchy'}

This also applies when a route-set references another route-set or as-set.

## Existing Methods of Exclusion

The filter-set class ({{Section 5.4 of RFC2622}}) defines a set of routes by describing what its `filter` attribute matches. {{Section 4.3 of RFC4012}} adds `mp-filter`, which covers both address families. A network applies such a set in its own policy, accepting the routes the filter matches or, where the filter is negated, all others. Routes that a route-set contributed can be dropped this way.

The `mbrs-by-ref` and `member-of` pairing described above also limits which objects join a set. The set owner can restrict to specific maintainers in `mbrs-by-ref`, and an object's owner can leave the set out of its `member-of`.
However, this does not affect other sets in the hierarchy.

Consumers of a set, meaning the operators and tools that resolve it to build filters, also exclude members by means outside RPSL. Some filter-generation tooling and IRR servers offer options to drop named sets during expansion, so that a network can, for example, keep IXP route-server sets out of its filters. Such exclusions are chosen by the party building the filter and apply to a single resolution. They are not published to other consumers.

## Missing Exclusion Options

None of the existing options gives a set owner a way to exclude an AS number, as-set or route-set that was included recursively through `(src/mp-)members`. An owner can only control the members the object lists directly.

Consumers encounter problems such as:

1. A set somewhere in the hierarchy includes a member its owner has no relationship with. Consumers build filters that accept those routes. The set's owner can then make advertisements it is not authorised to make, whether a route hijack (intentional) or a route leak (accidental). The inclusion may be nested many levels down, where the consumer has no direct relationship with the owner that made it, and so no practical way to get it removed.
1. A member intended to be a downstream is instead a peer or upstream. The IRR now shows the including set's owner as that member's transit provider. Filters can then expand massively, even to the whole global routing table. They become too large to program onto devices and too broad to offer useful protection.
1. A member is added whose actions violate a law, a geo-political agreement, sanctions, or a peer or upstream's terms. Peers and upstreams of the including set's owner may now forward traffic for that member. If the including set belongs to a direct peer of the consumer, the two can discuss an alternative between themselves. If the member instead sits many levels down under a peer, that peer usually cannot help, having no relationship with the member itself, and the consumer is left with fragile manual workarounds. The same applies where a peer or upstream already serves the added member directly and a regulation forbids that peer or upstream from serving it via a third party.

The `excl-members` attribute lets a set owner name AS numbers, as-sets and route-sets to exclude when its own set is resolved, including ones an included set brings in. The included set itself is unchanged. Because the attribute is published with the object rather than chosen by the consumer, every resolver that implements this document applies the same exclusions.

`excl-members` does not change how a route is validated against a Route Origin Authorization {{RFC9582}} or an Autonomous System Provider Authorization {{I-D.ietf-sidrops-aspa-verification}}, or how the roles defined in {{RFC9234}} apply.

## Requirements Language

{::boilerplate bcp14-tagged}

## Terminology

The terms upstream, downstream, peer and transit provider are used as defined in {{I-D.ietf-grow-routing-ops-terms}}.

# The `excl-members` Attribute

`excl-members` is a new attribute on the as-set and route-set classes. It builds on the `src-members` attribute defined in {{I-D.ietf-grow-rpsl-registry-scoped-members}}. Readers should be familiar with `src-members` and its motivation before continuing.

## The as-set Class

On an as-set, `excl-members` uses almost the same syntax as `members` ({{Section 5.1 of RFC2622}}): one or more AS numbers or as-set primary keys. The only difference is that an as-set key MUST be prefixed with a registry name and a double colon, for example `EXAMPLE::`. This removes the ambiguity of unscoped as-set primary keys, described in {{I-D.ietf-grow-rpsl-registry-scoped-members}}.

{:vspace}
Attribute:
: `excl-members`

Value:
: list of (`<as-number>` or `<registry-name>::<as-set-name>`)

Type:
: optional, multi-valued

## The route-set Class

On a route-set, `excl-members` uses syntax similar to `members` ({{Sections 5.2 and 5.3 of RFC2622}}): one or more AS numbers, as-set primary keys, or route-set primary keys. Unlike `(mp-)members`, it does not accept address prefixes, with or without a range operator. Any as-set or route-set key MUST be prefixed with a registry name and a double colon, for example `EXAMPLE::`, for the same reason as on the as-set class.

{:vspace}
Attribute:
: `excl-members`

Value:
: list of (`<registry-name>::<route-set-name>` or `<registry-name>::<as-set-name>` or `<as-number>` or `<registry-name>::<route-set-name><range-operator>`)

Type:
: optional, multi-valued

## Attribute Validation

When an authoritative IRR registry processes the creation or update of an as-set or route-set with an `excl-members` attribute, it MUST validate the attribute's contents.

### Registry Scopes and Duplicate Keys

Every reference to an as-set or route-set in `excl-members` MUST contain a registry scope. AS numbers are globally unique and are written without one. IRR registry software MUST reject an `excl-members` attribute containing two keys that are identical once their registry scopes are removed:

~~~~ rpsl
excl-members: RIPE::AS-EXAMPLE, ARIN::AS-EXAMPLE
~~~~
{: #fig-invalid-duplicate-keys title='Invalid object fragment using multiple registry scopes with the same RPSL primary key'}

If this were allowed, the two entries would refer to two different sets, whereas `(mp-)members` can only hold one `AS-EXAMPLE`, leaving it ambiguous which set the exclusion refers to.

IRR registry software MUST also reject an object where `excl-members` and `src-members` name the same key with different registry scopes:

~~~~ rpsl
members: AS-EXAMPLE
src-members: ARIN::AS-EXAMPLE
excl-members: RIPE::AS-EXAMPLE
~~~~
{: #fig-invalid-scope-mismatch title='Invalid object fragment using different registry scopes with the same RPSL primary key across attributes'}

Here `src-members` takes precedence over `members`, so `ARIN::AS-EXAMPLE` would be included, yet the `excl-members` value `RIPE::AS-EXAMPLE` would not match it.

### No Membership, Scope or Existence Requirement

IRR registry software MUST NOT require that a key in `excl-members` is also a direct member of the object being created or updated. `excl-members` applies to everything reached through the object that contains it, and the object named may be referenced several levels further down.

IRR registry software also MUST NOT require the registry scope on an `excl-members` key to be one it recognises. An authoritative server's content may be mirrored to resolvers that see many more registries.

An `excl-members` entry may name an object that a resolver cannot retrieve, because no such object exists or because that registry is not among those it has data for. Exclusions are matched against during resolution, not during creation of the object.

# Resolver Behaviour

The `excl-members` value applies to everything reached through the set that contains it, down the tree. That means a set is resolved under its own exclusions and those of every object on the way to it, from the viewpoint of the set requested by the consumer. A member named by any of the exclusions MUST be ignored by the resolver.

Because more than one set may reference the same object, the same object can be excluded on one path and still included through a different path, where that exclusion does not exist.

A member that joined a set through `mbrs-by-ref` and `member-of` MUST be treated the same as one listed in `members` or `mp-members`. On an as-set an excluded AS number MUST NOT be included. On a route-set this has no effect, because `excl-members` cannot name a prefix.

The result of resolving a set MUST NOT depend on the order in which an implementation follows references.

An `excl-members` key that names an as-set or route-set contains a registry scope.

1. A key that contains no registry scope, in `members` or `mp-members`, MUST be compared against the `excl-members` key with that key's scope removed.
1. A registry-scoped key in `src-members` ({{I-D.ietf-grow-rpsl-registry-scoped-members}}) MUST match a registry-scoped `excl-members` key exactly, with neither scope removed.
1. Where `src-members` and `members` or `mp-members` on the same object define the same key, once the scope is stripped from the `src-members` entry, the `src-members` key MUST be compared against `excl-members` with both scopes present, and takes precedence over the `members` or `mp-members` entry.

Where a reference names a set without a registry scope and an exclusion matches it, that reference MUST NOT be followed. The resolver MUST NOT instead resolve that reference in another registry. Doing so could contribute members that would otherwise not have been included.

## Exclusions on an as-set

When `excl-members` is populated on an as-set, a resolver MUST NOT follow a reference to any as-set that `excl-members` names, and MUST NOT include any AS number it names. The exclusion covers `members` and `src-members`, on the as-set that contains it and on every as-set reached through it.

Consider the as-sets in {{fig-as-set-unresolved}}:

~~~~ rpsl
as-set: AS-EXAMPLE-A1
members: AS-EXAMPLE-B1, AS64500
source: ARIN

as-set: AS-EXAMPLE-B1
members: AS64501, AS-EXAMPLE-C1
excl-members: RIPE::AS-EXAMPLE-D1, AS64504, AS64501
source: RIPE

as-set: AS-EXAMPLE-C1
members: AS64502, AS64504, AS-EXAMPLE-D1
src-members: RIPE::AS-EXAMPLE-D1
source: RIPE

as-set: AS-EXAMPLE-D1
members: AS64503
source: RIPE
~~~~
{: #fig-as-set-unresolved title='An example as-set hierarchy'}

The members of AS-EXAMPLE-A1, accounting for `excl-members`, are AS64500 and AS64502.

* AS64501 is not included, because it is listed in both `members` and `excl-members` on AS-EXAMPLE-B1. An exclusion also takes effect on the same object.
* AS64504 is not included either, even though it is a member of AS-EXAMPLE-C1, one level below the object that excludes it. The exclusion applies to everything reached through AS-EXAMPLE-B1.
* AS64503 is the only member of AS-EXAMPLE-D1, and is not included. AS-EXAMPLE-C1 references that set in `src-members` as `RIPE::AS-EXAMPLE-D1`, which matches the `excl-members` entry on AS-EXAMPLE-B1 exactly, with both registry scopes present.

## Exclusions on a route-set

When `excl-members` is populated on a route-set, a resolver MUST NOT follow a reference to any as-set or route-set that `excl-members` names. A route-set reaches sets of both classes, so the exclusion covers `(mp-)members` and `src-members` on the route-set that contains it and on every route-set reached through it, and `members` and `src-members` on every as-set reached through it.

Per {{Section 5.3 of RFC2622}}, a `(mp-)members` or `src-members` entry naming an AS number stands for the routes originated by that AS. Where `excl-members` lists that AS number, a resolver MUST NOT expand such an entry. The resolver does not re-examine the origin of prefixes reached by other references.

Consider the route-sets in {{fig-route-set-unresolved}}:

~~~~ rpsl
route-set: RS-EXAMPLE-A1
members: 192.0.2.0/25, RS-EXAMPLE-B1
source: ARIN

route-set: RS-EXAMPLE-B1
mp-members: 2001:db8::/33
mp-members: RS-EXAMPLE-C1, RS-EXAMPLE-C2
src-members: RIPE::RS-EXAMPLE-C2
excl-members: RIPE::RS-EXAMPLE-C2
source: RIPE

route-set: RS-EXAMPLE-C1
members: 192.0.2.128/25, RS-EXAMPLE-C2
source: RIPE

route-set: RS-EXAMPLE-C2
mp-members: 2001:db8:8000::/33
source: RIPE
~~~~
{: #fig-route-set-unresolved title='An example route-set hierarchy'}

The members of AS-EXAMPLE-A1, accounting for `excl-members`, are 192.0.2.0/25, 192.0.2.128/25 and 2001:db8::/33.

* 2001:db8:8000::/33 is not included, because RS-EXAMPLE-B1 scopes its own reference with `src-members: RIPE::RS-EXAMPLE-C2` and excludes exactly that scoped key.
* RS-EXAMPLE-C1 references RS-EXAMPLE-C2 as well, without a scope. That reference is compared against the `excl-members` entry with the registry scope removed, so it matches and is excluded too.

## Multiple Paths to a Set

The exclusions of each object on the way accumulate as resolution descends. An implementation may therefore have to track several collections of exclusions at once, one for each path it is currently following, rather than a single one for the whole resolution.

Consider the as-sets in {{fig-scope-unresolved}}, in which AS-EXAMPLE-C2 can be reached both through AS-EXAMPLE-B1 and through AS-EXAMPLE-B2:

~~~~ rpsl
as-set: AS-EXAMPLE-A1
members: AS-EXAMPLE-B1, AS-EXAMPLE-B2
excl-members: AS64505
source: ARIN

as-set: AS-EXAMPLE-B1
members: AS-EXAMPLE-C1
excl-members: RIPE::AS-EXAMPLE-C2
source: ARIN

as-set: AS-EXAMPLE-B2
members: AS-EXAMPLE-C2
source: ARIN

as-set: AS-EXAMPLE-C1
members: AS-EXAMPLE-C2, AS64503, AS64505
source: ARIN

as-set: AS-EXAMPLE-C2
members: AS64504
source: RIPE
~~~~
{: #fig-scope-unresolved title='An as-set hierarchy in which AS-EXAMPLE-C2 can be reached two ways'}

Resolving AS-EXAMPLE-A1 reaches AS-EXAMPLE-C2 in two ways:

* Through AS-EXAMPLE-B1 and then AS-EXAMPLE-C1. AS64505 is excluded by AS-EXAMPLE-A1, and AS-EXAMPLE-C2 by AS-EXAMPLE-B1, though AS-EXAMPLE-C2 is not a member of AS-EXAMPLE-B1 itself. This path contributes only AS64503.
* Through AS-EXAMPLE-B2. Only the exclusion of AS64505 applies here, so the reference to AS-EXAMPLE-C2 is followed. This path contributes AS64504.

AS-EXAMPLE-A1 resolves to AS64503 and AS64504. AS-EXAMPLE-C2 is still reached through AS-EXAMPLE-B2.

Implementations MUST NOT apply an exclusion to objects other than the object that contains it and those reached through it. If they did, the owner of an included set could add keys to its own `excl-members` and remove members from unrelated parts of the hierarchy.

# IANA Considerations {#IANA}

This memo includes no request to IANA.

# Security Considerations {#Security}

A resolver that does not support `excl-members` will not apply exclusions in results. Operators who depend on exclusions should verify that the resolver they use supports the attribute.

The presence of the attribute does not indicate correct filtering, as tools using the IRR should be designed to ignore attributes they do not understand ({{Section 10.2 of RFC2622}}).

A set owner cannot verify through the IRR that an exclusion has taken effect for any given consumer.

Resolving a set with exclusions costs more than resolving one without. An implementation has to track what is excluded separately for each part of the hierarchy. Combined with circular references, which resolvers must already detect, this can be used to consume resources. Implementations are RECOMMENDED to limit the depth or size of a resolution.

--- back
