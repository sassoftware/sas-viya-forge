window.MathJax = {
  tex: {
    inlineMath: [["\\(", "\\)"]],
    displayMath: [["\\[", "\\]"]],
    processEscapes: true,
    processEnvironments: true
  },
  options: {
    ignoreHtmlClass: ".*|",
    processHtmlClass: "arithmatex"
  }
};

document$.subscribe(() => {
  document.querySelectorAll(".md-sidebar--secondary .md-ellipsis").forEach((element) => {
    element.classList.add("arithmatex");
  });

  const elements = [
    document.querySelector(".md-content"),
    document.querySelector(".md-sidebar--secondary")
  ].filter((element) => element);

  MathJax.typesetPromise(elements);
});
