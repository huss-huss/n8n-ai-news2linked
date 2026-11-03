// Minimal stand-in for the n8n Code node runtime, used by tests/test_code_nodes.py.
// Reads a JSON request on stdin:
//   { workflow, node, items, env, staticData, nodeOutputs: { "<node name>": [items] } }
// and prints { output, staticData } as JSON. Supports the globals these workflows use:
// $input, $json, $env, $getWorkflowStaticData, $('<node>').all()/first()/item.
const fs = require('fs');

const req = JSON.parse(fs.readFileSync(0, 'utf8'));
const wf = JSON.parse(fs.readFileSync(req.workflow, 'utf8'));
const node = wf.nodes.find((n) => n.name === req.node);
if (!node) throw new Error(`node not found: ${req.node}`);
const staticData = req.staticData || {};
const outputs = req.nodeOutputs || {};
const items = req.items || [];
const ref = (name) => {
  const list = outputs[name];
  if (!list) throw new Error(`no output provided for node ${name}`);
  return { all: () => list, first: () => list[0], item: list[0] };
};
const run = (item) => {
  const fn = new Function('$input', '$json', '$env', '$getWorkflowStaticData', '$', node.parameters.jsCode);
  return fn({ first: () => items[0], all: () => items, item }, item?.json, req.env || {}, () => staticData, ref);
};
let output;
if (node.parameters.mode === 'runOnceForEachItem') {
  output = items.map((item) => run(item));
} else {
  const result = run(items[0]);
  output = Array.isArray(result) ? result : [result];
}
process.stdout.write(JSON.stringify({ output, staticData }));
