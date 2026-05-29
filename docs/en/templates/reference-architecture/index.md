---
title: "{{ DOCUMENT_TITLE }}"
tags:
  - Reference Architecture
  - Valid From - {{VALID_FROM}}
---

# {{ DOCUMENT_TITLE }}

{% include '{{ INTRODUCTION_LINK }}' %}

{% include '{{ SCENARIO_LINK }}' %}

{% include '{{ SOLUTION_LINK }}' %}

<!--
  Alternatively, you can use links instead of include statements if the sections in your document are long and having multiple pages provides a better reading experience. If you use this approach, make sure to use a top level title (# Title) on each page.

  - [Scenario]({{ SCENARIO_LINK }})
  - [Solution]({{ SOLUTION_LINK }})
-->

## Additional Resource
<!--- If there are any additional resources that are relevant to this Best Practice include them below: -->

- [NAME](LINK)