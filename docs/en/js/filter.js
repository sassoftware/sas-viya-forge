let minimumYear = 2024;
let minimumMonth =  1;

document.addEventListener("DOMContentLoaded", function() {
  fetch('search_index.json')
    .then(response => response.json())
    .then(data => {
      const typeTags = new Set();
      const guideTags = new Set();
      const pillarTags = new Set();
      const topicTags = new Set();
      const providerTags = new Set();

      const docs = data.docs.filter(doc => !doc.location.includes("#"))
      
      const pages = docs.map(doc => {
        const pageTags = doc.tags || [];
        pageTags.forEach(tag => {
          if (tag == "Reference Architecture") {
            typeTags.add("Reference Architecture");
          } else if (tag == "Best Practice") {
            typeTags.add("Best Practice");
          } else if (tag.startsWith("Guide")) {
            typeTags.add("Guide")
            guideTags.add(tag);
          } else if (tag.startsWith("Pillar")) {
            pillarTags.add(tag);
          } else if (tag.startsWith("Topic")) {
            topicTags.add(tag);
          } else if (tag.startsWith("Infrastructure Provider")) {
            providerTags.add(tag);
          }
        });
        return { title: doc.title, tags: pageTags, url: doc.location };
      });

      versions = generateVersions(minimumYear, minimumMonth, new Date().getFullYear(), new Date().getMonth() + 1);
      const versionTags = new Set(versions);

      populateDropdown("type", "type-tags", typeTags);
      populateDropdown("guide", "guide-tags", guideTags);
      populateDropdown("pillar", "pillar-tags", pillarTags);
      populateDropdown("topic", "topic-tags", topicTags);
      populateDropdown("provider", "provider-tags", providerTags);
      populateDropdown("version", "version", versionTags);

      // Initialize Select2
      $('#type-tags').select2();
      $('#guide-tags').select2();
      $('#pillar-tags').select2();
      $('#topic-tags').select2();
      $('#provider-tags').select2();
      $('#version').select2();

      window.pages = pages; // Store pages globally for filtering
    });
});

function generateVersions(startYear, startMonth, endYear, endMonth) {
  const versions = [];

  for (let year = startYear; year <= endYear; year++) {
      const finalMonth = (year === endYear) ? endMonth : 12;
      for (let month = (year === startYear) ? startMonth : 1; month <= finalMonth; month++) {
          const version = `${year}.${month.toString().padStart(2, '0')}`;
          versions.push(version);
      }
  }

  return versions;
}

function populateDropdown(selector, dropdownId, tags) {
  const select = document.getElementById(dropdownId);
  
  const option = document.createElement("option");
  option.selected = true;
  option.value = "None"
  option.text = "Select " + selector;
  select.appendChild(option)

  tags.forEach(tag => {
    const option = document.createElement("option");
    option.value = tag;
    if (tag.includes("-")) {
      option.text = tag.split("-")[1];
    } else {
      option.text = tag
    }
    
    select.appendChild(option);
  });
}

function filterPages() {
  const selectedTypeOptions = Array.from(document.getElementById("type-tags").selectedOptions);
  const selectedGuideOptions = Array.from(document.getElementById("guide-tags").selectedOptions);
  const selectedPillarOptions = Array.from(document.getElementById("pillar-tags").selectedOptions);
  const selectedTopicOptions = Array.from(document.getElementById("topic-tags").selectedOptions);
  const selectedProviderOptions = Array.from(document.getElementById("provider-tags").selectedOptions);

  const selectedTypeTags = selectedTypeOptions.filter(option => option.value != "None").map(option => option.value);
  const selectedGuideTags = selectedGuideOptions.filter(option => option.value != "None").map(option => option.value);
  const selectedPillarTags =selectedPillarOptions.filter(option => option.value != "None").map(option => option.value);
  const selectedTopicTags = selectedTopicOptions.filter(option => option.value != "None").map(option => option.value);
  const selectedProviderTags = selectedProviderOptions.filter(option => option.value != "None").map(option => option.value);

  const selectedTags = [...selectedTypeTags,...selectedGuideTags, ...selectedPillarTags, ...selectedTopicTags, ...selectedProviderTags];

  const resultsDiv = document.getElementById("search-results");
  resultsDiv.innerHTML = ""; // Clear previous results
  resultsDiv.appendChild(document.createElement("h2")).textContent = "Search Results";

  // Get all pages that meet the selected tags
  var taggedPages = [];
  if (selectedTags.length > 0) {
    taggedPages = window.pages.filter(page => selectedTags.every(tag => page.tags.some(pageTag => pageTag.startsWith(tag))));
  }

  const selectedVersion = document.getElementById("version").value;
  const selectedYear = parseInt(selectedVersion.split(".")[0])
  const selectedMonth = parseInt(selectedVersion.split(".")[1])

  // Find all pages that have a Valid From version before the selected version
  const allowedFromVersions = generateVersions(minimumYear, minimumMonth, selectedYear, selectedMonth)
  const minVersionedTaggedPages = taggedPages.filter(page => allowedFromVersions.some(version => page.tags.includes("Valid From - " + version)));

  // Filter out any pages that have a Valid To tag that is not allowed (past the selected version)
  const notAllowedToVersions = generateVersions(minimumYear, minimumMonth, selectedYear, selectedMonth - 1)
  const versionedTaggedPages = minVersionedTaggedPages.filter(page => !notAllowedToVersions.some(version => page.tags.includes("Valid To - " + version)));

  versionedTaggedPages.forEach(page => {
    const pageElement = document.createElement("a");
    pageElement.href = "../" + page.url;
    pageElement.textContent = page.title;
    pageElement.className = "result-tile";
    resultsDiv.appendChild(pageElement);
  });
}