---
stand_alone: true
title: Explicitly excluding objects from RPSL sets
abbrev: Explicitly excluding objects from RPSL sets
docname: draft-bensley-rpsl-exclude-members-00
date: 2026-3-27
category: info
ipr: trust200902
submissiontype: IETF
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
normative:
  RFC2119:
  RFC2622:
  RFC4012:
informative:
  RFC9582:
  draft-romijn-grow-rpsl-registry-scoped-members:
    target: https://datatracker.ietf.org/doc/draft-romijn-grow-rpsl-registry-scoped-members/
    title: Registry scoped members for RPSL set objects
    author:
      -
        ins: S. Romijn
        name: Sasha Romijn
        org: Reliably Coded
      -
        ins: J. Bensley
        name: James Bensley
        org: Inter.link GmbH
    date: 2025-02-21
    format:
      HTML: https://www.ietf.org/archive/id/draft-romijn-grow-rpsl-registry-scoped-members-01.html
      TXT: https://www.ietf.org/archive/id/draft-romijn-grow-rpsl-registry-scoped-members-01.txt
  draft-ietf-sidrops-aspa-verification:
    target: https://datatracker.ietf.org/doc/draft-ietf-sidrops-aspa-verification/
    title: BGP AS_PATH Verification Based on Autonomous System Provider Authorization (ASPA) Objects
    author:
      -
        ins: A. Azimov
        name: Alexander Azimov
        org: Yandex
      -
        ins: E. Bogomazov
        name: Eugene Bogomazov
        org: Qrator Labs
      -
        ins: R. Bush
        name: Randy Bush
        org: IIJ & Arrcus
      -
        ins: K. Patel
        name: Keyur Patel
        org: Arrcus
      -
        ins: J. Snijders
        name: Job Snijders
        org:
      -
        ins: K. Sriram
        name: Kotikalapudi Sriram
        org: USA NIST
    date: 2025-03-23
    format:
      HTML: https://www.ietf.org/archive/id/draft-ietf-sidrops-aspa-verification-22.html
      TXT: https://www.ietf.org/archive/id/draft-ietf-sidrops-aspa-verification-22.txt

--- abstract

This document updates {{RFC2622}} and {{RFC4012}} by defining the `excl-members` attribute on as-set and route-set classes in the Routing Policy Specification Language (RPSL). The existing RPSL syntax only supports the implicit inclusion of everything contained within an as-set or route-set. The newly defined attribute allows operators to overcome this limitation of the existing syntax by enabling them to explicitly exclude certain members from the implicit inclusion.

--- middle

# Introduction

The Routing Policy Specification Language (RPSL) {{RFC2622}} defines the as-set and route-set classes. These sets can reference direct members (such as an AS number or IP prefix) or additional sets, which in turn can reference further sets recursively. Server and client software can follow these references to resolve all members of a set. Once all references have been resolved, what remains is a set of prefixes or ASes.

## Existing Methods of Inclusion

The existing RPSL syntax allows for members of an as-set or route-set to be specified in multiple ways:

1. {{RFC2622}} defines the `members` attribute.
    1. {{Section 5.1 of RFC2622}} defines that for an as-set class this attribute stores one or more primary keys, each referencing an aut-num or an as-set object.
    1. {{Sections 5.2 and 5.3 of RFC2622}} define that for a route-set class this attribute stores one or more primary keys, each referencing a route-set object (optionally with a range operator appended), an aut-num, or an as-set. Alternatively, the `members` attribute on a route-set may store an IPv4 address prefix range directly (i.e., not an RPSL primary key that points to a route object). In this case, the address prefix range is used to identify matching route objects. That address prefix range may optionally have a range operator appended.
