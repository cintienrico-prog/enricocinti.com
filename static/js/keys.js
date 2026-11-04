// Keyboard shortcuts. The site works fully without this file.
//   h/a/p/t (or whatever config.toml `nav` sets) — go to page
//   j/k — move between publications / list entries
(() => {
  const nav = {};
  document.querySelectorAll("nav a[data-key]").forEach((a) => (nav[a.dataset.key] = a.href));

  const focusables = () =>
    Array.from(document.querySelectorAll("main summary, main .list a"));

  document.addEventListener("keydown", (ev) => {
    if (ev.ctrlKey || ev.metaKey || ev.altKey) return;
    const t = ev.target;
    if (t.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName)) return;

    if (nav[ev.key]) {
      window.location.href = nav[ev.key];
      return;
    }
    if (ev.key === "j" || ev.key === "k") {
      const items = focusables();
      if (!items.length) return;
      const i = items.indexOf(document.activeElement);
      const next = ev.key === "j" ? Math.min(i + 1, items.length - 1) : Math.max(i - 1, 0);
      items[i === -1 ? 0 : next].focus();
      ev.preventDefault();
    }
  });
})();
