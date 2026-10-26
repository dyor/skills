#!/usr/bin/env node
/**
 * md-mermaid: Local Sidecar, CLI & MCP Server for rendering Mermaid blocks in Markdown files
 * into crisp local PNGs stored in a sibling `.mermaid/` subfolder for Android Studio's
 * Markdown preview.
 *
 * Key Android Studio (Compose Markdown Preview) rules enforced:
 * 1. Uses absolute `file:///...` paths for both the inline preview image and clickable links.
 * 2. Generates BOTH a 100%-width inline preview PNG (default 1500px physical Retina width via `sips`)
 *    AND an unscaled high-DPI `@3x` full-size PNG linked via `[🔍 View Full Size](file:///...)`.
 * 3. Escapes `-->` as `--&gt;` inside the hidden `<!-- md-mermaid:source ... -->` HTML comment
 *    so Mermaid arrows NEVER prematurely close the HTML comment in CommonMark!
 * 4. Also writes the raw `.mmd` file in `.mermaid/` and links `[📐 Mermaid Source](file:///...)`
 *    so clicking it in Android Studio opens the diagram source directly.
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execFileSync } = require('child_process');
const os = require('os');

const CHROME_PATHS = [
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Chromium.app/Contents/MacOS/Chromium',
  '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
];

function findChrome() {
  for (const p of CHROME_PATHS) {
    if (fs.existsSync(p)) return p;
  }
  return undefined;
}

const RUNTIME_DIR = fs.existsSync(path.join(__dirname, 'node_modules', '.bin', 'mmdc'))
  ? __dirname
  : path.join(os.homedir(), '.local', 'share', 'md-mermaid');
const MMDC_BIN = path.join(RUNTIME_DIR, 'node_modules', '.bin', 'mmdc');
const PUPPETEER_CONFIG_PATH = path.join(RUNTIME_DIR, 'puppeteer-config.json');
const MERMAID_CONFIG_PATH = path.join(RUNTIME_DIR, 'mermaid-config.json');

function ensureConfigs() {
  const executablePath = findChrome();
  const puppeteerCfg = {
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu'],
  };
  if (executablePath) {
    puppeteerCfg.executablePath = executablePath;
  }
  fs.writeFileSync(PUPPETEER_CONFIG_PATH, JSON.stringify(puppeteerCfg, null, 2));

  const mermaidCfg = {
    theme: 'dark',
    themeVariables: {
      fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
      fontSize: '16px',
      primaryColor: '#1e293b',
      primaryTextColor: '#f8fafc',
      primaryBorderColor: '#475569',
      lineColor: '#94a3b8',
      secondaryColor: '#0f172a',
      tertiaryColor: '#27272a',
      clusterBkg: '#27272a',
      clusterBorder: '#52525b',
    },
    flowchart: {
      htmlLabels: true,
      curve: 'basis',
      padding: 20,
      subGraphTitleMargin: {
        top: 12,
        bottom: 20,
      },
    },
  };
  fs.writeFileSync(MERMAID_CONFIG_PATH, JSON.stringify(mermaidCfg, null, 2));
}

function shortHash(text) {
  return crypto.createHash('sha256').update(text.trim()).digest('hex').slice(0, 10);
}

function slugifyFile(filePath) {
  return path.basename(filePath, path.extname(filePath)).replace(/[^a-zA-Z0-9_-]/g, '-');
}

function escapeHtmlComment(code) {
  return code.replace(/-->/g, '--&gt;').replace(/<!-/g, '&lt;!-');
}

function unescapeHtmlComment(code) {
  return code.replace(/--&gt;/g, '-->').replace(/&lt;!-/g, '<!-');
}

function renderMermaidImages(mermaidCode, mmdPath, fullPngPath, previewPngPath, previewWidth = 1500) {
  ensureConfigs();
  fs.mkdirSync(path.dirname(fullPngPath), { recursive: true });
  fs.writeFileSync(mmdPath, mermaidCode.trim() + '\n', 'utf8');

  // Render high-res @3x full-size image
  execFileSync(
    MMDC_BIN,
    [
      '-i', mmdPath,
      '-o', fullPngPath,
      '-c', MERMAID_CONFIG_PATH,
      '-p', PUPPETEER_CONFIG_PATH,
      '-b', '#18181b',
      '-s', '3',
      '-w', '1800',
    ],
    { stdio: 'pipe' }
  );

  // Copy fullPngPath to previewPngPath and resize to target previewWidth using macOS sips
  fs.copyFileSync(fullPngPath, previewPngPath);
  if (previewWidth && previewWidth > 0 && fs.existsSync('/usr/bin/sips')) {
    try {
      execFileSync(
        '/usr/bin/sips',
        ['--resampleWidth', String(previewWidth), previewPngPath, '--out', previewPngPath],
        { stdio: 'pipe' }
      );
    } catch (_) {}
  }
}

/**
 * Pattern matches either:
 * 1) An already-managed md-mermaid block:
 *    <!-- md-mermaid:start ... --> ... <!-- md-mermaid:end -->
 * 2) Or a standalone ```mermaid ... ``` fenced code block.
 */
