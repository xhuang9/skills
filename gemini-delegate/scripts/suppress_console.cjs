const originalLog = console.log.bind(console);
const originalWarn = console.warn.bind(console);
const originalDebug = console.debug.bind(console);

function shouldSuppress(args) {
  if (!args || args.length === 0) {
    return false;
  }

  const first = typeof args[0] === "string" ? args[0] : "";

  if (first === "Loaded cached credentials.") {
    return true;
  }

  if (first === "Hook system initialized successfully") {
    return true;
  }

  if (first === "Experiments loaded") {
    return true;
  }

  if (/^Hook registry initialized with \d+ hook entries$/.test(first)) {
    return true;
  }

  if (/^Ignore file not found: .*\.geminiignore, continue without it\.$/.test(first)) {
    return true;
  }

  if (/^Skill ".*" from ".*" is overriding the built-in skill\.$/.test(first)) {
    return true;
  }

  return false;
}

console.log = (...args) => {
  if (!shouldSuppress(args)) {
    originalLog(...args);
  }
};

console.warn = (...args) => {
  if (!shouldSuppress(args)) {
    originalWarn(...args);
  }
};

console.debug = (...args) => {
  if (!shouldSuppress(args)) {
    originalDebug(...args);
  }
};
