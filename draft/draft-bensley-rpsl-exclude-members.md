---
stand_alone: true
title: Explicitly excluding objects from RPSL sets
abbrev: Explicitly excluding objects from RPSL sets
docname: draft-bensley-rpsl-exclude-members-00
date: 2025-3-24
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

This document updates {{RFC2622}} and {{RFC4012}} by defining the `excl-members` attribute on as-set and route-set classes in the Routing Policy Specification Language (RPSL). This new attribute allows operators to overcome limitations of the existing syntax, which currently only supports the implicit inclusion of everything contained within an as-set or route-set.

--- middle

# Introduction

The Routing Policy Specification Language (RPSL) {{RFC2622}} defines the as-set and route-set classes. These sets can either reference a direct member of the set (such as an AS number, IP prefix, etc.), or additional sets which themselves have their own direct members and/or reference yet more sets, ad infinitum. Server and client software can follow these references to recursively resolve all the members of a set i.e., until all references have been resolved leaving a set of prefixes or ASes.

## Existing Methods of Inclusion

The existing RPSL syntax allows for members of an as-set or route-set to be specified in multiple ways:

1. {{RFC2622}} defines the `members` attribute.
    1. {{Section 5.1 of RFC2622}} defines that for an as-set this attribute stores one or more primary keys, each referencing an aut-num or or as-set object.
    1. {{Sections 5.2 and 5.3 of RFC2622}} and  defines that for a route-set this attribute may store one or more primary keys, each referencing a route-set object which optionally has a range operator appended, an aut-num, or an as-set. Alternatively, the `members` attribute on a route-set may store an IPv4 address prefix range directly i.e., not an RPSL primary key that points directly to route object, and that prefix range is used to identify matching route objects. That address prefix range may optionally have a range operator appended.
1. {{Section 4.2 of RFC4012}} defines the `mp-members` attribute for route-sets. This attribute may store one or more primary keys, each referencing a route-set object which optionally has a range operator appended, or an IPv4 address prefix range directly, or an IPv6 address prefix range directly. Although not explicitly stated in RFC4012, implementations of the `mp-members` attributes have based it on the RFC2622 definition and allowed the attribute to also store the RPSL primary key of aut-nums and as-sets.
1. {{RFC2622}} defines the `mbrs-by-ref` and `member-of` attributes.
    1. {{Section 5.1 of RFC2622}} defines that for an as-set these attributes allow for the inclusion of aut-nums in the as-set, iff the criteria defined in the RFC linking both attributes together is met.
    1. {{Section 5.2 of RFC2622}} defines that for a route-set these attributes allow for the inclusion of routes in the route-set, iff the criteria defined in the RFC linking both attributes together is met.
1. {{Section 3 of RFC4012}} defines the router6 class along with the `member-of` attribute on that class, and as a result, allows for the inclusion of route6 objects in a route-set, iff the criteria relating to `mbrs-by-ref` and `member-of` attributes defined in {{Section 5.2 of RFC2622}} is met.

When using the `(mp-)members` attribute to include an as-set or route-set (hereinafter the "included set") inside another as-set or route-set (hereinafter the "including set"), all members of the included set are included in the including set. This is not limited to the members directly nested inside the included set, but all members recursively included all the way down the RPSL hierarchy. This implicit recursive inclusion logic is herein referred to as "greedy" logic.

In the figure below, the as-set `AS-EXAMPLE-1` only includes one member but, as a result of that single inclusion, AS-EXAMPLE-1 now contains the aut-nums AS65001, AS65002, and AS65003:

~~~~ rpsl
as-set: AS-EXAMPLE-1
members: AS-EXAMPLE-2

as-set: AS-EXAMPLE-2
members: AS65001, AS65002, AS-EXAMPLE-3

as-set: AS-EXAMPLE-3
members: AS65003
~~~~
{: title='A three level hierarchy is created even though AS-EXAMPLE-1 only includes one additional as-set'}

The same inclusion logic applies to a route-set which references another route-set, as-set, or aut-num, in the `members` attribute; everything inside the included set, all the way down the recursed tree, is implicitly included into the including set.

