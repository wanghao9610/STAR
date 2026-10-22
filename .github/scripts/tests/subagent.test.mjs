import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { getEventListeners, once } from "node:events";
import { test } from "node:test";
import { setTimeout as delay } from "node:timers/promises";

import { waitForChildProcess } from "../../../.pi/extensions/star-subagent/process-lifecycle.ts";

function spawnNode(source) {
	return spawn(process.execPath, ["-e", source], { stdio: ["ignore", "pipe", "pipe"] });
}

function trackChild(t, proc) {
	t.after(() => {
		if (proc.exitCode === null && proc.signalCode === null) proc.kill("SIGKILL");
	});
	return proc;
}

async function waitUntilReady(proc) {
	proc.stdout.setEncoding("utf8");
	for await (const chunk of proc.stdout) {
		if (chunk.includes("ready")) return;
	}
	throw new Error("Child process exited before becoming ready");
}

test("reports normal and nonzero exits", { timeout: 2000 }, async (t) => {
	await t.test("normal exit", async () => {
		const result = await waitForChildProcess(trackChild(t, spawnNode("process.exit(0)")));
		assert.deepEqual(result, { exitCode: 0, signal: null, wasAborted: false, diagnostic: undefined });
	});

	await t.test("nonzero exit", async () => {
		const result = await waitForChildProcess(trackChild(t, spawnNode("process.exit(7)")));
		assert.deepEqual(result, { exitCode: 7, signal: null, wasAborted: false, diagnostic: undefined });
	});
});

test("normalizes signal termination to failure with a diagnostic", { timeout: 2000 }, async (t) => {
	const proc = trackChild(t, spawnNode("setInterval(() => {}, 1000)"));
	await once(proc, "spawn");
	const completion = waitForChildProcess(proc);
	proc.kill("SIGTERM");

	const result = await completion;
	assert.equal(result.exitCode, 1);
	assert.equal(result.signal, "SIGTERM");
	assert.equal(result.diagnostic, "Subagent terminated by signal SIGTERM.");
});

test("aborting escalates to SIGKILL when the child ignores SIGTERM", { timeout: 2000 }, async (t) => {
	const proc = trackChild(
		t,
		spawnNode('process.on("SIGTERM", () => {}); console.log("ready"); setInterval(() => {}, 1000)'),
	);
	await waitUntilReady(proc);
	const controller = new AbortController();
	const completion = waitForChildProcess(proc, controller.signal, 50);

	controller.abort();
	const result = await completion;

	assert.equal(result.wasAborted, true);
	assert.equal(result.exitCode, 1);
	assert.equal(result.signal, "SIGKILL");
	assert.equal(result.diagnostic, "Subagent terminated by signal SIGKILL.");
});

test("removes the abort listener and cancels escalation after the child exits", { timeout: 2000 }, async (t) => {
	const proc = trackChild(
		t,
		spawnNode(
			'process.on("SIGTERM", () => process.exit(0)); console.log("ready"); setInterval(() => {}, 1000)',
		),
	);
	await waitUntilReady(proc);
	const sentSignals = [];
	const kill = proc.kill.bind(proc);
	proc.kill = (signal) => {
		sentSignals.push(signal);
		return kill(signal);
	};
	const controller = new AbortController();
	const completion = waitForChildProcess(proc, controller.signal, 50);
	assert.equal(getEventListeners(controller.signal, "abort").length, 1);

	controller.abort();
	const result = await completion;
	await delay(100);

	assert.equal(result.wasAborted, true);
	assert.equal(getEventListeners(controller.signal, "abort").length, 0);
	assert.deepEqual(sentSignals, ["SIGTERM"]);
});

test("reports a failed spawn", { timeout: 2000 }, async (t) => {
	const proc = trackChild(t, spawn("star-subagent-command-that-does-not-exist", [], { stdio: "ignore" }));
	const result = await waitForChildProcess(proc);

	assert.equal(result.exitCode, 1);
	assert.equal(result.signal, null);
});

test("honors an already-aborted signal", { timeout: 2000 }, async (t) => {
	const proc = trackChild(
		t,
		spawnNode('process.on("SIGTERM", () => {}); console.log("ready"); setInterval(() => {}, 1000)'),
	);
	await waitUntilReady(proc);
	const controller = new AbortController();
	controller.abort();

	const result = await waitForChildProcess(proc, controller.signal, 50);

	assert.equal(result.wasAborted, true);
	assert.equal(result.signal, "SIGKILL");
});