1. {{Section 4.2 of RFC4012}} defines the `mp-members` attribute for the route-set class. This attribute may store one or more primary keys, each referencing a route-set object (optionally with a range operator appended), or an IPv4/IPv6 address prefix range directly. Although not explicitly stated in {{RFC4012}}, implementations of the `mp-members` attribute have generally followed the {{RFC2622}} `members` behavior and also allow aut-num and as-set primary keys.
1. {{RFC2622}} defines the `mbrs-by-ref` and `member-of` attributes.
    1. {{Section 5.1 of RFC2622}} defines that for an as-set these attributes allow for the inclusion of aut-nums in the as-set, iff the criteria defined in the RFC linking both attributes together is met.
    1. {{Section 5.2 of RFC2622}} defines that for a route-set these attributes allow for the inclusion of routes in the route-set, iff the criteria defined in the RFC linking both attributes together is met.
1. {{Section 3 of RFC4012}} defines the router6 class along with the `member-of` attribute on that class, and as a result, allows for the inclusion of route6 objects in a route-set, iff the criteria relating to `mbrs-by-ref` and `member-of` attributes defined in {{Section 5.2 of RFC2622}} is met.

When using the `(mp-)members` attribute to include an as-set or route-set (hereinafter the "included set") inside of an as-set or route-set (hereinafter the "including set"), all members of the included set are included in the including set. This is not limited to the members directly nested inside the included set, but all members recursively included all the way down the RPSL hierarchy of the included set. This implicit recursive inclusion logic is hereinafter referred to as "greedy inclusion logic".

In the figure below, the as-set `AS-EXAMPLE-1` only includes one member but, as a result of that single inclusion, AS-EXAMPLE-1 now contains the aut-nums AS65001, AS65002, and AS65003:

~~~~ rpsl
as-set: AS-EXAMPLE-1
members: AS-EXAMPLE-2

as-set: AS-EXAMPLE-2
members: AS65001, AS65002, AS-EXAMPLE-3

as-set: AS-EXAMPLE-3
members: AS65003
~~~~
{: title='An example of greedy inclusion logic. A three level hierarchy is recursed even though AS-EXAMPLE-1 only includes one additional as-set'}

The same inclusion logic applies to a route-set which references another route-set or as-set in the `members` attribute; everything inside the included set, all the way down the recursed tree, is implicitly included into the including set.

Similarly, greedy inclusion logic also applies to prefixes; the `(mp-)members` attribute of a route-set includes any route/route6 objects which match the IPv4/6 address prefix range and optional range operator.

## Existing Methods of Exclusion

The filter-set class and `filter` attribute are defined in {{Section 5.4 of RFC2622}}. The `mp-filter` attribute was later defined in {{Section 2.5.2 of RFC4012}}. Together these attributes provide a method for declaring in the IRR ecosystem the prefixes a network will _not_ accept.

The `(mp-)filter` attribute may be used to exclude route/route6 objects which have been included by the greedy inclusion logic of the `(mp-)members` attribute of a route-set. The way this is achieved in practice is by first including all route/route6 objects which match the IPv4/6 address prefix range and optional range operator in the `(mp-)members` attribute of a route-set, and then removing any route/route6 objects from this result which match the IPv4/6 address prefix range and optional range operator in the `(mp-)filter` attribute of the filter-set.

For as-sets and route-sets which use the `mbrs-by-ref` and `member-of` attributes, both attributes have to contain corresponding values. This reduces the greediness of the inclusion logic when compared to the `(mp-)members` attribute alone, because the including set _and_ included set MUST both reference each other (whereas the `(mp-)members` attribute alone only requires the including set to reference the included set). It is also possible to further reduce the greediness by changing the value of the `mbrs-by-ref` attribute from ANY to a list of specific values, and/or by removing the as-set or route-set primary key from the `members-of` attribute of an aut-num or route/route6 object.

There is currently no method to exclude either an aut-num, an as-set, or a route-set, which was included by the greedy inclusion logic of the `(mp-)members` attribute of an as-set or route-set object. This is the missing functionality within the RPSL syntax which this document aims to address.

