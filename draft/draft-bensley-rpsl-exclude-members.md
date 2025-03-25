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

--- abstract

This document updates {{RFC2622}} and {{RFC4012}} by defining the `excl-members` attribute on as-set and route-set classes in the Routing Policy Specification Language (RPSL). This new attribute allows operators to overcome limitations of the existing syntax, which currently only supports the implicit inclusion of everything contained within an as-set or route-set.

--- middle

# Introduction

The Routing Policy Specification Language (RPSL) {{RFC2622}} defines the as-set and route-set classes. These sets can either reference a direct member of the set (such as an AS number, IP prefix, etc.), or additional sets which themselves have their own direct members and/or reference yet more sets, ad infinitum. Server and client software can follow these references to recursively resolve all the members of a set i.e., until all references have been resolved leaving a set of prefixes or ASes.

## Existing Methods of Inclusion

The existing RPSL syntax allows for members of an as-set or route-set to be specified in multiple ways:

1. {{RFC2622}} defines the `members` attribute.
    1. {{Section 5.1 of RFC2622}} defines that for an as-set this attribute stores one or more primary keys, each referencing an aut-num object or or as-set object.
    1. {{Section 5.2 of RFC2622}} defines that for a route-set this attribute may store one or more primary keys, each referencing a route-set object which optionally has a range operator appended. Alternatively, the `members` attribute on a route-set may store an IPv4 address prefix range directly i.e., not an RPSL primary key that points another route object, and that address prefix range may optionally have a range operator appended.
1. {{Section 4.2 of RFC4012}} defines the `mp-members` attribute for route-sets. This attribute may store one or more primary keys, each referencing a route-set object which optionally has a range operator appended, or an IPv4 address prefix range directly, or an IPv6 address prefix range directly.
1. {{RFC2622}} defines the `mbrs-by-ref` and `member-of` attributes.
    1. {{Section 5.1 of RFC2622}} defines that for an as-set these attributes allow for the inclusion of aut-nums in the as-set, iff the criteria defined in the RFC linking both attributes together is met.
    1. {{Section 5.2 of RFC2622}} defines that for a route-set these attributes allow for the inclusion of routes in the route-set, iff the criteria defined in the RFC linking both attributes together is met.
1. {{Section 3 of RFC4012}} defines the router6 class along with the `member-of` attribute on that class, and as a result, allows for the inclusion of route6 objects in a route-set, iff the criteria relating to `mbrs-by-ref` and `member-of` attributes defined in {{Section 5.2 of RFC2622}} is met.

When using the `(mp-)members` attribute to include an as-set or route-set (hereinafter the "included set") inside another as-set or route-set (hereinafter the "including set"), all members of the included set are included in the including set. This is not limited to the members directly nested inside the included set, but all members recursively included all the way down the RPSL hierarchy. This implicit recursive inclusion logic is hereon referred to as "greedy" logic.

In the example below, the as-set `AS-EXAMPLE-1` only includes one member but, as a result of that single inclusion, AS-EXAMPLE-1 now contains the aut-nums AS65001, AS65002, and AS65003:

~~~~ rpsl
as-set: AS-EXAMPLE-1
members: AS-EXAMPLE-2

as-set: AS-EXAMPLE-2
members: AS65001, AS65002, AS-EXAMPLE-3

as-set: AS-EXAMPLE-3
members: AS65003
~~~~
{: title='A three level hierarchy is created even though AS-EXAMPLE-1 includes only one additional as-set'}

The same inclusion logic applies to a route-set which references another route-set in the `members` attribute; everything inside the included set, all the way down the recursed tree, is implicitly included into the including set.

Similarly greedy logic also applies to prefixes too; the `(mp-)members` attribute of a route-set includes any route/route6 objects which match the IPv4/6 address prefix range and optional range operator.

## Existing Methods of Exclusion

The filter-set class and `filter` attribute are defined in {{Section 5.4 of RFC2622}}. Correspondingly, the `mp-filter` attribute was later defined in {{Section 2.5.2 of RFC4012}}. Together these attributes provide a method for declaring in the IRR ecosystem the prefixes a network will not accept.

Additionally, the `(mp-)filter` attribute may be used to exclude route/route6 objects which have been included by the greedy logic of the `(mp-)members` attribute of a route-set. This is achieved by first including all route/route6 objects which match the IPv4/6 address prefix range and optional range operator in the `(mp-)members` attribute on the route-set, and then removing any route/route6 objects from this result which match the IPv4/6 address prefix range and optional range operator in the `(mp-)members` attribute of the filter-set.

For as-sets and route-sets which use the `mbrs-by-ref` and `member-of` attributes, both attributes have to contain corresponding values. This already reduces the greediness of the inclusion logic. It is also already possible to further reduce the greediness. This can be achieved by changing the value of `mbrs-by-ref` from ANY to a list of specific values, and/or by removing the as-set or route-set primary key from the `members-of` attribute of an aut-num or route/route6 object.

