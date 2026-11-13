import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const helper = fileURLToPath(new URL("../../../.agents/scripts/json.sh", import.meta.url));
function run(input, program = "print json(r)", executable = "bash") {
    return spawnSync(executable, ["-c", 'source "$1"; star_json_eval "$2"', "json-test", helper, program], {
        input, encoding: "utf8",
    });
}

test("shell JSON reader round-trips values against Node's independent parser", () => {
    const values = [null, true, false, 0, -0.5, 1e50, "", "中文😀", 'quote " slash \\ /',
        "\b\f\r\n\t\u001f\u007f", ["01", "1", null, [], {}],
        { "odd\"key\\\n": "$(touch never-executed)", nested: { list: [1, true, ""] } }];
    for (const executable of ["bash", "/bin/bash"]) {
        for (const value of values) {
            const result = run(JSON.stringify(value), undefined, executable);
            assert.equal(result.status, 0, result.stderr);
            assert.deepEqual(JSON.parse(result.stdout), value);
        }
    }
    const escaped = run('{"text":"\\u4e2d\\u6587\\ud83d\\ude00"}');
    assert.equal(escaped.status, 0, escaped.stderr);
    assert.deepEqual(JSON.parse(escaped.stdout), { text: "中文😀" });
});

test("shell JSON reader rejects malformed input without accepting a valid prefix", () => {
    for (const input of ["", '"\\u0000"', "null trailing", "01", "+1", "1.", "1e", "[1,]", '{"a":}',
        '{"a":1,}', '{a:1}', '[true false]', '"\\x41"', '"\\u123"', '"\\ud800"',
        '"\\udc00"', '"unclosed', '"raw\nnewline"', '"raw\tcontrol"']) {
        const result = run(input);
        assert.equal(result.status, 2, input);
        assert.equal(result.stdout, "", input);
    }
});

test("shell JSON equality retains types, numeric meaning and missing fields", () => {
    const result = run('{"value":1}', `
        if(!equal(parse("1.0"),parse("1"))) exit 1
        if(equal(string("01"),string("1"))) exit 1
        if(equal(string("1"),number(1))) exit 1
        x=get(r,"absent"); if(has(r,"absent")) exit 1
        if(!equal(parse("{\\"x\\":1.0}"),parse("{\\"x\\":1}"))) exit 1
        print "passed"
    `);
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.stdout.trim(), "passed");
});

test("shell JSON sorting uses decoded text rather than escaped JSON spellings", () => {
    const input = ["/aA", "/a\t", '/a"', "/a\\", "/a", "/a中"];
    const result = run(JSON.stringify(input), 'print json(sorted(r,"",0))');
    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(JSON.parse(result.stdout), input.toSorted());
});

test("shell JSON canonical object keys keep prefix keys before longer keys", () => {
    const result = run('{"runtime_digest":"","runtime":"","aa":2,"a":1}');
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.stdout.trim(), '{"a":1,"aa":2,"runtime":"","runtime_digest":""}');
});
