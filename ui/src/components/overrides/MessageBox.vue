<template>
    <!-- This component overrides DWC's MessageBox to integrate M291 dialogs into NeXT UI -->
    <v-card v-if="messageBox" class="nxt-message-box" elevation="8">
        <v-card-title class="pb-2">
            <v-icon left :color="messageBoxIcon.color">{{ messageBoxIcon.icon }}</v-icon>
            {{ messageBox.title || 'NeXT' }}
            <v-spacer />
            <v-chip small outlined>Non-blocking</v-chip>
        </v-card-title>
        
        <v-card-text>
            <div v-html="messageBox.message" class="message-content"></div>
            
            <!-- Progress bar for timeout -->
            <v-progress-linear
                v-if="hasTimeout && timeoutProgress > 0"
                :value="timeoutProgress"
                color="warning"
                class="mt-3"
                height="4"
            />
            <div v-if="hasTimeout && timeoutProgress > 0" class="text-caption text-center mt-1">
                {{ Math.ceil(remainingTime) }}s remaining
            </div>
        </v-card-text>
        
        <v-card-actions>
            <v-spacer />
            <v-btn
                v-for="(choice, index) in messageBoxChoices"
                :key="index"
                :color="getButtonColor(index)"
                :variant="getButtonVariant(index)"
                @click="respondToMessage(index)"
                class="mx-1"
            >
                {{ choice }}
            </v-btn>
        </v-card-actions>
    </v-card>
</template>

<script>
import BaseComponent from '../base/BaseComponent.vue';

export default {
    name: 'MessageBox',
    extends: BaseComponent,
    data() {
        return {
            timeoutProgress: 0,
            remainingTime: 0,
            timeoutInterval: null
        };
    },

    computed: {
        // Monitor RRF object model for message box state
        messageBox() {
            return this.$store.state.machine.model.messageBox;
        },

        hasTimeout() {
            return this.messageBox && this.messageBox.timeout > 0;
        },

        messageBoxChoices() {
            if (!this.messageBox) return [];
            
            // Handle different message box modes
            switch (this.messageBox.mode) {
                case 0: // Message only
                    return [];
                case 1: // Message with close button
                    return ['Close'];
                case 2: // Message with OK button
                    return ['OK'];
                case 3: // Message with OK/Cancel
                    return ['OK', 'Cancel'];
                case 4: // Message with Yes/No
                    return ['Yes', 'No'];
                default:
                    // Custom choices if provided
                    return this.messageBox.choices || ['OK'];
            }
        },

        messageBoxIcon() {
            if (!this.messageBox) return { icon: 'mdi-information', color: 'info' };
            
            // Determine icon based on message content or mode
            const message = (this.messageBox.message || '').toLowerCase();
            if (message.includes('caution') || message.includes('warning')) {
                return { icon: 'mdi-alert', color: 'warning' };
            }
            if (message.includes('error') || message.includes('abort')) {
                return { icon: 'mdi-alert-circle', color: 'error' };
            }
            if (this.messageBox.mode === 4) { // Yes/No questions
                return { icon: 'mdi-help-circle', color: 'primary' };
            }
            return { icon: 'mdi-information', color: 'info' };
        }
    },

    watch: {
        messageBox: {
            handler(newVal, oldVal) {
                if (newVal && !oldVal) {
                    // New message box appeared
                    this.startTimeout();
                } else if (!newVal && oldVal) {
                    // Message box disappeared
                    this.clearTimeout();
                }
            },
            immediate: true
        }
    },

    methods: {
        respondToMessage(buttonIndex) {
            if (!this.messageBox) return;
            
            // Send response to RRF
            this.sendCode(`M292 P${buttonIndex}`);
            this.clearTimeout();
        },

        getButtonColor(index) {
            if (!this.messageBox) return 'default';
            
            // Color coding for different button types
            if (this.messageBox.mode === 4) { // Yes/No
                return index === 0 ? 'success' : 'error'; // Yes=green, No=red
            }
            if (this.messageBox.mode === 3) { // OK/Cancel
                return index === 0 ? 'primary' : 'default'; // OK=primary, Cancel=default
            }
            
            // Check if this is the default button
            if (this.messageBox.default === index) {
                return 'primary';
            }
            
            return 'default';
        },

        getButtonVariant(index) {
            if (this.messageBox && this.messageBox.default === index) {
                return 'contained';
            }
            return 'outlined';
        },

        startTimeout() {
            this.clearTimeout();
            
            if (!this.hasTimeout) return;
            
            this.remainingTime = this.messageBox.timeout;
            this.timeoutProgress = 100;

            this.timeoutInterval = setInterval(() => {
                this.remainingTime -= 0.1;
                this.timeoutProgress = (this.remainingTime / this.messageBox.timeout) * 100;

                if (this.remainingTime <= 0) {
                    // Timeout - select default or first option
                    const defaultChoice = this.messageBox.default || 0;
                    this.respondToMessage(defaultChoice);
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
.nxt-message-box {
    position: fixed;
    top: 20px;
    right: 20px;
    max-width: 500px;
    z-index: 2000;
    border-left: 4px solid currentColor;
}

.message-content {
    line-height: 1.5;
}

.message-content >>> b {
    font-weight: 600;
}

.message-content >>> br {
    margin: 4px 0;
}

.v-btn {
    min-width: 80px;
}
</style>