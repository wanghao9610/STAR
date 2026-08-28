// Zero-dependency `/star` and `/star-auto` slash commands. Each is a thin
// front door: the handler injects one follow-up turn that reads the shared
// file (`.agents/commands/star.md` or `star-auto.md`) and applies it to the
// user's request. The shared files own the routing table, the "empty request
// selects star-flow-status" rule, and the auto procedure; this shim only
// carries the argument across.
//
// No imports on purpose: this file is a project-local package linked into the
// profile, so its module path is the project directory and any `@deepseek-ai/*`
// import would fail parent-walk resolution. `ctx.commands` is injected and the
// follow-up message is built inline with the same shape `createUserMessage`
// produces.

const name = "star";
const inject = ["commands"];

function apply(ctx) {
  ctx.commands.register({
    name: "star",
    description: "Route a request to the right STAR skill",
    input: { hint: "[what you want to do]" },
    // The request is injected verbatim as the follow-up message, so the
    // command/run log event must not duplicate it as `args`.
    recordInput: false,
    handler: ({ agent, rawInput }) => {
      const request = rawInput.trim();
      agent.followup({
        id: crypto.randomUUID(),
        role: "user",
        content: [{
          type: "text",
          text: request === ""
            ? "Read `.agents/commands/star.md` and apply its router to an empty request (select `star-flow-status`)."
            : `Read \`.agents/commands/star.md\` and apply its router to this request: ${request}`,
        }],
        source: { kind: "user" },
      });
      return { kind: "success" };
    },
  });
  ctx.commands.register({
    name: "star-auto",
    description: "Drive the STAR workflow toward a stated goal",
    input: { hint: "[goal] [stop=<stop line>] [involve=<level>]" },
    // Same as /star: the invocation is injected verbatim as the follow-up
    // message, so the command/run log event must not duplicate it as `args`.
    recordInput: false,
    handler: ({ agent, rawInput }) => {
      const invocation = rawInput.trim();
      agent.followup({
        id: crypto.randomUUID(),
        role: "user",
        content: [{
          type: "text",
          text: invocation === ""
            ? "Read `.agents/commands/star-auto.md` and follow it; the invocation carries no goal, so ask for one."
            : `Read \`.agents/commands/star-auto.md\` and follow it with this invocation: ${invocation}`,
        }],
        source: { kind: "user" },
      });
      return { kind: "success" };
    },
  });
}

export { apply, inject, name };
