/**
 * Pure utility functions for plan mode.
 * Extracted for testability.
 */

// Parse one literal command. Shell expansion, redirection and compound commands
// need a shell parser and are deliberately outside this argument guard.
function commandWords(command: string): string[] | null {
	const words: string[] = [];
	let word = "";
	let quote = "";
	let started = false;
	for (const char of command) {
		if (/[\r\n\0]/.test(char)) return null;
		if (quote) {
			if (char === quote) quote = "";
			else {
				if (quote === '"' && /[$`\\]/.test(char)) return null;
				word += char;
			}
		} else if (char === "'" || char === '"') {
			quote = char;
			started = true;
		} else if (char === " " || char === "\t") {
			if (started) words.push(word);
			word = "";
			started = false;
		} else {
			if (/\s/.test(char)) return null;
			if (/[\\$`;&|<>(){}*?\[\]~#]/.test(char)) return null;
			word += char;
			started = true;
		}
	}
	if (quote) return null;
	if (started) words.push(word);
	return words;
}

// Unknown options are rejected, including abbreviated long options. An option
// that consumes a value must consume exactly one word before checking resumes.
function readOnlyArgs(args: string[], flags: string, values = "", maxOperands = Infinity): boolean {
	const switches = new Set(flags.split(" "));
	const valued = new Set(values.split(" ").filter(Boolean));
	let operands = 0;
	let optionsEnded = false;
	for (let i = 0; i < args.length; i++) {
		const arg = args[i];
		if (optionsEnded || !arg.startsWith("-") || arg === "-") {
			if (++operands > maxOperands) return false;
		} else if (arg === "--") optionsEnded = true;
		else if (switches.has(arg)) continue;
		else if (valued.has(arg)) {
			if (++i === args.length) return false;
		} else if (arg.startsWith("--")) {
			if (!arg.includes("=") || !valued.has(arg.slice(0, arg.indexOf("=")))) return false;
		} else {
			for (let j = 1; j < arg.length; j++) {
				const flag = `-${arg[j]}`;
				if (valued.has(flag)) {
					if (j === arg.length - 1 && ++i === args.length) return false;
					break;
				}
				if (!switches.has(flag)) return false;
			}
		}
	}
	return true;
}

// Only programs and options whose arguments have been checked for writes or
// command execution belong here. Interactive pagers, interpreters, network
// clients and general wrappers stay unavailable until their arguments are checked.
const READ_COMMANDS: Record<string, [string, string?, number?]> = {
	cat: ["-b -e -n -s -t -u -v -A -E -T --number --number-nonblank --squeeze-blank"],
	head: ["-q -v --quiet --verbose", "-n -c --lines --bytes"],
	tail: ["-q -v --quiet --verbose", "-n -c --lines --bytes"],
	ls: ["-a -A -l -h -d -R -r -t -S -F -p -i -n -1 --all --almost-all --directory --recursive"],
	pwd: ["-L -P", "", 0],
	wc: ["-c -m -l -w -L --bytes --chars --lines --words --max-line-length"],
	grep: ["-E -F -G -P -i -v -w -x -n -H -h -l -L -c -q -s -r -R -o -a -I", "-e -f -m -A -B -C --regexp --file --max-count --after-context --before-context --context"],
	rg: ["--files --hidden --no-ignore --no-ignore-vcs --follow --glob-case-insensitive --no-heading --heading --line-number --files-with-matches --files-without-match --count --count-matches --fixed-strings --ignore-case --smart-case --word-regexp --only-matching --multiline -n -H -l -L -c -i -s -S -F -w -o -v -q -a -u -U -0", "-e -f -g -t -T -m -A -B -C --regexp --file --glob --iglob --type --type-not --max-count --max-depth --after-context --before-context --context --color --sort --sortr"],
	sort: ["-b -d -f -g -h -i -M -n -R -r -s -u -V -c -C --reverse --unique --stable --numeric-sort --human-numeric-sort", "-k -t --key --field-separator"],
	uniq: ["-c -d -u -i --count --repeated --unique --ignore-case", "-f -s -w --skip-fields --skip-chars --check-chars", 1],
	diff: ["-u -c -q -r -s -w -b -B -i --unified --brief --recursive --ignore-all-space", "-U -C --context", 2],
	du: ["-a -c -h -k -m -s -x --all --total --human-readable --summarize", "-d --max-depth"],
	df: ["-a -h -H -i -k -m -P -T --human-readable"],
	which: ["-a -s"],
	type: ["-a -f -p -P -t"],
	printenv: ["-0 --null"],
	uname: ["-a -s -n -r -v -m -p -i -o --all", "", 0],
	whoami: ["", "", 0],
	id: ["-u -g -G -n -r -p", "", 1],
	uptime: ["-p -s", "", 0],
	ps: ["-a -A -e -f -l -u -x -w", "-p -o -U"],
};

/** Allow a supported literal read command, rejecting unverified shell syntax and options. */
export function isSafeCommand(command: string): boolean {
	const words = commandWords(command);
	if (!words?.length) return false;
	const [program, ...args] = words;
	if (program === "node" || program === "python" || program === "python3") {
		return args.length === 1 && args[0] === "--version";
	}
	if (program !== "git") {
		const spec = Object.hasOwn(READ_COMMANDS, program) ? READ_COMMANDS[program] : undefined;
		return spec !== undefined && readOnlyArgs(args, ...spec);
	}
	while (args[0] === "--no-pager" || args[0] === "--no-optional-locks" || args[0] === "-C") {
		if (args.shift() === "-C" && !args.shift()) return false;
	}
	const subcommand = args.shift();
	switch (subcommand) {
		case "status":
			return readOnlyArgs(args, "-s -b -u -uno -unormal -uall --short --branch --porcelain --porcelain=v1 --porcelain=v2 --ignored --untracked-files --untracked-files=no --untracked-files=normal --untracked-files=all");
		case "diff":
		case "log":
		case "show":
			// Git's optional values (notably --pretty and -U) do not consume
			// the following word, which must still be checked as an option.
			return readOnlyArgs(args.map((arg) => {
				if (/^--(max-count|format|pretty|since|until)=/.test(arg)) return arg.slice(0, arg.indexOf("="));
				return /^-U\d+$/.test(arg) ? "-U" : arg;
			}), "--oneline --all --decorate --graph --stat --shortstat --numstat --name-only --name-status --no-patch --no-color --color=never --no-ext-diff --no-textconv --cached --staged --check --reverse --raw --max-count --format --pretty --since --until -p -s -w -b -U", "-n");
		case "branch": {
			const optionEnd = args.includes("--") ? args.indexOf("--") : args.length;
			const listsBranches = args.slice(0, optionEnd).includes("--list");
			return readOnlyArgs(args, "-a -r -v --all --remotes --verbose --list --show-current", "", listsBranches ? Infinity : 0);
		}
		case "remote":
			return readOnlyArgs(args, "-v --verbose", "", 0);
		case "config":
			return args[0] === "--get" && args.length === 2 && !args[1].startsWith("-");
		case "ls-files":
			return readOnlyArgs(args, "-z -c -d -m -o -i -s --cached --deleted --modified --others --ignored --stage --exclude-standard");
		case "ls-tree":
			return readOnlyArgs(args, "-d -r -t -l -z --name-only --name-status --full-name --full-tree");
		default:
			return false;
	}
}

export interface TodoItem {
	step: number;
	text: string;
	completed: boolean;
}

export function cleanStepText(text: string): string {
	let cleaned = text
		.replace(/\*{1,2}([^*]+)\*{1,2}/g, "$1") // Remove bold/italic
		.replace(/`([^`]+)`/g, "$1") // Remove code
		.replace(
			/^(Use|Run|Execute|Create|Write|Read|Check|Verify|Update|Modify|Add|Remove|Delete|Install)\s+(the\s+)?/i,
			"",
		)
		.replace(/\s+/g, " ")
		.trim();

	if (cleaned.length > 0) {
		cleaned = cleaned.charAt(0).toUpperCase() + cleaned.slice(1);
	}
	if (cleaned.length > 50) {
		cleaned = `${cleaned.slice(0, 47)}...`;
	}
	return cleaned;
}

export function extractTodoItems(message: string): TodoItem[] {
	const items: TodoItem[] = [];
	const headerMatch = message.match(/\*{0,2}Plan:\*{0,2}\s*\n/i);
	if (!headerMatch) return items;

	const planSection = message.slice(message.indexOf(headerMatch[0]) + headerMatch[0].length);
	const numberedPattern = /^\s*(\d+)[.)]\s+\*{0,2}([^*\n]+)/gm;

	for (const match of planSection.matchAll(numberedPattern)) {
		const text = match[2]
			.trim()
			.replace(/\*{1,2}$/, "")
			.trim();
		if (text.length > 5 && !text.startsWith("`") && !text.startsWith("/") && !text.startsWith("-")) {
			const cleaned = cleanStepText(text);
			if (cleaned.length > 3) {
				items.push({ step: items.length + 1, text: cleaned, completed: false });
			}
		}
	}
	return items;
}

export function extractDoneSteps(message: string): number[] {
	const steps: number[] = [];
	for (const match of message.matchAll(/\[DONE:(\d+)\]/gi)) {
		const step = Number(match[1]);
		if (Number.isFinite(step)) steps.push(step);
	}
	return steps;
}

export function markCompletedSteps(text: string, items: TodoItem[]): number {
	const doneSteps = extractDoneSteps(text);
	for (const step of doneSteps) {
		const item = items.find((t) => t.step === step);
		if (item) item.completed = true;
	}
	return doneSteps.length;
}