## The Need for Additional Exclusion Control

A local network operator which manages an as-set or route-set object, is only in control of which members are directly included included their set. They have no control over the members included beyond this first level of inclusion. This can lead to problems for other networks connecting to the local network, when using the set for route filtering purposes.

The other network, using the the local network's set to build a routing filter, may decided to exclude certain members from the local network's set. This decision needs to be made based on context known to the other network. For example, filtering the presence of any IXP Route Server as-sets or any sets for networks which are known to the other network to be transit free. There are various reasons why the other network may wish to exclude members from the local network's set, however, the context for which sets to exclude is based on knowledge and policy specific to the other network, and is out of scope of this document.

After having excluded any members which the other network doesn't want to include, the other network can then use the remainder of the local network's set to build a routing filter. However, the other network doesn't have the full context about the contents of the local network's set. For example, nested many levels down inside the local network's set are networks for which the the local network MUST NOT be a connectivity provider. The other network can't know the relationship between the local network and these nested entries within the set. The local network operator needs a method to provide this context to the other network, so that the other network's existing process for excluding set members can be extended with this additional context. This is the scope of this document.

## Problems with the Existing Syntax

The existing greedy inclusion logic of the `(mp-)members` attribute of as-sets and route-sets, coupled with the inability to alter this logic, means that there is no method for a local network operator to provide context to other network operators about set member exclusions. Due to this inability to provide such context, other networks encounter various problems when using the local network's set to build routing filters. A non-exhaustive list of undesirable outcomes are provided below.

1. The owner of an including set adds a new member, but the included set is not connected with, or related to, the including set. This allows the including set owner to make routing advertisements they are not authorised to make, either intentionally (commonly known as a route hijack), or accidentally (commonly known as a route leak). Other networks lack this context and will generate routing policy based on the unauthorised inclusion.

    This can happen anywhere in the set hierarchy; the unauthorised include may be nested many levels down within the set used by the other network, making it difficult to get the included set removed due to no direct relationship between the network making the inclusion and the network using the as-set or route-set to build a routing filter.

1. A member is added to a set which creates a loop when the set is resolved (set A contains set B which contains set A). This can lead to IRR derived prefix or AS path filters either massively expanding in size, or simply not being resolvable.

1. A member is added to a set which is intended to contain a network's downstreams, but the included set relates to a peer or upstream, not a downstream. According the IRR data, the operator of the including set has now become a transit provider for the operator of the included set. This can also lead to IRR derived prefix or AS path filters massively expanding in size, to a point at which the filters are effectively nullified and provide no protection. This can happen because one or more included sets, which when recursively resolved, expand to the entire global BGP routing table, or because they become so big they can no longer be programmed into network devices.

1. A member is added to a set which relates to an network who's actions violate a law, a geo-political agreement, sanctions, or the connectivity terms and conditions, of a peer or upstream of the including set operator. All peers and upstreams of the networking owning the including set will now route traffic for the included set. If the including set is operated by a direct peer, two peers may be able to discuss an alternative approach between themselves. If the including set is many levels down within the set hierarchy of a peer, the peer likely can not help due to having no relationship with the including set. The operator may have to implement manual workarounds to avoid routing traffic for the included set, which may be difficult to maintain and error prone.

1. A member is added to a set with whom a peer or upstream of the including set operator already has a direct relation. A regulatory requirement may restrict the peer or upstream from exchanging traffic with the operator of the included set via the including set operator, or via any 3rd party operator. Again, such a scenario may required manual workarounds.

This document updates the RPSL definitions in {{RFC2622}} and {{RFC4012}} by introducing the `excl-members` attribute.

This allows the including set operator to exclude aut-nums, as-sets, and route-sets, from the included set, or to exclude the included set entirely, from being included in the including set. This allows operators to have finer grained control over the members of their sets, and to avoid the undesired outcomes described above.

