<template>
    <v-card class="nxt-action-widget" v-if="pendingAction">
        <v-card-title class="pb-2">
            <v-icon left color="warning">mdi-alert-circle-outline</v-icon>
            {{ $t('NeXT.actions.title') }}
        </v-card-title>
        
        <v-card-text>
            <v-alert type="warning" outlined class="mb-3">
                {{ pendingActionMessage }}
            </v-alert>
            
            <v-row>
                <v-col cols="6">
                    <v-btn 
                        color="success" 
                        block 
                        large
                        :disabled="uiFrozen"
                        @click="confirmAction"
                    >
                        <v-icon left>mdi-check</v-icon>
                        {{ $t('NeXT.actions.confirm') }}
                    </v-btn>
                </v-col>
                <v-col cols="6">
                    <v-btn 
                        color="error" 
                        block 
                        large
                        :disabled="uiFrozen"
                        @click="cancelAction"
                    >
                        <v-icon left>mdi-close</v-icon>
                        {{ $t('NeXT.actions.cancel') }}
                    </v-btn>
                </v-col>
            </v-row>
        </v-card-text>
    </v-card>
</template>

<script>
import BaseComponent from '../base/BaseComponent.vue';

export default {
    name: 'NxtActionConfirmationWidget',
    extends: BaseComponent,
    computed: {
        pendingAction() {
            return this.$store.state.machine.model.global?.nxtPendingAction;
        },

        pendingActionMessage() {
            if (!this.pendingAction) return '';
            
            // Map action types to messages
            const actionMessages = {
                'spindle_start': this.$t('NeXT.actions.spindleStart'),
                'spindle_stop': this.$t('NeXT.actions.spindleStop'),
                'coolant_on': this.$t('NeXT.actions.coolantOn'),
                'coolant_off': this.$t('NeXT.actions.coolantOff')
            };
            
            return actionMessages[this.pendingAction] || this.pendingAction;
        }
    },

    methods: {
        confirmAction() {
            // Send confirmation response to backend
            this.sendCode('set global.nxtActionResponse = "confirm"');
            this.sendCode('set global.nxtPendingAction = null');
        },

        cancelAction() {
            // Send cancellation response to backend
            this.sendCode('set global.nxtActionResponse = "cancel"');
            this.sendCode('set global.nxtPendingAction = null');
        }
    }
};
</script>

<style scoped>
.nxt-action-widget {
    border: 2px solid #ff9800;
}
</style>