const { test } = require("node:test")
const assert = require("node:assert/strict")
const Model = require("../Model.js")

test("czech translates to italian and italian to czech", () => {
  const targets = ["cs", "it"].map(Model.targetOf)

  assert.deepEqual(targets, ["it", "cs"])
})

test("a known source language asks for a translation in one fixed direction", () => {
  const prompt = Model.instructions("it")

  assert.match(prompt, /from Italian into Czech/)
})

test("an unknown source language asks Claude to detect it", () => {
  const prompt = Model.instructions("auto")

  assert.match(prompt, /Detect whether .* Czech or Italian/)
})

test("a successful reply yields the detected source and the translation", () => {
  const stdout = JSON.stringify({ is_error: false, structured_output: { source: "it", translation: "Ahoj" } })

  const result = Model.parseReply(stdout)

  assert.deepEqual(result, { source: "it", translation: "Ahoj", error: "" })
})

test("an error reply carries Claude's message", () => {
  const stdout = JSON.stringify({ is_error: true, result: "Not logged in" })

  const result = Model.parseReply(stdout)

  assert.equal(result.error, "Not logged in")
})

test("output that is not a reply is reported as an error", () => {
  const results = ["", "command not found", JSON.stringify({ is_error: false, structured_output: { source: "de", translation: "x" } })]
    .map(Model.parseReply)

  assert.ok(results.every(r => r.error !== "" && r.translation === ""))
})

test("the reply schema only accepts the languages of the pair", () => {
  const schema = JSON.parse(Model.replySchema())

  assert.deepEqual(schema.properties.source.enum, ["cs", "it"])
})
