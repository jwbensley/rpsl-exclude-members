---
stand_alone: true
title: Explicitly excluding RPSL objects from RPSL set objects
abbrev: Explicitly excluding RPSL objects from RPSL set objects
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

--- abstract

This document updates RFC2622 and RFC4012 by specifying `excl-members`, a new attribute on as-set and route-set objects in the Routing Policy Specification Language (RPSL). This new attribute enables the exclusion of objects from a set, which allows operators to overcome the implicit "include everything" approach of existing syntax.

--- middle

# Introduction

The Routing Policy Specification Language (RPSL) {{RFC2622}} defines the as-set and route-set objects. These sets can either reference a direct member of the set (such as an AS number, IP prefix, etc.), or additional sets which themselves have their own direct members and/or reference yet more sets, ad infinitum. Server and client software can follow these references to resolve a set down to its members, a set of prefixes or ASes.

The existing RPSL syntax allows for members of an as-set or route-set to be specified in multiple ways:

1. {{RFC2622}} defines the `members` attribute.
    1. {{Section 5.1 of RFC2622}} defines that for an as-set this attribute stores one or more primary keys, each referencing an aut-num object or or as-set object.
    1. {{Section 5.2 of RFC2622}} defines that for a route-set this attribute may store one or more primary keys, each referencing a route-set object which optionally has a range operator appended. Alternatively, the `members` attribute on a route-set may store an IPv4 address prefix range directly i.e., not the RPSL primary key that points a route object, and that address prefix range may optionally have a range operator appended.
1. {{Section 4.2 of RFC4012}} defines the `mp-members` attribute for route-sets. This attribute may store one or more primary keys, each referencing a route-set object which optionally has a range operator appended, or an IPv4 address prefix range directly, or an IPv6 address prefix range directly.
1. {{RFC2622}} defines the `mbrs-by-ref` and `member-of` attributes.
    1. {{Section 5.1 of RFC2622}} defines that for an as-set these attributes allow for the inclusion of aut-nums in the as-set, iff the criteria defined in the RFC is met.
    1. {{Section 5.2 of RFC2622}} defines that for a route-set these attributes allow for the inclusion of routes in the route-set, iff the criteria defined in the RFC is met.
1. {{Section 3 of RFC4012}} defines the router6 class along with the `member-of` attribute on that class, and as a result, allows for the inclusion of route6 objects in a route-set, iff the criteria relating to `mbrs-by-ref` and `member-of` attributes defined in {{Section 5.2 of RFC2622}} is met.

When using the `(mp)-members` attribute to include an as-set or route-set (hereinafter "included set") inside another as-set or route-set (hereinafter "including set"), all members of the included set are included in the including set. This is not just the members directly nested under the included set, but all members recursively included all the way down the RPSL hierarchy. This implicit recursive inclusion logic is hereon referred to as "greedy" logic.

In the example below, the as-set `AS-EXAMPLE-1` only includes one member but as a result of that single inclusion, AS-EXAMPLE-1 now contains the aut-nums AS65001, AS65002, and AS65003:

~~~~ rpsl
as-set: AS-EXAMPLE-1
members: AS65001, AS-EXAMPLE-2

as-set: AS-EXAMPLE-2
members: AS65002, AS-EXAMPLE-3

as-set: AS-EXAMPLE-3
members: AS65003
~~~~
{: title='A three level hierarchy is create even though AS-EXAMPLE-1 includes only one additional as-set'}

The same inclusion logic applies to a route-set which references another route-set in the `members` attribute; everything inside the included set, all the way down the recursed tree, is implicitly included into the including set.

Similarly greedy logic also applies to prefixes too; the `(mp)-members` attribute of a route-set includes any route/route6 objects which match the IPv4/6 address prefix range and the optional range operator.

There is a slight difference with IP prefixes though. Filters and the filter-set class are defined in {{Section 5.4 of RFC2622}}. Correspondingly, the `mp-filter` attribute was later defined in {{Section 2.5.2 of RFC4012}}. Together these attributes provide a way for filtering prefixes which may have been included by the greedy logic of the `(mp)-members` attributes.

There is currently no way to exclude either an as-set, an aut-num, or a route-set, which was included by the greedy logic of the `members` attribute on an as-set or route-set.

## Requirements Language

{::boilerplate bcp14-tagged}

## Terminology

In this document, the key words "MUST", "MUST NOT", "REQUIRED",
"SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY",
and "OPTIONAL" are to be interpreted as described in BCP 14, RFC 2119
{{RFC2119}}.

# Exclusion Rule


