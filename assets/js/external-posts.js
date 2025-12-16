function applyNewTabToPostLinks() {
  const links = document.querySelectorAll("a[href]");

  links.forEach(link => {
    const href = link.getAttribute("href");
    if (!href) return;

    const isPostLink =
      href.includes("/posts/") ||
      href.match(/\/\d{4}-\d{2}-\d{2}_/) ||
      href.startsWith("posts/") ||
      href.startsWith("../posts/");

    if (isPostLink && !link.hasAttribute("data-newtab")) {
      link.setAttribute("target", "_blank");
      link.setAttribute("rel", "noopener");
      link.setAttribute("data-newtab", "true"); // prevent reprocessing
    }
  });
}

// Run once on initial load
document.addEventListener("DOMContentLoaded", applyNewTabToPostLinks);

// Observe DOM changes (pagination, filtering, etc.)
const observer = new MutationObserver(() => {
  applyNewTabToPostLinks();
});

observer.observe(document.body, {
  childList: true,
  subtree: true
});