## Requirements Language

{::boilerplate bcp14-tagged}

## Terminology

In this document, the key words "MUST", "MUST NOT", "REQUIRED",
"SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY",
and "OPTIONAL" are to be interpreted as described in BCP 14, RFC 2119
{{RFC2119}}.

# The `excl-members` Attribute

The `excl-members` attribute is defined by this document for the as-set class and route-set class.

This attribute builds on the RPSL modifications introduced by the `src-members` attribute defined in {{draft-romijn-grow-rpsl-registry-scoped-members}}. Therefore, readers should be familiar with the `src-members` attribute and its motivation before reading the rest of this document.

## The as-set Class

The new `excl-members` attribute on the as-set class uses almost exactly the same syntax as the existing `members` attribute from {{Section 5.1 of RFC2622}}, in that one or more RPSL primary keys of an aut-num or as-set may be specified. The only difference is that when an as-set is specified in `excl-members`, the as-set primary key MUST be prefixed with a registry name and a double colon (e.g., `SOURCE::`). This requirement is to ensure that the correct object is being excluded due to the existing ambiguity of as-set primary keys in the IRR ecosystem (as documented in {{draft-romijn-grow-rpsl-registry-scoped-members}}).

{:vspace}
Attribute:
: `excl-members`

{:vspace}
Value:
: list of ([`as-number`] or [`registry-name`]::[`as-set-name`])

{:vspace}
Type:
: optional, multi-valued

## The route-set Class

The new `excl-members` attribute on the route-set class uses similar syntax as the existing `members` attribute from {{Sections 5.2 and 5.3 of RFC2622}}, in that one or more RPSL primary keys of an aut-num, an as-set, or route-set may be specified. What is different is that `excl-members` doesn't accept IPv4/6 address prefix ranges because they can already be filtered using a filter-set. In the case that an as-set or route-set is specified in `excl-members`, the set primary key MUST be prefixed with a registry name and a double colon (e.g., `SOURCE::`). This requirement is to ensure that the correct object is being excluded due to the existing ambiguity of as-set and route-set primary keys in the IRR ecosystem (as documented in {{draft-romijn-grow-rpsl-registry-scoped-members}}).

{:vspace}
Attribute:
: `excl-members`

{:vspace}
Value:
: list of ([`registry-name`]::[`route-set-name`] or [`registry-name`]::[`as-set-name`] or [`as-number`] or [`registry-name`]::[`route-set-name`][`range-operator`])

{:vspace}
Type:
: optional, multi-valued

## Attribute Validation

When an authoritative IRR registry processes the creation or update of an as-set or route-set object with the `excl-members` attribute present, it MUST validate the contents of the attribute.

### Registry Scoped Keys Only

All primary keys in `excl-members` MUST have a registry scope provided. By requiring registry scoped primary keys in the `excl-members` attribute, it becomes possible to have multiple references to the same RPSL primary key after stripping the registry prefix. This is not permitted, and IRR registry software MUST reject this:

~~~~ rpsl
excl-members: RIPE::AS-EXAMPLE, ARIN::AS-EXAMPLE
~~~~
{: title='Invalid object fragment using multiple registry prefixes with the same RPSL primary key'}

The IRR registry software MUST verify that without their registry prefix, all primary keys in `excl-members` are unique. If allowed, the attribute `excl-members: RIPE::AS-EXAMPLE, ARIN::AS-EXAMPLE` would refer to two different set objects, whereas the `(mp-)members` attribute can only contain one instance of `AS-EXAMPLE`, which creates ambiguity regarding which set the exclusion refers to when sets exist in multiple registries with the same primary key.

Similarly, the IRR software MUST NOT allow for the registry scopes in the `excl-members` attribute and the `src-members` attribute to be mixed, when both attributes are populated on the same set object, and when with the registry scope removed they are referencing the same primary key.

