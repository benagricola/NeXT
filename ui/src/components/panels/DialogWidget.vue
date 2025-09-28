<template>
    <v-dialog v-model="dialogVisible" persistent max-width="500">
        <v-card>
            <v-card-title>
                <v-icon left color="primary">mdi-message-question</v-icon>
                {{ dialogTitle }}
            </v-card-title>
            
            <v-card-text>
                <div v-html="dialogMessage" class="dialog-message"></div>
                
                <!-- Progress bar for timeout -->
                <v-progress-linear
                    v-if="timeoutProgress > 0"
                    :value="timeoutProgress"
                    color="warning"
                    class="mt-3"
                    height="4"
                />
                <div v-if="timeoutProgress > 0" class="text-caption text-center mt-1">
                    {{ Math.ceil(remainingTime) }}s remaining
                </div>
            </v-card-text>
            
            <v-card-actions>
                <v-spacer />
                <v-btn
                    v-for="(choice, index) in dialogChoices"
                    :key="index"
                    :color="index === dialogDefault ? 'primary' : 'default'"
                    :variant="index === dialogDefault ? 'contained' : 'outlined'"
                    @click="respondToDialog(index)"
                    class="mx-1"
                >
                    {{ choice }}
                </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
import BaseComponent from '../base/BaseComponent.vue';

export default {
    name: 'NxtDialogWidget',
    extends: BaseComponent,
    data() {
        return {
            timeoutProgress: 0,
            remainingTime: 0,
            timeoutInterval: null
        };
    },

    computed: {
        // Check if dialog is active from global variables
        dialogVisible() {
            return this.$store.state.machine.model.global?.nxtDialogActive === true;
        },

        dialogMessage() {
            return this.$store.state.machine.model.global?.nxtDialogMessage || '';
        },

        dialogTitle() {
            return this.$store.state.machine.model.global?.nxtDialogTitle || 'NeXT';
        },

        dialogChoices() {
            const choices = this.$store.state.machine.model.global?.nxtDialogChoices;
            if (Array.isArray(choices)) {
                return choices;
            }
            // Default to Yes/No for S4 dialogs
            return ['Yes', 'No'];
        },

        dialogDefault() {
            return this.$store.state.machine.model.global?.nxtDialogDefault || 0;
        },

        dialogTimeout() {
            return this.$store.state.machine.model.global?.nxtDialogTimeout || 30;
        }
    },

    watch: {
        dialogVisible(newVal) {
            if (newVal) {
                this.startTimeout();
            } else {
                this.clearTimeout();
            }
        }
    },

    methods: {
        respondToDialog(buttonIndex) {
            // Send response back to macro
            this.sendCode(`set global.nxtDialogResponse = ${buttonIndex}`);
            this.clearTimeout();
        },

        startTimeout() {
            this.clearTimeout();
            this.remainingTime = this.dialogTimeout;
            this.timeoutProgress = 100;

            this.timeoutInterval = setInterval(() => {
                this.remainingTime -= 0.1;
                this.timeoutProgress = (this.remainingTime / this.dialogTimeout) * 100;

                if (this.remainingTime <= 0) {
                    // Timeout - select default or cancel option
                    this.respondToDialog(this.dialogDefault);
                }
            }, 100);
        },

        clearTimeout() {
            if (this.timeoutInterval) {
                clearInterval(this.timeoutInterval);
                this.timeoutInterval = null;
            }
            this.timeoutProgress = 0;
            this.remainingTime = 0;
        }
    },

    beforeDestroy() {
        this.clearTimeout();
    }
};
</script>

<style scoped>
.dialog-message {
    line-height: 1.5;
}

.dialog-message >>> b {
    font-weight: 600;
}

.v-btn {
    min-width: 80px;
}
</style>