const COMBINED_REGEX = /<!--\s*md-mermaid:start[^>]*-->[\s\S]*?<!--\s*md-mermaid:end\s*-->|```mermaid\r?\n([\s\S]*?)```/g;
const INNER_MERMAID_REGEX = /```mermaid\r?\n([\s\S]*?)```/;

function buildReplacementBlock(absPreviewPath, absFullPath, absMmdPath, mermaidCode, hash, index) {
  const cleanCode = unescapeHtmlComment(mermaidCode.replace(/\s+$/, ''));
  const escapedCode = escapeHtmlComment(cleanCode);
  const previewUri = `file://${absPreviewPath}`;
  const fullUri = `file://${absFullPath}`;
  const mmdUri = `file://${absMmdPath}`;

  return [
    `<!-- md-mermaid:start hash=${hash} index=${index} -->`,
    ``,
    `![Mermaid Diagram ${index}](${previewUri})`,
    ``,
    `[🔍 View Full-Size Diagram](${fullUri}) · [📐 Edit Mermaid Source (.mmd)](${mmdUri})`,
    ``,
    `<!-- md-mermaid:source`,
    '```mermaid',
    escapedCode,
    '```',
    `-->`,
    `<!-- md-mermaid:end -->`,
  ].join('\n');
}

function processMarkdownFile(filePath, options = {}) {
  const absPath = path.resolve(filePath);
  if (!fs.existsSync(absPath)) {
    throw new Error(`File not found: ${absPath}`);
  }
  const previewWidth = options.width || 1500;
  const force = Boolean(options.force);
  const originalContent = fs.readFileSync(absPath, 'utf8');
  const mdDir = path.dirname(absPath);
  const fileSlug = slugifyFile(absPath);
  const mermaidSubdirName = '.mermaid';
  const mermaidDir = path.join(mdDir, mermaidSubdirName);

  let diagramIndex = 0;
  let renderedCount = 0;
  let cachedCount = 0;

  const updatedContent = originalContent.replace(COMBINED_REGEX, (fullMatch, standaloneCode) => {
    let mermaidCode = standaloneCode;
    if (mermaidCode === undefined) {
      const innerMatch = fullMatch.match(INNER_MERMAID_REGEX);
      if (!innerMatch) return fullMatch;
      mermaidCode = unescapeHtmlComment(innerMatch[1]);
    }

    diagramIndex += 1;
    const hash = shortHash(mermaidCode);
    const baseName = `${fileSlug}-${diagramIndex}-${hash}`;
    const absPreviewPath = path.join(mermaidDir, `${baseName}.png`);
    const absFullPath = path.join(mermaidDir, `${baseName}-full.png`);
    const absMmdPath = path.join(mermaidDir, `${baseName}.mmd`);

    if (force || !fs.existsSync(absPreviewPath) || !fs.existsSync(absFullPath) || !fs.existsSync(absMmdPath)) {
      if (fs.existsSync(mermaidDir)) {
        const prefix = `${fileSlug}-${diagramIndex}-`;
        for (const existing of fs.readdirSync(mermaidDir)) {
          if (existing.startsWith(prefix) && !existing.startsWith(baseName)) {
            try { fs.unlinkSync(path.join(mermaidDir, existing)); } catch (_) {}
          }
        }
      }
      renderMermaidImages(mermaidCode, absMmdPath, absFullPath, absPreviewPath, previewWidth);
      renderedCount += 1;
    } else {
      cachedCount += 1;
    }

    return buildReplacementBlock(absPreviewPath, absFullPath, absMmdPath, mermaidCode, hash, diagramIndex);
  });

  const fileModified = updatedContent !== originalContent;
  if (fileModified && diagramIndex > 0) {
    fs.writeFileSync(absPath, updatedContent, 'utf8');
  }

  return {
    file: absPath,
    diagramsFound: diagramIndex,
    renderedCount,
    cachedCount,
    fileModified,
  };
}

