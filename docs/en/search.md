---
title: Search
---

# Search

All artifacts in the Viya Forge repository contain at least three tags that organize them by the type of Guide, the Pillar and the Topic.
By using the selection options below you can find all artifacts that match the selected tags.

Select at least your Viya version and one of the other tags to see the results.

You can also use the global search functionality by pressing the forward-slash button on your keyboard or clicking in the search bar at the top of the screen.
The global search functionality searches through the entire site for any occurrence of the provided string.

!!! note

    Can't find what you need? You can contribute to Viya Forge using the instructions on our [Contribute](../../contributing.md) page.
    You can also request a new document by creating a [new Issue](https://github.com/sassoftware/sas-viya-forge/issues/new/choose) in our GitHub project or vote for an [existing request](https://github.com/sassoftware/sas-viya-forge/issues).

<div id="search-container" class="md-typeset">
    <h2>Search Options</h2>
    <div id="search-option-row">
        <div id="tag-filter" class="md-typeset">
            <label for="type-tags">Type:</label>
            <select id="type-tags" class="md-input" onchange="filterPages()" placeholder="Select type"></select>
        </div>
        <div id="tag-filter" class="md-typeset">
            <label for="guide-tags">Guide:</label>
            <select id="guide-tags" class="md-input" onchange="filterPages()"></select>
        </div>
        <div id="tag-filter" class="md-typeset">
            <label for="pillar-tags">Pillar:</label>
            <select id="pillar-tags" class="md-input" onchange="filterPages()"></select>
        </div>
    </div>
    <div id="search-option-row">
        <div id="tag-filter" class="md-typeset">
            <label for="topic-tags">Topic:</label>
            <select id="topic-tags" class="md-input" onchange="filterPages()"></select>
        </div>
        <div id="tag-filter" class="md-typeset">
            <label for="provider-tags">Provider:</label>
            <select id="provider-tags" class="md-input" onchange="filterPages()"></select>
        </div>
        <div id="tag-filter" class="md-typeset">
            <label for="version">Version:</label>
            <select id="version" class="md-input" onchange="filterPages()"></select>
        </div>
    </div>
</div>

<div id="search-results">
    <h2>Search Results</h2>
    <!-- Filtered results will be displayed here -->
</div>

<script src="../js/filter.js"></script>