~~~~ rpsl
member: AS-EXAMPLE
src-members: ARIN::AS-EXAMPLE
excl-members: RIPE::AS-EXAMPLE
~~~~
{: title='Invalid object fragment using different registry prefixes with the same RPSL primary key across attributes'}

If allowed, due to the presence of the `src-members` attribute, ARIN::AS-EXAMPLE is included instead of AS-EXAMPLE (`src-members` is taking preference over `members`), and the `excl-members` attribute value RIPE::AS-EXAMPLE wouldn't match the `src-members` value.

### Any Primary Key and Registry Scope

The IRR software MUST NOT require that the primary key of an entry in the `excl-members` attribute is also a direct member of the object being created or updated. The `excl-members` attribute is used to exclude objects anywhere in the recursive set hierarchy, starting from the point of definition, moving downwards within the hierarchy. This is because the object to be excluded might have been included by a member, of a member, of a member (ad infinitum).

When creating or updating an object with the `excl-members` attribute, authoritative IRR software MUST NOT require that the registry scope which precedes the object primary key is one the IRR software recognizes as valid. An authoritative IRR server may have its content mirrored to resolver IRR servers, which have visibility of many more registries.

## Joint vs. Split Attributes

The `excl-members` attribute could have been designed to be two separate attributes i.e., `excl-members` and `excl-mp-members`. This would provide finer grained control by only excluding a primary key found in a `members` attribute, and only excluding a primary key found in an `mp-members` attribute, respectively. This creates additional problems though:

1. If the primary key of an object which needs to be excluded exists in the set hierarchy in a `members` attribute, but is only excluded if found in an `mp-members` attribute (e.g., it is only referenced in `excl-mp-members`), the object referenced is not successfully excluded. The problem is that the wrong exclude attribute has been used. This problem doesn't exist with a single combined exclude attribute.
1. The syntax of the `mp-members` attribute allows it to contain all types of value supported by the `members` attribute, plus additional value types not supported by the `members` attribute (syntactically `mp-members` supports a superset of `members`). A primary key type which is valid in both attributes, such as a route-set, could be included via the `members` attribute or the `mp-members` attribute in the set hierarchy. To ensure this object is excluded, it's primary key would need to be added to both exclude attributes. This creates the problem that the two attributes would need to always store all values which are valid in the `members` attribute. This would render an `excl-members` attribute redundant because everything is duplicated in an `excl-mp-members` attribute. This problem doesn't exist with a single combined exclude attribute.
1. Split exclude attributes allows for the intentional evasion of an exclusion, by looking in the set hierarchy, observing that a primary key is excluded only if found in one of the `(mp-)members` attributes, and then intentionally including it in the other attribute. This problem doesn't exist with a combined excluded attribute.

Due to the problems listed above, the `excl-members` attribute has been specifically designed to be a single attribute to avoid these problems.

# Exclusion Logic

## The as-set Class

When the `excl-members` attribute is populated on an as-set object, the primary keys stored in the attribute reference aut-nums or as-sets that MUST NOT be resolved by a resolving IRR server, when recursively resolving the members of that as-set object.

1. This exclusion applies to the `members` attribute of the as-set object which has the `excl-members` attribute populated, and the `members` attribute of all recursively resolved as-sets within that set. Because the RPSL primary keys stored in the `excl-members` attribute are prefixed with a registry scope, the primary keys in the `members` attribute MUST be checked against all keys in the `excl-members` attribute with the registry scope removed.
1. This exclusion applies to the `src-members` attribute (as defined in {{draft-romijn-grow-rpsl-registry-scoped-members}}) of the as-set object which has the `excl-members` attribute populated, and the `src-members` attribute of all recursively resolved as-sets within that set. In this case the registry scoped RPSL primary keys in `src-members` MUST match a registry scoped key in `excl-members` exactly, without the registry scope having been removed from either of the two keys being compared.
1. If both `members` and `src-members` are defined on an as-set object, and the same key exists in both attributes when the registry scope is removed from the `src-members` entry, the key from `src-members` which is prefixed with a registry scope MUST be compared against all entries in `excl-members` with their registry scopes present. Matching keys in `src-members` takes precedence over matching keys in `members`.

