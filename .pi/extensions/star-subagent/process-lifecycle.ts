import type { ChildProcess } from "node:child_process";

export interface ChildProcessCompletion {
	exitCode: number;
	signal: NodeJS.Signals | null;
	wasAborted: boolean;
	diagnostic?: string;
}

/** Wait for a child to close and enforce abort escalation while it is still running. */
export function waitForChildProcess(
	proc: ChildProcess,
	abortSignal?: AbortSignal,
	forceKillDelayMs = 5000,
): Promise<ChildProcessCompletion> {
	return new Promise((resolve) => {
		let exited = proc.exitCode !== null || proc.signalCode !== null;
		let settled = false;
		let wasAborted = false;
		let forceKillTimer: ReturnType<typeof setTimeout> | undefined;

		const clearForceKillTimer = () => {
			if (forceKillTimer) {
				clearTimeout(forceKillTimer);
				forceKillTimer = undefined;
			}
		};

		const removeAbortListener = () => abortSignal?.removeEventListener("abort", abort);

		const finish = (code: number | null, signal: NodeJS.Signals | null) => {
			if (settled) return;
			settled = true;
			exited = true;
			clearForceKillTimer();
			removeAbortListener();
			resolve({
				exitCode: code ?? 1,
				signal,
				wasAborted,
				diagnostic: signal ? `Subagent terminated by signal ${signal}.` : undefined,
			});
		};

		const abort = () => {
			wasAborted = true;
			if (exited) return;
			proc.kill("SIGTERM");
			forceKillTimer = setTimeout(() => {
				if (!exited) proc.kill("SIGKILL");
			}, forceKillDelayMs);
		};

		proc.once("exit", () => {
			exited = true;
			clearForceKillTimer();
			removeAbortListener();
		});
		proc.once("close", finish);
		proc.once("error", () => finish(1, null));

		if (abortSignal) {
			if (abortSignal.aborted) abort();
			else abortSignal.addEventListener("abort", abort, { once: true });
		}
	});
}
