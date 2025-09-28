<template>
    <v-container class="pa-2" fluid>
        <v-row>
            <!-- Status Widget - Always visible -->
            <v-col cols="12" md="6" lg="4">
                <nxt-status-widget />
            </v-col>

            <!-- Action Confirmation Widget - Visible when needed -->
            <v-col cols="12" md="6" lg="4" v-if="pendingAction">
                <nxt-action-confirmation-widget />
            </v-col>
        </v-row>

        <v-row>
            <!-- Probe Results Panel -->
            <v-col cols="12" lg="6">
                <nxt-probe-results-panel />
            </v-col>

            <!-- Probing Cycles Panel -->
            <v-col cols="12" lg="6">
                <nxt-probing-cycles-panel />
            </v-col>
        </v-row>

        <v-row>
            <!-- Configuration Panel -->
            <v-col cols="12">
                <nxt-configuration-panel />
            </v-col>
        </v-row>
    </v-container>
</template>

<script>
import BaseComponent from './components/base/BaseComponent.vue';

export default {
    name: 'NeXT',
    extends: BaseComponent,
    computed: {
        // Check if there's a pending action requiring confirmation
        pendingAction() {
            return this.$store.state.machine.model.global?.nxtPendingAction || null;
        }
    },
    mounted() {
        // Set global flag that UI is ready
        this.sendCode('set global.nxtUiReady = true');
        console.log('NeXT UI loaded successfully');
    },
    beforeDestroy() {
        // Clear UI ready flag when component is destroyed
        this.sendCode('set global.nxtUiReady = false');
    }
};
</script>

<style scoped>
.v-container {
    max-width: 1200px;
}
</style>