import { App, Editor, MarkdownView, Modal, Notice, Plugin, PluginSettingTab, Setting, TFile, TAbstractFile } from 'obsidian';
import { getAPI, DataviewApi } from "obsidian-dataview";

interface DataviewPage {
	type: unknown;
	link: unknown;
	file: TFile;
}

interface LinkData {
	name: string;
	url: string;
	tags: string[];
	short_description: string;
	full_description: string;
	type: string;
}

interface LinksExportSettings {
	exportPath: string;
}

const DEFAULT_SETTINGS: LinksExportSettings = {
	exportPath: 'links.json'
}

export default class LinksExportPlugin extends Plugin {
	settings: LinksExportSettings;

	async onload() {
		await this.loadSettings();

		// Add a ribbon icon to trigger the export
		this.addRibbonIcon('link', 'Export Links to JSON', async () => {
			await this.exportLinks();
		});

		// Add settings tab
		this.addSettingTab(new LinksExportSettingTab(this.app, this));

		// This adds a status bar item to the bottom of the app. Does not work on mobile apps.
		const statusBarItemEl = this.addStatusBarItem();
		statusBarItemEl.setText('Status Bar Text');

		// This adds a simple command that can be triggered anywhere
		this.addCommand({
			id: 'open-sample-modal-simple',
			name: 'Open sample modal (simple)',
			callback: () => {
				new SampleModal(this.app).open();
			}
		});
		// This adds an editor command that can perform some operation on the current editor instance
		this.addCommand({
			id: 'sample-editor-command',
			name: 'Sample editor command',
			editorCallback: (editor: Editor, view: MarkdownView) => {
				console.log(editor.getSelection());
				editor.replaceSelection('Sample Editor Command');
			}
		});
		// This adds a complex command that can check whether the current state of the app allows execution of the command
		this.addCommand({
			id: 'open-sample-modal-complex',
			name: 'Open sample modal (complex)',
			checkCallback: (checking: boolean) => {
				// Conditions to check
				const markdownView = this.app.workspace.getActiveViewOfType(MarkdownView);
				if (markdownView) {
					// If checking is true, we're simply "checking" if the command can be run.
					// If checking is false, then we want to actually perform the operation.
					if (!checking) {
						new SampleModal(this.app).open();
					}

					// This command will only show up in Command Palette when the check function returns true
					return true;
				}
			}
		});

		// If the plugin hooks up any global DOM events (on parts of the app that doesn't belong to this plugin)
		// Using this function will automatically remove the event listener when this plugin is disabled.
		this.registerDomEvent(document, 'click', (evt: MouseEvent) => {
			console.log('click', evt);
		});

		// When registering intervals, this function will automatically clear the interval when the plugin is disabled.
		this.registerInterval(window.setInterval(() => console.log('setInterval'), 5 * 60 * 1000));
	}

	onunload() {

	}

	async loadSettings() {
		this.settings = Object.assign({}, DEFAULT_SETTINGS, await this.loadData());
	}

	async saveSettings() {
		await this.saveData(this.settings);
	}

	private formatWikiLink(link: string): string {
		// Extract text from [[link]] format
		const match = link.match(/\[\[(.*?)\]\]/);
		if (!match) return link;

		const linkContent = match[1];
		// If there's a pipe, take the second part, otherwise use the whole content
		const parts = linkContent.split('|');
		return parts.length > 1 ? parts[1] : parts[0];
	}

	private formatTags(tags: string): string[] {
		if (!tags) return [];
		// Split by comma and process each tag
		return tags.split(',')
			.map(tag => tag.trim())
			.map(tag => this.formatWikiLink(tag))
			.filter(tag => {
				// Keep tags that don't end in a file extension
				if (!tag.includes('.')) return true;
				// Or tags that specifically end in .md
				return tag.toLowerCase().endsWith('.md');
			})
			.map(tag => tag.replace(/\.md$/i, '')); // Remove .md extension if present
	}