function revertMarkdownFile(filePath) {
  const absPath = path.resolve(filePath);
  const originalContent = fs.readFileSync(absPath, 'utf8');
  const managedRegex = /<!--\s*md-mermaid:start[^>]*-->[\s\S]*?<!--\s*md-mermaid:end\s*-->/g;
  const updatedContent = originalContent.replace(managedRegex, (block) => {
    const innerMatch = block.match(INNER_MERMAID_REGEX);
    if (!innerMatch) return block;
    const restored = unescapeHtmlComment(innerMatch[1].replace(/\s+$/, ''));
    return '```mermaid\n' + restored + '\n```';
  });
  const fileModified = updatedContent !== originalContent;
  if (fileModified) {
    fs.writeFileSync(absPath, updatedContent, 'utf8');
  }
  return { file: absPath, fileModified };
}

function collectMarkdownFiles(targetPath) {
  const abs = path.resolve(targetPath);
  const stat = fs.statSync(abs);
  if (stat.isFile()) {
    return abs.endsWith('.md') ? [abs] : [];
  }
  const results = [];
  for (const entry of fs.readdirSync(abs, { withFileTypes: true })) {
    if (entry.name.startsWith('.') || entry.name === 'node_modules' || entry.name === 'build') {
      continue;
    }
    const full = path.join(abs, entry.name);
    if (entry.isDirectory()) {
      results.push(...collectMarkdownFiles(full));
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      results.push(full);
    }
  }
  return results;
}

async function startMcpServer() {
  const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
  const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
  const {
    CallToolRequestSchema,
    ListToolsRequestSchema,
  } = require('@modelcontextprotocol/sdk/types.js');

  const server = new Server(
    { name: 'md-mermaid', version: '1.1.0' },
    { capabilities: { tools: {} } }
  );

  server.setRequestHandler(ListToolsRequestSchema, async () => ({
    tools: [
      {
        name: 'render_mermaid_in_markdown',
        description:
          'Renders all ```mermaid diagrams in a Markdown (.md) file or directory into local PNGs inside a sibling .mermaid/ folder (with both a 100%-width preview PNG and a clickable Full-Size PNG + .mmd source link using absolute file:// paths for Android Studio).',
        inputSchema: {
          type: 'object',
          properties: {
            targetPath: {
              type: 'string',
              description: 'Absolute path to a .md file or directory containing .md files.',
            },
            width: {
              type: 'number',
              description: 'Physical pixel width for the inline preview PNG (defaults to 1500 for full-width Retina display in Android Studio).',
            },
            force: {
              type: 'boolean',
              description: 'Force re-rendering PNGs even if the hash matches cached images.',
            },
          },
          required: ['targetPath'],
        },
      },
      {
        name: 'revert_mermaid_in_markdown',
        description: 'Reverts md-mermaid image blocks back to plain ```mermaid code blocks.',
        inputSchema: {
          type: 'object',
          properties: {
            targetPath: {
              type: 'string',
              description: 'Absolute path to a .md file or directory.',
            },
          },
          required: ['targetPath'],
        },
      },
    ],
  }));

  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    if (name === 'render_mermaid_in_markdown') {
      const files = collectMarkdownFiles(args.targetPath);
      const summaries = [];
      for (const f of files) {
        summaries.push(processMarkdownFile(f, { width: args.width || 1500, force: args.force }));
      }
      return {
        content: [{ type: 'text', text: JSON.stringify(summaries, null, 2) }],
      };
    }
    if (name === 'revert_mermaid_in_markdown') {
      const files = collectMarkdownFiles(args.targetPath);
      const summaries = files.map((f) => revertMarkdownFile(f));
      return {
        content: [{ type: 'text', text: JSON.stringify(summaries, null, 2) }],
      };
    }
    throw new Error(`Unknown tool: ${name}`);
  });

  const transport = new StdioServerTransport();
  await server.connect(transport);
}

