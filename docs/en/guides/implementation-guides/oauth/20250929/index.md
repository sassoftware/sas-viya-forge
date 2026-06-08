---
title: Using Viya APIs with OAuth clients
tags:
  - Topic - API
  - Topic - OAuth
  - Guide - Implementation
  - Pillar - Security
  - Valid From - 2025.02
---

# Using Viya APIs with OAuth clients

{% include 'guides/implementation-guides/oauth/20250929/introduction.md' %}

## API usage stages

Interaction with SAS Viya APIs can be divided in five different stages, of which the last two are optional. There are some closing remarks in the final sixth stage.

1. [Identification & Authentication](/sections/generic/implementation-guides/oauth/20250929/authentication_identification.md)
2. [Authorization and API Interaction](/sections/generic/implementation-guides/oauth/20250929/authorization_interaction.md)
4. [SAS Runtime usage](/sections/generic/implementation-guides/oauth/20250929/runtimes.md) (optional)
5. [External services usage](/sections/generic/implementation-guides/oauth/20250929/external-services.md) (optional)
6. [Closing Remarks](/sections/generic/implementation-guides/oauth/20250929/closing.md)

Depending on the type of API request that you want to make, different choices will have to be made during each of these phases. This document will discuss these phases in sequence.