Similarly greedy logic also applies to prefixes too; the `(mp-)members` attribute of a route-set includes any route/route6 objects which match the IPv4/6 address prefix range and optional range operator.

## Existing Methods of Exclusion

The filter-set class and `filter` attribute are defined in {{Section 5.4 of RFC2622}}. Correspondingly, the `mp-filter` attribute was later defined in {{Section 2.5.2 of RFC4012}}. Together these attributes provide a method for declaring in the IRR ecosystem the prefixes a network will not accept.

Additionally, the `(mp-)filter` attribute may be used to exclude route/route6 objects which have been included by the greedy logic of the `(mp-)members` attribute of a route-set. This is achieved by first including all route/route6 objects which match the IPv4/6 address prefix range and optional range operator in the `(mp-)members` attribute on the route-set, and then removing any route/route6 objects from this result which match the IPv4/6 address prefix range and optional range operator in the `(mp-)members` attribute of the filter-set.

For as-sets and route-sets which use the `mbrs-by-ref` and `member-of` attributes, both attributes have to contain corresponding values. This already reduces the greediness of the inclusion logic. It is also already possible to further reduce the greediness. This can be achieved by changing the value of `mbrs-by-ref` from ANY to a list of specific values, and/or by removing the as-set or route-set primary key from the `members-of` attribute of an aut-num or route/route6 object.

There is currently no method to exclude either an aut-num, an as-set, or a route-set, which was included by the greedy logic of the `(mp-)members` attribute of an as-set or route-set object.

## The Need for Additional Exclusion Control

The existing greedy logic of the `(mp-)members` attribute of as-sets and route-sets, coupled with the inability to alter this logic, can result in various undesired effects for operators. A non-exhaustive list of possible undesirable outcomes follows:

1. A member is added to a set which is not connected to or related to the network operated by the owner of the including set. This allows the including set owner to originate prefixes they aren't authorised to originate. Upstreams and peers of the network owning the including set, aren't able to generate an IRR derived prefix or AS path filter which excludes the unauthorised included set. Note that this can happen anywhere in the set hierarchy; the unauthorised include may be nested many levels down within the including set used by a peer or upstream, making it difficult to get included set removed.

1. A member is added to a set which creates a loop when the set is resolved (set A contains set B which contains set A). This can lead to IRR derived prefix or AS path filters either massively expanding in size, or simply not being resolvable.

1. A member is added to a set, that set is intended to contain a network's downstreams, but the included set relates to a peer or upstream, not a downstream. The operator of the including set now becomes a transit provider for the operator of the included set. This can also lead to IRR derived prefix or AS path filters massively expanding in size.

1. A member is added to a set which relates to an operator who's actions violate a law, a geo-political agreement, or the connectivity terms and conditions, of a peer or upstream of the including set operator. The peer or upstream has no choice but to exclude the included set from their peer's or downstream's IRR derived prefix or AS path filters. However, this currently requires a custom and potentially manual workaround, as there is no standard mechanism to support this in an automated manor.

1. A member is added to a set with whom a peer or upstream of the including set operator already has a direct relation. A regulatory requirement may restrict the peer or upstream from exchanging traffic with the operator of the included set via the including set operator, or via any 3rd party operator.

This document updates the RPSL definition in {{RFC4012}} by introducing the `excl-members` attribute, which allows the including set operator to exclude aut-nums, as-sets, and route-sets, from the included set, or exclude the included set entirely.

## Requirements Language

{::boilerplate bcp14-tagged}

## Terminology

In this document, the key words "MUST", "MUST NOT", "REQUIRED",
"SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY",
and "OPTIONAL" are to be interpreted as described in BCP 14, RFC 2119
{{RFC2119}}.

# The `excl-members` Attribute

The `excl-members` attribute is defined for the as-set class and route-set class.

## The as-set Class

The new `excl-members` attribute on the as-set class uses almost exactly the same syntax as the existing `members` attribute from {{Section 5.1 of RFC2622}}, in that one or more RPSL primary keys of an aut-num or as-set may be specified. The only difference is that when an as-set is specified in `excl-members`, the as-set primary key MUST be prefixed with a registry name and a double colon (e.g., `SOURCE::`). This requirement is to ensure that the correct object is being excluded due to the inherent ambiguity of as-set primary keys in the existing IRR ecosystem (as documented in {{draft-romijn-grow-rpsl-registry-scoped-members}}).

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