The figure below shows IRR data in its raw and unresolved state. In the figure, RIPE::AS-EXAMPLE-4 is not defined (it may not exist, or the resolving IRR system may not contain data from the RIPE registry):

~~~~ rpsl
as-set: AS-EXAMPLE-1
members: AS-EXAMPLE-2, AS65001
source: ARIN

as-set: AS-EXAMPLE-2
members: AS65002, AS-EXAMPLE-3
excl-members: RIPE::AS-EXAMPLE-4, AS65005, AS65002
source: RIPE

as-set: AS-EXAMPLE-3
members: AS65003, AS65005, AS-EXAMPLE-4
src-members: RIPE::AS-EXAMPLE-4
source: RIPE

as-set: AS-EXAMPLE-4
members: AS65004
source: ARIN
~~~~
{: title='An example as-set hierarchy, in its unresolved state'}

The figure below shows the result from a resolving IRR server having resolved the members of set `AS-EXAMPLE-1` when the logic relating to `excl-members` is applied:

~~~~ rpsl
as-set: AS-EXAMPLE-1
members: AS65001, AS65003
~~~~
{: title='AS-EXAMPLE-1 in its resolved state with exclusions applied'}

* It can be seen that `excl-members` took effect on the object it was defined, not just it's descendants. This is shown by AS65002 not being included in the final result because AS65002 is both a `member` _and_ `excl-members` of AS-EXAMPLE-2.
* AS-EXAMPLE-4 is excluded even though AS-EXAMPLE-4 is defined in ARIN and is a `member` of AS-EXAMPLE-3. This happens because a `src-members` attribute is defined on AS-EXAMPLE-3, and it takes precedence over the `members` attribute. This means RIPE::AS-EXAMPLE-4 would be included, but it is excluded by the `excl-members` attribute one level higher in the tree on AS-EXAMPLE-2.

## The route-set Class

When the `excl-members` attribute is populated on a route-set object, the primary keys stored in the attribute reference aut-nums, or as-sets, or route-sets, that MUST NOT be resolved by a resolving IRR server, when recursively resolving the members of that route-set object.

1. This exclusion applies to the `(mp-)members` attributes of the route-set object which has the `excl-members` attribute populated, and the `(mp-)members` attributes of all recursively resolved route-sets and as-sets within that route-set. Because the RPSL primary keys stored in the `excl-members` attribute are prefixed with a registry scope, the primary keys in the `(mp-)members` attributes MUST be checked against all keys in `excl-members` attribute with the registry scope removed.
1. This exclusion applies to the `src-members` attribute (as defined in {{draft-romijn-grow-rpsl-registry-scoped-members}}) of the route-set object which has the `excl-members` attribute populated, and the `src-members` attribute of all recursively resolved route-sets and as-sets within that route-set. In this case the registry scoped RPSL primary keys in `src-members` MUST match a registry scoped key in `excl-members` exactly, without the registry scope having being removed from either of the two keys being compared.
1. If both `(mp-)members` and `src-members` are defined on a route-set object, and the same key exists in both attributes when the registry scope is removed from the `src-members` entry, the key from `src-members` which is prefixed with a registry scope MUST be compared against all entries in `excl-members` with their registry scopes present. Matching keys in `src-members` takes precedence over matching keys in `(mp-)members`.

The figure below shows IRR data in its raw and unresolved state:

~~~~ rpsl
route-set: RS-EXAMPLE-1
members: 192.0.2.0/25, RS-EXAMPLE-2
source: ARIN

