// STAR session hooks for Pi.
//
// Pi's extension point is TypeScript, not a command-hook table, so this file
// plays the part .claude/settings.json, .codex/hooks.json, .cursor/hooks.json and
// .qwen/settings.json play in the other trees: it is the registration, and the
// three scripts beside this file are the logic, one copy per tree as everywhere
// else. They sit here rather than in .pi/hooks/ because Pi reserves that name for
// the old extensions directory and warns whenever it exists. Pi discovers
// .pi/extensions/*/index.ts by itself once the project is trusted, so there is
// nothing to register by hand and nothing to merge after an update.
//
// What it wires:
//   - model-id provenance and the project-memory index, injected as one message
//     before the first agent run, and again whenever the model changes
//   - the commit guard, on the bash tool, declining what conventions §1 forbids
//
// What it deliberately does not wire: the involve gate. That hook exists to
// answer the permission prompt before a file edit while .env reads INVOLVE=low,
// and Pi ships no permission prompts — there is no prompt to skip, so the level
// governs only what the skills themselves ask.

import { CONFIG_DIR_NAME, isToolCallEventType, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { join } from "node:path";

export default function (pi: ExtensionAPI) {
    // The context message is injected at a prompt rather than at session start,
    // because session_start cannot add to the conversation. Pending is set again
    // on a model change so the provenance line that reaches the writing turn is
    // the model actually writing.
    let pending = true;
    let injectedModel = "";

    const hook = (cwd: string, name: string) => join(cwd, CONFIG_DIR_NAME, "extensions", "star-hooks", name);

    // A hook that prints nothing has nothing to say — an empty memory store, or a
    // copy this project does not carry. A hook that cannot be run at all is not
    // worth a dialog either: code -1 with no text reads as "no decision" at both
    // call sites below.
    const run = async (script: string, args: string[]) => {
        try {
            const result = await pi.exec("bash", [script, ...args], { timeout: 10000 });
            return { code: result.code, text: result.stdout.trim() };
        } catch {
            return { code: -1, text: "" };
        }
    };

    // The two context hooks say what they have to say on stdout and exit 0.
    const context = async (cwd: string, name: string, args: string[] = []) => {
        const { code, text } = await run(hook(cwd, name), args);
        return code === 0 ? text : "";
    };

    pi.on("session_start", async () => {
        pending = true;
        injectedModel = "";
    });

    pi.on("model_select", async (event) => {
        if (modelId(event.model) !== injectedModel) pending = true;
    });

    pi.on("before_agent_start", async (_event, ctx) => {
        if (!pending) return;
        pending = false;
        injectedModel = modelId(ctx.model);

        const parts = [
            await context(ctx.cwd, "star_model_id.sh", [injectedModel]),
            await context(ctx.cwd, "star_memory.sh"),
        ].filter((part) => part.length > 0);
        if (parts.length === 0) return;

        return {
            message: {
                customType: "star-context",
                content: parts.join("\n\n"),
                display: false,
            },
        };
    });

    pi.on("tool_call", async (event, ctx) => {
        if (!isToolCallEventType("bash", event)) return;
        // The guard declines by printing one reason and exiting non-zero; exit 0
        // with no output is its "no decision", and so is a copy that would not run.
        const { code, text } = await run(hook(ctx.cwd, "star_commit_guard.sh"), [event.input.command]);
        if (code > 0 && text) return { block: true, reason: text };
    });
}

// ctx.model is the model object, and the id alone is what conventions §8 records.
// The provider goes with it because two providers serve the same id under
// different names, and an artifact says which one wrote it.
function modelId(model: { id?: string; provider?: string } | undefined): string {
    if (!model?.id) return "";
    return model.provider ? `${model.provider}/${model.id}` : model.id;
}
