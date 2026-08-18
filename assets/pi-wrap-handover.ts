import { readFile, rename, rm, unlink, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, isAbsolute, join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const configDir = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
const pointerPath = join(configDir, "wrap-next.json");

async function claimPointer(): Promise<{ claim: string; next: string } | undefined> {
	const claim = `${pointerPath}.claim-${process.pid}`;
	try {
		await rename(pointerPath, claim);
	} catch {
		return;
	}

	try {
		const parsed = JSON.parse(await readFile(claim, "utf8")) as { path?: unknown };
		if (
			typeof parsed.path !== "string" ||
			!isAbsolute(parsed.path) ||
			!parsed.path.endsWith("/.plans/next.md")
		) {
			throw new Error("invalid handover path");
		}
		return { claim, next: parsed.path };
	} catch {
		await rm(claim, { force: true });
	}
}

async function consumeHandover(cwd: string): Promise<string | undefined> {
	const pointer = await claimPointer();
	const next = pointer?.next ?? join(cwd, ".plans", "next.md");

	try {
		const content = await readFile(next, "utf8");
		await writeFile(join(dirname(next), "next.prev.md"), content);
		await unlink(next);
		if (pointer) await rm(pointer.claim, { force: true });
		return content;
	} catch {
		if (pointer) {
			try {
				await rename(pointer.claim, pointerPath);
			} catch {
				await rm(pointer.claim, { force: true });
			}
		}
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (event, ctx) => {
		if (event.reason !== "startup" && event.reason !== "new") return;

		const handover = await consumeHandover(ctx.cwd);
		if (!handover) return;

		pi.sendMessage({
			customType: "wrap-handover",
			content: `Continue from this session handover:\n\n${handover}`,
			display: true,
		});
		ctx.ui.notify("Loaded .plans/next.md handover", "info");
	});
}
