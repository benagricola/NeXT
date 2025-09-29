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
            
            <!-- Input fields for number/string input modes -->
            <form v-if="needsNumberInput || needsStringInput" @submit.prevent="submitInput" class="mt-3">
                <v-text-field
                    v-if="needsNumberInput"
                    v-model.number="numberInput"
                    type="number"
                    :min="messageBox.min"
                    :max="messageBox.max"
                    :step="needsIntInput ? 1 : 'any'"
                    :label="needsIntInput ? 'Enter integer' : 'Enter number'"
                    outlined
                    dense
                    autofocus
                    required
                />
                <v-text-field
                    v-else-if="needsStringInput"
                    v-model="stringInput"
                    type="text"
                    :minlength="messageBox.min || 0"
                    :maxlength="messageBox.max || 100"
                    label="Enter text"
                    outlined
                    dense
                    autofocus
                    required
                />
            </form>
            
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
            <template v-if="needsNumberInput || needsStringInput">
                <!-- Input mode buttons -->
                <v-btn
                    color="primary"
                    :disabled="!canConfirm"
                    @click="submitInput"
                >
                    OK
                </v-btn>
                <v-btn
                    v-if="messageBox.cancelButton"
                    color="default"
                    variant="outlined"
                    @click="cancelMessage"
                    class="ml-2"
                >
                    Cancel
                </v-btn>
            </template>
            <template v-else-if="isMultipleChoice()">
                <!-- Multiple choice buttons (OK/Cancel, Yes/No, or custom choices) -->
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
                <!-- Cancel button if explicitly available -->
                <v-btn
                    v-if="messageBox.cancelButton"
                    color="default"
                    variant="outlined"
                    @click="cancelMessage"
                    class="mx-1"
                >
                    Cancel
                </v-btn>
            </template>
            <template v-else>
                <!-- Single button (OK, Close, etc.) -->
                <v-btn
                    v-for="(choice, index) in messageBoxChoices"
                    :key="index"
                    color="primary"
                    @click="respondToMessage(index)"
                    class="mx-1"
                >
                    {{ choice }}
                </v-btn>
            </template>
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
            timeoutInterval: null,
            numberInput: 0,
            stringInput: ''
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
            
            // If custom choices are provided, use them
            if (this.messageBox.choices && Array.isArray(this.messageBox.choices)) {
                return this.messageBox.choices;
            }
            
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
                    return ['OK'];
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
        },

        // Input handling computed properties
        needsIntInput() {
            return this.messageBox && this.messageBox.mode === 5; // IntInput mode
        },

        needsNumberInput() {
            return this.messageBox && (this.messageBox.mode === 5 || this.messageBox.mode === 6); // IntInput or FloatInput
        },

        needsStringInput() {
            return this.messageBox && this.messageBox.mode === 7; // StringInput mode
        },

        canConfirm() {
            if (this.needsNumberInput) {
                const isValidNumber = typeof this.numberInput === 'number' && !isNaN(this.numberInput);
                if (!isValidNumber) return false;
                
                if (this.needsIntInput && this.numberInput !== Math.round(this.numberInput)) {
                    return false;
                }
                
                if (this.messageBox.min !== null && this.numberInput < this.messageBox.min) return false;
                if (this.messageBox.max !== null && this.numberInput > this.messageBox.max) return false;
                
                return true;
            }

            if (this.needsStringInput) {
                const minLen = this.messageBox.min || 0;
                const maxLen = this.messageBox.max || 100;
                return this.stringInput.length >= minLen && this.stringInput.length <= maxLen;
            }

            return true;
        }
    },

    watch: {
        messageBox: {
            handler(newVal, oldVal) {
                if (newVal && !oldVal) {
                    // New message box appeared - initialize input values
                    if (typeof newVal.default === 'number') {
                        this.numberInput = newVal.default;
                    } else if (typeof newVal.default === 'string') {
                        this.stringInput = newVal.default;
                    } else {
                        this.numberInput = 0;
                        this.stringInput = '';
                    }
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
            if (!this.messageBox || !this.messageBox.seq) return;
            
            // Send proper M292 response with sequence number
            if (this.messageBox.mode >= 3) { // Multiple choice modes
                this.sendCode(`M292 R{${buttonIndex}} S${this.messageBox.seq}`);
            } else {
                // Simple OK/Close responses
                this.sendCode(`M292 S${this.messageBox.seq}`);
            }
            
            this.clearTimeout();
        },

        cancelMessage() {
            if (!this.messageBox || !this.messageBox.seq) return;
            
            // Send cancel response if cancel button is available
            if (this.messageBox.cancelButton) {
                this.sendCode(`M292 P1 S${this.messageBox.seq}`);
            }
            
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

        submitInput() {
            if (!this.canConfirm || !this.messageBox || !this.messageBox.seq) return;

            // Send input response with proper format
            if (this.needsNumberInput) {
                this.sendCode(`M292 R{${this.numberInput}} S${this.messageBox.seq}`);
            } else if (this.needsStringInput) {
                // Escape quotes in string input
                const escapedString = this.stringInput.replace(/"/g, '""').replace(/'/g, "''");
                this.sendCode(`M292 R{"${escapedString}"} S${this.messageBox.seq}`);
            }
            
            this.clearTimeout();
        },

        isMultipleChoice() {
            return this.messageBox && this.messageBox.mode >= 3 && this.messageBox.mode <= 4;
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
                    // Timeout - select default or first option for multiple choice
                    if (this.isMultipleChoice()) {
                        const defaultChoice = this.messageBox.default || 0;
                        this.respondToMessage(defaultChoice);
                    } else {
                        // For simple dialogs, just acknowledge
                        this.respondToMessage(0);
                    }
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