	private formatDescription(description: string): string {
		// First replace [[link]] with **link**
		const withBoldLinks = description.replace(/\[\[(.*?)\]\]/g, (_, content) => {
			const parts = content.split('|');
			const text = parts.length > 1 ? parts[1] : parts[0];
			return `**${text}**`;
		});
		// Then escape pipe symbols and backticks
		return withBoldLinks
			.replace(/\|/g, '\\|')
			.replace(/`/g, '\\`');
	}

	async exportLinks() {
		console.log("Starting export process...");
		const dataviewApi: DataviewApi | undefined = getAPI();
		if (!dataviewApi) {
			console.error("Dataview API not available");
			new Notice('Dataview plugin is not available!');
			return;
		}
		console.log("Dataview API loaded successfully");

		try {
			// Get all pages using dataview query
			const query = 'TABLE WITHOUT ID file.path as Path, file.name as Name, link as Link, join(file.outlinks, ", ") as Tags, type as Type FROM "Notes" OR "Definitions" WHERE type = "link" OR type = "tool"';
			console.log("Executing query:", query);
			const result = await dataviewApi.query(query);
			console.log("Query result:", result);

			if (!result.successful) {
				console.error("Query failed:", result.error);
				throw new Error(result.error);
			}

			console.log("Number of rows returned:", result.value.values.length);
			console.log("Raw query results:", JSON.stringify(result.value.values, null, 2));

			const links = await Promise.all(result.value.values.map(async (row: string[]) => {
				console.log("Processing row:", row);
				// Load the full content of the page to get description
				const file = this.app.vault.getAbstractFileByPath(row[0]);
				if (!(file instanceof TFile)) {
					console.log("File not found or not a TFile:", row[0]);
					return null;
				}

				console.log("Loading content for file:", file.path);
				const content = await this.app.vault.read(file);
				const description = this.getDescription(content);
				console.log("Extracted description:", description);

				// Format tags and description
				const formattedTags = this.formatTags(row[3]);
				const formattedFullDescription = this.formatDescription(description);
				const formattedShortDescription = this.formatDescription(description.split('\n')[0]);

				// Return link object
				return {
					name: row[1],
					url: row[2],
					tags: formattedTags,
					short_description: formattedShortDescription,
					full_description: formattedFullDescription,
					type: row[4]
				} as LinkData;
			}));

			console.log("Processed links:", links);
			console.log("Number of valid links:", links.filter((link: LinkData | null) => link !== null).length);

			// Filter out null entries
			const validLinks = links.filter((link: LinkData | null): link is LinkData => link !== null);
			const jsonContent = JSON.stringify(validLinks, null, 2);

			console.log("Final JSON content:", jsonContent);

			// Save to file
			const exportFile = this.app.vault.getAbstractFileByPath(this.settings.exportPath);
			if (exportFile instanceof TFile) {
				console.log("Updating existing file:", this.settings.exportPath);
				await this.app.vault.modify(exportFile, jsonContent);
			} else {
				console.log("Creating new file:", this.settings.exportPath);
				await this.app.vault.create(this.settings.exportPath, jsonContent);
			}

			new Notice(`Links exported to ${this.settings.exportPath}`);
			console.log("Export completed successfully");
		} catch (error) {
			console.error('Error exporting links:', error);
			console.error('Error stack:', error.stack);
			new Notice('Error exporting links. Check console for details.');
		}
	}

	private getDescription(fileContent: string): string {
		const fileContentLines = fileContent.split('\n');
		const linkLineIdx = fileContentLines.findIndex(line => line.startsWith("## Link: "));
		if (linkLineIdx === -1) {
			console.log("No '## Link:' line found in content");
			return "";
		}
		const fileDescriptionLines = fileContentLines.slice(linkLineIdx + 1);
		return fileDescriptionLines.join("\n").trim();
	}
}

class SampleModal extends Modal {
	constructor(app: App) {
		super(app);
	}

	onOpen() {
		const { contentEl } = this;
		contentEl.setText('Woah!');
	}

	onClose() {
		const { contentEl } = this;
		contentEl.empty();
	}
}

class LinksExportSettingTab extends PluginSettingTab {
	plugin: LinksExportPlugin;

	constructor(app: App, plugin: LinksExportPlugin) {
		super(app, plugin);
		this.plugin = plugin;
	}

	display(): void {
		const { containerEl } = this;

		containerEl.empty();

		containerEl.createEl('h2', { text: 'Links Export Settings' });

		new Setting(containerEl)
			.setName('Export path')
			.setDesc('Path where the JSON file will be saved')
			.addText(text => text
				.setPlaceholder('links.json')
				.setValue(this.plugin.settings.exportPath)
				.onChange(async (value) => {
					this.plugin.settings.exportPath = value;
					await this.plugin.saveSettings();
				}));
	}
}