route-set: RS-EXAMPLE-2
mp-members: 2001:db8::/33
mp-members: RS-EXAMPLE-3, RS-EXAMPLE-4
src-members: RIPE::RS-EXAMPLE-3, RIPE::RS-EXAMPLE-4
excl-members: RIPE::RS-EXAMPLE-4
source: RIPE

route-set: RS-EXAMPLE-3
members: 192.0.2.128/25, RS-EXAMPLE-4
source: RIPE

route-set: RS-EXAMPLE-4
members: 2001:db8:8000::/33
source: ARIN
~~~~
{: title='An example route-set hierarchy, in its unresolved state'}

The figure below shows the result from a resolving IRR server having resolved the members of set `RS-EXAMPLE-1` when the logic relating to `excl-members` is applied:

~~~~ rpsl
route-set: RS-EXAMPLE-1
members: 192.0.2.0/25, 2001:db8::/33, 192.0.2.128/25
~~~~
{: title='RS-EXAMPLE-1 in its resolved state with exclusions applied'}

* It can be seen that `excl-members` took effect on the object it was defined on, not just it's descendants. This is shown by 2001:db8:8000::/33 not being included in the final result because RS-EXAMPLE-4 is both a `member` _and_ `excl-members` of RS-EXAMPLE-2.
* Even though RS-EXAMPLE-4 is excluded by RS-EXAMPLE-2, it was also included by RS-EXAMPLE-3, but still 2001:db8:8000::/33 is excluded. This shows that the exclusion logic applies from the point in the hierarchy where it is defined, all the way down, taking precedence over any subsequent includes.
* RS-EXAMPLE-4 is excluded even though RS-EXAMPLE-4 is defined in ARIN and RIPE::RS-EXAMPLE-4 is specified in `excl-members` on RS-EXAMPLE-2. This is because the RS-EXAMPLE-4 entry in the `(mp-)members` attribute of RS-EXAMPLE-3 is ambiguous due to the lack of `src-members` attribute on RS-EXAMPLE-3. This means that the `excl-members` value RIPE::RS-EXAMPLE-4 has to be checked against the `members` attribute on RS-EXAMPLE-3 with the registry scope removed, which results in a match when checking for primary keys to be excluded from the recursive resolution.

## Cumulative Excludes

As as-set and route-set objects are recursively resolved and `excl-members` attributes are discovered, the RPSL primary keys to be excluded need to be tracked.

At any point in the hierarchy where `excl-members` is discovered, all `(mp-)members` and `src-members` attributes from that point onwards are subject to the `excl-members` which have been discovered so far. However, depending on the resolution algorithm being used by the resolving software i.e., a depth first search or breadth first search, multiple lists of RPSL keys to exclude may have to be maintained (the exact implementation details are outside the scope of this document).

This section does not aim to define how the logic should be implemented in software, simply to demonstrate that the exclusion list is cumulative, but not as simple as a single global list.

The following figure shows as-set objects in their unresolved state:

~~~~ rpsl
as-set: AS-EXAMPLE-1
members: AS-EXAMPLE-2, AS-EXAMPLE-3
excl-members: RIPE::AS-EXAMPLE-4

as-set: AS-EXAMPLE-2
members: AS-EXAMPLE-4
excl-members: RIPE::AS-EXAMPLE-5

as-set: AS-EXAMPLE-4
members: AS65004

as-set: AS-EXAMPLE-3
members: AS-EXAMPLE-5
excl-members: AS65006

as-set: AS-EXAMPLE-5
members: AS65005
~~~~
{: title='An example as-set hierarchy, in its unresolved state'}

The following figure shows the resolved members of as-set AS-EXAMPLE-1:

