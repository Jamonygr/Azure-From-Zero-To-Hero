(() => {
  "use strict";
  const storageKey = "azureZeroToHeroLearnerProgress.v1";
  const version = "1.0.0";
  const courseId = "azure-from-zero-to-hero";
  const ids = Array.from({ length: 31 }, (_, i) => `CLZ-${String(90 + i * 10).padStart(3, "0")}`);
  const fields = ["status", "exerciseComplete", "cleanupComplete", "assessmentScore", "updatedAt"];
  const date = (value) => typeof value === "string" && /^\d{4}-\d{2}-\d{2}T/.test(value) && !Number.isNaN(Date.parse(value));
  const fresh = () => ({ schemaVersion: version, courseId, exportedAt: new Date().toISOString(), labs: Object.fromEntries(ids.map((id) => [id, { status: "not-started", exerciseComplete: false, cleanupComplete: false, assessmentScore: null, updatedAt: new Date().toISOString() }])) });
  function validateRecord(record) {
    if (!record || typeof record !== "object" || Array.isArray(record) || record.schemaVersion !== version || record.courseId !== courseId || !date(record.exportedAt)) throw new Error("Use this course's version 1.0.0 progress export.");
    if (Object.keys(record).sort().join() !== ["schemaVersion", "courseId", "exportedAt", "labs"].sort().join()) throw new Error("Unexpected progress fields. Identity, state, and credential data are never accepted.");
    if (!record.labs || Object.keys(record.labs).sort().join() !== [...ids].sort().join()) throw new Error("The export must contain exactly this course's 31 lessons.");
    for (const id of ids) {
      const entry = record.labs[id];
      if (!entry || Object.keys(entry).sort().join() !== [...fields].sort().join() || !["not-started", "in-progress", "complete"].includes(entry.status) || typeof entry.exerciseComplete !== "boolean" || typeof entry.cleanupComplete !== "boolean" || !date(entry.updatedAt) || !(entry.assessmentScore === null || Number.isInteger(entry.assessmentScore) && entry.assessmentScore >= 0 && entry.assessmentScore <= 100)) throw new Error(`Invalid progress for ${id}.`);
    }
    return record;
  }
  let warning = "";
  function readRecord(strict = false) {
    try { const value = localStorage.getItem(storageKey); return value ? validateRecord(JSON.parse(value)) : fresh(); }
    catch { warning = "Saved progress is unavailable or invalid. Export a backup if available; new changes require working browser storage."; if (strict) throw new Error(warning); return fresh(); }
  }
  function writeRecord(record) {
    validateRecord(record);
    localStorage.setItem(storageKey, JSON.stringify(record));
    window.dispatchEvent(new Event("zth-progress-changed"));
    return record;
  }
  function update(id, action) {
    if (!ids.includes(id)) throw new Error("Unknown lesson.");
    const record = readRecord(true);
    action(record.labs[id]);
    record.labs[id].updatedAt = new Date().toISOString();
    record.exportedAt = record.labs[id].updatedAt;
    return writeRecord(record);
  }
  function saveAssessmentScore(id, score) {
    if (id === "CLZ-090" || !Number.isInteger(score) || score < 0 || score > 100) throw new Error("Invalid assessment score.");
    return update(id, (entry) => { entry.assessmentScore = score; });
  }
  window.zthProgress = Object.freeze({ storageKey, validateRecord, readRecord, saveAssessmentScore, emptyRecord: fresh });
  const element = (tag, value, className) => { const e = document.createElement(tag); if (value) e.textContent = value; if (className) e.className = className; return e; };
  const button = (text, action) => { const b = element("button", text); b.type = "button"; b.addEventListener("click", action); return b; };

  function renderLesson(container) {
    if (container.dataset.ready) return;
    container.dataset.ready = "true";
    const id = container.dataset.zthLesson;
    const card = element("section", "", "zth-progress-card");
    card.setAttribute("aria-label", `${id} self-reported progress`);
    card.append(element("h2", "Your lesson progress"), element("p", "Exercise and cleanup completion are self-reported. Verify the lesson results in Terraform and Azure before recording them."));
    const status = element("p"); status.setAttribute("role", "status"); status.setAttribute("aria-live", "polite");
    const actions = element("div", "", "zth-progress-actions");
    function act(action) { try { update(id, action); redraw(); } catch (error) { status.textContent = `Progress could not be saved: ${error.message}`; } }
    actions.append(button("Mark exercise complete", () => act((entry) => { entry.exerciseComplete = true; entry.status = entry.cleanupComplete ? "complete" : "in-progress"; })), button("Mark cleanup complete / not applicable", () => act((entry) => { entry.cleanupComplete = true; entry.status = entry.exerciseComplete ? "complete" : "in-progress"; })));
    function redraw() { const data = readRecord().labs[id]; status.textContent = `${data.status.replaceAll("-", " ")} · exercise ${data.exerciseComplete ? "reported complete" : "not reported"} · cleanup ${data.cleanupComplete ? "reported complete or not applicable" : "not reported"}${data.assessmentScore === null ? "" : ` · quiz ${data.assessmentScore}%`}`; }
    card.append(actions, status);
    if (id === "CLZ-090") { card.append(element("p", "Setup checklist: inspect tools, review trusted installation choices, verify pinned versions, run the readiness audit, and resolve blocking results.")); }
    else { const quiz = element("a", "Practice this lesson's 30 questions"); quiz.href = new URL(`practice/?lab=${id}`, siteRoot).href; card.append(quiz); }
    if (warning) card.append(element("p", warning));
    container.append(card); redraw(); window.addEventListener("zth-progress-changed", redraw);
  }

  const script = document.currentScript;
  const siteRoot = script?.src ? new URL("../", script.src) : new URL("./", location.href);
  async function renderDashboard(container) {
    if (container.dataset.ready) return;
    container.dataset.ready = "true";
    const card = element("section", "", "zth-progress-card");
    card.append(element("h2", "Browser-local dashboard"));
    const message = element("p"); message.setAttribute("role", "status"); message.setAttribute("aria-live", "polite");
    const summary = element("p");
    const meter = document.createElement("progress"); meter.max = 31; meter.className = "zth-progress-meter";
    const grid = element("div", "", "zth-progress-grid");
    const actions = element("div", "", "zth-progress-actions");
    actions.append(button("Export progress JSON", () => {
      try { const record = readRecord(); const url = URL.createObjectURL(new Blob([JSON.stringify(record, null, 2)], { type: "application/json" })); const link = document.createElement("a"); link.href = url; link.download = "azure-zero-to-hero-progress.json"; link.click(); URL.revokeObjectURL(url); message.textContent = "Progress exported. Keep this backup private."; }
      catch (error) { message.textContent = `Export failed: ${error.message}`; }
    }));
    const label = element("label", "Import progress JSON", "zth-file-button");
    const input = document.createElement("input"); input.type = "file"; input.accept = ".json,application/json"; input.setAttribute("aria-label", "Import progress JSON"); label.append(input); actions.append(label);
    input.addEventListener("change", async () => { try { const file = input.files[0]; if (!file) return; if (file.size > 256 * 1024) throw new Error("The export must be smaller than 256 KiB."); const record = validateRecord(JSON.parse(await file.text())); writeRecord(record); message.textContent = "Progress imported for this course."; } catch (error) { message.textContent = `Import refused. Your existing progress is unchanged. ${error.message}`; } input.value = ""; });
    card.append(summary, meter, actions, message, grid); container.append(card);
    let lessons = [];
    function redraw() {
      const record = readRecord(); const complete = ids.filter((id) => record.labs[id].status === "complete").length;
      summary.textContent = `${complete} of 31 available lessons reported complete. CLZ-090 and CLZ-300 remain optional.`; meter.value = complete; meter.setAttribute("aria-label", summary.textContent); grid.replaceChildren();
      for (const lesson of lessons) { const entry = record.labs[lesson.labId]; const item = element("div", "", "zth-progress-item"); const link = element("a", `${lesson.labId} — ${lesson.title}`); link.href = new URL(lesson.pathUrl, siteRoot).href; item.append(link, element("p", `${entry.status.replaceAll("-", " ")} · quiz ${entry.assessmentScore === null ? "not taken" : `${entry.assessmentScore}%`}`)); grid.append(item); }
    }
    try { const response = await fetch(new URL("catalog.json", script.src), { credentials: "omit" }); if (!response.ok) throw new Error(`HTTP ${response.status}`); const data = await response.json(); if (!Array.isArray(data.labs) || data.labs.length !== 31 || data.labs.some((item) => !ids.includes(item.labId) || typeof item.title !== "string" || !/^labs\/CLZ-[0-9]{3}-[a-z0-9-]+\/$/.test(item.pathUrl))) throw new Error("Invalid lesson catalog."); lessons = data.labs; redraw(); if (warning) message.textContent = warning; }
    catch (error) { redraw(); message.textContent = `Lesson links could not load: ${error.message}. Your progress is preserved; reload to retry.`; }
    window.addEventListener("zth-progress-changed", redraw);
  }
  function render() { document.querySelectorAll("[data-zth-lesson]").forEach(renderLesson); document.querySelectorAll("[data-zth-progress-dashboard]").forEach(renderDashboard); }
  if (typeof document$ !== "undefined") document$.subscribe(render);
  else if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", render);
  else render();
})();