There is currently no way to exclude either an aut-num, an as-set, or a route-set, which was included by the greedy logic of the `(mp-)members` attribute of an as-set or route-set object.

## Overinclusiveness

The existing greedy logic of the `(mp-)-members` attribute of as-sets and route-sets, coupled with the inability to alter this logic, leads to overinclusiveness. This can result in various undesired effects for operators. A non-exhaustive list of possible undesirable outcomes follows:

1. A member is added to a set which is not connected to or related to the network operated by the owner of the including set. This allows the including set owner to originate prefixes they aren't authorised to originate. Upstreams and peers of the network owning the including set, aren't able to generate an IRR based prefix filter which excludes the unauthorised included set. Note that this can happen anywhere in the set hierarchy, the unauthorised include may be nested many levels down within the set used by a peer or upstream, making it difficult for the peer/downstream to remove the included set. Also note that great progress has been made with the deployment of Route Origin Authorizations (ROAs) as defined in {{RFC9582}}, which makes this type of hijack more difficult however, this hasn't been resolved yet.

1. A member is added to a set which creates a loop when the set is resolved (set A contains set B which contains set A). This can lead to IRR derived prefix filters or AS path filters either massively expanding in size, or simply not being resolvable.

1. A member is added to a set, that set is intended to contain a networks downstreams, but the included set relates to a peer or upstream, not a downstream. The operator of the including set now becomes a transit provider for the operator of the included set. This can also lead to IRR derived prefix filters or AS path filters massively expanding in size.

1. A member is added to a set which relates to an operator who's actions violate a law or a geo-political agreement in the country of the peer or upstream of the including set operator. The peer or upstream has no choice but to exclude the included set from their peer's or downstream's IRR derived prefix or AS path filters. However, this currently requires a custom and potentially manual workaround, as there is no standard mechanism to support this in an automated manor.

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

The new `excl-members` attribute on the as-set class uses almost exactly the same syntax as the existing `members` attribute from {{Section 5.1 of RFC2622}}, in that one or more RPSL primary keys of an aut-num or as-set may be specified. The only difference is that when an as-set is specified in `excl-members`, the as-set name MUST be prefixed with a registry name and a double colon (e.g., `SOURCE::`). This requirement is to ensure that the correct object is being excluded due to the inherent ambiguity of as-set primary keys in the existing IRR ecosystem (as demonstrated in draft-romijn-grow-rpsl-registry-scoped-members).  ##### FIX LINK TO DRAFT

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

The new `excl-members` attribute on the route-set class uses similar syntax as the existing `members` attribute from {{Section 5.2 of RFC2622}}, in that one or more RPSL primary keys of an aut-num, an as-set, or route-set may be specified. What is different is that `excl-members` doesn't accept IPv4/6 address prefix ranges because they can already be filtered using a filter-set. In the case that an as-set or route-set is specified in `excl-members`, the set name MUST be prefixed with a registry name and a double colon (e.g., `SOURCE::`). This requirement is to ensure that the correct object is being excluded due to the inherent ambiguity of as-set and route-set primary keys in the existing IRR ecosystem (as demonstrated in draft-romijn-grow-rpsl-registry-scoped-members).  ##### FIX LINK TO DRAFT

{:vspace}
Attribute:
: `excl-members`

{:vspace}
Value:
: list of ([`registry-name`]::[`route-set-name`] or [`registry-name`]::[`as-set-name`] or [`as-number`] or [`registry-name`]::[`route-set-name`][`range-operator`])

{:vspace}
Type:
: optional, multi-valued

## Exclusion Logic

When the `excl-members` attribute is populated on an as-set object, the primary keys stored in the attribute define aut-nums and as-sets that MUST NOT be resolved when recursively resolving the members of that as-set object.

1. This exclusion applies to the `members` attribute of the object itself, and the members attribute of all recursively resolved sets. Because the set names are stored in the `excl-members` attribute with a registry scope prepended, the set names in `members` must be checked against all set names in `excl-members` with the registry scope removed.
1. This exclusion applies to the `src-members` attribute (as defined in draft-romijn-grow-rpsl-registry-scoped-members ##### FIX LINK TO DRAFT) of the object itself, and the members attribute of all recursively resolved sets. In this case the sets in `src-members` must match a set in `excl-members` exactly without removing the registry scope.


~~~~ rpsl
as-set: AS-EXAMPLE-1
members: AS-EXAMPLE-2

as-set: AS-EXAMPLE-2
members: AS65001, AS65002, AS-EXAMPLE-3

as-set: AS-EXAMPLE-3
members: AS65003
~~~~
{: title='XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx'}

# IANA Considerations {#IANA}

This memo includes no request to IANA.

# Security Considerations {#Security}

This document removes a potential security issue where routing
policy could be manipulated by maliciously creating set objects,
which could be used in favor of legitimate objects.

While not a new issue, references between set objects can be
circular, and software MUST detect such cases while resolving.
It is RECOMMENDED to also limit the depth or size of their resolving
to prevent excessive resource use.


--- back