The new `excl-members` attribute on the route-set class uses similar syntax as the existing `members` attribute from {{Sections 5.2 and 5.3 of RFC2622}}, in that one or more RPSL primary keys of an aut-num, an as-set, or route-set may be specified. What is different is that `excl-members` doesn't accept IPv4/6 address prefix ranges because they can already be filtered using a filter-set. In the case that an as-set or route-set is specified in `excl-members`, the set primary key MUST be prefixed with a registry name and a double colon (e.g., `SOURCE::`). This requirement is to ensure that the correct object is being excluded due to the inherent ambiguity of as-set and route-set primary keys in the existing IRR ecosystem (as documented in {{draft-romijn-grow-rpsl-registry-scoped-members}}).

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

When an authoritative IRR registry processes an as-set or route-set object with the `excl-members` attribute present, it MUST validate the contents of the attribute.

### Registry Scoped Keys Only

All primary keys in `excl-members` MUST have a registry scope provided with the exception of an AS number.

By requiring registry scoped as-set and route-set keys to be used in the `excl-members` attribute, it becomes possible to have multiple references to the same RPSL primary key. This is not permitted, and IRR registry software MUST reject this:

~~~~ rpsl
excl-members: RIPE::AS-EXAMPLE, ARIN::AS-EXAMPLE
~~~~
{: title='Invalid object fragment using multiple registry prefixes with the same RPSL primary key'}

The IRR registry software MUST verify that without their registry prefix, all references from `excl-members` are unique.

If allowed, the attribute `excl-members: RIPE::AS-EXAMPLE, ARIN::AS-EXAMPLE` would refer to two different set objects, whereas the `(mp-)members` attribute can only contain one instance of `AS-EXAMPLE`, which is ambiguous as to which set this refers to when sets exist in multiple registries with the same primary key.

Similarly, the IRR software MUST NOT allow for the registry scopes in the `excl-members` attribute and the `src-members` attribute to be mixed, when both attributes are populated on the same set object, and when they referencing the same primary key with the registry scope removed.

~~~~ rpsl
member: AS-EXAMPLE
src-members: ARIN::AS-EXAMPLE
excl-members: RIPE::AS-EXAMPLE
~~~~
{: title='Invalid object fragment using different registry prefixes with the same RPSL primary key across attributes'}

If allowed, due to the presence of the `src-members` attribute, ARIN::AS-EXAMPLE is included instead of AS-EXAMPLE (`src-members` is taking preference over `members`), and the `excl-members` attribute value RIPE::AS-EXAMPLE wouldn't match the `src-members` value.

### Any Primary Key and Registry Scope

The IRR software MUST NOT require that the primary key of an entry in the `excl-members` attribute is a direct member of the object being updated. The `excl-members` attribute is used to exclude objects anywhere in the hierarchy, starting from the point of definition.

The IRR software MUST NOT require that the registry scope which precedes the object primary key, is a registry the IRR software knows to be a valid registry. An authoritative IRR server may have it's content mirrored to resolver IRR servers, which have visibility of many more registries.

# Exclusion Logic

## The as-set Class

When the `excl-members` attribute is populated on an as-set object, the primary keys stored in the attribute reference aut-nums or as-sets that MUST NOT be resolved when recursively resolving the members of that as-set object.

1. This exclusion applies to the `members` attribute of the as-set object which has the `excl-members` attribute populated, and the `members` attribute of all recursively resolved as-sets within that set. Because the RPSL primary keys stored in the `excl-members` attribute have a registry scope prepended, the primary keys in the `members` attribute MUST be checked against all keys in the `excl-members` attribute with the registry scope removed.
1. This exclusion applies to the `src-members` attribute (as defined in {{draft-romijn-grow-rpsl-registry-scoped-members}}) of the as-set object which has the `excl-members` attribute populated, and the `src-members` attribute of all recursively resolved as-sets within that set. In this case the registry scoped RPSL primary keys in `src-members` MUST match a registry scoped key in `excl-members` exactly, without the registry scope having being removed from either of the two keys being compared.
1. If both `members` and `src-members` are defined on an as-set object, and the same key exists in both attributes when the registry scope is removed from the `src-members` entry, the key from `src-members` with the registry scope prepended MUST be compared against all entries in `excl-members`. Matching keys in `src-members` takes precedence over matching keys in `members`.

