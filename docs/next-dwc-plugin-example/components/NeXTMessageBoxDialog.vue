<template>
	<!-- Standard Modal Dialog (for non-NeXT dialogs or when NeXT UI not ready) -->
	<v-dialog v-if="shouldShowModal" v-model="modalShown" :no-click-animation="isPersistent" :persistent="isPersistent">
		<v-card>
			<v-card-title class="justify-center">
				<span class="headline">{{ messageBox.title }}</span>
			</v-card-title>
			<v-card-text>
				<div class="text-center" v-html="messageBox.message"></div>
			</v-card-text>
			<v-card-actions v-if="hasButtons" class="flex-wrap justify-center">
				<template v-if="isMultipleChoice">
					<v-btn v-for="(choice, index) in messageBox.choices" :key="choice" 
						   color="blue darken-1" :text="messageBox.default !== index" @click="accept(index)">
						{{ choice }}
					</v-btn>
					<v-btn v-if="messageBox.cancelButton" color="blue darken-1" text @click="cancel">
						{{ $t("generic.cancel") }}
					</v-btn>
				</template>
				<template v-else>
					<v-btn color="blue darken-1" text @click="ok" :disabled="!canConfirm">
						{{ $t(isPersistent ? "generic.ok" : "generic.close") }}
					</v-btn>
					<v-btn v-if="messageBox.cancelButton" color="blue darken-1" text @click="cancel">
						{{ $t("generic.cancel") }}
					</v-btn>
				</template>
			</v-card-actions>
		</v-card>
	</v-dialog>

	<!-- Persistent NeXT Dialog (shown in dedicated UI section) -->
	<div v-else-if="shouldShowPersistent" class="next-persistent-dialog">
		<v-card class="ma-2" elevation="2">
			<v-card-title class="next-dialog-title">
				<v-icon color="primary" class="mr-2">mdi-message-alert</v-icon>
				<span>{{ messageBox.title || nextDialogTitle }}</span>
				<v-spacer />
				<v-btn icon small @click="dismissPersistent" v-if="!isPersistent">
					<v-icon>mdi-close</v-icon>
				</v-btn>
			</v-card-title>
			
			<v-card-text>
				<div v-html="messageBox.message || nextDialogMessage"></div>
			</v-card-text>
			
			<v-card-actions v-if="hasButtons || nextDialogHasChoices">
				<v-spacer />
				<!-- NeXT Custom Dialog Choices -->
				<template v-if="nextDialogActive && nextDialogHasChoices">
					<v-btn v-for="(choice, index) in nextDialogChoices" :key="choice"
						   color="primary" @click="respondToNeXTDialog(index)">
						{{ choice }}
					</v-btn>
				</template>
				<!-- Standard M291 Dialog Choices -->
				<template v-else-if="isMultipleChoice">
					<v-btn v-for="(choice, index) in messageBox.choices" :key="choice"
						   color="primary" @click="accept(index)">
						{{ choice }}
					</v-btn>
				</template>
				<template v-else>
					<v-btn color="primary" @click="ok" :disabled="!canConfirm">
						{{ $t("generic.ok") }}
					</v-btn>
				</template>
			</v-card-actions>
		</v-card>
	</div>
</template>

<script lang="ts">
import { Axis, AxisLetter, MessageBox, MessageBoxMode } from "@duet3d/objectmodel";
import Vue from "vue";
import store from "@/store";
import { isNumber } from "@/utils/numbers";

