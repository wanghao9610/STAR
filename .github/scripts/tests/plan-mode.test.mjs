import assert from "node:assert/strict";
import { test } from "node:test";
import { isSafeCommand } from "../../../.pi/extensions/star-plan-mode/utils.ts";

test("plan mode permits common reads and treats quoted search text as data", () => {
	for (const command of [
		"git status --short",
		"git --no-pager -C 'project with spaces' log --oneline -n5",
		"git diff --stat HEAD -- 'file with spaces.ts'",
		"git log --format='%h %s' --max-count=5",
		"git diff -U5 HEAD",
		"git branch",
		"git branch -av",
		"git branch --list 'feature/*'",
		"git remote -v",
		"git config --get remote.origin.url",
		"git ls-files --cached",
		"git ls-tree -r HEAD",
		"rg --files --hidden -g '*.ts'",
		"rg -n -F 'rm -rf; $(whoami) | >' -- README.md",
		"grep -nE '^(foo|bar)$' 'input file.txt'",
		'cat "input file.txt"',
		"head -n20 README.md",
		"tail --lines=10 README.md",
		"ls -lah",
		"wc -l README.md",
		"sort -nr -k 2 input.txt",
		"uniq -c input.txt",
		"diff -u before.txt after.txt",
		"python --version",
		"node --version",
	]) assert.equal(isSafeCommand(command), true, command);
});

test("plan mode rejects writes hidden behind otherwise readable command names", () => {
	for (const command of [
		"git branch new-branch",
		"git branch -D old-branch",
		"git branch --edit-description",
		"git branch new-branch\u00a0--list",
		"git branch new-branch\u2003--list",
		"git remote add fixture https://example.invalid/repo",
		"git remote set-url origin https://example.invalid/repo",
		"git config user.name Changed",
		"git -c alias.read='!touch marker' read",
		"git log --output=output.txt",
		"git log --pretty --output=output.txt",
		"git log --format --output=output.txt",
		"git log -U --output=output.txt",
		"git diff --output output.txt",
		"git diff --ext-diff",
		"git show --textconv HEAD:file",
		"curl -o output.txt https://example.invalid",
		"curl -K options.txt https://example.invalid",
		"sort -o output.txt input.txt",
		"sort -rooutput.txt input.txt",
		"sort --output=output.txt input.txt",
		"sort --out=output.txt input.txt",
		"sort --compress-program=helper input.txt",
		"uniq input.txt output.txt",
		"rg --pre helper text",
		"rg --hostname-bin helper text",
		"find . -delete",
		"awk 'BEGIN { system(\"touch marker\") }'",
		"sed -n 'w output.txt' input.txt",
		"env sh script.sh",
		"npm audit fix",
		"node --version script.js",
		"python --version script.py",
	]) assert.equal(isSafeCommand(command), false, command);
});

test("plan mode refuses unsupported shell syntax and malformed arguments", () => {
	for (const command of [
		"", " ", "git", "git -C", "git status --unknown", "head -n",
		"cat input.txt > output.txt",
		"cat input.txt | tee output.txt",
		"git status && touch marker",
		"git status; touch marker",
		"git status\ntouch marker",
		"cat $(touch marker)",
		'cat "$(touch marker)"',
		"cat `touch marker`",
		"cat <(touch marker)",
		"cat $INPUT",
		"cat *.txt",
		"cat input{1,2}.txt",
		"cat 'unfinished",
		'cat "unfinished',
		"git status # comment",
		"g\\it status",
		"constructor",
	]) assert.equal(isSafeCommand(command), false, command);
});