The figure below shows IRR data in its raw an unresolved state:

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
{: title='An example as-set hierarchy, in it's unresolved state'}

The figure below shows the result of resolving the members of set `AS-EXAMPLE-1` when the `excl-members` logic is applied:

~~~~ rpsl
as-set: AS-EXAMPLE-1
members: AS65001, AS65003
~~~~
{: title='AS-EXAMPLE-1 in it's resolved state with exclusions applied'}

* It can be seen that `excl-members` took effect on the object it was defined, not just it's descendants. This is shown by AS65002 not being included in the final result because AS65002 is both a `member` _and_ `excl-members` of AS-EXAMPLE-2.
* AS-EXAMPLE-4 is excluded even though AS-EXAMPLE-4 is defined in ARIN and RIPE::AS-EXAMPLE-4 is specified in `excl-members` on AS-EXAMPLE-2. This is because the AS-EXAMPLE-4 entry in the `members` attribute of AS-EXAMPLE-3 is ambiguous, but a `src-members` attribute has been defined which takes precedence over `members`. The exclusion is applied against the `src-members` attribute of AS-EXAMPLE-3 (which may be an as-set not displayed here or a non-existing set).

## The route-set Class

When the `excl-members` attribute is populated on a route-set object, the primary keys stored in the attribute reference aut-nums, or as-sets, or route-sets, that MUST NOT be resolved when recursively resolving the members of that route-set object.

1. This exclusion applies to the `(mp-)members` attributes of the route-set object which has the `excl-members` attribute populated, and the `(mp-)members` attributes of all recursively resolved route-sets and as-sets within that route-set. Because the RPSL primary keys stored in the `excl-members` attribute have a registry scope prepended, the primary keys in the `(mp-)members` attributes MUST be checked against all keys in `excl-members` attribute with the registry scope removed.
1. This exclusion applies to the `src-members` attribute (as defined in {{draft-romijn-grow-rpsl-registry-scoped-members}}) of the route-set object which has the `excl-members` attribute populated, and the `src-members` attribute of all recursively resolved route-sets and as-sets within that route-set. In this case the registry scoped RPSL primary keys in `src-members` MUST match a registry scoped key in `excl-members` exactly, without the registry scope having being removed from either of the two keys being compared.
1. If both `(mp-)members` and `src-members` are defined on a route-set object, and the same key exists in both attributes when the registry scope is removed from the `src-members` entry, the key from `src-members` with the registry scope prepended MUST be compared against all entries in `excl-members`. Matching keys in `src-members` takes precedence over matching keys in `(mp-)members`.

The figure below shows IRR data in its raw an unresolved state:

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
{: title='An example route-set hierarchy, in it's unresolved state'}

The figure below shows the result of resolving the members of set `RS-EXAMPLE-1` when the `excl-members` logic is applied:

~~~~ rpsl
as-set: RS-EXAMPLE-1
members: 192.0.2.0/25, 2001:db8::/33, 192.0.2.128/25
~~~~
{: title='RS-EXAMPLE-1 in it's resolved state with exclusions applied'}

* It can be seen that `excl-members` took effect on the object it was defined on, not just it's descendants. This is shown by 2001:db8:8000::/33 not being included in the final result because RS-EXAMPLE-4 is both a `member` _and_ `excl-members` of RS-EXAMPLE-2.
* Even though RS-EXAMPLE-4 is excluded by RS-EXAMPLE-2, it was also included by RS-EXAMPLE-3, but still 2001:db8:8000::/33 is excluded. This shows that the exclusion logic applies from the point in the hierarchy where it is defined, all the way down, taking precedence over any subsequent includes.
* RS-EXAMPLE-4 is excluded even though RS-EXAMPLE-4 is defined in ARIN and RIPE::RS-EXAMPLE-4 is specified in `excl-members` on RS-EXAMPLE-2. This is because the AS-EXAMPLE-4 entry in the `(mp-)members` attribute of RS-EXAMPLE-3 is ambiguous due to the lack of `src-members` attribute on RS-EXAMPLE-3. This means that the `excl-members` value RIPE::RS-EXAMPLE-4 has to be checked against the `members` attribute on RS-EXAMPLE-3 with the registry scope removed.

## Cumulative Excludes

As as-set or route-set objects are recursively resolved and `excl-members` attributes are discovered, the RPSL primary keys to be excluded need to be tracked. At any point in the hierarchy where `excl-members` is discovered, all `(mp-)members` and `src-members` attributes from that point onwards are subject to the `excl-members` which have been discovered so far. However, depending on the resolution algorithm being used by the resolving software i.e., a depth first search or breadth first search, multiple lists of RPSL keys to exclude may have to be maintained (the exact implementation details are outside the scope of this document).

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
{: title='An example as-set hierarchy, in it's unresolved state'}

The following figure shows the resolved members of as-set AS-EXAMPLE-1:

~~~~ rpsl
as-set: AS-EXAMPLE-1
members: AS65005
~~~~
{: title='AS-EXAMPLE-1 in it's resolved state with exclusions applied'}

1. The resolving process starts by resolving the members of AS-EXAMPLE-1.
1. If a depth first search approach is taken by the IRR software, AS-EXAMPLE-2 might be resolved next. AS-EXAMPLE-4 is not included due to the `excl-members` attribute defined on AS-EXAMPLE-1. This is being applied from the point of definition onwards, the resolving process inherited the currently defined list of excludes (RIPE::AS-EXAMPLE-4) when it moved on to resolve AS-EXAMPLE-2.
1. AS-EXAMPLE-2 defined a new `excl-members` attribute with the value RIPE::AS-EXAMPLE-5 however, there is nothing left to resolve in AS-EXAMPLE-2 so this exclusion has no effect.
1. Continuing the depth first search approach, the IRR software returns to AS-EXAMPLE-1, and uses the exclusion list as it existed whilst resolving AS-EXAMPLE1-1 (it contains only RIPE::AS-EXAMPLE-4), and now begins to resolve AS-EXAMPLE-3.
1. AS-EXAMPLE-3 includes AS-EXAMPLE-5. This is not excluded even though the IRR software has encountered an `excl-members` attribute which contains the value RIPE::AS-EXAMPLE-5. This is because that `excl-members` attribute was found on a different branch of the hierarchy.
1. Continuing the resolution process, resolving AS-EXAMPLE-5 returns AS65005 only. The exclusion of AS65006 defined on AS-EXAMPLE-3 was applied to the resolution of AS-EXAMPLE-5 in addition to the exclusion of RIPE::AS-EXAMPLE-4, however no `members` or `src-members` attributes were found on AS-EXAMPLE-5 with these values.

The example shows that discovered exclusions do not apply across branches of the hierarchy. This MUST NOT be allowed by the software implementation. If allowed, the operator of an as-set or route-set would be able to excluded objects from other sets they are not responsible for.

# Backwards Compatibility

The behaviour or RPSL compliant software is to ignore unrecognised attributes. This means that adding the exclusion logic defined in this document based on the contents of a new attribute has no impact when existing IRR software implementations process an object with the new attribute defined.

# IANA Considerations

This memo includes no request to IANA.

# Security Considerations

This document adds the ability to specify that IRR derived prefix and AS path filter lists may exclude specific entries, which may be the cause of security issue, that are presently included by the existing greedy logic.

It is possible that the operator of an including set includes the wrong primary key in the `excl-members` attribute. However, this is not a new issue, it has long been possible to include the unintended primary keys in set objects. This document doesn't change this existing behaviour.

Great progress has been made with the deployment of Route Origin Authorizations (ROAs) as defined in {{RFC9582}}, and the ongoing development of Autonomous System Provider Authorization (ASPA) objects as defined in {{draft-ietf-sidrops-aspa-verification}}. The method proposed in this document in intended to compliment those existing developments, further enriching the existing operator's toolkit, and not work against them or be mutually exclusive.

--- back