export default Vue.extend({
	computed: {
		// Standard DWC MessageBox from object model
		currentMessageBox(): MessageBox | null { 
			return store.state.machine.model.state.messageBox; 
		},
		
		// NeXT UI readiness flag
		nxtUiReady(): boolean {
			return store.state.machine.model.global?.nxtUiReady === true;
		},
		
		// NeXT custom dialog state
		nextDialogActive(): boolean {
			return store.state.machine.model.global?.nxtDialogActive === true;
		},
		nextDialogMessage(): string | null {
			return store.state.machine.model.global?.nxtDialogMessage || null;
		},
		nextDialogTitle(): string | null {
			return store.state.machine.model.global?.nxtDialogTitle || null;
		},
		nextDialogChoices(): Array<string> | null {
			return store.state.machine.model.global?.nxtDialogChoices || null;
		},
		nextDialogHasChoices(): boolean {
			return store.state.machine.model.global?.nxtDialogHasChoices === true;
		},
		nextDialogFlag(): number {
			return store.state.machine.model.global?.nxtDialogFlag || 0;
		},
		
		// Dialog display logic
		shouldShowModal(): boolean {
			return (this.currentMessageBox && this.currentMessageBox.mode !== null) && 
				   (!this.nxtUiReady || this.nextDialogFlag === 2); // Always modal for critical dialogs
		},
		shouldShowPersistent(): boolean {
			return this.nxtUiReady && 
				   ((this.currentMessageBox && this.currentMessageBox.mode !== null) || this.nextDialogActive) &&
				   this.nextDialogFlag !== 2; // Not for critical dialogs
		},
		
		// Standard MessageBox properties (from original DWC component)
		messageBox(): MessageBox {
			return this.currentMessageBox || new MessageBox();
		},
		hasButtons(): boolean {
			return this.messageBox.mode !== MessageBoxMode.noButtons;
		},
		isMultipleChoice(): boolean {
			return this.messageBox.mode === MessageBoxMode.multipleChoice;
		},
		isPersistent(): boolean {
			return this.messageBox.mode >= MessageBoxMode.okOnly;
		},
		canConfirm(): boolean {
			// Simplified version - full validation would include input checks
			return true;
		}
	},
	
	data() {
		return {
			modalShown: false,
			numberInput: 0,
			stringInput: ""
		}
	},
	
	methods: {
		// Standard M291/M292 response methods (from original DWC component)
		async ok() {
			this.modalShown = false;
			if ([MessageBoxMode.closeOnly, MessageBoxMode.okOnly, MessageBoxMode.okCancel].includes(this.messageBox.mode)) {
				await store.dispatch("machine/sendCode", { code: `M292 S${this.messageBox.seq}`, noWait: true });
			}
		},
		
		async accept(choice: number) {
			this.modalShown = false;
			if (this.messageBox.mode >= MessageBoxMode.multipleChoice) {
				await store.dispatch("machine/sendCode", { code: `M292 R{${choice}} S${this.messageBox.seq}`, noWait: true });
			}
		},
		
		async cancel() {
			this.modalShown = false;
			if (this.messageBox.cancelButton) {
				await store.dispatch("machine/sendCode", { code: `M292 P1 S${this.messageBox.seq}`, noWait: true });
			}
		},
		
		// NeXT custom dialog response
		async respondToNeXTDialog(choice: number) {
			// Set the response in the global variable for M1000 to pick up
			await store.dispatch("machine/sendCode", { 
				code: `set global.nxtDialogResponse = ${choice}`, 
				noWait: true 
			});
		},
		
		// Dismiss persistent dialog
		dismissPersistent() {
			if (this.nextDialogActive) {
				store.dispatch("machine/sendCode", { 
					code: `set global.nxtDialogActive = false`, 
					noWait: true 
				});
			}
		}
	},
	
	watch: {
		currentMessageBox: {
			deep: true,
			handler(to: MessageBox | null) {
				if (to && to.mode !== null && this.shouldShowModal) {
					this.modalShown = true;
				} else {
					this.modalShown = false;
				}
			}
		}
	}
});
</script>

<style scoped>
.next-persistent-dialog {
	position: fixed;
	top: 80px;
	right: 16px;
	max-width: 400px;
	z-index: 100;
}

.next-dialog-title {
	background-color: var(--v-primary-base);
	color: white;
}

.next-dialog-title .v-icon {
	color: inherit !important;
}
</style>