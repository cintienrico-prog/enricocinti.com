// The "On this page" / "Contents" column: marks the section being read.
// On list pages (publications, teaching) it also builds the list, from the page's
// sections (main .panel[id] > .panel-title); paper pages come with the list already
// made from the paper's table of contents. Without JS that column stays hidden on
// list pages and is a plain list of links on paper pages.
(() => {
  const aside = document.querySelector("aside.outline");
  if (!aside) return;

  if (!aside.querySelector("a[href^='#']")) {
    const sections = Array.from(document.querySelectorAll("main .panel[id]"));
    if (sections.length < 2) return;
    const list = aside.querySelector("ol");
    for (const s of sections) {
      const title = s.querySelector(".panel-title");
      const li = document.createElement("li");
      const a = document.createElement("a");
      a.href = "#" + s.id;
      a.textContent = title ? title.textContent : s.id;
      li.append(a);
      list.append(li);
    }
    aside.hidden = false;
  }

  // Each link with the element it points to, in page order.
  const pairs = Array.from(aside.querySelectorAll("a[href^='#']"))
    .map((a) => [a, document.getElementById(decodeURIComponent(a.hash.slice(1)))])
    .filter(([, el]) => el);
  if (!pairs.length) return;

  // The current one is the last whose top has scrolled past a line near the top of the window.
  const mark = () => {
    const line = window.innerHeight * 0.3;
    let current = pairs[0][0];
    for (const [a, el] of pairs) if (el.getBoundingClientRect().top <= line) current = a;
    if (window.innerHeight + window.scrollY >= document.body.scrollHeight - 2) current = pairs[pairs.length - 1][0];
    for (const [a] of pairs) a.classList.toggle("active", a === current);
  };
  let queued = false;
  window.addEventListener("scroll", () => {
    if (queued) return;
    queued = true;
    requestAnimationFrame(() => { queued = false; mark(); });
  }, { passive: true });
  mark();
})();