~~~~ rpsl
as-set: AS-EXAMPLE-1
members: AS65005
~~~~
{: title='AS-EXAMPLE-1 in it's resolved state with exclusions applied'}

1. The resolving process starts by resolving the members of AS-EXAMPLE-1.
1. If a depth first search approach is taken by the IRR software, AS-EXAMPLE-2 might be resolved next. AS-EXAMPLE-4 is not included due to the `excl-members` attribute defined on AS-EXAMPLE-1. This is being applied from the point of definition onwards, the resolving process inherited the currently defined list of excludes (RIPE::AS-EXAMPLE-4) when it moved on to resolve AS-EXAMPLE-2.
1. AS-EXAMPLE-2 defined a new `excl-members` attribute with the value RIPE::AS-EXAMPLE-5 however, there is nothing left to resolve in AS-EXAMPLE-2 so this exclusion has no effect.
1. Continuing the depth-first search approach, the IRR software returns to AS-EXAMPLE-1, uses the exclusion list as it existed while resolving AS-EXAMPLE-1 (containing only RIPE::AS-EXAMPLE-4), and then resolves AS-EXAMPLE-3.
1. AS-EXAMPLE-3 includes AS-EXAMPLE-5. This is not excluded even though the IRR software has encountered an `excl-members` attribute which contains the value RIPE::AS-EXAMPLE-5. This is because that `excl-members` attribute was found on a different branch of the set hierarchy.
1. Continuing the resolution process, resolving AS-EXAMPLE-5 returns AS65005 only. The exclusion of AS65006 defined on AS-EXAMPLE-3 was applied to the resolution of AS-EXAMPLE-5 in addition to the exclusion of RIPE::AS-EXAMPLE-4, however no `members` or `src-members` attributes were found on AS-EXAMPLE-5 with these values.

The example shows that discovered exclusions do not apply across branches of the hierarchy. This MUST NOT be allowed by the software implementation. If allowed, the operator of an as-set or route-set would be able to influence their upstream or peer to exclude objects they are not responsible for.

# Backwards Compatibility

{{Section 2 of RFC2622}} defines syntax which allows for finer grained inclusion and exclusion of IP prefix ranges in the `(mp-)members` attribute of a route-set (i.e., `^-`, `^+`, `^n`, and `^n-m`). It could be possible to introduce similar style syntax to the existing `(mp-)members` attributes, which would match and include or exclude aut-num, as-set, and route-set primary keys. This breaks backwards compatibility though. Existing IRR implementations or tooling which parses IRR data, which has not been updated to include such changes to the existing attributes, would break when encountering data from an implementation which has been updated which returns data using these new syntax options.

The behaviour of RPSL compliant software is to ignore unrecognised attributes. This means that adding the exclusion logic defined in this document, based on the contents of a new attribute, has no impact when existing IRR software implementations process an object with the new attribute defined.

Although not related to the ability to retain backwards compatibility for parsing data, there is a breaking change introduced by this document in relation to the data returned from an IRR implementation which has implemented the defined changes. The returned data from two IRR resolvers, with the exact same database, and one of the resolvers uses software which has not implemented the changes introduced in this document, would not be the same. Therefore, for consumers of the returned data, the presence of the `excl-members` attribute indicates that data may have been excluded, if any matches to the excluded primary keys were found during the resolving process.

# Security Considerations

This document adds the ability to specify that IRR derived prefix and AS path filter lists may exclude specific entries, which may be the cause of security issues, that are presently included by the existing greedy inclusion logic.

It is possible that the operator of an including set includes the wrong primary key in the `excl-members` attribute. However, this is not a new issue, it has long been possible to include the unintended primary keys in set objects. This document doesn't change this existing behaviour. It does limit the scope of the unintended inclusion by requiring registry scoped keys only in the `excl-members` attribute.

Great progress has been made with the deployment of Route Origin Authorizations (ROAs) as defined in {{RFC9582}}, and the ongoing development of Autonomous System Provider Authorization (ASPA) objects as defined in {{draft-ietf-sidrops-aspa-verification}}. The method proposed in this document is intended to complement those existing developments, further enriching the operator toolkit, and not work against them or be mutually exclusive.

--- back
