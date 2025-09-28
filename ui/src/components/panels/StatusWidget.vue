<template>
    <v-card class="nxt-status-widget">
        <v-card-title class="pb-2">
            <v-icon left color="primary">mdi-information-outline</v-icon>
            {{ $t('NeXT.status.title') }}
            <v-spacer />
            <v-chip small color="success" v-if="nxtLoaded">
                NeXT v{{ nxtVersion }}
            </v-chip>
            <v-chip small color="error" v-else>
                NeXT Not Loaded
            </v-chip>
        </v-card-title>
        
        <v-card-text>
            <v-row dense>
                <!-- Tool Information -->
                <v-col cols="12" sm="6">
                    <div class="status-item">
                        <strong>{{ $t('NeXT.status.tool') }}</strong>
                        <span v-if="currentTool" class="ml-2">
                            T{{ currentTool.number }} - {{ currentTool.name || 'Unnamed Tool' }}
                        </span>
                        <span v-else class="ml-2 text--secondary">
                            No Tool Selected
                        </span>
                    </div>
                </v-col>

                <!-- WCS Information -->
                <v-col cols="12" sm="6">
                    <div class="status-item">
                        <strong>{{ $t('NeXT.status.wcs') }}</strong>
                        <span class="ml-2">G{{ 53 + currentWorkplace }}</span>
                    </div>
                </v-col>

                <!-- Spindle Status -->
                <v-col cols="12">
                    <div class="status-item">
                        <strong>{{ $t('NeXT.status.spindle') }}</strong>
                        <span class="ml-2">
                            <v-icon small :color="spindleColor">{{ spindleIcon }}</v-icon>
                            {{ spindleStatusText }}
                            <span v-if="spindleRpm > 0" class="ml-1">
                                ({{ Math.round(spindleRpm) }} {{ $t('NeXT.status.rpm') }})
                            </span>
                        </span>
                    </div>
                </v-col>

                <!-- Current Position (if axes are homed) -->
                <v-col cols="12" v-if="allAxesHomed">
                    <div class="status-item">
                        <strong>Position:</strong>
                        <span class="ml-2">
                            <span v-for="(pos, axis) in absolutePosition" :key="axis" class="mr-3">
                                {{ axis }}{{ formatCoordinate(pos) }}
                            </span>
                        </span>
                    </div>
                </v-col>
            </v-row>
        </v-card-text>
    </v-card>
</template>

<script>
import BaseComponent from '../base/BaseComponent.vue';

export default {
    name: 'NxtStatusWidget',
    extends: BaseComponent,
    computed: {
        spindleState() {
            return this.$store.state.machine.model.spindles?.[0]?.state || 0;
        },

        spindleRpm() {
            return this.$store.state.machine.model.spindles?.[0]?.current || 0;
        },

        spindleColor() {
            switch (this.spindleState) {
                case 1: return 'success'; // Forward
                case -1: return 'warning'; // Reverse
                default: return 'grey'; // Off
            }
        },

        spindleIcon() {
            switch (this.spindleState) {
                case 1: return 'mdi-rotate-right';
                case -1: return 'mdi-rotate-left';
                default: return 'mdi-stop';
            }
        },

        spindleStatusText() {
            switch (this.spindleState) {
                case 1: return this.$t('NeXT.status.spindleForward');
                case -1: return this.$t('NeXT.status.spindleReverse');
                default: return this.$t('NeXT.status.spindleOff');
            }
        }
    }
};
</script>

<style scoped>
.nxt-status-widget {
    height: 100%;
}

.status-item {
    margin-bottom: 8px;
}

.status-item:last-child {
    margin-bottom: 0;
}
</style>