function runWatch(targetPath, options = {}) {
  const chokidar = require('chokidar');
  const abs = path.resolve(targetPath);
  console.log(`[md-mermaid] Watching for Markdown Mermaid changes in: ${abs}`);
  const processing = new Set();

  const handleFile = (filePath) => {
    if (!filePath.endsWith('.md') || processing.has(filePath)) return;
    processing.add(filePath);
    try {
      const res = processMarkdownFile(filePath, options);
      if (res.renderedCount > 0 || res.fileModified) {
        console.log(`[md-mermaid] Updated ${path.basename(filePath)} (${res.renderedCount} rendered, ${res.cachedCount} cached)`);
      }
    } catch (err) {
      console.error(`[md-mermaid] Error in ${filePath}:`, err.message);
    } finally {
      setTimeout(() => processing.delete(filePath), 300);
    }
  };

  chokidar
    .watch(abs, {
      ignored: /(^|[\/\\])\..|node_modules|build/,
      persistent: true,
      ignoreInitial: false,
      awaitWriteFinish: { stabilityThreshold: 250, pollInterval: 100 },
    })
    .on('add', handleFile)
    .on('change', handleFile);
}

async function main() {
  const args = process.argv.slice(2);
  const cmd = args[0] || 'help';

  if (cmd === 'mcp') {
    await startMcpServer();
    return;
  }

  const widthFlagIdx = args.indexOf('--width');
  const width = widthFlagIdx !== -1 ? parseInt(args[widthFlagIdx + 1], 10) : 1500;
  const force = args.includes('--force');
  const positional = args.slice(1).filter(
    (a, i, arr) => !a.startsWith('--') && arr[i - 1] !== '--width'
  );

  if (cmd === 'sync' || cmd === 'render') {
    const target = positional[0] || process.cwd();
    const files = collectMarkdownFiles(target);
    let totalRendered = 0;
    let totalDiagrams = 0;
    for (const f of files) {
      const res = processMarkdownFile(f, { width, force });
      if (res.diagramsFound > 0) {
        totalDiagrams += res.diagramsFound;
        totalRendered += res.renderedCount;
        console.log(`✓ ${f}: ${res.diagramsFound} diagram(s) (${res.renderedCount} rendered, ${res.cachedCount} cached)`);
      }
    }
    console.log(`Done. Processed ${totalDiagrams} diagram(s) across ${files.length} Markdown file(s) (${totalRendered} newly rendered).`);
  } else if (cmd === 'watch') {
    const target = positional[0] || process.cwd();
    runWatch(target, { width, force });
  } else if (cmd === 'revert') {
    const target = positional[0] || process.cwd();
    const files = collectMarkdownFiles(target);
    for (const f of files) {
      const res = revertMarkdownFile(f);
      if (res.fileModified) {
        console.log(`↺ Reverted ${f}`);
      }
    }
  } else {
    console.log(`Usage:
  md-mermaid sync <file-or-dir> [--width 1500] [--force]
  md-mermaid watch <file-or-dir> [--width 1500]
  md-mermaid revert <file-or-dir>
  md-mermaid mcp`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
