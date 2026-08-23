import { readFile, rename, rm, unlink, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, isAbsolute, join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const configDir = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
const pointerPath = join(configDir, "wrap-next.json");

async function restoreOrDrop(claim: string): Promise<void> {
	try {
		await rename(claim, pointerPath);
	} catch {
		await rm(claim, { force: true });
	}
}

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
	let claim = pointer?.claim;
	let next = join(cwd, ".plans", "next.md");

	if (pointer) {
		// Honor the pointer only inside its own project; another project's
		// handover must not leak into this session.
		const project = dirname(dirname(pointer.next));
		if (cwd === project || cwd.startsWith(project + "/")) {
			next = pointer.next;
		} else {
			await restoreOrDrop(pointer.claim);
			claim = undefined;
		}
	}

	try {
		const content = await readFile(next, "utf8");
		await writeFile(join(dirname(next), "next.prev.md"), content);
		await unlink(next);
		if (claim) await rm(claim, { force: true });
		return content;
	} catch (error) {
		if (claim) {
			// Handover already consumed elsewhere: the pointer is stale, drop it.
			if ((error as NodeJS.ErrnoException).code === "ENOENT") {
				await rm(claim, { force: true });
			} else {
				await restoreOrDrop(claim);
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
